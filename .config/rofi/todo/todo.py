#!/usr/bin/env python3
"""Backend for the rofi todo module — operates directly on ~/TODO.md.

The single source of truth is ~/TODO.md (open items only, checkbox + section
style); ~/DONE.md is the completed-item archive with mirrored headings. Every
mutation is committed to the local-only bare repo ~/.todo.git so it is
recoverable and never touches the public dotfiles.

Commands:
  list                 one line per open item: "<section> · <title>"
  add "<text>"         append "- [ ] <text>" under ## Inbox (created if absent)
  done "<display>"     move the item's whole block to DONE.md (mirrored section)
  delete "<display>"   remove the item's whole block
  line "<display>"     print the TODO.md line number of the item (for the editor)

An item is matched by the exact "<section> · <title>" string that `list` emits,
so selection round-trips without fragile line-number passing.

Paths are env-overridable (TODO_FILE / DONE_FILE / TODO_GIT_DIR) for testing.
"""
import os
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

HOME = Path.home()
TODO = Path(os.environ.get("TODO_FILE", HOME / "TODO.md"))
DONE = Path(os.environ.get("DONE_FILE", HOME / "DONE.md"))
GIT_DIR = os.environ.get("TODO_GIT_DIR", str(HOME / ".todo.git"))

OPEN_RE = re.compile(r"^- \[[ ~]\] ")           # top-level open item
BULLET_RE = re.compile(r"^- ")                    # any top-level bullet (block boundary)
HEADER_RE = re.compile(r"^(#{1,6}) ")
BOLD_RE = re.compile(r"\*\*(.+?)\*\*")


def read(p):
    return p.read_text().split("\n") if p.exists() else []


def write(p, lines):
    text = "\n".join(lines)
    if not text.endswith("\n"):
        text += "\n"
    p.write_text(text)


def title_of(line):
    """Human-readable title for an open-item line."""
    body = line[len("- [ ] "):]
    m = BOLD_RE.search(body)
    t = m.group(1) if m else body
    t = re.sub(r"\s+", " ", t).strip()
    return t[:110]


def section_at(lines, i):
    """Nearest (h2, h3) headers above line i. h3 only if it follows the h2."""
    h2 = h3 = None
    for j in range(i):
        m = HEADER_RE.match(lines[j])
        if not m:
            continue
        lvl = len(m.group(1))
        text = lines[j][lvl + 1:].strip()
        if lvl == 2:
            h2, h3 = text, None
        elif lvl == 3:
            h3 = text
    return h2, h3


def open_items(lines):
    """List of dicts for every open item, with block extent and section."""
    items = []
    for i, line in enumerate(lines):
        if not OPEN_RE.match(line):
            continue
        # block: from i until the next top-level bullet / header / EOF
        j = i + 1
        while j < len(lines):
            s = lines[j]
            if HEADER_RE.match(s) or BULLET_RE.match(s):
                break
            j += 1
        h2, h3 = section_at(lines, i)
        section = h3 or h2 or "(no section)"
        items.append({
            "start": i, "end": j,          # block is lines[start:end]
            "title": title_of(line),
            "section": section, "h2": h2, "h3": h3,
            "display": f"{section} · {title_of(line)}",
        })
    return items


def find(lines, display):
    for it in open_items(lines):
        if it["display"] == display:
            return it
    return None


def strip_trailing_blanks(block):
    while block and block[-1].strip() == "":
        block.pop()
    return block


def normalize_blanks(lines):
    """Collapse runs of blank lines to one; trim leading/trailing blanks.
    Matches the files' one-blank-between-blocks convention; never touches
    single blanks, so existing header spacing is preserved."""
    out = []
    for l in lines:
        if l.strip() == "" and out and out[-1].strip() == "":
            continue
        out.append(l)
    while out and out[0].strip() == "":
        out.pop(0)
    while out and out[-1].strip() == "":
        out.pop()
    return out


def commit(msg):
    if not Path(GIT_DIR).exists():
        return
    env = {**os.environ}
    base = ["git", "--git-dir", GIT_DIR, "--work-tree", str(HOME)]
    paths = [str(TODO)]
    if DONE.exists():
        paths.append(str(DONE))
    subprocess.run(base + ["add"] + paths, env=env,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(base + ["commit", "-m", msg], env=env,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


# ── section placement in DONE.md ──────────────────────────────────────────────

def section_end(lines, header_i, level):
    """Index just past the section that starts at header_i (level `level`)."""
    for k in range(header_i + 1, len(lines)):
        m = HEADER_RE.match(lines[k])
        if m and len(m.group(1)) <= level:
            return k
    return len(lines)


def find_header(lines, level, text, start=0, stop=None):
    stop = len(lines) if stop is None else stop
    want = ("#" * level) + " " + text
    for k in range(start, stop):
        if lines[k].rstrip() == want:
            return k
    return -1


def place_in_done(done, h2, h3, block):
    """Insert block under the mirrored h2/h3 section, creating headers if absent."""
    if not done or (len(done) == 1 and done[0] == ""):
        done = ["# DONE", ""]
    h2 = h2 or "(no section)"
    h2i = find_header(done, 2, h2)
    if h2i == -1:
        if done and done[-1].strip() != "":
            done.append("")
        done.append("## " + h2)
        h2i = len(done) - 1
    if h3:
        h2_end = section_end(done, h2i, 2)
        h3i = find_header(done, 3, h3, start=h2i, stop=h2_end)
        if h3i == -1:
            ins = h2_end
            hdr = ["### " + h3, ""]
            if ins > 0 and done[ins - 1].strip() != "":
                hdr = [""] + hdr
            done[ins:ins] = hdr
            h3i = ins + (1 if hdr[0] == "" else 0)
        target_i, level = h3i, 3
    else:
        target_i, level = h2i, 2
    ins = section_end(done, target_i, level)
    chunk = list(block)
    # ensure a blank line before and after the inserted chunk
    pre = [""] if (ins > 0 and done[ins - 1].strip() != "") else []
    post = [""] if (ins < len(done) and done[ins].strip() != "") else []
    done[ins:ins] = pre + chunk + post
    return done


# ── commands ──────────────────────────────────────────────────────────────────

def cmd_list():
    for it in open_items(read(TODO)):
        print(it["display"])


def cmd_line(display):
    lines = read(TODO)
    it = find(lines, display)
    print((it["start"] + 1) if it else 1)


def cmd_add(text):
    text = text.strip()
    if not text:
        return
    lines = read(TODO)
    if not lines or lines == [""]:
        lines = ["# TODO", ""]
    inbox_i = find_header(lines, 2, "Inbox")
    if inbox_i == -1:
        # create Inbox right after the top title; normalize_blanks fixes spacing
        pos = 1 if lines and lines[0].startswith("# ") else 0
        lines[pos:pos] = ["", "## Inbox", "- [ ] " + text, ""]
    else:
        end = section_end(lines, inbox_i, 2)
        ins = end
        while ins > inbox_i + 1 and lines[ins - 1].strip() == "":
            ins -= 1
        lines[ins:ins] = ["- [ ] " + text]
    write(TODO, normalize_blanks(lines))
    commit(f"todo: add — {text[:60]}")


def cmd_done(display):
    lines = read(TODO)
    it = find(lines, display)
    if not it:
        sys.exit(f"no such item: {display}")
    block = strip_trailing_blanks(lines[it["start"]:it["end"]])
    # flip the checkbox and date-stamp the parent line
    head = block[0]
    head = re.sub(r"^- \[[ ~]\] ", "- [x] ", head)
    head = head + f" (done {date.today().isoformat()})"
    block[0] = head
    # remove from TODO.md
    del lines[it["start"]:it["end"]]
    write(TODO, normalize_blanks(lines))
    # add to DONE.md
    done = place_in_done(read(DONE), it["h2"], it["h3"], block)
    write(DONE, normalize_blanks(done))
    commit(f"todo: done — {it['title'][:60]}")


def cmd_delete(display):
    lines = read(TODO)
    it = find(lines, display)
    if not it:
        sys.exit(f"no such item: {display}")
    del lines[it["start"]:it["end"]]
    write(TODO, normalize_blanks(lines))
    commit(f"todo: delete — {it['title'][:60]}")


def main(argv):
    if not argv:
        cmd_list()
        return
    cmd, *rest = argv
    arg = rest[0] if rest else ""
    {
        "list": lambda: cmd_list(),
        "line": lambda: cmd_line(arg),
        "add": lambda: cmd_add(arg),
        "done": lambda: cmd_done(arg),
        "delete": lambda: cmd_delete(arg),
    }.get(cmd, cmd_list)()


if __name__ == "__main__":
    main(sys.argv[1:])
