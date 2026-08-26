"""Drive the real VotRite Flutter build in a browser and capture raw app screens.

The web build in build/web was compiled with baseUrl http://127.0.0.1:8972/api, so
running mockapi.py on that port is what feeds it: the app never resolves
api.votritemobil.com and production is never contacted. Vote writes land in
mockapi's writes.log instead of a real counter. (The Playwright route on
api.votritemobil.com below is belt-and-braces for a build compiled against the
live URL -- with this build it never fires.)

Usage:  python3 mockapi.py &                      # the stand-in API, port 8972
        (cd build/web && python3 -m http.server 8899)
        python3 capture.py 8899 normal            # full ballot walkthrough
        python3 capture.py 8899 pin               # the PIN screen on its own
        python3 capture.py 8899 vi                # accessibility settings
"""
import json, sys, os, re, urllib.parse
from playwright.sync_api import sync_playwright
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mockdata as M

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "raw")
os.makedirs(OUT, exist_ok=True)
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8899
WRITES = []


def payload(data):
    return json.dumps({"data": data, "message": "1"})


CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "*",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
}


def handle(route, request):
    if request.method == "OPTIONS":
        route.fulfill(status=204, headers=CORS)
        return
    u = urllib.parse.urlparse(request.url)
    path, q = u.path, urllib.parse.parse_qs(u.query)
    body = {}
    if request.post_data:
        try:
            body = json.loads(request.post_data)
        except Exception:
            pass
    if path.endswith("/ballot/active"):
        data = M.BALLOTS
    elif path.endswith("/pincode") and request.method == "GET":
        data = M.PINCODE if q.get("pin", [""])[0] == "482913" else []
    elif path.endswith("/race/active"):
        data = M.RACES
    elif path.endswith("/candidate") and request.method == "GET":
        data = M.CANDIDATES.get(int(q.get("race_id", [0])[0]), [])
    elif path.endswith("/ballot/party"):
        data = M.PARTIES
    elif path.endswith("/proposition"):
        data = M.PROPOSITIONS
    elif "/counter/" in path or path.endswith("/pincode/update") or path.endswith("/candidate/create"):
        WRITES.append((path, body))          # recorded, never forwarded
        data = []
    else:
        data = []
    route.fulfill(status=200, content_type="application/json", headers=CORS, body=payload(data))


class App:
    def __init__(self, page):
        self.page = page

    def shot(self, name, wait=1400):
        self.page.wait_for_timeout(wait)
        self.page.screenshot(path=f"{OUT}/{name}.png")
        print("  shot ->", name)

    def labels(self):
        return self.page.evaluate("""() => [...document.querySelectorAll('flt-semantics')]
            .map(e => (e.getAttribute('aria-label')||e.textContent||'').trim())
            .filter(t => t && t.length < 90)""")

    def tap(self, text, nth=0, wait=1200):
        """Tap the SMALLEST semantics node whose label contains `text`.

        Flutter's semantics tree nests: an ancestor carries the whole page's text
        concatenated, so a plain match lands mid-screen. Smallest area = the widget.
        """
        el = self.page.evaluate("""([t, n]) => {
            const m = [...document.querySelectorAll('flt-semantics')].filter(e =>
                (e.getAttribute('aria-label')||e.textContent||'').includes(t)
            ).map(e => {
                const r = e.getBoundingClientRect();
                return {x: r.x + r.width/2, y: r.y + r.height/2, a: r.width*r.height};
            }).filter(o => o.a > 0).sort((p, q) => p.a - q.a);
            return m[n] || null;
        }""", [text, nth])
        if not el:
            print(f"  !! no node for {text!r}; labels = {self.labels()}")
            return False
        self.page.touchscreen.tap(el["x"], el["y"])
        print(f"  tap {text!r} @ {int(el['x'])},{int(el['y'])}")
        self.page.wait_for_timeout(wait)
        return True

    def tap_lowest(self, text, wait=1200):
        """Tap the lowest node carrying `text` -- for dialogs where the title and
        the confirm button share a label, the button is the one further down."""
        el = self.page.evaluate("""(t) => {
            const m = [...document.querySelectorAll('flt-semantics')].filter(e =>
                ((e.getAttribute('aria-label')||e.textContent||'').trim() === t)
            ).map(e => {
                const r = e.getBoundingClientRect();
                return {x: r.x + r.width/2, y: r.y + r.height/2, a: r.width*r.height};
            }).filter(o => o.a > 0).sort((p, q) => q.y - p.y);
            return m[0] || null;
        }""", text)
        if not el:
            print(f"  !! no node for {text!r}; labels = {self.labels()}")
            return False
        self.page.touchscreen.tap(el["x"], el["y"])
        print(f"  tap(lowest) {text!r} @ {int(el['x'])},{int(el['y'])}")
        self.page.wait_for_timeout(wait)
        return True

    def start(self, port):
        self.page.goto(f"http://127.0.0.1:{port}/", wait_until="networkidle")
        self.page.wait_for_timeout(6000)
        self.page.evaluate("""() => {
            const b = document.querySelector('flt-semantics-placeholder');
            if (b) b.click();
        }""")
        self.page.wait_for_timeout(2500)


def run(pw, port, which):
    b = pw.chromium.launch(args=["--force-device-scale-factor=3"])
    ctx = b.new_context(viewport={"width": 430, "height": 932},
                        device_scale_factor=3, is_mobile=True, has_touch=True)
    ctx.route(re.compile(r"api\.votritemobil\.com"), handle)
    page = ctx.new_page()
    a = App(page)
    a.start(port)

    if which == "normal":
        a.shot("01_language", 600)
        a.tap("English")
        a.shot("02_mode")
        a.tap("Normal Mode", wait=2500)
        a.shot("03_ballots")
        print("  labels:", a.labels()[:12])
        a.tap("General Election 2026", wait=2500)
        a.shot("04_pin_empty")
        # Tapping the field makes Flutter mount a real <input> over the canvas;
        # typing into that element is what actually reaches the widget.
        a.tap("Enter your PIN code", wait=1200)
        page.locator("input").first.type("48291", delay=90)
        a.shot("05_pin_typed", 800)
        page.wait_for_timeout(3500)          # login submits itself on the 5th digit
        a.shot("06_race")
        a.tap("Ellen Marsh", wait=1200)
        a.shot("07_race_selected")
        a.tap("Next Race", wait=2500)
        a.shot("08_race2")
        print("  labels 08:", a.labels()[:16])
        a.tap("Marcus Bell", wait=900)
        a.tap("Priya Raman", wait=900)
        a.tap("Continue", wait=2500)
        a.shot("09_proposition")
        a.tap("Vote YES", wait=1200)
        a.shot("10_prop_voted")
        a.tap("Review", wait=2500)
        a.shot("11_review")
        # Safe: this build points at 127.0.0.1:8972, so the cast lands in the
        # local mock and is written to writes.log. Production is never contacted.
        a.tap("Cast Ballot", wait=3000)
        a.shot("12_cast_confirm")
        a.tap_lowest("Cast Ballot", wait=4500)
        a.shot("13_finish")
        print("  labels 13:", a.labels()[:20])
    elif which == "pin":
        a.tap("English")
        a.tap("Normal Mode", wait=2500)
        a.tap("General Election 2026", wait=2500)
        a.tap("Enter your PIN code", wait=1200)
        # four digits only: the form submits itself on the fifth, and we want the
        # PIN screen itself, not the screen after it
        page.locator("input").first.type("4829", delay=110)
        a.shot("04_pin", 1200)
    else:
        a.tap("English")
        a.tap("Visually Impaired", wait=4500)
        a.shot("10_vi_settings")
        print("  labels:", a.labels()[:20])

    b.close()


def main():
    which = sys.argv[2] if len(sys.argv) > 2 else "normal"
    with sync_playwright() as p:
        run(p, PORT, which)
    print("WRITES attempted:", WRITES)


if __name__ == "__main__":
    main()
