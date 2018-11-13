/////////////////////////////////////////////////////////////////////////////
// MyOTAThing.ino
// COM3505 lab assessment: Over-The-Air update template; ADD YOUR CODE HERE!
/////////////////////////////////////////////////////////////////////////////
#include "MyOTAThing.h"
// the wifi and HTTP server libraries ///////////////////////////////////////
#include <WiFi.h>         // wifi
//#include <ESPserver.h> // simple server
#include <ESPWebServer.h>
#include <HTTPClient.h>   // ESP32 library for making HTTP requests
#include <Update.h>       // OTA update library
#include "libraries/CPP_PageNode.cpp"
#include <iostream>
#include <WiFiClient.h>
#include <WiFiClientSecure.h>
#include <SPIFFS.h>

// OTA stuff ////////////////////////////////////////////////////////////////
int doCloudGet(HTTPClient *, String, String); // helper for downloading 'ware
void doOTAUpdate();                           // main OTA logic
int currentVersion = 22; // Used to check for updates
String gitID = "a-chapman"; //Team's git ID

// MAC and IP helpers ///////////////////////////////////////////////////////
char MAC_ADDRESS[13]; // MAC addresses are 12 chars, plus the NULL terminator
void getMAC(char *);
String ip2str(IPAddress);                 // helper for printing IP addresses

// LED utilities, loop slicing ///////////////////////////////////////////////
void ledOn();
void ledOff();
void blink(int = 1, int = 300);
int loopIteration = 0;

// WebServer Stuff
ESPWebServer server(80);

// Structure representing response when getting latest version.
struct versionResponse{
  int responseCode;
  int latestVersion;
};

// HTTPS Certificates
// Github Root CA Certificate
const char* root_ca = \
  "-----BEGIN CERTIFICATE-----\n"
  "MIIDxTCCAq2gAwIBAgIQAqxcJmoLQJuPC3nyrkYldzANBgkqhkiG9w0BAQUFADBs\n" \
  "MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3\n" \
  "d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3VyYW5j\n" \
  "ZSBFViBSb290IENBMB4XDTA2MTExMDAwMDAwMFoXDTMxMTExMDAwMDAwMFowbDEL\n" \
  "MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3\n" \
  "LmRpZ2ljZXJ0LmNvbTErMCkGA1UEAxMiRGlnaUNlcnQgSGlnaCBBc3N1cmFuY2Ug\n" \
  "RVYgUm9vdCBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMbM5XPm\n" \
  "+9S75S0tMqbf5YE/yc0lSbZxKsPVlDRnogocsF9ppkCxxLeyj9CYpKlBWTrT3JTW\n" \
  "PNt0OKRKzE0lgvdKpVMSOO7zSW1xkX5jtqumX8OkhPhPYlG++MXs2ziS4wblCJEM\n" \
  "xChBVfvLWokVfnHoNb9Ncgk9vjo4UFt3MRuNs8ckRZqnrG0AFFoEt7oT61EKmEFB\n" \
  "Ik5lYYeBQVCmeVyJ3hlKV9Uu5l0cUyx+mM0aBhakaHPQNAQTXKFx01p8VdteZOE3\n" \
  "hzBWBOURtCmAEvF5OYiiAhF8J2a3iLd48soKqDirCmTCv2ZdlYTBoSUeh10aUAsg\n" \
  "EsxBu24LUTi4S8sCAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQF\n" \
  "MAMBAf8wHQYDVR0OBBYEFLE+w2kD+L9HAdSYJhoIAu9jZCvDMB8GA1UdIwQYMBaA\n" \
  "FLE+w2kD+L9HAdSYJhoIAu9jZCvDMA0GCSqGSIb3DQEBBQUAA4IBAQAcGgaX3Nec\n" \
  "nzyIZgYIVyHbIUf4KmeqvxgydkAQV8GK83rZEWWONfqe/EW1ntlMMUu4kehDLI6z\n" \
  "eM7b41N5cdblIZQB2lWHmiRk9opmzN6cN82oNLFpmyPInngiK3BD41VHMWEZ71jF\n" \
  "hS9OMPagMRYjyOfiZRYzy78aG6A9+MpeizGLYAiJLQwGXFK3xPkKmNEVX58Svnw2\n" \
  "Yzi9RKR/5CYrCsSXaQ3pjOLAEFe4yHYSkVXySGnYvCoCWw9E1CAx2/S6cCZdkGCe\n" \
  "vEsXCS+0yx5DaMkHJ8HSXPfqIbloEpw8nL+e/IBcm2PN7EeqJSdnoDfzAIJ9VNep\n" \
  "+OkuE6N36B9K\n" \
  "-----END CERTIFICATE-----\n";

// Button Press Timers
int buttonPin = 14;
long button_hold_length;
byte button_prev_state = HIGH;
int button_current_state;
unsigned long button_press_start; // how long since the button was first pressed


// LED Pins
// LEDs are assigned to pins 32,15 and 12
const int redLED = 32;
const int yellowLED = 15;
const int greenLED = 12;

// SoftAP Information
String softAPSSID = "MyOTAThing";
String softAPPassword = "defaultpassword";
String netSSID = "uos-other";
String netPassword = "shefotherkey05";

// SETUP: initialisation entry point //////////////////////////////////////// DONE
void setup() {
  Serial.begin(115200);         // initialise the serial line
  getMAC(MAC_ADDRESS);          // store the MAC address

  // GPIO Setup
  pinMode(buttonPin, INPUT_PULLUP);
  pinMode(redLED, OUTPUT);
  pinMode(yellowLED, OUTPUT);
  pinMode(greenLED, OUTPUT);
  
  // Print some startup stuff.
  Serial.printf("\nMyOTAThing setup...\nESP32 MAC = %s\n", MAC_ADDRESS);
  Serial.printf("firmware is at version %d\n", currentVersion);

  // Turn off red light at startup
  digitalWrite(redLED, LOW);
  dln(startupDBG, "Lights On GPIO Reset");

  // Start the access point.
  startNetwork();
  // Start the web server.
  startWebServer();

  // We could do an OTA update at startup. But lets not...
  //doOTAUpdate();
}

// LOOP: task entry point /////////////////////////////////////////////////// DONE
void loop() {
  // Slice sizes for doing things every x loops.
  int sliceSize = 5000000;
  // Loop counter
  loopIteration++;

  Serial.println("BEANS");
  // Get the time when board button is first pressed.
  button_current_state = digitalRead(buttonPin);
  // if the button state changes to pressed, remember the start time
  if (button_current_state == LOW && button_prev_state == HIGH && (millis() - button_press_start) > 200) {
    button_press_start = millis();
    dln(loopDBG, "Button Pressed");
  }

  // Get length the button was/has been held for
  button_hold_length = millis() - button_press_start;
  // If button has been held a reasonable amount of time, consider it a press
  if (button_hold_length > 100){
    // When user lets go of button
    if (button_current_state == HIGH && button_prev_state == LOW) {
      dln(loopDBG, "Button Released");
      // If the button had been held for 3 to 15 seconds, do an update
      if ((button_hold_length > 3000)&&(button_hold_length < 15000)){
        dln(loopDBG, "Button Hold 3-15s");
        doOTAUpdateSecure();
      }
      // If the button had been held more than 15 seconds, do a factory reset.
      if (button_hold_length > 15000){
        dln(loopDBG, "Button Hold > 15s");
        doRevertToFactory();
      }
    }
  }

  // Every x loops. Do this.
  if(loopIteration % sliceSize == 0){
    // a slice every sliceSize iterations
    dln(loopDBG, "In Slice - Check Version");
    versionResponse updateCheck = getLatestVersion(false);
    if (updateCheck.latestVersion > currentVersion){
      dln(loopDBG, "Light Enabled");
      digitalWrite(redLED, HIGH);  
    }
    if (WiFi.status() != WL_CONNECTED){
      
    }
  }

  // Deal with pending web requests.
  server.handleClient(); 

  // Record state of button on this loop.
  button_prev_state = button_current_state;
}

// FLASHING FUNCTION: Perform factory reset /////////////////////////////////////////////////// DONE

// Reverts to factory software stored in SPIFFS
void doRevertToFactory(){
  dln(factoryDBG, "Begin revert to factory.");
  SPIFFS.begin();
  // Check Factory FW has been flashed to SPIFFS
  if (SPIFFS.exists("/FACTORY.bin")){
      // Load factory file from SPIFFS
      dln(factoryDBG, "File Found");
      File fw = SPIFFS.open("/FACTORY.bin", "r");
      
      uint32_t maxSketchSpace = 0x140000;
      
      // Update using filestream
      // Check that enough space is available in main partition to flash firmware
      if (!Update.begin(maxSketchSpace, U_FLASH)) { 
        dln(factoryDBG, "Not enough space for flashing factory image.");
      }
      // Stream the file and flash the update
      while (fw.available()) {
        uint8_t ibuffer[128];
        fw.read((uint8_t *)ibuffer, 128);
        Update.write(ibuffer, sizeof(ibuffer));
      }
      // Check that the update is done. Print error if not
      if (!Update.end(true)){
        dln(factoryDBG, "The update did not correctly finish");
      }
      // Close the file
      
      fw.close();
      // Restart ESP32
      dln(factoryDBG, "ESP32 Restarting - FW Reset Complete");
      ESP.restart();
  } else {
    dln(factoryDBG, "File Not Found");
  }

}

// OTA over-the-air updates stuff /////////////////////////////////////////// 
void doOTAUpdate() {             // the main OTA logic
  // Boolean controls whether update is needed
  bool updateNeeded = true;

  // Manage the HTTP Request process
  HTTPClient http;

  // Stores respose code returned by httpclient
  int respCode;

  // Stores latest firmware version on server
  int highestAvailableVersion = -1;

  // Do a GET to read the version file from the cloud
  dln(otaDBG, "Checking for new FW...");
  versionResponse response = getLatestVersion(false);

  /* If the response is HTTP OK. Read version file from stream. Otherwise print
     error getting version. */
  if(response.responseCode == 200){
    highestAvailableVersion = response.latestVersion;
  } else{
    updateNeeded = false;
    Serial.printf("Couldn't get version! HTTP rtn code: %d\n", respCode);
  }

  // Free up resources. Payload handled.
  http.end();

  // Check whether the fetched version is higher than current FW version.
  if(currentVersion >= highestAvailableVersion) {
    dln(otaDBG, "FW version is already up to date");
    updateNeeded = false;
  }

 /*  Other methods
  needed are Update.isFinished and Update.getError. When an update
  has been performed correctly, you can restart the device via ESP.restart().
  */

  if (updateNeeded){
    dbg(otaDBG, "Constructing Filepath: ");
    String filepath = String(highestAvailableVersion) + ".bin";
    dln(otaDBG, filepath.c_str());
    
    // Get response from server
    respCode = doCloudGet(&http, gitID, filepath);
  
    int len = http.getSize();
  
    if (respCode == HTTP_CODE_OK){
      dln(otaDBG, "Reached file: HTTP_CODE_OK ");
      if (len > 0){
        bool shouldUpdate = true;
      }
    }else{
      dbg(otaDBG, "File could not be reached. HTTP Response: ");
      dln(otaDBG, respCode);
    }
  
    WiFiClient *tcp = http.getStreamPtr();
  
    Serial.println("Beginning Update...");
    if (!Update.begin(len)){
      dln(otaDBG, "Not enough space for flashing FW image.");
    }
    if(Update.writeStream(*tcp) != len){
      dln(otaDBG, "FW flash error, or stream interrupted.");
    }
    if (!Update.end()){
      dln(otaDBG, Update.getError());
    }
  
    http.end();
    dln(otaDBG, "ESP32 Restarting - FW Update Complete");
    ESP.restart();
  }

}

// OTA over-the-air update stuff ///////////////////////////////////////////
void doOTAUpdateSecure() {             // the main OTA logic
  // Host URL of bin location
  const char* baseUrl = "raw.githubusercontent.com";
  // Port for SSL connection.
  const int  httpsPort = 443;
  // URI at which binfile can be found.
  const char* url_i = "/a-chapman/TestOTABinaries/master/";

  // Boolean controls whether update is needed
  bool updateNeeded = true;

  // Manage the HTTP Request process
  HTTPClient https;

  // Stores respose code returned by httpclient
  int respCode;

  // Stores latest firmware version on server
  int highestAvailableVersion = -1;

  // Do a GET to read the version file from the cloud
  dln(otaDBG, "Checking for new FW...");

  // Get secure response from server
  versionResponse response = getLatestVersion(true);

  /* If the response is HTTP OK. Read version file from stream. Otherwise print
     error getting version. */
  if(response.responseCode == HTTP_CODE_OK){
    highestAvailableVersion = response.latestVersion;
  } else{
    updateNeeded = false;
    Serial.printf("Couldn't get version! HTTP rtn code: %d\n", respCode);
  }

  // Free up resources. Payload handled.
  https.end();

  // Check whether the fetched version is higher than current FW version.
  if(currentVersion >= highestAvailableVersion) {
    dln(otaDBG, "FW version is already up to date");
    updateNeeded = false;
  }

  // If the above checks have been passed and an update is available. Continue.
  if (updateNeeded){
    dbg(otaDBG, "Constructing Filepath: ");
    // Construct filepath of latest bin file.
    String filepath = String(highestAvailableVersion) + ".bin";
    dln(otaDBG, filepath.c_str());

    // WiFiClientSecure used to initiate a secure conntection to HTTPS server.
    WiFiClientSecure client;
    // WifiClient stores stream object. Packets still transmitted over HTTPS.
    WiFiClient* stream;

    // Sets the certificate that the WiFiClient should expect @ server.
    client.setCACert(root_ca);
    dln(otaDBG, "TLS Certificate Set");

    // Check that a connection to host can be established
    if (!client.connect(baseUrl, 443)){
      dln(otaDBG, "Secure Connection Could not be established");
    } else{
      dln(otaDBG, "Secure Connection established");
    }

    // Connect to the server and check Root CA certificate matches (inititing SSL)
    respCode = doCloudGetSecure(&https, String(baseUrl), httpsPort, String(url_i), filepath);

    // Get the size of the file on server.
    int len = https.getSize();

    // If the response code is positive, begin OTA update.
    if (respCode == 200){
      // Get stream pointer
      stream = https.getStreamPtr();
      // Check that enough space is available to perform the update
      if (!Update.begin(len)){
        dln(otaDBG, "Not enough space for flashing FW image.");
      }
      // Read from the stream to flash memory. Returns true if length of stream doesn't match that from httpget
      if(Update.writeStream(*stream) != len){
        dln(otaDBG, "FW flash error, or stream interrupted.");
      }
      // If all bytes have been written to flash, or an update has unexpectedly halted, this will return false.
      if (!Update.end()){
        dln(otaDBG, Update.getError());
      }

      // Save resources. Close https
      https.end();
      dln(otaDBG, "ESP32 Restarting - FW Update Complete");
      // Restart the esp. Eboot has been written to overwrite old sketch on next boot.
      ESP.restart();
    } else {
      dln(otaDBG, "FW Update Could Not Be Reached");
    }
  } else {
    dln(otaDBG, "Update may not be required");
  }
}

// Update Checkers ////////////////////////////////////////////////////////// DONE
// Checks for an update using version file and returns structure containing the response code and version (if connection established).
versionResponse getLatestVersion(bool useHTTPS){
  versionResponse thisResponse;

  // Manage the HTTP Request process
  HTTPClient http;

  // Do a GET to read the version file from the cloud
  dln(cloudDBG, "Getting version from server");
  if (useHTTPS == true){
    dln(cloudDBG, "Using HTTPS");
    // Host URL of bin location
    const char* baseUrl = "raw.githubusercontent.com";
    // Port for SSL connection.
    const int  httpsPort = 443;
    // URI at which binfile can be found.
    const char* url_i = "/a-chapman/TestOTABinaries/master/";
    thisResponse.responseCode = doCloudGetSecure(&http, String(baseUrl), httpsPort, url_i,"version");
  } else{
    thisResponse.responseCode = doCloudGet(&http, gitID, "version");
  }

  // Default latest version is 0
  thisResponse.latestVersion = 0;

  /* If the response is HTTP OK. Read version file from stream. Otherwise print
     error getting version. */
  if(thisResponse.responseCode == 200){
    dln(cloudDBG, "RESPONSE FROM SERVER OK");
    thisResponse.latestVersion = atoi(http.getString().c_str());

    dln(cloudDBG, "RESPONSE RETURNED");
    dbg(cloudDBG, "LATEST = V.");
    dln(cloudDBG, thisResponse.latestVersion);
  }

  // Free up resources. Payload handled.
  http.end();
  // Return response.
  return thisResponse;
}

// Cloud Get Utilities (HTTP and HTTPS) ///////////////////////////////////////////////////////// DONE
// helper for downloading from cloud firmware server via HTTPS GET
int doCloudGetSecure(HTTPClient *https, String host, uint16_t port, String url, String fileName){
  // Build URL
  String final_url = "https://" + host + url + fileName;
  // Make GET Request
  https->begin(final_url, root_ca);
  // Return response code.
  return https->GET();
}

// helper for downloading from cloud firmware server via HTTP GET
int doCloudGet(HTTPClient *http, String gitID, String fileName) {
  // build up URL from components; for example:
  // http://com3505.gate.ac.uk/repos/com3505-labs-2018-adalovelace/BinFiles/2.bin
  String baseUrl =
    "http://com3505.gate.ac.uk/repos/";
  String url =
    baseUrl + "com3505-labs-2018-" + gitID + "/BinFiles/" + fileName;
  // make GET request and return the response code
  http->begin(url);
  http->addHeader("User-Agent", "ESP32");
  return http->GET();
}


// Access Point / WiFi Utilities ////////////////////////////////////////////////////////// DONE
void startNetwork(){
  dln(networkDBG, "Setting up network...");
  dbg(networkDBG, "Connecting To Network: ");
  dln(networkDBG, netSSID);

  // Device will act as both a station and an access point. 
  WiFi.mode(WIFI_AP_STA);
  // Create AP with SSID myOTAThing and pwd "defaultpassword"
  WiFi.softAP(softAPSSID.c_str(), softAPPassword.c_str());
  dln(networkDBG, "Started softAP...");
  // Join UoS Other/Default Network
  WiFi.begin(netSSID.c_str(), netPassword.c_str());
  dln(networkDBG, "Joining a network");
  //WiFi.begin("uos-other", "shefotherkey05");
  // Wait ten seconds for a connection
  int result = WiFi.waitForConnectResult();
  if (result != WL_CONNECTED){
    dln(networkDBG, "No Connection Made");
  }
  // Print Network Status to Serial
  dln(networkDBG, networkStatusToString());

  // Print IP to Serial.
  dln(networkDBG, WiFi.localIP());
}

// Converts network status constants to representative strings.
String networkStatusToString(){
  switch (WiFi.status()){
    case WL_IDLE_STATUS:
      return "Adapter Idle";
    case WL_NO_SSID_AVAIL:
      return "No SSID Available";
    case WL_CONNECTED:  
      return "Connected";
    case WL_CONNECT_FAILED:
      return "Connection Failed";
    case WL_SCAN_COMPLETED:
      return "Scan Finished";
    case WL_CONNECTION_LOST:
      return "Connection Lost";
    case WL_DISCONNECTED:
      return "Disconnected";
    default:
      return "Unrecognised Status";
  }
}

// This function registers page handlers for uris @ the access point. DONE
void startWebServer(){
  dln(serverDBG, "Beginning Web Server...");

  // Register GET. These are pages to be served.
  server.on("/", handleRoot);
  server.on("/netstat", handleNetStat);
  server.on("/netselect", handleNetSelect);
  server.on("/fwupdate", handleFWUpdate);
  
  // Register POSTs. These are used when a form is sent.
  server.on("/wifiupdate", handlewifiupdate);
  server.on("/wifidisconnect", handlewifidisconnect);
  server.on("/postsecureupdate", doOTAUpdateSecure);
  server.on("/postunsecureupdate", doOTAUpdate);
  server.on("/wifichangepwd", handleWiFiPasswordChange);
  server.onNotFound(handleNotFound);

  // Begin Web Server
  server.begin();
}



// POST Handlers ////////////////////////////////////////////////////// DONE

// When form with new WiFi details is posted, this connects the IoT device to the chosen network. DONE
void handlewifiupdate(){
  String ssid = "";
  String key = "";
  for(uint8_t i = 0; i < server.args(); i++ ) {
    if(server.argName(i) == "ssid")
      ssid = server.arg(i);
    else if(server.argName(i) == "key")
      key = server.arg(i);
  }
  dln(serverDBG, "Stored Details Are Now: ");
  dln(serverDBG, ssid);
  dln(serverDBG, key);
  if(netSSID != ""){
    dln(serverDBG, "Connecting To New Network");
    
    netSSID = ssid;
    netPassword = key;
    
    char ssidchars[netSSID.length()+1];
    char keychars[netPassword.length()+1];
    netSSID.toCharArray(ssidchars, netSSID.length()+1);
    netPassword.toCharArray(keychars, netPassword.length()+1);
    WiFi.begin(ssidchars, keychars);
    int result = WiFi.waitForConnectResult();
    if (result != WL_CONNECTED){
      dln(networkDBG, "No Connection Made");
    }
    // Print Network Status to Serial
    dln(networkDBG, networkStatusToString());
  }
  

  
  dln(serverDBG, "Requester Redirected");
  // Redirect user to main menu
  delay(1000);
  server.sendHeader("Location", String("/"), true);
  server.send ( 302, "text/plain", "");
}

// Function which disconnects the station from chosen AP. DONE
void handlewifidisconnect(){
  dln(networkDBG, "Disconnecting from WiFi");
  // Forget credentials
  netSSID = "";
  netPassword = "";
  // Disconnects from the wifi
  WiFi.disconnect();
  // Delays so this operation has ample time to complete.
  delay(1000);
  dln(serverDBG, "Requester Redirected");
  // Redirects user back to the homepage.
  server.sendHeader("Location", String("/"), true);
  server.send ( 302, "text/plain", "");
}

// Handler for when user changes the password for softAP.DONE
void handleWiFiPasswordChange(){
  // Get new password from POST args.
  for(uint8_t i = 0; i < server.args(); i++ ) {
    if(server.argName(i) == "password"){
      softAPPassword = server.arg(i);
    }
  }

  // Redirect user to main menu
  server.sendHeader("Location", String("/"), true);
  server.send ( 302, "text/plain", "");
  delay(1000);
  
  // Restart ESP32 network capabilities
  dln(networkDBG, "Restarting Network With New Credentials");   
  startNetwork();
}


// GET Page Builders ///////////////////////////////////////////////////// DONE

// Writes a webpage when user navigates to '/'
void handleRoot(){
  dln(serverDBG, "Serving ESP32 Menu");
  // Top Down Definition of DOM
  CPP_PageNode* root_node = new CPP_PageNode("<html>", false) ;
  CPP_PageNode* head_node = new CPP_PageNode("<head>", false, root_node);
  CPP_PageNode* body_node = new CPP_PageNode("<body>", false, root_node);
  CPP_PageNode* heading_node = new CPP_PageNode("<h1>", false, body_node);
  CPP_PageNode* heading_text_node = new CPP_PageNode("ESP32 Menu:", true, heading_node);
  CPP_PageNode* ul_options_node = new CPP_PageNode("<ul>", false, body_node);
  // Write options menu depending on connection status.
  CPP_PageNode* li_netstat = new CPP_PageNode("<li>", false, ul_options_node);
  CPP_PageNode* li_netstat_anchor = new CPP_PageNode("<a href = '/netstat'>Network  Status</a>", true, li_netstat);
  CPP_PageNode* li_fwupdate = new CPP_PageNode("<li>", false, ul_options_node);
  CPP_PageNode* li_fwupdate_anchor = new CPP_PageNode("<a href = '/fwupdate'>OTA Update</a>", true, li_fwupdate);
  CPP_PageNode* li_netselect = new CPP_PageNode("<li>", false, ul_options_node);
  CPP_PageNode* li_netselect_anchor = new CPP_PageNode("<a href = '/netselect'> Select Network </a>", true, li_netselect);

  // Assemble the page to a char[] and send to the requester.
  std::string DOM_str = root_node->draw_me_and_my_child();
  char cstr[DOM_str.size()+1];
  std::copy(DOM_str.begin(), DOM_str.end(), cstr);
  cstr[DOM_str.size()] = '\0';

  server.send(200, "text/html", cstr);
  root_node -> dissassemble();
}

// Writes a webpage when user navigates to '/netstat'
void handleNetStat(){
  dln(serverDBG, "Serving Network Stats");

  // Define DOM of a webpage showing network statistics. 
  CPP_PageNode* root_node = new CPP_PageNode("<html>", false) ;
  CPP_PageNode* head_node = new CPP_PageNode("<head>", false, root_node);
  CPP_PageNode* body_node = new CPP_PageNode("<body>", false, root_node);
  String connectStatus = "<p>" + networkStatusToString() + "</p>";
  CPP_PageNode* connection_status_node = new CPP_PageNode(connectStatus.c_str(), true, body_node);

  // Table showing ssid and rssi of the network
  CPP_PageNode* netstat_table = new CPP_PageNode("<table>", false, body_node);
  CPP_PageNode* ssid_row = new CPP_PageNode("<tr>", false, netstat_table);
  CPP_PageNode* ssid_row_data_0 = new CPP_PageNode("<td> SSID </td>", true, ssid_row);
  CPP_PageNode* ssid_row_data_1 = new CPP_PageNode("<td>", false, ssid_row);
  CPP_PageNode* ssid_row_data_1_txt = new CPP_PageNode("None", true, ssid_row_data_1);
  CPP_PageNode* rssi_row = new CPP_PageNode("<tr>", false, netstat_table);
  CPP_PageNode* rssi_row_data_0 = new CPP_PageNode("<td> RSSI </td>", true, rssi_row);
  CPP_PageNode* rssi_row_data_1 = new CPP_PageNode("<td>", false, rssi_row);
  CPP_PageNode* rssi_row_data_1_txt = new CPP_PageNode("None", true, rssi_row_data_1);
  CPP_PageNode* disconnect_row = new CPP_PageNode("<tr><td colspan='2'><form method='POST' action='wifidisconnect'><input type='submit' value='Disconnect'></form></td></tr>",true, netstat_table);

  // Set table data if connected to a network.
  if (WiFi.status() == WL_CONNECTED){
    ssid_row_data_1_txt->set_tag(WiFi.SSID().c_str()); 
    char rssi_to_cha[4];
    ltoa(WiFi.RSSI(), rssi_to_cha, 10);
    rssi_row_data_1_txt->set_tag(rssi_to_cha); 
  }

  // Define a form which lets the user change the password of the softAP.        
  CPP_PageNode* password_change_node = new CPP_PageNode("<div>", false, body_node);
  CPP_PageNode* password_change_header = new CPP_PageNode("<h2> Change AP Password </h2>", true, password_change_node);
  CPP_PageNode* password_change_warning = new CPP_PageNode("<p> After changing this, remember to forget the network and enter new AP password on your device.</p>", true, password_change_node);
  CPP_PageNode* password_change_form = new CPP_PageNode("<form method='POST' action='wifichangepwd'><br/>New Password: <input type='textarea' name='password'> <input type='submit' value='Change Password'></form>", true, password_change_node);
  
  // Assemble the page to a char[] and send to the requester.
  std::string DOM_str = root_node->draw_me_and_my_child();
  char cstr[DOM_str.size()+1];
  std::copy(DOM_str.begin(), DOM_str.end(), cstr);
  cstr[DOM_str.size()] = '\0';

  server.send(200, "text/html", cstr);
  root_node -> dissassemble();

}

// Writes a webpage when user navigates to '/netselect'
void handleNetSelect(){
  dln(serverDBG, "Serving Network List");

  // Define page DOM
  CPP_PageNode* root_node = new CPP_PageNode("<html>", false) ;
  CPP_PageNode* head_node = new CPP_PageNode("<head>", false, root_node);
  CPP_PageNode* body_node = new CPP_PageNode("<body>", false, root_node);
  CPP_PageNode* heading_node = new CPP_PageNode("<h1>", false, body_node);
  CPP_PageNode* heading_text_node = new CPP_PageNode("WiFi Networks:", true, heading_node);
  if (WiFi.status() == WL_CONNECTED){
    CPP_PageNode* connected_aleady_node = new CPP_PageNode("CONNECTED", true, body_node);
  }

  // Define a table of networks to be written to the page.
  CPP_PageNode* SSID_form_node = new CPP_PageNode("<form method='POST' action='wifiupdate'>", false, body_node);
  CPP_PageNode* table_node = new CPP_PageNode("<table>", false, SSID_form_node);
  CPP_PageNode* table_row_header_node = new CPP_PageNode("<tr>", false, table_node);
  CPP_PageNode* table_header_0_node = new CPP_PageNode("<th> " " </th>", true, table_row_header_node);
  CPP_PageNode* table_header_1_node = new CPP_PageNode("<th> # </th>", true, table_row_header_node);
  CPP_PageNode* table_header_2_node = new CPP_PageNode("<th> SSID </th>", true, table_row_header_node);
  CPP_PageNode* table_header_3_node = new CPP_PageNode("<th> RSSI </th>", true, table_row_header_node);

  // Get available networds.
  int num_networks = WiFi.scanNetworks();

  // Create a row in table for each available network.
  for (int i = 0; i < num_networks; i++ ){
    char int_to_cha[3];
    itoa(i, int_to_cha, 10);

    char rssi_to_cha[4];
    ltoa(WiFi.RSSI(i), rssi_to_cha, 10);

    String radialbttn = "<td><input type='radio' name='ssid' value='" + WiFi.SSID(i) + "' ></td>";
    // Also print to table
    CPP_PageNode* table_row_data_node = new CPP_PageNode("<tr>", false, table_node);
    CPP_PageNode* table_data_node_formopt = new CPP_PageNode(radialbttn.c_str(), true, table_row_data_node);
    CPP_PageNode* table_data_node_num = new CPP_PageNode("<td>", false, table_row_data_node);
    CPP_PageNode* table_data_node_num_d = new CPP_PageNode(int_to_cha, true, table_data_node_num);
    CPP_PageNode* table_data_node_SSID = new CPP_PageNode("<td>", false, table_row_data_node);
    CPP_PageNode* table_data_node_SSID_d = new CPP_PageNode(WiFi.SSID(i).c_str(), true, table_data_node_SSID);
    CPP_PageNode* table_data_node_RSSI =new CPP_PageNode("<td>", false, table_row_data_node);
    CPP_PageNode* table_data_node_RSSI_d = new CPP_PageNode(rssi_to_cha, true, table_data_node_RSSI);
  }

  // Add rows to let user self define SSID and Key
  //CPP_PageNode* table_other_row_node =new CPP_PageNode("<tr><td><input type='radio' name='ssid' value='other'></td><td>Other:</td><td><input type='textarea' name='other-ssid'></td><tr>", true, table_node);
  CPP_PageNode* password_node =new CPP_PageNode("<br/>Pass key: <input type='textarea' name='key'><br/><br/>", true, SSID_form_node);
  // Button submits form to change network credentials.
  CPP_PageNode* submit_node =new CPP_PageNode("<input type='submit' value='Submit'>", true, SSID_form_node);
  
  // Assemble the page to a char[] and send to the requester.
  std::string DOM_str = root_node->draw_me_and_my_child();
  char cstr[DOM_str.size()+1];
  std::copy(DOM_str.begin(), DOM_str.end(), cstr);
  cstr[DOM_str.size()] = '\0';

  server.send(200, "text/html", cstr);
  root_node-> dissassemble();
}

// Writes a webpage when user navigates to '/fwupdate'
void handleFWUpdate(){
  dln(serverDBG, "Serving OTA Page");

  // Get latest version/response code from HTTPS and HTTP sources.
  versionResponse secureResponse;
  secureResponse = getLatestVersion(true);

  versionResponse unsecureResponse;
  unsecureResponse = getLatestVersion(false);

  // Define page DOM
  CPP_PageNode* root_node = new CPP_PageNode("<html>", false) ;
  CPP_PageNode* head_node = new CPP_PageNode("<head>", false, root_node);
  CPP_PageNode* body_node = new CPP_PageNode("<body>", false, root_node);
  CPP_PageNode* heading_node = new CPP_PageNode("<h1>", false, body_node);
  CPP_PageNode* heading_text_node = new CPP_PageNode("Update Menu: ", true, heading_node);
  CPP_PageNode* current_ver_node = new CPP_PageNode("<p>", false, body_node);
  String versionmsg = "Current Version: " + String(currentVersion);
  CPP_PageNode* current_ver_data_node = new CPP_PageNode(versionmsg.c_str(), true, current_ver_node);
  CPP_PageNode* latest_ver_s_node = new CPP_PageNode("<p>", false, body_node);
  CPP_PageNode* latest_ver_s_data_node = new CPP_PageNode("", true, latest_ver_s_node);

  // If the response is OK print the version returned from the server and decide whether the print message telling user to update.
  if (secureResponse.responseCode == 200){ 
    if (secureResponse.latestVersion > currentVersion){
      String msg = "Latest Version (Secure Server): " + String(secureResponse.latestVersion);
      latest_ver_s_data_node->set_tag(msg.c_str());
      CPP_PageNode* install_latest_secure_node = new CPP_PageNode("<form method='POST' action='postsecureupdate'><input type='submit' value='Update Now'></form>", true, body_node); 
    } 
    else{
      latest_ver_s_data_node->set_tag("You are already on the latest version HTTPS");
    }
  }
  else{
    latest_ver_s_data_node->set_tag("Could not retrive latest version from HTTPS server.");
  }

  // More DOM definition. 
  CPP_PageNode* latest_ver_u_node = new CPP_PageNode("<p>", false, body_node);
  CPP_PageNode* latest_ver_u_data_node = new CPP_PageNode("", true, latest_ver_u_node);
  
  // As above. This time for the unsecure server
  if (unsecureResponse.responseCode == 200){ 
    if (unsecureResponse.latestVersion > currentVersion) {
      String msg = "Latest Version (HTTP Server): " + String(unsecureResponse.latestVersion);
      latest_ver_u_data_node->set_tag(msg.c_str());
      CPP_PageNode* install_latest_unsecure_node = new CPP_PageNode("<form method='POST' action='postunsecureupdate'><input type='submit' value='Update Now'></form>", true, body_node);
    }
    else{
      latest_ver_u_data_node->set_tag("You are already on the latest version HTTP");
    }
  }
  else{
    latest_ver_s_data_node->set_tag("Could not retrive latest version from HTTP server.");
  }

  // Assemble the page to a char[] and send to the requester.
  std::string DOM_str = root_node->draw_me_and_my_child();
  char cstr[DOM_str.size()+1];
  std::copy(DOM_str.begin(), DOM_str.end(), cstr);
  cstr[DOM_str.size()] = '\0';

  server.send(200, "text/html", cstr);
  root_node -> dissassemble();
}

// Show this page when the URL isnt found. 
void handleNotFound(){
  dln(serverDBG, "Serving OTA Page");  
}

// misc utilities //////////////////////////////////////////////////////////
// get the ESP's MAC address
void getMAC(char *buf) { // the MAC is 6 bytes, so needs careful conversion...
  uint64_t mac = ESP.getEfuseMac(); // ...to string (high 2, low 4):
  char rev[13];
  sprintf(rev, "%04X%08X", (uint16_t) (mac >> 32), (uint32_t) mac);

  // the byte order in the ESP has to be reversed relative to normal Arduino
  for(int i=0, j=11; i<=10; i+=2, j-=2) {
    buf[i] = rev[j - 1];
    buf[i + 1] = rev[j];
  }
  buf[12] = '\0';
}

// LED blinkers
void ledOn()  { digitalWrite(BUILTIN_LED, HIGH); }
void ledOff() { digitalWrite(BUILTIN_LED, LOW); }
void blink(int times, int pause) {
  ledOff();
  for(int i=0; i<times; i++) {
    ledOn(); delay(pause); ledOff(); delay(pause);
  }
}

// utility for printing IP addresses
String ip2str(IPAddress address) {
  return
    String(address[0]) + "." + String(address[1]) + "." +
    String(address[2]) + "." + String(address[3]);
}


