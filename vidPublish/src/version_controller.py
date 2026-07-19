"""
Version Controller — Publish Log Viewer
----------------------------------------
A native Windows desktop tool (Tkinter, stdlib only — no installs needed)
for browsing the DWG/PDF publish log CSV.

Default log path:
    \\\\Desktop-igi8ekn\\VID_20D\\share\\updated_projects_files\\section\\publish_log.csv

Features:
    - Auto-loads the default CSV path on startup (falls back to file picker if missing)
    - Column structure is read directly from the CSV header (works with any CSV,
      not hardcoded to specific column names)
    - Per-column checkbox filters (multi-select), like Google Sheets filter-by-condition
    - Free-text search across all columns
    - Click any path cell -> "Open in Explorer" button opens that folder directly
      in Windows File Explorer (uses the real path, opens the containing folder
      and selects the file if it exists)
    - Sort by clicking column headers
    - Export the currently filtered/sorted view to a new CSV
    - Auto-refresh button to re-read the CSV from disk (since it's a live log)

Run with:  python version_controller.py
Requires:  Python 3.8+ on Windows 11 (uses only the standard library)
"""

import csv
import os
import re
import subprocess
import sys
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from collections import OrderedDict

DEFAULT_LOG_PATH = r"\\Desktop-igi8ekn\VID_20D\share\updated_projects_files\section\publish_log.csv"

APP_BG = "#10141a"
PANEL_BG = "#161b22"
PANEL_BG_2 = "#1c222b"
LINE = "#2a323d"
TEXT = "#d7dde4"
TEXT_DIM = "#8a96a3"
TEXT_FAINT = "#5a6470"
AMBER = "#e0a030"
AMBER_DARK = "#7a5a22"
GREEN = "#5fb87a"
RED = "#d9685f"
ROW_EVEN = "#161b22"
ROW_ODD = "#10141a"
MONO_FONT = ("Consolas", 9)
SANS_FONT = ("Segoe UI", 9)
SANS_BOLD = ("Segoe UI", 9, "bold")
TITLE_FONT = ("Segoe UI", 13, "bold")


def looks_like_path(values):
    hits = 0
    checked = 0
    for v in values:
        if not v:
            continue
        checked += 1
        if re.search(r"[\\/]", v) and (re.search(r"\.\w{2,5}$", v) or len(re.split(r"[\\/]", v)) > 2):
            hits += 1
    return checked > 0 and hits > checked * 0.4


def looks_like_datetime(key, values):
    if re.search(r"date|time|timestamp", key, re.I):
        return True
    hits = 0
    checked = 0
    for v in values:
        if not v:
            continue
        checked += 1
        if re.match(r"^\d{8}_\d{6}$", v) or re.match(r"^\d{4}-\d{2}-\d{2}", v):
            hits += 1
    return checked > 0 and hits > checked * 0.5


def looks_like_status(values):
    distinct = set(v for v in values if v)
    if not distinct or len(distinct) > 6:
        return False
    avg_len = sum(len(v) for v in distinct) / len(distinct)
    return avg_len < 16


def format_datetime_value(v):
    m = re.match(r"^(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})$", v)
    if m:
        y, mo, d, h, mi, s = m.groups()
        return f"{d}-{mo}-{y} {h}:{mi}:{s}"
    return v


class Column:
    def __init__(self, key, idx, values):
        self.key = key
        self.idx = idx
        self.label = key.replace("_", " ")
        self.is_date = looks_like_datetime(key, values)
        self.is_path = (not self.is_date) and looks_like_path(values)
        self.is_status = (not self.is_date) and (not self.is_path) and looks_like_status(values)
        self.is_long_text = (not self.is_date) and (not self.is_path) and (not self.is_status) and any(len(v) > 40 for v in values)
        distinct_count = len(set(v for v in values if v))
        self.filterable = (
            not self.is_path
            and not self.is_long_text
            and distinct_count > 0
            and distinct_count <= max(15, int(len(values) * 0.6) + 1)
        )


class FilterPopover(tk.Toplevel):
    def __init__(self, parent, app, column, anchor_widget):
        super().__init__(parent)
        self.app = app
        self.column = column
        self.overrideredirect(True)
        self.configure(bg=LINE, bd=1)
        self.resizable(False, False)

        x = anchor_widget.winfo_rootx()
        y = anchor_widget.winfo_rooty() + anchor_widget.winfo_height() + 2
        self.geometry(f"240x340+{x}+{y}")

        outer = tk.Frame(self, bg=PANEL_BG_2)
        outer.pack(fill="both", expand=True, padx=1, pady=1)

        head = tk.Frame(outer, bg=PANEL_BG_2)
        head.pack(fill="x", padx=10, pady=(8, 4))
        tk.Label(head, text=f"Filter — {column.label}", bg=PANEL_BG_2, fg=TEXT_DIM,
                  font=("Segoe UI", 8, "bold")).pack(side="left")
        link_frame = tk.Frame(head, bg=PANEL_BG_2)
        link_frame.pack(side="right")
        tk.Label(link_frame, text="All", bg=PANEL_BG_2, fg=AMBER, font=("Segoe UI", 8, "bold"),
                  cursor="hand2").pack(side="left", padx=(0, 6))
        tk.Label(link_frame, text="None", bg=PANEL_BG_2, fg=AMBER, font=("Segoe UI", 8, "bold"),
                  cursor="hand2").pack(side="left")
        all_lbl, none_lbl = link_frame.winfo_children()
        all_lbl.bind("<Button-1>", lambda e: self.set_all(True))
        none_lbl.bind("<Button-1>", lambda e: self.set_all(False))

        search_frame = tk.Frame(outer, bg=PANEL_BG_2)
        search_frame.pack(fill="x", padx=10, pady=(0, 6))
        self.search_var = tk.StringVar()
        search_entry = tk.Entry(search_frame, textvariable=self.search_var, bg=APP_BG, fg=TEXT,
                                  insertbackground=TEXT, relief="flat", font=SANS_FONT)
        search_entry.pack(fill="x", ipady=3)
        self.search_var.trace_add("write", lambda *a: self.rebuild_list())

        list_container = tk.Frame(outer, bg=PANEL_BG_2)
        list_container.pack(fill="both", expand=True, padx=4)
        canvas = tk.Canvas(list_container, bg=PANEL_BG_2, highlightthickness=0, height=200)
        scrollbar = ttk.Scrollbar(list_container, orient="vertical", command=canvas.yview)
        self.list_frame = tk.Frame(canvas, bg=PANEL_BG_2)
        self.list_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=self.list_frame, anchor="nw", width=210)
        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        foot = tk.Frame(outer, bg=PANEL_BG_2)
        foot.pack(fill="x", padx=10, pady=8)
        apply_btn = tk.Button(foot, text="Apply", bg=AMBER, fg="#1a1304", relief="flat",
                                font=("Segoe UI", 8, "bold"), command=self.apply, cursor="hand2",
                                activebackground="#eeb44a")
        apply_btn.pack(side="right", ipadx=10, ipady=2)

        self.value_vars = OrderedDict()
        self.value_counts = self.app.unique_values(column.key)
        self.rebuild_list()

        self.bind("<FocusOut>", lambda e: self.maybe_close())
        self.focus_set()
        self.transient(parent)

    def maybe_close(self):
        self.after(150, self._check_close)

    def _check_close(self):
        try:
            if self.focus_get() is None:
                self.destroy()
        except Exception:
            pass

    def set_all(self, checked):
        for var in self.value_vars.values():
            var.set(checked)

    def rebuild_list(self):
        for w in self.list_frame.winfo_children():
            w.destroy()
        filt = self.search_var.get().lower()
        existing = {k: v.get() for k, v in self.value_vars.items()}
        self.value_vars.clear()
        current_filter = self.app.filters.get(self.column.key, set())
        for val, count in self.value_counts:
            if filt and filt not in val.lower():
                continue
            checked = existing.get(val, (len(current_filter) == 0 or val in current_filter))
            var = tk.BooleanVar(value=checked)
            self.value_vars[val] = var
            row = tk.Frame(self.list_frame, bg=PANEL_BG_2)
            row.pack(fill="x", pady=1)
            cb = tk.Checkbutton(row, variable=var, bg=PANEL_BG_2, fg=TEXT, selectcolor=APP_BG,
                                  activebackground=PANEL_BG_2, relief="flat", highlightthickness=0,
                                  font=MONO_FONT)
            cb.pack(side="left")
            lbl_text = val if len(val) <= 24 else val[:21] + "..."
            tk.Label(row, text=lbl_text, bg=PANEL_BG_2, fg=TEXT, font=MONO_FONT, anchor="w").pack(side="left", fill="x", expand=True)
            tk.Label(row, text=str(count), bg=PANEL_BG_2, fg=TEXT_FAINT, font=("Consolas", 8)).pack(side="right", padx=(0, 4))

    def apply(self):
        checked_vals = {val for val, var in self.value_vars.items() if var.get()}
        total_vals = {val for val, _ in self.value_counts}
        if checked_vals == total_vals or len(checked_vals) == 0:
            self.app.filters[self.column.key] = set()
        else:
            self.app.filters[self.column.key] = checked_vals
        self.app.render()
        self.destroy()


class VersionControllerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Version Controller — Publish Log")
        self.root.geometry("1400x780")
        self.root.minsize(900, 500)
        self.root.configure(bg=APP_BG)

        self.columns = []
        self.data = []
        self.raw_headers = []
        self.filters = {}
        self.search_term = ""
        self.sort_key = None
        self.sort_desc = True
        self.current_csv_path = None
        self.filter_buttons = {}

        self._build_style()
        self._build_ui()

        self.load_csv(DEFAULT_LOG_PATH, prompt_on_fail=True)

    # ---------------------------------------------------------- styling
    def _build_style(self):
        style = ttk.Style()
        try:
            style.theme_use("clam")
        except Exception:
            pass
        style.configure("Treeview",
                         background=PANEL_BG, fieldbackground=PANEL_BG, foreground=TEXT,
                         rowheight=26, font=SANS_FONT, borderwidth=0)
        style.configure("Treeview.Heading",
                         background=PANEL_BG_2, foreground=TEXT_DIM, font=("Segoe UI", 8, "bold"),
                         relief="flat", borderwidth=0)
        style.map("Treeview.Heading", background=[("active", "#222932")])
        style.map("Treeview",
                  background=[("selected", "#243040")],
                  foreground=[("selected", TEXT)])
        style.configure("Vertical.TScrollbar", background=PANEL_BG_2, troughcolor=APP_BG,
                         bordercolor=APP_BG, arrowcolor=TEXT_DIM)
        style.configure("Horizontal.TScrollbar", background=PANEL_BG_2, troughcolor=APP_BG,
                         bordercolor=APP_BG, arrowcolor=TEXT_DIM)

    # ---------------------------------------------------------- UI build
    def _build_ui(self):
        # ===== Title bar =====
        titlebar = tk.Frame(self.root, bg=PANEL_BG, height=58)
        titlebar.pack(fill="x", side="top")
        titlebar.pack_propagate(False)

        left = tk.Frame(titlebar, bg=PANEL_BG)
        left.pack(side="left", padx=16, pady=8)

        stamp = tk.Label(left, text="REV", bg=APP_BG, fg=AMBER, font=("Consolas", 9, "bold"),
                          relief="solid", bd=2, width=4, height=2)
        stamp.pack(side="left", padx=(0, 10))

        title_box = tk.Frame(left, bg=PANEL_BG)
        title_box.pack(side="left")
        tk.Label(title_box, text="Version Controller", bg=PANEL_BG, fg="white", font=TITLE_FONT).pack(anchor="w")
        self.sub_label = tk.Label(title_box, text="No file loaded", bg=PANEL_BG, fg=TEXT_DIM, font=("Consolas", 8))
        self.sub_label.pack(anchor="w")

        right = tk.Frame(titlebar, bg=PANEL_BG)
        right.pack(side="right", padx=16, pady=8)
        self.counter_label = tk.Label(right, text="", bg=PANEL_BG, fg=TEXT_DIM, font=("Consolas", 8))
        self.counter_label.pack(side="left", padx=(0, 12))

        self._make_btn(right, "⟳ Refresh", self.refresh_csv).pack(side="left", padx=2)
        self._make_btn(right, "📂 Open File...", self.browse_csv).pack(side="left", padx=2)

        # ===== Toolbar =====
        toolbar = tk.Frame(self.root, bg=PANEL_BG_2, height=46)
        toolbar.pack(fill="x", side="top")
        toolbar.pack_propagate(False)

        search_frame = tk.Frame(toolbar, bg=APP_BG, highlightbackground=LINE, highlightthickness=1)
        search_frame.pack(side="left", padx=12, pady=8, ipady=2)
        tk.Label(search_frame, text="🔍", bg=APP_BG, fg=TEXT_DIM, font=("Segoe UI", 9)).pack(side="left", padx=(6, 2))
        self.search_var = tk.StringVar()
        search_entry = tk.Entry(search_frame, textvariable=self.search_var, bg=APP_BG, fg=TEXT,
                                  insertbackground=TEXT, relief="flat", font=MONO_FONT, width=32)
        search_entry.pack(side="left", padx=(0, 8), ipady=3)
        self.search_var.trace_add("write", self._on_search)

        self.filter_strip = tk.Frame(toolbar, bg=PANEL_BG_2)
        self.filter_strip.pack(side="left", padx=4, pady=8)

        right_tools = tk.Frame(toolbar, bg=PANEL_BG_2)
        right_tools.pack(side="right", padx=12, pady=8)
        self._make_btn(right_tools, "Clear filters", self.clear_filters).pack(side="left", padx=2)
        self._make_btn(right_tools, "⬇ Export view", self.export_view).pack(side="left", padx=2)

        # ===== Active filter chips =====
        self.chips_frame = tk.Frame(self.root, bg=APP_BG)
        self.chips_frame.pack(fill="x", padx=12, pady=(6, 0))

        # ===== Table =====
        table_frame = tk.Frame(self.root, bg=APP_BG)
        table_frame.pack(fill="both", expand=True, padx=12, pady=10)

        self.tree = ttk.Treeview(table_frame, show="headings", selectmode="browse")
        vsb = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        hsb = ttk.Scrollbar(table_frame, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

        self.tree.grid(row=0, column=0, sticky="nsew")
        vsb.grid(row=0, column=1, sticky="ns")
        hsb.grid(row=1, column=0, sticky="ew")
        table_frame.grid_rowconfigure(0, weight=1)
        table_frame.grid_columnconfigure(0, weight=1)

        self.tree.tag_configure("even", background=ROW_EVEN)
        self.tree.tag_configure("odd", background=ROW_ODD)
        self.tree.tag_configure("status_ok", foreground=GREEN)
        self.tree.tag_configure("status_skip", foreground=RED)

        self.tree.bind("<Double-1>", self._on_row_double_click)
        self.tree.bind("<Button-3>", self._on_row_right_click)

        # context menu for opening paths
        self.context_menu = tk.Menu(self.root, tearoff=0, bg=PANEL_BG_2, fg=TEXT,
                                      activebackground="#222932", activeforeground=AMBER, bd=0)

        # ===== Footer =====
        footer = tk.Frame(self.root, bg=PANEL_BG, height=28)
        footer.pack(fill="x", side="bottom")
        footer.pack_propagate(False)
        self.footer_label = tk.Label(footer, text="Showing 0 of 0 rows", bg=PANEL_BG, fg=TEXT_FAINT,
                                       font=("Consolas", 8))
        self.footer_label.pack(side="left", padx=12)
        tk.Label(footer, text="Double-click a path cell to open it in File Explorer  ·  Right-click for more options",
                  bg=PANEL_BG, fg=TEXT_FAINT, font=("Consolas", 8)).pack(side="right", padx=12)

    def _make_btn(self, parent, text, command):
        btn = tk.Button(parent, text=text, command=command, bg=PANEL_BG_2, fg=TEXT,
                         activebackground="#222932", activeforeground=AMBER,
                         relief="flat", font=("Segoe UI", 8, "bold"), cursor="hand2",
                         bd=1, highlightbackground=LINE, padx=10, pady=4)
        return btn

    # ---------------------------------------------------------- CSV loading
    def load_csv(self, path, prompt_on_fail=False):
        if not os.path.isfile(path):
            if prompt_on_fail:
                messagebox.showwarning(
                    "Default log not found",
                    f"Could not find the default publish log at:\n\n{path}\n\n"
                    "Pick the CSV file manually."
                )
                self.browse_csv()
                return
            else:
                messagebox.showerror("File not found", f"Could not find:\n{path}")
                return

        try:
            with open(path, newline="", encoding="utf-8-sig") as f:
                reader = csv.reader(f)
                rows = [r for r in reader]
        except UnicodeDecodeError:
            with open(path, newline="", encoding="latin-1") as f:
                reader = csv.reader(f)
                rows = [r for r in reader]
        except Exception as e:
            messagebox.showerror("Could not read CSV", str(e))
            return

        rows = [r for r in rows if any(c.strip() for c in r)]
        if not rows:
            messagebox.showerror("Empty CSV", "That file has no rows.")
            return

        headers = [h.strip() for h in rows[0]]
        data_rows = rows[1:]

        self.raw_headers = headers
        col_values = [[ (r[i].strip() if i < len(r) else "") for r in data_rows] for i in range(len(headers))]
        self.columns = [Column(h, i, col_values[i]) for i, h in enumerate(headers)]

        self.data = []
        for r in data_rows:
            obj = {}
            for i, h in enumerate(headers):
                obj[h] = r[i].strip() if i < len(r) else ""
            self.data.append(obj)

        date_col = next((c for c in self.columns if c.is_date), None)
        self.sort_key = date_col.key if date_col else (self.columns[0].key if self.columns else None)
        self.sort_desc = True
        self.filters = {c.key: set() for c in self.columns if c.filterable}
        self.search_term = ""
        self.search_var.set("")

        self.current_csv_path = path
        self.sub_label.config(text=f"{path}  ·  {len(headers)} columns  ·  {len(self.data)} rows")

        self._build_columns()
        self._build_filter_strip()
        self.render()

    def refresh_csv(self):
        if self.current_csv_path:
            self.load_csv(self.current_csv_path)
        else:
            self.browse_csv()

    def browse_csv(self):
        initial_dir = os.path.dirname(DEFAULT_LOG_PATH)
        try:
            path = filedialog.askopenfilename(
                title="Open publish log CSV",
                filetypes=[("CSV files", "*.csv"), ("All files", "*.*")],
                initialdir=initial_dir if os.path.isdir(initial_dir) else None,
            )
        except Exception:
            path = filedialog.askopenfilename(
                title="Open publish log CSV",
                filetypes=[("CSV files", "*.csv"), ("All files", "*.*")],
            )
        if path:
            self.load_csv(path)

    # ---------------------------------------------------------- columns / tree setup
    def _build_columns(self):
        col_ids = [c.key for c in self.columns]
        self.tree["columns"] = col_ids
        for c in self.columns:
            width = 230 if c.is_path else (150 if c.is_long_text else (140 if c.is_date else 110))
            self.tree.heading(c.key, text=c.label.upper() + ("  ▾" if c.key == self.sort_key else ""),
                               command=lambda key=c.key: self._on_sort(key))
            self.tree.column(c.key, width=width, minwidth=70, anchor="w", stretch=False)

    def _on_sort(self, key):
        if self.sort_key == key:
            self.sort_desc = not self.sort_desc
        else:
            self.sort_key = key
            self.sort_desc = True
        self._build_columns()
        self.render()

    # ---------------------------------------------------------- filters UI
    def _build_filter_strip(self):
        for w in self.filter_strip.winfo_children():
            w.destroy()
        self.filter_buttons = {}
        for c in self.columns:
            if not c.filterable:
                continue
            btn = self._make_btn(self.filter_strip, f"▾ {c.label}", lambda col=c: self._open_filter_popover(col))
            btn.pack(side="left", padx=2)
            self.filter_buttons[c.key] = btn

    def _open_filter_popover(self, column):
        FilterPopover(self.root, self, column, self.filter_buttons[column.key])

    def unique_values(self, field):
        counts = OrderedDict()
        for r in self.data:
            v = r.get(field, "") or "(blank)"
            counts[v] = counts.get(v, 0) + 1
        return sorted(counts.items(), key=lambda kv: -kv[1])

    def _on_search(self, *args):
        self.search_term = self.search_var.get()
        self.render()

    def clear_filters(self):
        for k in self.filters:
            self.filters[k] = set()
        self.search_var.set("")
        self.render()

    def _render_chips(self):
        for w in self.chips_frame.winfo_children():
            w.destroy()
        any_active = False
        for field, vals in self.filters.items():
            col = next((c for c in self.columns if c.key == field), None)
            for v in vals:
                any_active = True
                chip = tk.Frame(self.chips_frame, bg="#22201a", highlightbackground=AMBER_DARK,
                                  highlightthickness=1)
                chip.pack(side="left", padx=3, pady=2)
                lbl = f"{col.label if col else field}: {v}"
                tk.Label(chip, text=lbl, bg="#22201a", fg=AMBER, font=("Consolas", 8)).pack(side="left", padx=(8, 4), pady=2)
                x = tk.Label(chip, text="✕", bg="#22201a", fg=AMBER, font=("Consolas", 8, "bold"), cursor="hand2")
                x.pack(side="left", padx=(0, 6))
                x.bind("<Button-1>", lambda e, f=field, val=v: self._remove_filter(f, val))
        if any_active:
            clear = tk.Label(self.chips_frame, text="Clear all", bg=APP_BG, fg=TEXT_DIM, font=("Consolas", 8, "underline"),
                               cursor="hand2")
            clear.pack(side="left", padx=6)
            clear.bind("<Button-1>", lambda e: self.clear_filters())

    def _remove_filter(self, field, val):
        self.filters[field].discard(val)
        self.render()

    # ---------------------------------------------------------- row matching / rendering
    def _matches(self, row):
        for field, vals in self.filters.items():
            if not vals:
                continue
            v = row.get(field, "") or "(blank)"
            if v not in vals:
                return False
        if self.search_term:
            term = self.search_term.lower()
            hay = " ".join(row.get(c.key, "") for c in self.columns).lower()
            if term not in hay:
                return False
        return True

    def render(self):
        if not hasattr(self, "filter_buttons"):
            return
        for key, btn in self.filter_buttons.items():
            n = len(self.filters.get(key, set()))
            col = next(c for c in self.columns if c.key == key)
            label = f"▾ {col.label}" + (f" ({n})" if n else "")
            btn.config(text=label, fg=AMBER if n else TEXT)

        self._render_chips()

        rows = [r for r in self.data if self._matches(r)]

        if self.sort_key:
            def sort_val(r):
                v = r.get(self.sort_key, "")
                return v
            rows.sort(key=sort_val, reverse=self.sort_desc)

        self.tree.delete(*self.tree.get_children())
        for i, r in enumerate(rows):
            tag = "even" if i % 2 == 0 else "odd"
            values = []
            for c in self.columns:
                v = r.get(c.key, "")
                if c.is_date:
                    v = format_datetime_value(v)
                elif c.is_path and v:
                    parts = re.split(r"[\\/]", v)
                    v = "...\\" + "\\".join(parts[-2:]) if len(parts) > 1 else v
                values.append(v if v else "—")
            iid = self.tree.insert("", "end", values=values, tags=(tag,))

        self.footer_label.config(text=f"Showing {len(rows)} of {len(self.data)} rows")

        status_col = next((c for c in self.columns if c.is_status), None)
        if status_col:
            counts = OrderedDict()
            for r in self.data:
                v = (r.get(status_col.key, "") or "(blank)").lower()
                counts[v] = counts.get(v, 0) + 1
            parts = [f"{k.upper()}: {v}" for k, v in counts.items()]
            self.counter_label.config(text="   ".join(parts) + f"   TOTAL: {len(self.data)}")
        else:
            self.counter_label.config(text=f"TOTAL: {len(self.data)}")

        # keep a parallel structure to map displayed row -> original full values
        self._displayed_rows = rows

    # ---------------------------------------------------------- opening paths in Explorer
    def _on_row_double_click(self, event):
        region = self.tree.identify("region", event.x, event.y)
        if region != "cell":
            return
        col_id = self.tree.identify_column(event.x)
        row_id = self.tree.identify_row(event.y)
        if not row_id:
            return
        col_index = int(col_id.replace("#", "")) - 1
        if col_index < 0 or col_index >= len(self.columns):
            return
        column = self.columns[col_index]
        if not column.is_path:
            return
        row_index = self.tree.index(row_id)
        full_value = self._displayed_rows[row_index].get(column.key, "")
        if full_value:
            self.open_in_explorer(full_value)

    def _on_row_right_click(self, event):
        row_id = self.tree.identify_row(event.y)
        col_id = self.tree.identify_column(event.x)
        if not row_id:
            return
        self.tree.selection_set(row_id)
        col_index = int(col_id.replace("#", "")) - 1
        if col_index < 0 or col_index >= len(self.columns):
            return
        column = self.columns[col_index]
        row_index = self.tree.index(row_id)
        full_value = self._displayed_rows[row_index].get(column.key, "")

        self.context_menu.delete(0, "end")
        if column.is_path and full_value:
            self.context_menu.add_command(label="Open in File Explorer",
                                            command=lambda: self.open_in_explorer(full_value))
            self.context_menu.add_command(label="Copy path",
                                            command=lambda: self._copy_to_clipboard(full_value))
        else:
            self.context_menu.add_command(label="Copy cell value",
                                            command=lambda: self._copy_to_clipboard(full_value))
        self.context_menu.tk_popup(event.x_root, event.y_root)

    def _copy_to_clipboard(self, text):
        self.root.clipboard_clear()
        self.root.clipboard_append(text)

    def open_in_explorer(self, path):
        if not path:
            return
        path = path.strip()
        if sys.platform != "win32":
            messagebox.showinfo("Not on Windows", f"Path:\n{path}\n\n(Explorer can only be opened on Windows.)")
            return
        try:
            if os.path.isfile(path):
                subprocess.run(["explorer", "/select,", path])
            elif os.path.isdir(path):
                subprocess.run(["explorer", path])
            else:
                # file/folder might not exist (publish dirs can be cleaned up) —
                # try opening the parent folder instead
                parent = os.path.dirname(path)
                if os.path.isdir(parent):
                    subprocess.run(["explorer", parent])
                else:
                    # last resort: just hand the raw path to explorer and let
                    # Windows show its own "not found" dialog if needed
                    subprocess.run(["explorer", path])
        except Exception as e:
            messagebox.showerror("Could not open Explorer", str(e))

    # ---------------------------------------------------------- export
    def export_view(self):
        if not self.data:
            return
        rows = [r for r in self.data if self._matches(r)]
        if self.sort_key:
            rows.sort(key=lambda r: r.get(self.sort_key, ""), reverse=self.sort_desc)

        path = filedialog.asksaveasfilename(
            title="Export filtered view",
            defaultextension=".csv",
            filetypes=[("CSV files", "*.csv")],
            initialfile="filtered_publish_log.csv",
        )
        if not path:
            return
        try:
            with open(path, "w", newline="", encoding="utf-8-sig") as f:
                writer = csv.DictWriter(f, fieldnames=self.raw_headers)
                writer.writeheader()
                for r in rows:
                    writer.writerow(r)
            messagebox.showinfo("Export complete", f"Saved {len(rows)} rows to:\n{path}")
        except Exception as e:
            messagebox.showerror("Export failed", str(e))


def main():
    root = tk.Tk()
    try:
        root.iconbitmap(default="")
    except Exception:
        pass
    app = VersionControllerApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
