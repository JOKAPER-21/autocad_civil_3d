"""
Telegram Extension Downloader
------------------------------
Downloads files with chosen extensions from a Telegram chat/channel/group.

Setup:
    pip install telethon tqdm
    Fill in config.json, then:
        python downloader.py
"""

import asyncio
import csv
import json
import os
import re
import sys
import time
from datetime import datetime, timezone

from telethon import TelegramClient
from telethon.errors import FloodWaitError
from telethon.tl.types import DocumentAttributeFilename
from tqdm import tqdm

CONFIG_PATH = "config.json"
LOG_DIR = "logs"
CSV_LOG_PATH = os.path.join(LOG_DIR, "downloaded.csv")
ERROR_LOG_PATH = os.path.join(LOG_DIR, "errors.log")

CSV_FIELDS = ["Filename", "MessageID", "Date", "Size(MB)", "Status", "DownloadTime"]
INVALID_CHARS = r'<>:"/\|?*'


def load_config():
    if not os.path.exists(CONFIG_PATH):
        raise FileNotFoundError(f"{CONFIG_PATH} not found. Create it first.")
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    if not cfg.get("api_id") or not cfg.get("api_hash"):
        raise ValueError("config.json must include api_id and api_hash.")

    cfg.setdefault("extensions", [".dxf"])
    cfg.setdefault("output_folder", "downloads")
    cfg.setdefault("organize_by", "flat")
    cfg.setdefault("start_date", "")
    cfg.setdefault("end_date", "")
    cfg.setdefault("workers", 3)
    cfg.setdefault("retry_count", 5)
    cfg.setdefault("skip_existing", True)

    cfg["extensions"] = [
        e.lower() if e.startswith(".") else f".{e.lower()}" for e in cfg["extensions"]
    ]
    return cfg


def parse_date(value):
    if not value:
        return None
    return datetime.strptime(value, "%Y-%m-%d").replace(tzinfo=timezone.utc)


def sanitize(name: str) -> str:
    name = re.sub(f"[{re.escape(INVALID_CHARS)}]", "_", name)
    return name.strip() or "unnamed"


def get_filename(message):
    if not message.document:
        return None
    for attr in message.document.attributes:
        if isinstance(attr, DocumentAttributeFilename):
            return attr.file_name
    return None


class CsvLogger:
    """Appends rows to the CSV log and preloads already-downloaded message IDs for resume."""

    def __init__(self, path):
        self.path = path
        self.downloaded_ids = set()
        self._load_existing()
        self._ensure_header()

    def _load_existing(self):
        if not os.path.exists(self.path):
            return
        with open(self.path, "r", newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                if row.get("Status") == "Downloaded":
                    try:
                        self.downloaded_ids.add(int(row["MessageID"]))
                    except (KeyError, ValueError):
                        continue

    def _ensure_header(self):
        write_header = not os.path.exists(self.path) or os.path.getsize(self.path) == 0
        if write_header:
            with open(self.path, "a", newline="", encoding="utf-8") as f:
                csv.DictWriter(f, fieldnames=CSV_FIELDS).writeheader()

    def log(self, filename, message_id, date, size_mb, status, download_time):
        with open(self.path, "a", newline="", encoding="utf-8") as f:
            csv.DictWriter(f, fieldnames=CSV_FIELDS).writerow({
                "Filename": filename,
                "MessageID": message_id,
                "Date": date,
                "Size(MB)": f"{size_mb:.2f}",
                "Status": status,
                "DownloadTime": f"{download_time:.2f}s" if status == "Downloaded" else "-",
            })


def build_save_path(base_folder, organize_by, chat_name, msg_date, filename, message_id):
    if organize_by == "chat":
        folder = os.path.join(base_folder, sanitize(chat_name))
    elif organize_by == "chat_year_month":
        folder = os.path.join(
            base_folder, sanitize(chat_name), f"{msg_date.year:04d}", f"{msg_date.month:02d}"
        )
    else:
        folder = base_folder

    os.makedirs(folder, exist_ok=True)
    filename = sanitize(filename)
    candidate = os.path.join(folder, filename)

    if os.path.exists(candidate):
        stem, ext = os.path.splitext(filename)
        candidate = os.path.join(folder, f"{stem}_{message_id}{ext}")

    return candidate


async def choose_chat(client):
    dialogs = []
    print("\nLoading chats...\n")
    async for dialog in client.iter_dialogs():
        dialogs.append(dialog)

    for i, dialog in enumerate(dialogs):
        print(f"{i + 1:4d}. {dialog.name}")

    while True:
        raw = input("\nSelect chat number: ").strip()
        try:
            choice = int(raw)
        except ValueError:
            print("Invalid selection.")
            continue
        if 1 <= choice <= len(dialogs):
            return dialogs[choice - 1]
        print("Invalid selection.")


async def collect_messages(client, dialog, extensions, start_date, end_date):
    matches = []
    scanned = 0
    print("\nScanning messages (this can take a while for large chats)...")

    async for msg in client.iter_messages(dialog.entity):
        scanned += 1
        if scanned % 5000 == 0:
            print(f"  scanned {scanned:,} messages, {len(matches):,} matches so far...")

        if start_date and msg.date < start_date:
            continue
        if end_date and msg.date > end_date:
            continue

        filename = get_filename(msg)
        if filename and any(filename.lower().endswith(ext) for ext in extensions):
            matches.append(msg)

    matches.reverse()  # oldest first
    return matches, scanned


async def download_one(msg, cfg, chat_name, csv_logger, semaphore, global_bar, stats):
    filename = get_filename(msg)
    message_id = msg.id
    size_bytes = msg.file.size if msg.file else 0
    size_mb = size_bytes / (1024 * 1024)

    async with semaphore:
        save_path = build_save_path(
            cfg["output_folder"], cfg["organize_by"], chat_name, msg.date, filename, message_id
        )

        if cfg["skip_existing"] and (
            message_id in csv_logger.downloaded_ids or os.path.exists(save_path)
        ):
            csv_logger.log(filename, message_id, msg.date.isoformat(), size_mb, "Skipped", 0)
            stats["skipped"] += 1
            global_bar.update(1)
            return

        attempt = 0
        backoff = 2
        while attempt < cfg["retry_count"]:
            attempt += 1
            bar = tqdm(
                total=size_bytes, unit="B", unit_scale=True, unit_divisor=1024,
                desc=filename[:30], leave=False,
            )
            last = 0

            def progress_callback(current, total):
                nonlocal last
                bar.update(current - last)
                last = current

            try:
                start = time.time()
                await msg.download_media(file=save_path, progress_callback=progress_callback)
                bar.close()
                elapsed = time.time() - start

                csv_logger.log(filename, message_id, msg.date.isoformat(), size_mb, "Downloaded", elapsed)
                stats["downloaded"] += 1
                stats["bytes"] += size_bytes
                global_bar.update(1)
                return

            except FloodWaitError as e:
                bar.close()
                with open(ERROR_LOG_PATH, "a", encoding="utf-8") as ef:
                    ef.write(f"{datetime.now()} | {filename} (id={message_id}): FloodWait {e.seconds}s\n")
                await asyncio.sleep(e.seconds + 1)

            except Exception as exc:
                bar.close()
                with open(ERROR_LOG_PATH, "a", encoding="utf-8") as ef:
                    ef.write(f"{datetime.now()} | {filename} (id={message_id}) attempt {attempt}: {exc}\n")
                if attempt >= cfg["retry_count"]:
                    csv_logger.log(filename, message_id, msg.date.isoformat(), size_mb, "Error", 0)
                    stats["errors"] += 1
                    global_bar.update(1)
                    return
                await asyncio.sleep(backoff)
                backoff *= 2


async def main():
    cfg = load_config()
    os.makedirs(cfg["output_folder"], exist_ok=True)
    os.makedirs(LOG_DIR, exist_ok=True)

    start_date = parse_date(cfg["start_date"])
    end_date = parse_date(cfg["end_date"])

    csv_logger = CsvLogger(CSV_LOG_PATH)

    client = TelegramClient("telegram_session", cfg["api_id"], cfg["api_hash"])
    await client.start()

    dialog = await choose_chat(client)
    chat_name = dialog.name
    print(f"\nSelected: {chat_name}\n")

    messages, scanned = await collect_messages(client, dialog, cfg["extensions"], start_date, end_date)
    print(f"\nScanned {scanned:,} messages. Found {len(messages):,} matching files.\n")

    if not messages:
        print("Nothing to download.")
        await client.disconnect()
        return

    stats = {"downloaded": 0, "skipped": 0, "errors": 0, "bytes": 0}
    semaphore = asyncio.Semaphore(cfg["workers"])
    global_bar = tqdm(total=len(messages), desc="Overall progress", unit="file")

    tasks = [
        download_one(msg, cfg, chat_name, csv_logger, semaphore, global_bar, stats)
        for msg in messages
    ]

    started = time.time()
    try:
        await asyncio.gather(*tasks)
    except KeyboardInterrupt:
        print("\nInterrupted. Progress has been saved — rerun to resume.")
    finally:
        global_bar.close()
        elapsed = time.time() - started
        await client.disconnect()

        print("\n" + "-" * 40)
        print("Telegram Downloader — Summary")
        print("-" * 40)
        print(f"Chat:              {chat_name}")
        print(f"Messages scanned:  {scanned:,}")
        print(f"Matching files:    {len(messages):,}")
        print(f"Downloaded:        {stats['downloaded']:,}")
        print(f"Skipped:           {stats['skipped']:,}")
        print(f"Errors:            {stats['errors']:,}")
        print(f"Downloaded size:   {stats['bytes'] / (1024**3):.2f} GB")
        print(f"Elapsed time:      {elapsed / 60:.1f} min")
        if elapsed > 0:
            print(f"Average speed:     {stats['bytes'] / elapsed / (1024*1024):.2f} MB/s")
        print("-" * 40)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nStopped by user.")
        sys.exit(0)