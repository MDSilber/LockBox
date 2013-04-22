import BaseHTTPServer, SimpleHTTPServer
import ssl
import json
import re

#import BreakfastSerial
FILENAME = "keys.json"

class MyHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200);
        self.send_header('Content-Type', 'application/json')
        self.end_headers()

        self.wfile.write("test");
        self.wfile.close();
        return
        
        path = self.path.split("?",1)
        path_no_params = path[0]
        path = path[1] if len(path) > 1 else ""
        query = self.process_params(path)

        if path_no_params == '/lock':
            self.wfile.write(json.dumps(self.do_lock(query)))
        elif path_no_params == '/unlock':
            self.wfile.write(json.dumps(self.do_unlock(query)))
        elif path_no_params == '/create':
            self.wfile.write(json.dumps(self.do_create(query)))
        else:
            response = {}
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

    def auth_check(self, query):
        if 'key' not in query or 'lockboxid' not in query:
            return False
        key_content = ''
        with open(FILENAME, 'r') as json_file:
            key_content = json_file.read()

        key_content = json.loads(key_content)
        if key_content[query['lockboxid']] == query['key']:
            return True

        return False 

    def do_lock(self, query):
        if not self.auth_check(query):
            return {'success': False, 'err': 'Authentication Failed'}
        ###TODO LOCKING CODE HERE
        return {'success': True}

    def do_unlock(self, query):
        if not self.auth_check(query):
            return {'success': False, 'err': 'Authentication Failed'}
        ###TODO UNLOCKING CODE HERE
        return {'success': True}

    def do_create(self, query):
        if 'key' not in query or 'lockboxid' not in query:
            return {'success': False, 'err': 'Creation failed'}
        key_content = {query['lockboxid']:query['key']}
        with open(FILENAME, 'w') as json_file:
            json_file.write(json.dumps(key_content))

        return {'success': True}

HOST = '0.0.0.0'
PORT = 4567
Handler = MyHandler
httpd = BaseHTTPServer.HTTPServer((HOST, PORT), Handler)
httpd.socket = ssl.wrap_socket (httpd.socket, certfile='server.pem', server_side=True)
print 'serving on ' + HOST + ":" + str(PORT)
httpd.serve_forever()

