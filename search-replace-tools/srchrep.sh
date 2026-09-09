#!/usr/bin/env python3

import argparse
import difflib
import os
import sys
import tempfile
from pathlib import Path


EXCLUDED_DIRS = {".git", ".svn", ".hg", "node_modules"}


def is_binary(data: bytes) -> bool:
    """Treat files containing NUL bytes as binary."""
    return b"\x00" in data


def show_diff(path: Path, old: bytes, new: bytes) -> None:
    old_text = old.decode("utf-8", errors="replace").splitlines(keepends=True)
    new_text = new.decode("utf-8", errors="replace").splitlines(keepends=True)

    diff = difflib.unified_diff(
        old_text,
        new_text,
        fromfile=str(path),
        tofile=str(path),
    )

    print("".join(diff), end="")


def replace_file(path: Path, search: bytes, replacement: bytes, dry_run: bool) -> bool:
    try:
        original = path.read_bytes()
    except (PermissionError, OSError) as exc:
        print(f"Skipping {path}: {exc}", file=sys.stderr)
        return False

    if is_binary(original):
        return False

    if search not in original:
        return False

    updated = original.replace(search, replacement)

    if dry_run:
        print(f"\n--- {path} ---")
        show_diff(path, original, updated)
        return True

    try:
        # Write through a temporary file, then replace the original.
        file_mode = path.stat().st_mode

        with tempfile.NamedTemporaryFile(
            mode="wb",
            dir=path.parent,
            prefix=f".{path.name}.",
            delete=False,
        ) as temp:
            temp.write(updated)
            temp_name = temp.name

        os.chmod(temp_name, file_mode)
        os.replace(temp_name, path)

        print(f"Updated: {path}")
        return True

    except (PermissionError, OSError) as exc:
        print(f"Could not update {path}: {exc}", file=sys.stderr)
        try:
            os.unlink(temp_name)
        except OSError:
            pass
        return False


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Recursively search and replace text in the current directory."
    )
    parser.add_argument("search", help="Text to search for")
    parser.add_argument("replacement", help="Replacement text")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show changes without modifying files",
    )

    args = parser.parse_args()

    root = Path.cwd()
    search = args.search.encode("utf-8")
    replacement = args.replacement.encode("utf-8")

    changed = 0
    scanned = 0

    for current_dir, dirnames, filenames in os.walk(root):
        # Do not descend into excluded directories.
        dirnames[:] = [
            dirname for dirname in dirnames
            if dirname not in EXCLUDED_DIRS
        ]

        for filename in filenames:
            path = Path(current_dir) / filename

            if path.is_symlink() or not path.is_file():
                continue

            # Do not modify this script if it happens to contain the search text.
            if path.resolve() == Path(__file__).resolve():
                continue

            scanned += 1
            if replace_file(path, search, replacement, args.dry_run):
                changed += 1

    action = "would be changed" if args.dry_run else "changed"
    print(f"\nScanned {scanned} files; {changed} files {action}.")

    return 0


if __name__ == "__main__":
    sys.exit(main())