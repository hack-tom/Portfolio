#ifndef MyOTA_DEF
  #define MyOTA_DEF
  #define dbg(b, s) if(b) Serial.print(s)
  #define dln(b, s) if(b) Serial.println(s)
  #define startupDBG      true
  #define loopDBG         true
  #define networkDBG      true
  #define cloudDBG        true
  #define otaDBG          true
  #define factoryDBG      true
  #define serverDBG      true
#endif
