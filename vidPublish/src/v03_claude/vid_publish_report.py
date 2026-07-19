#!/usr/bin/env python3
"""
vid_publish_report.py
-----------------------
Companion script for VidPublish.lsp (AutoCAD Civil 3D 2026 pipeline,
command VIDPUBLISH / alias PUBLISH).

WHAT THIS DOES
    The LSP does all the AutoCAD-side work (DWGPROPS comments, save,
    copy into a timestamped subfolder, optional PDF plot, log). This
    script does NOT touch AutoCAD or DWG files. It reads:
        <ROOT_PATH>\\publish_log.csv   (written by the LSP, one line per publish)
    and the actual folder structure under <ROOT_PATH>, then reports:
        - which yards have been published, and how many times
        - the most recent publish per yard, including PDF status
        - yards that have NEVER been published (still pending)
        - log entries whose destination DWG/PDF no longer exists on disk
          (e.g. someone deleted it, or it was on a server that's now
          disconnected for this user)
        - basic path-style mismatches (UNC vs local vs mapped drive) so
          you can see at a glance if different machines logged different
          root styles

    Each publish now lands in its own timestamped subfolder, e.g.:
        <publish>\\20260621_092903_delete-this\\20260621_092903_delete-this.dwg
        <publish>\\20260621_092903_delete-this\\20260621_092903_delete-this.pdf

USAGE
    python vid_publish_report.py "J:\\VID_autocad_publish_test"
    python vid_publish_report.py "\\\\server\\share\\VID_autocad_publish_test"
    (If no root is given, ROOT_PATH below is used.)

    Optional flags:
        --csv-out report.csv     write the full per-yard status table to CSV
        --missing-only           only list yards never published
        --json-out report.json   write a machine-readable summary

This script is read-only with respect to the publish log and DWG/PDF
files. It never modifies, moves, or deletes anything in ROOT_PATH.
"""

import sys
import os
import csv
import json
import argparse
from datetime import datetime
from pathlib import PureWindowsPath, Path

# --------------------------------------------------------------------------
# >>>>>>>>>>>>>>>>>>>>>  EDIT IF RUNNING WITHOUT ARGS  <<<<<<<<<<<<<<<<<<<<<
# Same root path as *VP-ROOT-PATH* in VidPublish.lsp.
# Only used if no path is passed on the command line.
# --------------------------------------------------------------------------
ROOT_PATH = r"J:\VID_autocad_publish_test"
# --------------------------------------------------------------------------

LOG_FILENAME = "publish_log.csv"

# Mirrors *VP-YARD-MAP* in VidPublish.lsp exactly.
# (code, segment) -- segment is the folder between root and dwg\yard\...
YARD_MAP = [
    ("NRK_naraikkinar", r"w1\MEJ_TEN"),
    ("GDN_gangaikondan", r"w1\MEJ_TEN"),
    ("TAY_talaiyuthu", r"w1\MEJ_TEN"),
    ("TEN_tirunelveli", r"w1\MEJ_TEN"),

    ("PCO_palayankottai", r"w1\TEN_TCN"),
    ("SDNR_seydunganallur", r"w1\TEN_TCN"),
    ("TTQ_thathankulam", r"w1\TEN_TCN"),
    ("SVV_srivaikuntam", r"w1\TEN_TCN"),
    ("AWT_alwarTirunagari", r"w1\TEN_TCN"),
    ("NZT_nazareth", r"w1\TEN_TCN"),
    ("KCHV_kachchanavilai", r"w1\TEN_TCN"),
    ("KZB_kurumbur", r"w1\TEN_TCN"),
    ("ANY_arumuganeri", r"w1\TEN_TCN"),
    ("KZY_kayalpattinam", r"w1\TEN_TCN"),
    ("TCN_tiruchendur", r"w1\TEN_TCN"),

    ("TYT_tirunelveliTown", r"w1\TEN_TSI"),
    ("PEA_pettai", r"w1\TEN_TSI"),
    ("SMD_cheranmahadevi", r"w1\TEN_TSI"),
    ("KARK_karraikkurichichi", r"w1\TEN_TSI"),
    ("VVR_viravanallur", r"w1\TEN_TSI"),
    ("KIC_kallidaikurichi", r"w1\TEN_TSI"),
    ("ASD_ambasamudram", r"w1\TEN_TSI"),
    ("KIB_kizhaAmbur", r"w1\TEN_TSI"),
    ("AZK_azhwarkurichi", r"w1\TEN_TSI"),
    ("RVS_ravanasamudram", r"w1\TEN_TSI"),
    ("KKY_kilakadaiyam", r"w1\TEN_TSI"),

    ("NLL_nalli", r"w2\NLL_TN"),
    ("CVP_kovilpatti", r"w2\NLL_TN"),
    ("KPM_kumarapuram", r"w2\NLL_TN"),
    ("KDU_kadambur", r"w2\NLL_TN"),
    ("MEJ_vanchiManiyachchi", r"w2\NLL_TN"),
    ("KLPM_kailasapuram", r"w2\NLL_TN"),
    ("TIP_tattapparai", r"w2\NLL_TN"),
    ("MVN_milavittan", r"w2\NLL_TN"),
    ("TME_tutimelur", r"w2\NLL_TN"),
    ("TN_tuticorin", r"w2\NLL_TN"),
    ("MMDR_melmarudur", r"w2\NLL_TN"),

    ("TDN_tiruparankundram", r"w3\MDU_NLL"),
    ("TMQ_tirumangalam", r"w3\MDU_NLL"),
    ("KGD_kalligudi", r"w3\MDU_NLL"),
    ("VPT_virudunagar", r"w3\MDU_NLL"),
    ("TY_tulikapatti", r"w3\MDU_NLL"),
    ("SRT_sattur", r"w3\MDU_NLL"),

    ("TTL_tiruttangal", r"w3\VPT_SNKL"),
    ("SVKS_sivakasi", r"w3\VPT_SNKL"),
    ("SVPR_srivilliputtur", r"w3\VPT_SNKL"),
    ("RJPM_rajapalayam", r"w3\VPT_SNKL"),

    ("SNKL_sankarankovil", r"w4\SNKL_EDP"),
    ("PBKS_pambakovilShandy", r"w4\SNKL_EDP"),
    ("KDNL_kadayanallur", r"w4\SNKL_EDP"),
    ("TSI_tenkasi", r"w4\SNKL_EDP"),
    ("SCT_sengottai", r"w4\SNKL_EDP"),
    ("BJM_bhagavathipuram", r"w4\SNKL_EDP"),
    ("AYV_aryankavu", r"w4\SNKL_EDP"),
    ("AYVN_newAryankavu", r"w4\SNKL_EDP"),
    ("EDN_edapalayam", r"w4\SNKL_EDP"),

    ("KTHY_kalthurutty", r"w4\EDP_QLN"),
    ("TML_tenmalai", r"w4\EDP_QLN"),
    ("OKL_ottakkal", r"w4\EDP_QLN"),
    ("EDN_edaman", r"w4\EDP_QLN"),
    ("PUU_punalur", r"w4\EDP_QLN"),
    ("AVS_avaneeswarem", r"w4\EDP_QLN"),
    ("KIF_kuri", r"w4\EDP_QLN"),
    ("KKZ_kottarakkara", r"w4\EDP_QLN"),
    ("EKN_ezhukone", r"w4\EDP_QLN"),
    ("KFV_kundaraEast", r"w4\EDP_QLN"),
    ("KUV_kundara", r"w4\EDP_QLN"),
    ("CTPE_chandanattop", r"w4\EDP_QLN"),
    ("KLQ_kilikollur", r"w4\EDP_QLN"),
    ("QLN_kollam", r"w4\EDP_QLN"),
]


# --------------------------------------------------------------------------
# PATH NORMALIZATION
# Same purpose as yp-normpath / yp-pathjoin in the LSP: different machines
# may have logged paths using local drives, mapped drives, UNC paths, or
# even forward slashes. We normalize everything to a comparable form
# using PureWindowsPath regardless of what OS this script runs on.
# --------------------------------------------------------------------------

def norm_win_path(raw: str) -> str:
    """Normalize a Windows-style path string: fix slash direction,
    collapse duplicate separators, strip trailing separator.
    Works even when this script is run on Linux/Mac for testing,
    since we use PureWindowsPath rather than relying on the host OS.
    """
    if not raw:
        return raw
    raw = raw.strip().replace("/", "\\")
    p = PureWindowsPath(raw)
    s = str(p)
    # PureWindowsPath collapses duplicate slashes already; just ensure
    # no trailing backslash (PureWindowsPath won't add one for normal
    # paths, this is defensive).
    if s.endswith("\\") and len(s) > 3:
        s = s.rstrip("\\")
    return s


def path_style(raw: str) -> str:
    """Classify a path as 'UNC', 'local-drive', or 'unknown' for the
    path-style mismatch report."""
    if not raw:
        return "unknown"
    raw = raw.strip()
    if raw.startswith("\\\\") or raw.startswith("//"):
        return "UNC"
    if len(raw) >= 2 and raw[1] == ":":
        return "local-drive"
    return "unknown"


def yard_target_folder(root: str, code: str, segment: str) -> str:
    """Reconstruct the expected publish folder for a yard code,
    mirroring yp-pathjoin in the LSP."""
    return norm_win_path(
        f"{root}\\{segment}\\dwg\\yard\\yd_{code}\\publish"
    )


# --------------------------------------------------------------------------
# LOG READING
# The LSP writes lines as:
#   timestamp,username,code,filename,srcpath,destdwg,pdfresult,destpdf,commands
#
#   pdfresult is one of: "ok", "failed", "skipped"
#     - "ok"      PDF checkbox was checked and the PDF plotted successfully
#     - "failed"  PDF checkbox was checked but plotting failed (DWG still published)
#     - "skipped" PDF checkbox was NOT checked
#   destpdf is still written even when pdfresult is "skipped"/"failed" (it's
#   the path the PDF *would* be at), so don't treat a non-empty destpdf as
#   proof a PDF file actually exists -- always check pdfresult first.
#
#   commands is free text from the dialog's Commands box (also written to
#   the drawing's DWGPROPS Comments field). The LSP strips commas/newlines
#   from this field before writing, so it should always be exactly one
#   CSV column -- but we still parse defensively below in case someone
#   hand-edited the CSV and reintroduced a comma.
# --------------------------------------------------------------------------

LOG_FIELDS = ["timestamp", "username", "code", "filename", "srcpath",
              "destdwg", "pdfresult", "destpdf", "commands"]
NUM_FIELDS = len(LOG_FIELDS)


def read_publish_log(root: str):
    """Read <root>\\publish_log.csv and return a list of dict rows.
    Returns an empty list (with a warning printed) if the log doesn't
    exist yet -- that's normal before the first publish.
    """
    # Build path string manually, since on non-Windows hosts Path()
    # won't understand backslashes as separators.
    log_path_str = norm_win_path(root) + "\\" + LOG_FILENAME

    candidate = _resolve_existing_path(log_path_str)
    if candidate is None:
        print(f"[INFO] No publish log found yet at: {log_path_str}")
        print("       (This is normal if nobody has published from the LSP yet.)")
        return []

    rows = []
    with open(candidate, "r", encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        for raw in reader:
            if not raw:
                continue
            if len(raw) < NUM_FIELDS:
                print(f"[WARN] Skipping malformed log line (too few fields): {raw}")
                continue
            if len(raw) > NUM_FIELDS:
                # Extra commas almost certainly came from the free-text
                # "commands" column (the last one). Keep the first
                # (NUM_FIELDS - 1) fields as-is, and re-glue everything
                # after that back into a single commands string.
                head = raw[:NUM_FIELDS - 1]
                commands_joined = ",".join(raw[NUM_FIELDS - 1:])
                row = dict(zip(LOG_FIELDS[:-1], head))
                row["commands"] = commands_joined
                rows.append(row)
                print(f"[WARN] Log line had extra commas in commands field, "
                      f"parsed leniently: {raw}")
                continue
            rows.append(dict(zip(LOG_FIELDS, raw)))
    return rows


def _resolve_existing_path(win_path: str):
    """Best-effort: check if a Windows-style path exists on THIS host.
    On Windows this just checks directly. On Linux/Mac (e.g. testing
    this script outside AutoCAD), Windows paths won't resolve, so this
    returns None and callers should treat that as 'not found here'.
    """
    if os.name == "nt":
        return win_path if os.path.isfile(win_path) else None
    # Non-Windows host: can't resolve a J:\ or \\server\ path directly.
    # Allow a fallback: if the user passed a path that's ALSO valid as
    # a POSIX path (e.g. testing with /mnt/... root), try that.
    posix_guess = win_path.replace("\\", "/")
    if os.path.isfile(posix_guess):
        return posix_guess
    return None


# --------------------------------------------------------------------------
# REPORT BUILDING
# --------------------------------------------------------------------------

def build_yard_status(root: str, log_rows: list):
    """For every yard in YARD_MAP, compute:
        - publish_count
        - last_published (timestamp string, or None)
        - last_dest (DWG path string, or None)
        - last_dest_exists (bool or 'unknown' if not checkable here)
        - last_pdf_result ("ok" / "failed" / "skipped" / None)
        - last_pdf_path (PDF path string, or None)
        - last_pdf_exists (bool, 'unknown', or 'n/a' if pdfresult != "ok")
        - last_commands (text written to DWGPROPS Comments, or None)
        - target_folder (expected publish folder)
        - path_style_seen (set of styles seen in log destdwg paths for this yard)
    """
    by_code = {code: [] for code, _ in YARD_MAP}
    for row in log_rows:
        code = row.get("code", "")
        if code in by_code:
            by_code[code].append(row)

    status = []
    for code, segment in YARD_MAP:
        rows = by_code[code]
        rows_sorted = sorted(rows, key=lambda r: r.get("timestamp", ""))
        last = rows_sorted[-1] if rows_sorted else None

        target_folder = yard_target_folder(root, code, segment)

        last_dest = last["destdwg"] if last else None
        dwg_exists = "unknown"
        if last_dest:
            dwg_exists = _resolve_existing_path_any(last_dest) is not None

        pdf_result = last.get("pdfresult") if last else None
        pdf_path = last.get("destpdf") if last else None
        if pdf_result == "ok" and pdf_path:
            pdf_exists = _resolve_existing_path_any(pdf_path) is not None
        elif pdf_result in ("failed", "skipped"):
            pdf_exists = "n/a"
        else:
            pdf_exists = "unknown"

        styles_seen = sorted({path_style(r.get("destdwg", "")) for r in rows}) if rows else []

        status.append({
            "code": code,
            "segment": segment,
            "target_folder": target_folder,
            "publish_count": len(rows),
            "last_published": last["timestamp"] if last else None,
            "last_user": last["username"] if last else None,
            "last_dest": last_dest,
            "last_dest_exists": dwg_exists,
            "last_pdf_result": pdf_result,
            "last_pdf_path": pdf_path,
            "last_pdf_exists": pdf_exists,
            "last_commands": last.get("commands") if last else None,
            "path_styles_seen": styles_seen,
        })
    return status


def _resolve_existing_path_any(win_path: str):
    """Like _resolve_existing_path but for an arbitrary file (not
    necessarily the log itself)."""
    if not win_path:
        return None
    if os.name == "nt":
        return win_path if os.path.isfile(win_path) else None
    posix_guess = win_path.replace("\\", "/")
    if os.path.isfile(posix_guess):
        return posix_guess
    return None


def print_summary(status: list, missing_only: bool):
    published = [s for s in status if s["publish_count"] > 0]
    pending = [s for s in status if s["publish_count"] == 0]

    print("=" * 78)
    print(f"VID PUBLISH REPORT  -  generated {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 78)
    print(f"Total yards tracked     : {len(status)}")
    print(f"Yards published >=1 time: {len(published)}")
    print(f"Yards never published   : {len(pending)}")
    print("-" * 78)

    if not missing_only:
        print("\nPUBLISHED YARDS")
        print("-" * 78)
        for s in published:
            dwg_flag = {
                True: "OK",
                False: "MISSING ON DISK",
                "unknown": "unverified (different host/drive)",
            }[s["last_dest_exists"]]

            pdf_flag = {
                "ok": "OK" if s["last_pdf_exists"] is True else
                      ("MISSING ON DISK" if s["last_pdf_exists"] is False else "unverified"),
                "failed": "PLOT FAILED",
                "skipped": "not requested",
                None: "n/a",
            }.get(s["last_pdf_result"], "n/a")

            print(f"  {s['code']:<26} count={s['publish_count']:<3} "
                  f"last={s['last_published']:<16} by={s['last_user']:<12} "
                  f"[DWG:{dwg_flag}] [PDF:{pdf_flag}]")
            if s["last_commands"]:
                print(f"      commands: {s['last_commands']}")
            if len(s["path_styles_seen"]) > 1:
                print(f"      ! multiple path styles logged for this yard: {s['path_styles_seen']}")

    print("\nPENDING YARDS (never published)")
    print("-" * 78)
    if not pending:
        print("  (none - every yard has been published at least once)")
    for s in pending:
        print(f"  {s['code']:<26} expected target: {s['target_folder']}")

    print("=" * 78)


def write_csv(status: list, out_path: str):
    fieldnames = ["code", "segment", "publish_count", "last_published",
                  "last_user", "last_dest", "last_dest_exists",
                  "last_pdf_result", "last_pdf_path", "last_pdf_exists",
                  "last_commands", "path_styles_seen", "target_folder"]
    with open(out_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for s in status:
            row = dict(s)
            row["path_styles_seen"] = ";".join(s["path_styles_seen"])
            writer.writerow(row)
    print(f"\n[OK] CSV report written: {out_path}")


def write_json(status: list, out_path: str):
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(status, f, indent=2)
    print(f"[OK] JSON report written: {out_path}")


# --------------------------------------------------------------------------
# CLI ENTRY POINT
# --------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Report on yard publish status from publish_log.csv "
                     "(companion to VidPublish.lsp / VIDPUBLISH command)."
    )
    parser.add_argument("root", nargs="?", default=ROOT_PATH,
                         help="Root path (local drive, mapped drive, or "
                              "UNC server path). Defaults to ROOT_PATH "
                              "set at the top of this script.")
    parser.add_argument("--csv-out", default=None,
                         help="Write full per-yard status table to this CSV file.")
    parser.add_argument("--json-out", default=None,
                         help="Write full per-yard status table to this JSON file.")
    parser.add_argument("--missing-only", action="store_true",
                         help="Only print yards that have never been published.")
    args = parser.parse_args()

    root = norm_win_path(args.root)
    print(f"Root path: {root}  (style: {path_style(root)})\n")

    log_rows = read_publish_log(root)
    status = build_yard_status(root, log_rows)
    print_summary(status, args.missing_only)

    if args.csv_out:
        write_csv(status, args.csv_out)
    if args.json_out:
        write_json(status, args.json_out)


if __name__ == "__main__":
    main()
