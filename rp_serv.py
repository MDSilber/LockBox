import BaseHTTPServer, SimpleHTTPServer
import ssl
import json
import re
import urllib2
import sys

from BreakfastSerial import Arduino, Led, Servo

import BreakfastSerial
FILENAME = "keys.json"
board = Arduino()
servo = Servo(board, 10)
leds = {'connected': Led(board, 5), 'disconnected': Led(board, 4),
        'locked': Led(board, 6), 'unlocked': Led(board, 7)}
is_locked = False

class MyHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()

        path = self.path.split("?", 1)
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

    def process_params(self, path):
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
        global is_locked
        if not self.auth_check(query):
            return {'success': False, 'err': 'Authentication Failed'}
        if is_locked:
            return {'success': True, 'msg': 'Already locked'}
        servo.set_position(90)
        leds['unlocked'].off()
        leds['locked'].on()
        is_locked = True
        return {'success': True}

    def do_unlock(self, query):
        global is_locked
        if not self.auth_check(query):
            return {'success': False, 'err': 'Authentication Failed'}
        if not is_locked:
            return {'success': True, 'msg': 'Already unlocked'}
        servo.set_position(0)
        leds['locked'].off()
        leds['unlocked'].on()
        is_locked = False
        return {'success': True}

    def do_create(self, query):
        if 'key' not in query or 'lockboxid' not in query:
            return {'success': False, 'err': 'Creation failed'}
        key_content = {query['lockboxid']:query['key']}
        j = {}
        content = ''
        with open(FILENAME, 'w+') as json_file:
            content = json_file.read()
            if content != '':
                j = json.loads(content)
            j.update(key_content)
            json_file.write(json.dumps(j))

        return {'success': True}

#MAIN CODE HERE
for _, l in leds.iteritems():
    l.off()

#CHECK IF INTERNET IS ON
#FROM http://stackoverflow.com/questions/3764291/checking-network-connection
try:
    response=urllib2.urlopen('http://74.125.228.4', timeout=1)
except urllib2.URLError as err:
    print 'INTERNET COULD NOT CONNECT, EXITING'
    sys.exit(1)

leds['connected'].on()
leds['unlocked'].on()
servo.set_position(0)

HOST = '0.0.0.0'
PORT = 4567
Handler = MyHandler
httpd = BaseHTTPServer.HTTPServer((HOST, PORT), Handler)
httpd.socket = ssl.wrap_socket (httpd.socket, certfile='server.pem', server_side=True)
print 'serving on ' + HOST + ":" + str(PORT)
httpd.serve_forever()

