#!/usr/bin/env python3
"""Utility to ensure SwiftUI preview target for Teatro.

This script detects whether the repository uses Swift Package Manager or an
Xcode project. It ensures that new Swift files containing `#Preview` are added
to a buildable preview application so Xcode can display SwiftUI previews.

Currently only Swift Package Manager projects are supported. The script will
add a new `TeatroPreviewApp` target to `Package.swift` if necessary and create
the required source files. The provided Swift file will be symlinked into that
target's source directory so it participates in the build.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path


PREVIEW_TARGET_NAME = "TeatroPreviewApp"
PREVIEW_TARGET_PATH = Path("Sources") / PREVIEW_TARGET_NAME
PREVIEW_APP_FILE = PREVIEW_TARGET_PATH / f"{PREVIEW_TARGET_NAME}.swift"
PACKAGE_MANIFEST = Path("Package.swift")

PREVIEW_APP_TEMPLATE = """import SwiftUI
import Teatro
import TeatroPlaygroundUI

@main
struct TeatroPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            StoryboardMIDIDemoPreviewView()
        }
    }
}
"""


def run(cmd: list[str]) -> subprocess.CompletedProcess:
    """Run command and return CompletedProcess."""
    return subprocess.run(cmd, text=True, capture_output=True)


def detect_project_type(repo_root: Path) -> str | None:
    """Return 'xcodeproj' or 'swiftpm' depending on project structure."""
    if any(repo_root.glob("*.xcodeproj")):
        return "xcodeproj"
    if (repo_root / PACKAGE_MANIFEST).exists():
        return "swiftpm"
    return None


def ensure_swiftpm_preview_target(repo_root: Path, swift_file: Path) -> None:
    manifest_path = repo_root / PACKAGE_MANIFEST
    content = manifest_path.read_text()
    if PREVIEW_TARGET_NAME not in content:
        # Insert new target before closing bracket of targets array
        target_def = (
            "        .target(\n"
            f"            name: \"{PREVIEW_TARGET_NAME}\",\n"
            "            dependencies: [\"Teatro\", \"TeatroPlaygroundUI\"],\n"
            f"            path: \"{PREVIEW_TARGET_PATH.as_posix()}\"\n"
            "        ),\n"
        )
        pattern = r"(targets:\s*\[)"
        match = re.search(pattern, content)
        if not match:
            raise SystemExit("Could not locate targets array in Package.swift")
        end_index = content.rfind("]")
        if end_index == -1:
            raise SystemExit("Malformed Package.swift: missing closing bracket")
        new_content = content[: end_index] + target_def + content[end_index:]
        manifest_path.write_text(new_content)
        print(f"Added {PREVIEW_TARGET_NAME} target to Package.swift")
    else:
        print(f"{PREVIEW_TARGET_NAME} target already present")

    PREVIEW_TARGET_PATH.mkdir(parents=True, exist_ok=True)
    if not PREVIEW_APP_FILE.exists():
        PREVIEW_APP_FILE.write_text(PREVIEW_APP_TEMPLATE)
        print(f"Created {PREVIEW_APP_FILE}")

    # Symlink the swift file into the preview target if not already there
    destination = PREVIEW_TARGET_PATH / swift_file.name
    if destination.resolve() == swift_file.resolve():
        return
    if not destination.exists():
        try:
            destination.symlink_to(os.path.relpath(swift_file, PREVIEW_TARGET_PATH))
            print(f"Symlinked {swift_file} to {destination}")
        except OSError:
            # Fall back to copying
            import shutil

            shutil.copy2(swift_file, destination)
            print(f"Copied {swift_file} to {destination}")


# Placeholder for future Xcode project support

def ensure_xcode_preview_target(repo_root: Path, swift_file: Path) -> None:
    raise NotImplementedError(
        "Xcode project modification is not implemented in this utility yet."
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Setup SwiftUI preview target")
    parser.add_argument("swift_file", type=Path, help="Path to the Swift file")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    swift_file = args.swift_file.resolve()

    project_type = detect_project_type(repo_root)
    if project_type == "swiftpm":
        ensure_swiftpm_preview_target(repo_root, swift_file)
    elif project_type == "xcodeproj":
        ensure_xcode_preview_target(repo_root, swift_file)
    else:
        print("Could not determine project type.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
