"""Check source file sizes and the Flutter screen layout described in SCREENS.md."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOTS = (ROOT / "DatingAPP/lib", ROOT / "backend/src")
FLUTTER_LIB = ROOT / "DatingAPP/lib"
SCREEN_MAP = ROOT / "SCREENS.md"
MAX_LINES = 400

SCREEN_CLASS = re.compile(r"^class (\w+(?:Screen|Viewer|Gate))\b", re.M)
DIRECTIVE = re.compile(r"""^\s*(?:import|export|part)\s+['"]([^'"]+)['"]""", re.M)


def check_sizes():
    files = []
    for source_root in SOURCE_ROOTS:
        for path in source_root.rglob("*"):
            if path.suffix not in {".dart", ".ts"} or path.name.endswith(
                (".g.dart", ".freezed.dart", ".d.ts")
            ):
                continue
            files.append((len(path.read_text().splitlines()), path))
    oversized = [(size, path) for size, path in files if size > MAX_LINES]
    for size, path in sorted(oversized, reverse=True):
        print(f"{path.relative_to(ROOT)}: {size} lines (limit {MAX_LINES})")
    if not oversized:
        print(f"Checked {len(files)} source files: all within {MAX_LINES} lines.")
        for size, path in sorted(files, reverse=True)[:5]:
            print(f"  {size:3}  {path.relative_to(ROOT)}")
    return not oversized


def snake_case(name):
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def reachable_files():
    """Dart files transitively imported (or included as parts) from main.dart."""
    package = "package:dating_app/"
    seen, stack = set(), [FLUTTER_LIB / "main.dart"]
    while stack:
        path = stack.pop().resolve()
        if path in seen or not path.exists():
            continue
        seen.add(path)
        for uri in DIRECTIVE.findall(path.read_text()):
            if uri.startswith(package):
                stack.append(FLUTTER_LIB / uri[len(package):])
            elif not uri.startswith(("dart:", "package:")):
                stack.append(path.parent / uri)
    return seen


def parked_screens(screen_map):
    """Screens named in the first column of the 'Parked screens' table."""
    section = re.search(r"^## Parked screens\n(.*?)(?=^## |\Z)", screen_map, re.M | re.S)
    if not section:
        return set()
    first_cells = re.findall(r"^\|([^|]*)\|", section.group(1), re.M)
    return {
        name
        for cell in first_cells
        for name in re.findall(r"\b(\w+(?:Screen|Viewer|Gate))\b", cell)
    }


def check_screens():
    problems = []
    screen_map = SCREEN_MAP.read_text() if SCREEN_MAP.exists() else ""
    if not screen_map:
        problems.append(f"{SCREEN_MAP.relative_to(ROOT)} is missing")
    parked = parked_screens(screen_map)
    reachable = reachable_files()
    screens = {}
    for path in sorted(FLUTTER_LIB.rglob("*.dart")):
        names = SCREEN_CLASS.findall(path.read_text())
        rel = path.relative_to(ROOT)
        if not names:
            continue
        if len(names) > 1:
            problems.append(f"{rel}: one screen per file, found {', '.join(names)}")
        if path.parent.name != "screens":
            problems.append(f"{rel}: screens belong in presentation/screens/")
        if len(names) == 1 and path.stem != snake_case(names[0]):
            problems.append(f"{rel}: name the file {snake_case(names[0])}.dart")
        for name in names:
            screens[name] = path
    for name, path in sorted(screens.items()):
        rel = path.relative_to(ROOT)
        if not re.search(rf"\b{name}\b", screen_map):
            problems.append(f"{rel}: {name} is not listed in SCREENS.md")
        is_reachable = path.resolve() in reachable
        if not is_reachable and name not in parked:
            problems.append(
                f"{rel}: {name} is not reachable from main.dart; "
                "navigate to it or list it under 'Parked screens' in SCREENS.md"
            )
        if is_reachable and name in parked:
            problems.append(
                f"{rel}: {name} is reachable but listed under 'Parked screens'"
            )
    for name in sorted(parked - set(screens)):
        problems.append(f"SCREENS.md: parked screen {name} no longer exists")
    for problem in problems:
        print(problem)
    if not problems:
        print(
            f"Checked {len(screens)} screens: one per file, named after the "
            f"screen, listed in SCREENS.md, and reachable ({len(parked)} parked)."
        )
    return not problems


def main():
    sizes_ok = check_sizes()
    screens_ok = check_screens()
    return 0 if sizes_ok and screens_ok else 1


if __name__ == "__main__":
    sys.exit(main())
