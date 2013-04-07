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
        
        response['response'] = 200
        response['path'] = self.path
        response['params'] = self.process_params(self.path)
        self.wfile.write(json.dumps(response))

        self.wfile.close()

    def process_params(self,path):
        path = "".join(path.split("?")[1:])
        params = dict(p.split('=', 1) for p in path.split('&'))
        print params
        return params
        


HOST = '0.0.0.0'
PORT = 4567
Handler = MyHandler
httpd = BaseHTTPServer.HTTPServer((HOST, PORT), Handler)
httpd.socket = ssl.wrap_socket (httpd.socket, certfile='server.pem', server_side=True)
print 'serving on ' + HOST + ":" + PORT
httpd.serve_forever()

