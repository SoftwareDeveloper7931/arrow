import os
import sys
import mimetypes
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

# Register required web & wasm MIME types
mimetypes.init()
mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('application/json', '.json')
mimetypes.add_type('font/otf', '.otf')
mimetypes.add_type('font/ttf', '.ttf')

class FlutterHTTPHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Allow cross-origin and prevent caching issues during local runs
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

    def guess_type(self, path):
        if path.endswith('.wasm'):
            return 'application/wasm'
        if path.endswith('.js'):
            return 'application/javascript'
        if path.endswith('.json'):
            return 'application/json'
        if path.endswith('.otf'):
            return 'font/otf'
        if path.endswith('.ttf'):
            return 'font/ttf'
        return super().guess_type(path)

    def log_message(self, format, *args):
        sys.stdout.write(f"[{self.log_date_time_string()}] {format % args}\n")
        sys.stdout.flush()

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    directory = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.getcwd(), 'build', 'web')
    
    server_address = ('', port)
    handler = lambda *args, **kwargs: FlutterHTTPHandler(*args, directory=directory, **kwargs)
    httpd = ThreadingHTTPServer(server_address, handler)
    print(f"Serving Arrow Flow from {directory} on http://localhost:{port}/ (Multi-threaded, WASM-ready)...")
    sys.stdout.flush()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")

if __name__ == '__main__':
    main()
