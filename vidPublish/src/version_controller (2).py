"""
Version Controller -- Publish Log Viewer
------------------------------------------
Native Windows desktop tool (Tkinter, standard library only -- no installs needed)
for browsing the DWG/PDF publish log CSV.

Default log path:
    \\\\Desktop-igi8ekn\\VID_20D\\share\\updated_projects_files\\section\\publish_log.csv

Run with:   python version_controller.py
Requires:   Python 3.8+ on Windows 11 (standard library only)
"""

import csv
import os
import re
import subprocess
import sys
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from tkinter import font as tkfont
from collections import OrderedDict

DEFAULT_LOG_PATH = r"\\Desktop-igi8ekn\VID_20D\share\updated_projects_files\section\publish_log.csv"

# ---------------------------------------------------------------- THEME (white)
APP_BG = "#f5f6f8"
PANEL_BG = "#ffffff"
PANEL_BG_2 = "#f0f1f4"
HEADER_BG = "#ffffff"
LINE = "#dde1e6"
LINE_SOFT = "#e8eaee"
TEXT = "#1f2430"
TEXT_DIM = "#697080"
TEXT_FAINT = "#9aa1ad"
AMBER = "#c9821a"
AMBER_BG = "#fdf2e1"
AMBER_BORDER = "#e8b96a"
GREEN = "#1e8a4c"
GREEN_BG = "#e7f6ec"
RED = "#c1392b"
RED_BG = "#fbeae8"
ROW_EVEN = "#ffffff"
ROW_ODD = "#f7f8fa"
ACCENT = "#2f6fed"
ACCENT_BG = "#eaf0fe"

# Crisper, larger UI fonts -- Segoe UI Variable/Segoe UI renders cleaner at
# slightly larger sizes than the previous 7-8pt set, which looked blurry on
# most Windows 11 DPI scales. Consolas remains for genuinely tabular data.
BASE_SIZE = 10
MONO_FONT = ("Consolas", BASE_SIZE)
MONO_FONT_SM = ("Consolas", BASE_SIZE - 1)
SANS_FONT = ("Segoe UI", BASE_SIZE)
SANS_FONT_SM = ("Segoe UI", BASE_SIZE)
SANS_BOLD = ("Segoe UI", BASE_SIZE, "bold")
SANS_BOLD_SM = ("Segoe UI", BASE_SIZE - 1, "bold")
TITLE_FONT = ("Segoe UI", 15, "bold")

ROW_PAD_Y = 7
CELL_PAD_X = 10
MIN_COL_WIDTH = 90
MAX_COL_WIDTH = 520

SEARCH_DEBOUNCE_MS = 220  # avoids re-rendering the whole table on every keystroke


# ============================================================ structure inference

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
    """
    Holds everything about a column, including its rendered pixel width,
    so width is never tracked in a separate dict that can drift out of
    sync with the live column list (that mismatch was the source of the
    'KeyError: DATE_TIME' crash during search).
    """
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
        self.values_sample = values
        self.width = 140  # computed later once fonts are available


# ============================================================ filter popover

class FilterPopover(tk.Toplevel):
    def __init__(self, parent, app, column, anchor_widget):
        super().__init__(parent)
        self.app = app
        self.column = column

        self.title("")
        self.configure(bg=PANEL_BG)
        self.resizable(False, False)
        self.transient(parent)
        self.overrideredirect(True)
        self.attributes("-topmost", True)
        self.configure(highlightbackground=LINE, highlightthickness=1)

        self._build(column)

        self.update_idletasks()
        w = 280
        h = self.winfo_reqheight()
        x = anchor_widget.winfo_rootx()
        y = anchor_widget.winfo_rooty() + anchor_widget.winfo_height() + 4
        screen_w = self.winfo_screenwidth()
        screen_h = self.winfo_screenheight()
        if x + w > screen_w:
            x = max(0, screen_w - w - 10)
        if y + h > screen_h:
            y = anchor_widget.winfo_rooty() - h - 4
        self.geometry(f"{w}x{h}+{x}+{y}")

        self.lift()
        self.focus_force()
        self.grab_set()

        self.bind("<Escape>", lambda e: self._close())
        self._global_click_bound = True
        self.app.root.bind_all("<Button-1>", self._on_global_click, add="+")

    def _on_global_click(self, event):
        try:
            if str(event.widget).startswith(str(self)):
                return
        except Exception:
            pass
        self._close()

    def _close(self):
        if self._global_click_bound:
            try:
                self.app.root.unbind_all("<Button-1>")
            except Exception:
                pass
            self._global_click_bound = False
        try:
            self.grab_release()
        except Exception:
            pass
        self.destroy()

    def _build(self, column):
        outer = tk.Frame(self, bg=PANEL_BG)
        outer.pack(fill="both", expand=True)

        head = tk.Frame(outer, bg=PANEL_BG_2)
        head.pack(fill="x")
        inner_head = tk.Frame(head, bg=PANEL_BG_2)
        inner_head.pack(fill="x", padx=10, pady=8)
        tk.Label(inner_head, text=f"Filter - {column.label}", bg=PANEL_BG_2, fg=TEXT_DIM,
                 font=SANS_BOLD_SM).pack(side="left")
        link_frame = tk.Frame(inner_head, bg=PANEL_BG_2)
        link_frame.pack(side="right")
        all_lbl = tk.Label(link_frame, text="All", bg=PANEL_BG_2, fg=ACCENT, font=SANS_BOLD_SM, cursor="hand2")
        all_lbl.pack(side="left", padx=(0, 8))
        none_lbl = tk.Label(link_frame, text="None", bg=PANEL_BG_2, fg=ACCENT, font=SANS_BOLD_SM, cursor="hand2")
        none_lbl.pack(side="left")
        all_lbl.bind("<Button-1>", lambda e: self.set_all(True))
        none_lbl.bind("<Button-1>", lambda e: self.set_all(False))

        search_frame = tk.Frame(outer, bg=PANEL_BG)
        search_frame.pack(fill="x", padx=10, pady=(8, 6))
        self.search_var = tk.StringVar()
        search_entry = tk.Entry(search_frame, textvariable=self.search_var, bg="#ffffff", fg=TEXT,
                                 insertbackground=TEXT, relief="solid", bd=1,
                                 highlightbackground=LINE, highlightcolor=ACCENT, font=SANS_FONT_SM)
        search_entry.pack(fill="x", ipady=5)
        self.search_var.trace_add("write", lambda *a: self.rebuild_list())

        list_outer = tk.Frame(outer, bg=PANEL_BG, highlightbackground=LINE, highlightthickness=1)
        list_outer.pack(fill="both", expand=True, padx=10)
        canvas = tk.Canvas(list_outer, bg=PANEL_BG, highlightthickness=0, height=220, width=240)
        scrollbar = ttk.Scrollbar(list_outer, orient="vertical", command=canvas.yview)
        self.list_frame = tk.Frame(canvas, bg=PANEL_BG)
        self.list_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=self.list_frame, anchor="nw", width=240)
        canvas.configure(yscrollcommand=scrollbar.set)
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        def _on_mousewheel(event):
            canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        canvas.bind("<MouseWheel>", _on_mousewheel)

        foot = tk.Frame(outer, bg=PANEL_BG)
        foot.pack(fill="x", padx=10, pady=10)
        apply_btn = tk.Button(foot, text="Apply", bg=ACCENT, fg="white", relief="flat",
                               font=SANS_BOLD_SM, command=self.apply, cursor="hand2",
                               activebackground="#1f56c4", activeforeground="white",
                               bd=0, padx=16, pady=5)
        apply_btn.pack(side="right")
        cancel_btn = tk.Button(foot, text="Cancel", bg=PANEL_BG, fg=TEXT_DIM, relief="flat",
                                font=SANS_FONT_SM, command=self._close, cursor="hand2",
                                activebackground=PANEL_BG_2, bd=0, padx=10, pady=5)
        cancel_btn.pack(side="right", padx=(0, 6))

        self.value_vars = OrderedDict()
        self.value_counts = self.app.unique_values(column.key)
        self.rebuild_list()

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
            row = tk.Frame(self.list_frame, bg=PANEL_BG)
            row.pack(fill="x")
            cb = tk.Checkbutton(row, variable=var, bg=PANEL_BG, fg=TEXT, selectcolor="#ffffff",
                                 activebackground=PANEL_BG, relief="flat", highlightthickness=0,
                                 font=MONO_FONT_SM, bd=0)
            cb.pack(side="left")
            lbl_text = val if len(val) <= 26 else val[:23] + "..."
            tk.Label(row, text=lbl_text, bg=PANEL_BG, fg=TEXT, font=MONO_FONT_SM, anchor="w").pack(
                side="left", fill="x", expand=True, pady=4)
            tk.Label(row, text=str(count), bg=PANEL_BG, fg=TEXT_FAINT, font=("Consolas", 8)).pack(
                side="right", padx=(0, 6))

    def apply(self):
        checked_vals = {val for val, var in self.value_vars.items() if var.get()}
        total_vals = {val for val, _ in self.value_counts}
        if checked_vals == total_vals or len(checked_vals) == 0:
            self.app.filters[self.column.key] = set()
        else:
            self.app.filters[self.column.key] = checked_vals
        self.app.render()
        self._close()


# ============================================================ main app

class VersionControllerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Version Controller -- Publish Log")
        self.root.geometry("1520x820")
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
        self._displayed_rows = []
        self._search_after_id = None

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
        style.configure("Vertical.TScrollbar", background=PANEL_BG_2, troughcolor=APP_BG,
                        bordercolor=APP_BG, arrowcolor=TEXT_DIM)
        style.configure("Horizontal.TScrollbar", background=PANEL_BG_2, troughcolor=APP_BG,
                        bordercolor=APP_BG, arrowcolor=TEXT_DIM)

        # measurement fonts used to size columns to their real content width
        self._mono_measure_font = tkfont.Font(family="Consolas", size=BASE_SIZE - 1)
        self._sans_measure_font = tkfont.Font(family="Segoe UI", size=BASE_SIZE)
        self._sans_bold_measure_font = tkfont.Font(family="Segoe UI", size=BASE_SIZE - 1, weight="bold")

    # ---------------------------------------------------------- UI build
    def _build_ui(self):
        titlebar = tk.Frame(self.root, bg=PANEL_BG, height=60)
        titlebar.pack(fill="x", side="top")
        titlebar.pack_propagate(False)
        tk.Frame(self.root, bg=LINE, height=1).pack(fill="x", side="top")

        left = tk.Frame(titlebar, bg=PANEL_BG)
        left.pack(side="left", padx=16, pady=8)

        stamp = tk.Label(left, text="REV", bg=AMBER_BG, fg=AMBER, font=("Consolas", 10, "bold"),
                          relief="solid", bd=1, width=4, height=2, highlightbackground=AMBER_BORDER)
        stamp.pack(side="left", padx=(0, 10))

        title_box = tk.Frame(left, bg=PANEL_BG)
        title_box.pack(side="left")
        tk.Label(title_box, text="Version Controller", bg=PANEL_BG, fg=TEXT, font=TITLE_FONT).pack(anchor="w")
        self.sub_label = tk.Label(title_box, text="No file loaded", bg=PANEL_BG, fg=TEXT_DIM, font=("Consolas", 9))
        self.sub_label.pack(anchor="w")

        right = tk.Frame(titlebar, bg=PANEL_BG)
        right.pack(side="right", padx=16, pady=8)
        self.counter_label = tk.Label(right, text="", bg=PANEL_BG, fg=TEXT_DIM, font=("Consolas", 9))
        self.counter_label.pack(side="left", padx=(0, 16))

        self._make_btn(right, "Refresh", self.refresh_csv).pack(side="left", padx=2)
        self._make_btn(right, "Open File...", self.browse_csv).pack(side="left", padx=2)

        toolbar = tk.Frame(self.root, bg=PANEL_BG_2, height=52)
        toolbar.pack(fill="x", side="top")
        toolbar.pack_propagate(False)
        tk.Frame(self.root, bg=LINE, height=1).pack(fill="x", side="top")

        search_frame = tk.Frame(toolbar, bg="#ffffff", highlightbackground=LINE, highlightthickness=1)
        search_frame.pack(side="left", padx=12, pady=10, ipady=2)
        tk.Label(search_frame, text="Search:", bg="#ffffff", fg=TEXT_DIM, font=SANS_FONT_SM).pack(side="left", padx=(10, 4))
        self.search_var = tk.StringVar()
        search_entry = tk.Entry(search_frame, textvariable=self.search_var, bg="#ffffff", fg=TEXT,
                                 insertbackground=TEXT, relief="flat", font=MONO_FONT, width=30)
        search_entry.pack(side="left", padx=(0, 10), ipady=4)
        self.search_var.trace_add("write", self._on_search_keystroke)

        filter_scroll_outer = tk.Frame(toolbar, bg=PANEL_BG_2)
        filter_scroll_outer.pack(side="left", padx=4, pady=10, fill="x", expand=True)
        self.filter_strip = tk.Frame(filter_scroll_outer, bg=PANEL_BG_2)
        self.filter_strip.pack(side="left")

        right_tools = tk.Frame(toolbar, bg=PANEL_BG_2)
        right_tools.pack(side="right", padx=12, pady=10)
        self._make_btn(right_tools, "Clear filters", self.clear_filters).pack(side="left", padx=2)
        self._make_btn(right_tools, "Export view", self.export_view, primary=True).pack(side="left", padx=2)

        self.chips_frame = tk.Frame(self.root, bg=APP_BG)
        self.chips_frame.pack(fill="x", padx=12, pady=(8, 0))

        self.header_frame = tk.Frame(self.root, bg=HEADER_BG)
        self.header_frame.pack(fill="x", padx=12, pady=(10, 0))
        tk.Frame(self.root, bg=LINE, height=1).pack(fill="x", padx=12)

        body_container = tk.Frame(self.root, bg=APP_BG, highlightbackground=LINE, highlightthickness=1)
        body_container.pack(fill="both", expand=True, padx=12, pady=(0, 10))

        self.body_canvas = tk.Canvas(body_container, bg=PANEL_BG, highlightthickness=0)
        vsb = ttk.Scrollbar(body_container, orient="vertical", command=self.body_canvas.yview)
        hsb = ttk.Scrollbar(body_container, orient="horizontal", command=self.body_canvas.xview)
        self.body_canvas.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

        self.body_canvas.grid(row=0, column=0, sticky="nsew")
        vsb.grid(row=0, column=1, sticky="ns")
        hsb.grid(row=1, column=0, sticky="ew")
        body_container.grid_rowconfigure(0, weight=1)
        body_container.grid_columnconfigure(0, weight=1)

        self.rows_frame = tk.Frame(self.body_canvas, bg=PANEL_BG)
        self.rows_window = self.body_canvas.create_window((0, 0), window=self.rows_frame, anchor="nw")
        self.rows_frame.bind("<Configure>", lambda e: self.body_canvas.configure(scrollregion=self.body_canvas.bbox("all")))

        def _on_mousewheel(event):
            self.body_canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        self.body_canvas.bind("<Enter>", lambda e: self.body_canvas.bind_all("<MouseWheel>", _on_mousewheel))
        self.body_canvas.bind("<Leave>", lambda e: self.body_canvas.unbind_all("<MouseWheel>"))

        footer = tk.Frame(self.root, bg=PANEL_BG, height=30)
        footer.pack(fill="x", side="bottom")
        footer.pack_propagate(False)
        tk.Frame(self.root, bg=LINE, height=1).pack(fill="x", side="bottom")
        self.footer_label = tk.Label(footer, text="Showing 0 of 0 rows", bg=PANEL_BG, fg=TEXT_FAINT,
                                      font=("Consolas", 9))
        self.footer_label.pack(side="left", padx=12)
        tk.Label(footer, text="Click Open next to a DWG/PDF column to launch it in File Explorer",
                 bg=PANEL_BG, fg=TEXT_FAINT, font=("Consolas", 9)).pack(side="right", padx=12)

    def _make_btn(self, parent, text, command, primary=False):
        if primary:
            btn = tk.Button(parent, text=text, command=command, bg=ACCENT, fg="white",
                             activebackground="#1f56c4", activeforeground="white",
                             relief="flat", font=SANS_BOLD_SM, cursor="hand2",
                             bd=0, padx=14, pady=6)
        else:
            btn = tk.Button(parent, text=text, command=command, bg="#ffffff", fg=TEXT,
                             activebackground=PANEL_BG_2, activeforeground=TEXT,
                             relief="solid", font=SANS_FONT_SM, cursor="hand2",
                             bd=1, highlightbackground=LINE, padx=12, pady=5)
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
                rows = list(csv.reader(f))
        except UnicodeDecodeError:
            with open(path, newline="", encoding="latin-1") as f:
                rows = list(csv.reader(f))
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
        col_values = [[(r[i].strip() if i < len(r) else "") for r in data_rows] for i in range(len(headers))]
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
        self.sub_label.config(text=f"{path}    |    {len(headers)} columns    |    {len(self.data)} rows")

        self._compute_col_widths()
        self._build_header_row()
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

    # ---------------------------------------------------------- column widths
    def _compute_col_widths(self):
        """
        Size each column to fit its FULL content (header label + widest
        value actually seen), instead of a fixed guess. Path columns are
        an exception: they only ever show an "Open"/"Folder" button, so
        they get a small fixed width regardless of how long the real path is.
        """
        for c in self.columns:
            if c.is_path:
                c.width = 130
                continue

            header_w = self._sans_bold_measure_font.measure(c.label.upper()) + 2 * CELL_PAD_X + 24
            font = self._mono_measure_font if (c.is_date or not c.is_long_text) else self._sans_measure_font

            sample_values = c.values_sample
            if c.is_long_text:
                # don't measure pathologically long single outliers forever;
                # cap how many chars we consider per value for width purposes
                widest = 0
                for v in sample_values:
                    vv = v if len(v) < 200 else v[:200]
                    widest = max(widest, self._sans_measure_font.measure(vv))
            else:
                widest = max((font.measure(v) for v in sample_values), default=0)

            content_w = widest + 2 * CELL_PAD_X + 12
            c.width = max(MIN_COL_WIDTH, min(MAX_COL_WIDTH, max(header_w, content_w)))

    # ---------------------------------------------------------- header row
    def _build_header_row(self):
        for w in self.header_frame.winfo_children():
            w.destroy()
        for c in self.columns:
            cell = tk.Frame(self.header_frame, bg=HEADER_BG, width=c.width, height=36,
                             highlightbackground=LINE_SOFT, highlightthickness=1)
            cell.pack(side="left", fill="y")
            cell.pack_propagate(False)
            arrow = ""
            if c.key == self.sort_key:
                arrow = "  \u25be" if self.sort_desc else "  \u25b4"
            lbl = tk.Label(cell, text=c.label.upper() + arrow, bg=HEADER_BG, fg=TEXT_DIM,
                            font=SANS_BOLD_SM, anchor="w", cursor="hand2")
            lbl.pack(fill="both", expand=True, padx=CELL_PAD_X, pady=8)
            lbl.bind("<Button-1>", lambda e, key=c.key: self._on_sort(key))

    def _on_sort(self, key):
        if self.sort_key == key:
            self.sort_desc = not self.sort_desc
        else:
            self.sort_key = key
            self.sort_desc = True
        self._build_header_row()
        self.render()

    # ---------------------------------------------------------- filters UI
    def _build_filter_strip(self):
        for w in self.filter_strip.winfo_children():
            w.destroy()
        self.filter_buttons = {}
        for c in self.columns:
            if not c.filterable:
                continue
            btn = self._make_btn(self.filter_strip, f"{c.label} \u25be", lambda col=c: self._open_filter_popover(col))
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

    # ---------------------------------------------------------- search (debounced)
    def _on_search_keystroke(self, *args):
        """
        Debounce: wait until typing pauses for SEARCH_DEBOUNCE_MS before
        re-rendering the whole table. Re-rendering on every single keystroke
        was the cause of the reported search lag, since each render rebuilds
        every visible row/cell widget.
        """
        if self._search_after_id is not None:
            self.root.after_cancel(self._search_after_id)
        self._search_after_id = self.root.after(SEARCH_DEBOUNCE_MS, self._apply_search)

    def _apply_search(self):
        self._search_after_id = None
        self.search_term = self.search_var.get()
        self.render()

    def clear_filters(self):
        for k in self.filters:
            self.filters[k] = set()
        self.search_var.set("")
        self.search_term = ""
        self.render()

    def _render_chips(self):
        for w in self.chips_frame.winfo_children():
            w.destroy()
        any_active = False
        for field, vals in self.filters.items():
            col = next((c for c in self.columns if c.key == field), None)
            for v in vals:
                any_active = True
                chip = tk.Frame(self.chips_frame, bg=AMBER_BG, highlightbackground=AMBER_BORDER,
                                 highlightthickness=1)
                chip.pack(side="left", padx=3, pady=2)
                lbl = f"{col.label if col else field}: {v}"
                tk.Label(chip, text=lbl, bg=AMBER_BG, fg=AMBER, font=("Consolas", 9)).pack(side="left", padx=(8, 4), pady=4)
                x = tk.Label(chip, text="\u2715", bg=AMBER_BG, fg=AMBER, font=("Consolas", 9, "bold"), cursor="hand2")
                x.pack(side="left", padx=(0, 8))
                x.bind("<Button-1>", lambda e, f=field, val=v: self._remove_filter(f, val))
        if any_active:
            clear = tk.Label(self.chips_frame, text="Clear all", bg=APP_BG, fg=TEXT_DIM,
                              font=("Consolas", 9, "underline"), cursor="hand2")
            clear.pack(side="left", padx=6)
            clear.bind("<Button-1>", lambda e: self.clear_filters())

    def _remove_filter(self, field, val):
        self.filters[field].discard(val)
        self.render()

    # ---------------------------------------------------------- row matching
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

    # ---------------------------------------------------------- rendering rows
    def render(self):
        if not self.columns:
            return
        for key, btn in self.filter_buttons.items():
            n = len(self.filters.get(key, set()))
            col = next(c for c in self.columns if c.key == key)
            label = f"{col.label} \u25be" + (f" ({n})" if n else "")
            btn.config(text=label, fg=AMBER if n else TEXT)

        self._render_chips()

        rows = [r for r in self.data if self._matches(r)]
        if self.sort_key:
            rows.sort(key=lambda r: r.get(self.sort_key, ""), reverse=self.sort_desc)
        self._displayed_rows = rows

        for w in self.rows_frame.winfo_children():
            w.destroy()

        for i, r in enumerate(rows):
            bg = ROW_EVEN if i % 2 == 0 else ROW_ODD
            row_frame = tk.Frame(self.rows_frame, bg=bg)
            row_frame.pack(fill="x")

            for c in self.columns:
                cell = tk.Frame(row_frame, bg=bg, width=c.width, height=34,
                                 highlightbackground=LINE_SOFT, highlightthickness=1)
                cell.pack(side="left", fill="y")
                cell.pack_propagate(False)

                value = r.get(c.key, "")
                self._render_cell(cell, c, value, bg)

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

    def _render_cell(self, cell, column, value, bg):
        if column.is_path:
            self._render_path_cell(cell, value, bg)
            return

        if column.is_date:
            tk.Label(cell, text=format_datetime_value(value), bg=bg, fg=TEXT_DIM, font=MONO_FONT_SM,
                     anchor="w").pack(fill="both", expand=True, padx=CELL_PAD_X, pady=ROW_PAD_Y)
            return

        if column.is_status:
            v = (value or "").lower()
            if v in ("ok", "done", "success", "yes", "complete", "completed"):
                fg, cbg = GREEN, GREEN_BG
            elif v in ("skipped", "skip", "fail", "failed", "no", "error"):
                fg, cbg = RED, RED_BG
            else:
                fg, cbg = TEXT_DIM, PANEL_BG_2
            inner = tk.Frame(cell, bg=bg)
            inner.pack(fill="both", expand=True, padx=CELL_PAD_X, pady=6)
            pill = tk.Label(inner, text=(value or "\u2014").upper(), bg=cbg, fg=fg,
                             font=("Segoe UI", 8, "bold"), padx=8, pady=3)
            pill.pack(side="left")
            return

        if re.search(r"file", column.key, re.I) and not column.is_path:
            tk.Label(cell, text=value or "\u2014", bg=bg, fg=TEXT, font=MONO_FONT_SM, anchor="w").pack(
                fill="both", expand=True, padx=CELL_PAD_X, pady=ROW_PAD_Y)
            return

        if re.search(r"yard|code", column.key, re.I):
            inner = tk.Frame(cell, bg=bg)
            inner.pack(fill="both", expand=True, padx=CELL_PAD_X, pady=6)
            tag = tk.Label(inner, text=value or "\u2014", bg=PANEL_BG_2, fg=TEXT_DIM,
                            font=MONO_FONT_SM, padx=7, pady=2)
            tag.pack(side="left")
            return

        if re.search(r"command|note|remark|comment", column.key, re.I):
            display = value.strip() or "\u2014"
            tk.Label(cell, text=display, bg=bg, fg=TEXT_DIM if value.strip() else TEXT_FAINT,
                     font=(SANS_FONT_SM[0], SANS_FONT_SM[1], "italic"), anchor="w").pack(
                fill="both", expand=True, padx=CELL_PAD_X, pady=ROW_PAD_Y)
            return

        tk.Label(cell, text=value or "\u2014", bg=bg, fg=TEXT, font=SANS_FONT_SM, anchor="w").pack(
            fill="both", expand=True, padx=CELL_PAD_X, pady=ROW_PAD_Y)

    def _render_path_cell(self, cell, value, bg):
        """
        Path columns never show the raw path text -- only a button.
        If the exact file exists: "Open" button -> selects the file in Explorer.
        If the file is missing but its parent folder exists: "Folder" button
            (different label so it's clear it's opening the containing
            folder, not the specific file) -> opens that folder in Explorer.
        If neither exists (or the cell is blank): a disabled-looking
            placeholder, no button.
        """
        inner = tk.Frame(cell, bg=bg)
        inner.pack(fill="both", expand=True, padx=CELL_PAD_X, pady=6)

        if not value:
            tk.Label(inner, text="\u2014", bg=bg, fg=TEXT_FAINT, font=SANS_FONT_SM).pack(side="left")
            return

        file_exists = os.path.isfile(value)
        folder_exists = os.path.isdir(os.path.dirname(value)) if not file_exists else True

        if file_exists:
            btn = tk.Button(inner, text="\u2197 Open", command=lambda v=value: self.open_in_explorer(v),
                             bg=ACCENT_BG, fg=ACCENT, relief="flat", bd=0,
                             font=SANS_BOLD_SM, cursor="hand2", padx=12, pady=4,
                             activebackground="#d8e4fd", activeforeground=ACCENT)
            btn.pack(side="left")
        elif folder_exists:
            btn = tk.Button(inner, text="\u2197 Folder", command=lambda v=value: self.open_in_explorer(v),
                             bg=PANEL_BG_2, fg=TEXT_DIM, relief="flat", bd=0,
                             font=SANS_BOLD_SM, cursor="hand2", padx=12, pady=4,
                             activebackground="#e4e6ea", activeforeground=TEXT)
            btn.pack(side="left")
            tk.Label(inner, text="file missing", bg=bg, fg=TEXT_FAINT,
                     font=("Segoe UI", 8, "italic")).pack(side="left", padx=(6, 0))
        else:
            tk.Label(inner, text="not found", bg=bg, fg=TEXT_FAINT, font=("Segoe UI", 8, "italic")).pack(side="left")

        menu = tk.Menu(self.root, tearoff=0, bg="#ffffff", fg=TEXT,
                        activebackground=PANEL_BG_2, activeforeground=TEXT, bd=1)
        menu.add_command(label="Open in File Explorer", command=lambda v=value: self.open_in_explorer(v))
        menu.add_command(label="Copy path", command=lambda v=value: self._copy_to_clipboard(v))

        def show_menu(e, m=menu):
            m.tk_popup(e.x_root, e.y_root)
        cell.bind("<Button-3>", show_menu)
        inner.bind("<Button-3>", show_menu)

    # ---------------------------------------------------------- explorer / clipboard
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
                parent = os.path.dirname(path)
                if os.path.isdir(parent):
                    subprocess.run(["explorer", parent])
                else:
                    subprocess.run(["explorer", path])
        except Exception as e:
            messagebox.showerror("Could not open Explorer", str(e))

    # ---------------------------------------------------------- export
    def export_view(self):
        if not self.data:
            return
        rows = self._displayed_rows

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
    app = VersionControllerApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
