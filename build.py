"""Turn a plain text file into an HTML page using template.html.

Usage: python3 build.py <input.txt> <output_dir>

The first line of the file is the title. Every other non-blank line
becomes a <p>. The page is saved as <output_dir>/<input name>.html and
its path is printed. Errors go to stderr with exit code 1.
"""

import html
import sys
from datetime import date
from pathlib import Path

TEMPLATE = Path(__file__).parent / "template.html"


def build(input_file, output_dir):
    lines = [line.strip() for line in input_file.read_text(encoding="utf-8").splitlines()]
    if not lines or not lines[0]:
        raise ValueError(f"{input_file} has no title on its first line")

    title = html.escape(lines[0])
    paragraphs = [f"<p>{html.escape(line)}</p>" for line in lines[1:] if line]
    today = date.today()

    page = (TEMPLATE.read_text(encoding="utf-8")
            .replace("{{TITLE}}", title)
            .replace("{{DATE}}", f"{today:%B} {today.day}, {today.year}")
            .replace("{{CONTENT}}", "\n\t\t\t".join(paragraphs)))

    output_dir.mkdir(parents=True, exist_ok=True)
    output_file = output_dir / f"{input_file.stem}.html"
    output_file.write_text(page, encoding="utf-8")
    return output_file


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: python3 build.py <input.txt> <output_dir>")
    try:
        print(build(Path(sys.argv[1]), Path(sys.argv[2])))
    except (OSError, UnicodeDecodeError, ValueError) as e:
        sys.exit(f"error: {e}")


if __name__ == "__main__":
    main()
