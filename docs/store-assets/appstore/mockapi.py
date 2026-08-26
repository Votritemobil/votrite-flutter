"""Local stand-in for the VotRite API, on the port this web build was compiled against.

The build at build/web was compiled with baseUrl http://127.0.0.1:8972/api, so serving
here is enough on its own -- the app never resolves api.votritemobil.com and production
is never contacted. Vote writes are logged to writes.log and answered, never forwarded.
"""
import json, os, sys, urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mockdata as M

HERE = os.path.dirname(os.path.abspath(__file__))


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, data):
        body = json.dumps({"data": data, "message": "1"}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
        self.end_headers()

    def _route(self, body):
        u = urllib.parse.urlparse(self.path)
        path, q = u.path, urllib.parse.parse_qs(u.query)
        print("API", self.command, path, dict(q) or body, flush=True)
        if path.endswith("/ballot/active"):
            return M.BALLOTS
        if path.endswith("/pincode") and self.command == "GET":
            return M.PINCODE if q.get("pin", [""])[0] == "48291" else []
        if path.endswith("/race/active"):
            return M.RACES
        if path.endswith("/candidate") and self.command == "GET":
            return M.CANDIDATES.get(int(q.get("race_id", ["0"])[0]), [])
        if path.endswith("/ballot/party"):
            return M.PARTIES
        if path.endswith("/proposition"):
            return M.PROPOSITIONS
        if "/counter/" in path or path.endswith("/pincode/update") or path.endswith("/candidate/create"):
            with open(os.path.join(HERE, "writes.log"), "a") as f:
                f.write(json.dumps({"path": path, "body": body}) + "\n")
            return []
        return []

    def do_GET(self):
        self._send(self._route({}))

    def do_POST(self):
        n = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(n).decode() if n else ""
        try:
            body = json.loads(raw)
        except Exception:
            body = raw
        self._send(self._route(body))


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 8972), H).serve_forever()
