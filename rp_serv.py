import BaseHTTPServer, SimpleHTTPServer
import ssl
import json
import re

class MyHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):
    def do_GET(self):
        response = {}
        self.send_response(200);
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        
        path = self.path.split("?",1)
        path_no_params = path[0]
        path = path[1] if len(path) > 1 else ""
        query = self.process_params(path)

        if path_no_params == '/lock':
            self.do_lock(query)
        elif path_no_params == '/unlock':
            self.do_unlock(query)
        else:
            response['response'] = 200
            response['full_path'] = self.path
            response['path_no_params'] = path_no_params
            response['query'] = query
            self.wfile.write(json.dumps(response))

        self.wfile.close()

    def process_params(self,path):
        if path == "":
            return {}

        params = dict(p.split('=', 1) for p in path.split('&'))
        return params

    def do_lock(self, query):
        return

    def do_unlock(self, query):
        return
        


HOST = '0.0.0.0'
PORT = 4567
Handler = MyHandler
httpd = BaseHTTPServer.HTTPServer((HOST, PORT), Handler)
httpd.socket = ssl.wrap_socket (httpd.socket, certfile='server.pem', server_side=True)
print 'serving on ' + HOST + ":" + str(PORT)
httpd.serve_forever()

