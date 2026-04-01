#!/usr/bin/env python3
"""
generate-catalog.py — Auto-generates catalog.json from HTML files in analyses/

For each HTML file, extracts:
  - title:   from <title> tag
  - author:  from <meta name="author"> (falls back to "Team")
  - date:    from <meta name="date"> or filename date pattern, or file mod time
  - summary: from <meta name="description"> or first meaningful <p> text
  - tags:    from <meta name="keywords"> or auto-detected from title + content

Drop HTML files into analyses/ and run this script — or let GitHub Actions run it.
"""

import json
import os
import re
import glob
from html.parser import HTMLParser
from datetime import datetime


ANALYSES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "analyses")
CATALOG_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "catalog.json")

# Keywords to detect for auto-tagging
TAG_RULES = [
    ("Resolve", ["resolve", "goto resolve"]),
    ("Rescue", ["rescue", "goto rescue"]),
    ("Nexus", ["nexus"]),
    ("AI", ["ai ", " ai,", "artificial intelligence", "machine learning", "agent", "agentic", "llm", "copilot"]),
    ("PLG", ["plg", "product-led", "product led", "self-serve", "trial", "conversion", "onboarding"]),
    ("RMM", ["rmm", "remote monitoring", "endpoint management", "patch", "device management"]),
    ("analytics", ["analytics", "dashboard", "metrics", "data viz", "visualization", "chart", "heatmap", "digest"]),
    ("competitive", ["competitive", "competitor", "landscape", "market", "versus", " vs "]),
    ("strategy", ["strategy", "strategic", "roadmap", "vision", "thesis", "bet "]),
    ("user-research", ["user research", "interview", "usability", "persona", "ux research"]),
    ("sales", ["sales", "revenue", "pipeline", "deal", "win rate", "quota"]),
    ("VoC", ["voc", "voice of customer", "voice of the customer", "feedback", "nps", "csat"]),
    ("funnel", ["funnel", "drop-off", "dropoff", "conversion rate"]),
    ("architecture", ["architecture", "pipeline", "backend", "infrastructure", "api", "system design"]),
    ("pitch", ["pitch", "proposal", "business case", "initiative"]),
    ("trends", ["trend", "weekly", "digest", "retrospective"]),
    ("security", ["security", "vulnerability", "threat", "zero trust", "compliance"]),
]


class HTMLMetaExtractor(HTMLParser):
    """Extracts title, meta tags, and visible text content from HTML."""

    def __init__(self):
        super().__init__()
        self.title = ""
        self.meta = {}
        self.paragraphs = []
        self.visible_text = []  # All visible text (for tag matching)
        self._in_title = False
        self._in_p = False
        self._current_p = ""
        self._in_style = False
        self._in_script = False

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        if tag == "title":
            self._in_title = True
        elif tag == "meta":
            name = attrs_dict.get("name", "").lower()
            content = attrs_dict.get("content", "")
            if name and content:
                self.meta[name] = content
        elif tag == "p" and not self._in_style and not self._in_script:
            self._in_p = True
            self._current_p = ""
        elif tag == "style":
            self._in_style = True
        elif tag == "script":
            self._in_script = True

    def handle_endtag(self, tag):
        if tag == "title":
            self._in_title = False
        elif tag == "p" and self._in_p:
            self._in_p = False
            text = self._current_p.strip()
            # Only keep paragraphs with real content (not just labels/short text)
            if len(text) > 40:
                self.paragraphs.append(text)
        elif tag == "style":
            self._in_style = False
        elif tag == "script":
            self._in_script = False

    def handle_data(self, data):
        if self._in_title:
            self.title += data
        elif self._in_p:
            self._current_p += data
        # Collect all visible text (not in style/script) for tag matching
        if not self._in_style and not self._in_script:
            self.visible_text.append(data)

    def get_visible_text(self):
        """Returns all visible text concatenated — no CSS or JS."""
        return " ".join(self.visible_text)


def extract_metadata(filepath):
    """Extract metadata from a single HTML file."""
    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    parser = HTMLMetaExtractor()
    try:
        parser.feed(content)
    except Exception:
        pass

    filename = os.path.basename(filepath)
    # Use only visible text (no CSS/JS) for tag matching
    visible_text = parser.get_visible_text()
    content_lower = (parser.title + " " + visible_text).lower()

    # Title
    title = (parser.meta.get("title") or parser.title or filename.replace(".html", "").replace("-", " ").title()).strip()
    # Clean common suffixes
    for suffix in [" — GoTo Resolve", " - GoTo Resolve"]:
        if title.endswith(suffix):
            title = title[: -len(suffix)].strip()

    # Author
    author = parser.meta.get("author", "Team").strip()

    # Date: try meta tag, then filename pattern (YYYY-MM-DD), then file mod time
    date_str = parser.meta.get("date", "").strip()
    if not date_str:
        date_match = re.search(r"(\d{4}-\d{2}-\d{2})", filename)
        if date_match:
            date_str = date_match.group(1)
        else:
            mtime = os.path.getmtime(filepath)
            date_str = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d")

    # Summary: try meta description, then first meaningful paragraph
    summary = parser.meta.get("description", "").strip()
    if not summary and parser.paragraphs:
        summary = parser.paragraphs[0]
        # Truncate if too long
        if len(summary) > 200:
            summary = summary[:197].rsplit(" ", 1)[0] + "…"

    # Tags: try meta keywords, then auto-detect
    keywords_raw = parser.meta.get("keywords", "").strip()
    if keywords_raw:
        tags = [t.strip() for t in keywords_raw.split(",") if t.strip()]
    else:
        tags = []
        for tag_name, patterns in TAG_RULES:
            if any(p in content_lower for p in patterns):
                tags.append(tag_name)
        # Deduplicate and limit
        tags = list(dict.fromkeys(tags))[:6]

    return {
        "title": title,
        "author": author,
        "date": date_str,
        "summary": summary,
        "tags": tags,
        "file": f"analyses/{filename}",
    }


def main():
    html_files = sorted(glob.glob(os.path.join(ANALYSES_DIR, "*.html")))

    if not html_files:
        print("No HTML files found in analyses/")
        return

    catalog = []
    for filepath in html_files:
        entry = extract_metadata(filepath)
        catalog.append(entry)
        print(f"  ✓ {os.path.basename(filepath)} → \"{entry['title']}\" [{', '.join(entry['tags'])}]")

    # Sort by date descending
    catalog.sort(key=lambda x: x.get("date", ""), reverse=True)

    with open(CATALOG_PATH, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)

    print(f"\nGenerated catalog.json with {len(catalog)} entries.")


if __name__ == "__main__":
    main()
