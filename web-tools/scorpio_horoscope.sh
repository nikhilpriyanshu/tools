#!/usr/bin/env bash
# scorpio_horoscope.sh
# Fetches today's Scorpio horoscope from Vogue India and prints only the main content.

set -euo pipefail

# ── Build today's URL ─────────────────────────────────────────────────────────
# Page URL format: /content/scorpio-horoscope-today-june-9-2026
# We need the month spelled out (no zero-padding on day), e.g. "june-9-2026"
MONTH=$(date +"%B" | tr '[:upper:]' '[:lower:]')   # e.g. june
DAY=$(date +%-d)                                    # e.g. 9  (no leading zero)
YEAR=$(date +"%Y")                                  # e.g. 2026

URL="https://www.vogue.in/content/scorpio-horoscope-today-${MONTH}-${DAY}-${YEAR}"

# ── Fetch & parse ─────────────────────────────────────────────────────────────
# Requires: curl  +  either python3 (preferred) or pup / htmlq as fallback

FETCH_CMD="curl -s -A 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 \
(KHTML, like Gecko) Chrome/124.0 Safari/537.36' \
--compressed '$URL'"

# We use Python's built-in html.parser — no extra install needed.
PARSER='
import sys, re
sys.stdout.reconfigure(encoding="utf-8")
from html.parser import HTMLParser

class HoroscopeParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self._in_article = False
        self._depth      = 0
        self._article_depth = 0
        self._in_skip    = False  # skip nav / form / video / newsletter sections
        self._skip_tags  = {"nav", "form", "figure", "aside", "footer",
                            "script", "style", "noscript"}
        self._skip_depth = 0
        self.title       = ""
        self.date_str    = ""
        self.paragraphs  = []
        self.cosmic_tip  = ""
        self._buf        = ""
        self._capture    = False

    # ── helpers ──────────────────────────────────────────────────────────────
    def _text(self): return self._buf.strip()

    def handle_starttag(self, tag, attrs):
        self._depth += 1
        attrs = dict(attrs)

        # Track article boundaries
        if tag == "article":
            self._in_article = True
            self._article_depth = self._depth
            return

        if not self._in_article:
            return

        # Skip unwanted sections
        if tag in self._skip_tags:
            if self._skip_depth == 0:
                self._in_skip = True
            self._skip_depth += 1
            return

        if self._in_skip:
            return

        # Capture title
        if tag == "h1":
            self._capture = True
            self._buf = ""
            return

        # Capture paragraphs (p) and divs used as content blocks
        if tag in ("p", "div") and not self._capture:
            cls = attrs.get("class", "")
            # Vogue wraps the horoscope text in a div; capture all text divs
            self._capture = True
            self._buf = ""

    def handle_endtag(self, tag):
        if not self._in_article:
            self._depth -= 1
            return

        if tag in self._skip_tags:
            if self._skip_depth > 0:
                self._skip_depth -= 1
            if self._skip_depth == 0:
                self._in_skip = False
            self._depth -= 1
            return

        if self._in_skip:
            self._depth -= 1
            return

        if tag == "h1" and self._capture:
            self.title = self._text()
            self._capture = False

        elif tag in ("p", "div") and self._capture:
            t = self._text()
            if len(t) > 40 and "sign up" not in t.lower() and \
               "newsletter" not in t.lower() and "cookie" not in t.lower():
                if "cosmic tip" in t.lower():
                    # strip label if parser merged it
                    self.cosmic_tip = re.sub(r"^cosmic\s+tip\s*[:\-–]?\s*",
                                             "", t, flags=re.I).strip()
                elif t not in self.paragraphs:
                    self.paragraphs.append(t)
            self._capture = False
            self._buf = ""

        if tag == "article" and self._depth == self._article_depth:
            self._in_article = False

        self._depth -= 1

    def handle_data(self, data):
        if self._capture and not self._in_skip:
            self._buf += data


html = sys.stdin.read()
p = HoroscopeParser()
p.feed(html)

# ── Output ────────────────────────────────────────────────────────────────────
# Grab date from <time> or title as fallback
date_match = re.search(r"(\d{1,2}\s+\w+\s+\d{4}|\w+\s+\d{1,2},?\s+\d{4})", html)
date_str = date_match.group(1) if date_match else ""

print("=" * 60)
if p.title:
    print(p.title)
if date_str:
    print(f"Date : {date_str}")
print("=" * 60)
print()

# De-duplicate and filter noise
seen = set()
for para in p.paragraphs:
    # Skip "Also read", link lists, sign names only, etc.
    if re.match(r"^(also read|trending|illustration|by )", para.lower()):
        continue
    if para in seen:
        continue
    seen.add(para)
    print(para)
    print()

if p.cosmic_tip:
    print(f"✨ Cosmic tip: {p.cosmic_tip}")
    print()
print("=" * 60)
print(f"Source: {sys.argv[1]}")
'

# ── Run ───────────────────────────────────────────────────────────────────────
echo "Fetching: $URL"
echo ""

curl -s \
  -A 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36' \
  --compressed \
  --max-time 15 \
  "$URL" \
| python3 -c "$PARSER" "$URL"
