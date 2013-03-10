/*
  Lockbox Circuit
 
 Circuit:
 * Ethernet shield attached to pins 10, 11, 12, 13
 
 */

#include <SPI.h>
#include <Ethernet.h>
#include <Servo.h>

// Enter a MAC address for your controller below.
// Newer Ethernet shields have a MAC address printed on a sticker on the shield
byte mac[] = {  
  0x00, 0xAA, 0xBB, 0xCC, 0xDE, 0x02 };

// Initialize the Ethernet client library
// with the IP address and port of the server 
// that you want to connect to (port 80 is default for HTTP):
EthernetClient client;
EthernetServer server(80);
Servo myservo;

boolean incoming = 0;

//Status lights
int noConnection = 4;
int connection = 5;
int locked = 6;
int unlocked = 7;

void startEthernet();
void lock();
void unlock();
void httpResponseOK();
void httpResponseBadRequest();

void setup() {
  // Open serial communications and wait for port to open:
  Serial.begin(9600);
  // this check is only needed on the Leonardo:
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }

  //Set up status indicators
  pinMode(noConnection, OUTPUT);
  pinMode(connection, OUTPUT);
  pinMode(locked, OUTPUT);
  pinMode(unlocked, OUTPUT);

  digitalWrite(noConnection, HIGH);
  digitalWrite(locked, HIGH);

  startEthernet();
}

void startEthernet()
{
  // start the Ethernet connection:
  while (Ethernet.begin(mac) == 0) {
    Serial.println("Failed to configure Ethernet using DHCP");
    // retry every 5 seconds
    delay(5000);
  }

  //Turn status light to blue
  digitalWrite(noConnection, LOW);
  digitalWrite(connection, HIGH);

  // print your local IP address:
  Serial.print("My IP address: ");
  for (byte thisByte = 0; thisByte < 4; thisByte++) {
    // print the value of each byte of the IP address:
    Serial.print(Ethernet.localIP()[thisByte], DEC);
    Serial.print("."); 
  }
  Serial.println();
  server.begin();
  Serial.print("server is at ");
  Serial.println(Ethernet.localIP());
}

void loop()
{
  // listen for incoming clients
  EthernetClient client = server.available();

  if (client) {
    Serial.println("******************************************* New Packet *******************************************\n\n");
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    //I think this should be "if" not "while"
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        Serial.print(c);
        char command;
        
        //Get jawn after dollar sign in order to parse request after request is completely received
        if(c == '$')
        {
          command = client.read();
        }
        
        if(c == '\n' && currentLineIsBlank) {
          // if you've gotten to the end of the line (received a newline
          // character) and the line is blank, the http request has ended,
          // so you can send a reply

          if (command == '1')
          {
            Serial.println("LOCK");
            httpResponseOK();
            client.println("<html><body><h1>Lock</h1></body></html>");
            lock();
          }
          else if (command == '2')
          {
            Serial.println("UNLOCK");
            httpResponseOK();
            client.println("<html><body><h1>Unlock</h1></body></html>");
            unlock();
          }
          else
          {
            httpResponseBadRequest();
            client.println("<html><body><h1>400 Bad Request</h1></body></html>");
          }
          break;
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
        } 
        else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
    Serial.println("Client disconnected");
  }
}

void lock()
{ 
  digitalWrite(locked, HIGH);
  digitalWrite(unlocked, LOW);

//  myservo.attach(9);  // attaches the servo on pin 9 to the servo object
//  myservo.write(1000);
//  delay(154);
//  myservo.detach();
}

void unlock()
{
  digitalWrite(unlocked, HIGH);
  digitalWrite(locked, LOW);

//  myservo.attach(9);  // attaches the servo on pin 9 to the servo object
//  myservo.write(2000);
//  delay(154);
//  myservo.detach();
}

void httpResponseOK()
{
  Serial.println("HTTP RESPONSE OK");
  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: text/html");
  client.println("Connnection: close");
  client.println();
  client.println("<!DOCTYPE HTML>"); 
}

void httpResponseBadRequest()
{
  Serial.println("HTTP RESPONSE BAD REQUEST");
  client.println("HTTP/1.1 400 BAD REQUEST");
  client.println("Content-Type: text/html");
  client.println("Connnection: close");
  client.println();
  client.println("<!DOCTYPE HTML>");  
  client.println("<html><body><h1>400 Bad Request<h1></body></html>");
}



