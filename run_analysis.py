"""Run the analysis notebook from local CSV inputs."""

from pathlib import Path

import nbformat
from nbclient import NotebookClient

ROOT = Path(__file__).resolve().parent
NOTEBOOK = ROOT / "puzzle_analysis.ipynb"


def main():
    required = ("level_summary.csv", "level_109_resource_summary.csv")
    missing = [name for name in required if not (ROOT / "data" / name).is_file()]
    if missing:
        raise SystemExit("Missing input files in data/: " + ", ".join(missing))

    notebook = nbformat.read(NOTEBOOK, as_version=4)
    NotebookClient(notebook, timeout=300, kernel_name="python3").execute(cwd=str(ROOT))
    nbformat.write(notebook, NOTEBOOK)
    print(f"Updated {NOTEBOOK.name}")


if __name__ == "__main__":
    main()
