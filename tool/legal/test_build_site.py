"""python3 -m unittest tool/legal/test_build_site.py"""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build_site  # noqa: E402


class RenderMarkdownTest(unittest.TestCase):
    def test_headings_lists_and_paragraphs(self):
        out = build_site.render_markdown(
            "# Title\n\nOne\nline.\n\n- a\n- b\n\n1. first\n2. second\n", "x@y.io"
        )
        self.assertEqual(
            out,
            "<h1>Title</h1>\n<p>One line.</p>\n<ul><li>a</li><li>b</li></ul>\n"
            "<ol><li>first</li><li>second</li></ol>",
        )

    def test_escapes_text_and_links_the_support_email(self):
        out = build_site.render_markdown(
            'Say "hi" <now> & [go](/privacy) to {supportEmail}.', "x@y.io"
        )
        self.assertIn("&lt;now&gt; &amp;", out)
        self.assertIn('<a href="/privacy">go</a>', out)
        self.assertIn('<a href="mailto:x@y.io" dir="ltr">x@y.io</a>', out)


class BuildTest(unittest.TestCase):
    def test_every_page_in_both_languages_from_the_app_copies(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            build_site.build(out, email="x@y.io")
            for slug in ("privacy", "terms", "delete-account"):
                self.assertTrue((out / f"{slug}.html").exists(), slug)
                ar = (out / "ar" / f"{slug}.html").read_text(encoding="utf-8")
                self.assertIn('<html lang="ar" dir="rtl">', ar)
            privacy = (out / "privacy.html").read_text(encoding="utf-8")
            first_heading = (build_site.LEGAL / "privacy_en.md").read_text(
                encoding="utf-8"
            ).splitlines()[0][2:]
            self.assertIn(f"<h1>{first_heading}</h1>", privacy)
            index = (out / "index.html").read_text(encoding="utf-8")
            self.assertIn('<section lang="ar" dir="rtl">', index)
            self.assertNotIn("{supportEmail}", index)


if __name__ == "__main__":
    unittest.main()
