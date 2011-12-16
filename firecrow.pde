//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.

//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.

//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.


/*
 *
 *  fireCrow - multipurpose firmware
 *
 */

#include <XBee.h>
#define BAUDRATE 9600

/*
  The firmware is multipurpose in the sense that the same firmware can be used with different plug-in cards. Without a card it doesn't do anything.
  Which code path it should use is determined by a identification process where 4 pins give a binary code for id. There is also 3 pins that give "oredering", i.e.
  if you have several firecrows we can give them order of firing. There is also two pins, ID-R and ID-OK that are used in the process. ID-R starts the reading when,
  when pulled low reading is finished ID-OK is pulled high.
*/

#define IDR 8
#define IDOK 6
#define ID1 4
#define ID2 20
#define ID3 18
#define ID4 17
#define P1 5
#define P2 0
#define P3 19

#define DEBUG_LED 11


//prototypes
//main
void setupIdentification();
void inUp(int pin);
void flash(int pin,int ms);
byte identify();
byte ordering();
void error(int code);
void pyrofyro(int nr_of_channels,int pins[]);

//main functions
void setup() {
  Serial.begin(9600);
  
  //flash debug led
  pinMode(DEBUG_LED,OUTPUT);
  flash(DEBUG_LED,300);
  
}

void loop() {    
  //start id process
  setupIdentification();
  
  //we don't do anything unless we read LOW on IDR
  while (1) {
    for (int i=0;i<9;i++) {
      if (digitalRead(IDR) == LOW) {
          break;
      } 
      delay(100);
    }
    flash(DEBUG_LED,100);
  }
  
  //get the identification
  byte id    = identify();
  byte order = ordering();
   
  switch (id) {
    case 1: {
      //TODO: move declaration somehwere else
      int channels[] = {1,2,3,4}; //FIXME: proper numbers
      pyrofyro(4,channels);
      break;
    }
    case 0:
    default:
      error(1);
      break;
  }
  error(2);
}


/*
 * Sets up identification
 */
void setupIdentification() {
  
  //setup of pins
  //control pins
  inUp(IDR);  
  pinMode(IDOK,OUTPUT);
  
  //id pins
  inUp(ID1);
  inUp(ID2);
  inUp(ID3);
  inUp(ID4);
  
  //ordering
  inUp(P1);
  inUp(P2);
  inUp(P3);

}

//sets pinmode to input and enables internal pull-up
void inUp(int pin) {
  pinMode(pin,INPUT);
  digitalWrite(pin,HIGH); //enable internal pull-up

}


void flash(int pin,int ms) {
  digitalWrite(pin,HIGH);
  delay(ms);
  digitalWrite(pin,LOW);
}



byte identify() {
  byte id = digitalRead(ID1) == LOW?B00000001:0;
          
  //read pins TODO: DRY this code a bit...
  if (digitalRead(ID2) == LOW) {
    id |= (1<<2);
  }
  if (digitalRead(ID3) == LOW) {
    id |= (1<<3);
  }
  if (digitalRead(ID4) == LOW) {
    id |= (1<<4);
  }

  return id;
} 


byte ordering() {
  byte id = digitalRead(P1) == LOW?B00000001:0;
          
  //read pins TODO: DRY this code a bit...
  if (digitalRead(P2) == LOW) {
    id |= (1<<2);
  }
  if (digitalRead(P3) == LOW) {
    id |= (1<<3);
  }
  return id;
}


void error(int code) {
  //first signal error
  for (int i=0; i<30; i++) {
    flash(DEBUG_LED,10);
    delay(10);
  }
  for (int i=0; i<code; i++) {
       flash(DEBUG_LED,500);
       delay(200);
  }
  delay(2000);
}




//pyrofyro
// start,msb,lsb     } 3 bytes  7E 00 0D
// API id            } 1 byte   90
// 00 padding        } 1 byte   00
// address 64bit     } 8 byte   7D 33 A2 00 40 3A A0 8E
// net address 16bit } 2 byte   00 00
// options           } 1 byte   01
// data              } 1 byte   (for now)
// checksum          } 1 byte

// 7E 00 0D 90 00 7D 33 A2 00 40 3A A0 8E 00 00 01 00 7D 
// 7E 00 0D 90 00 7D 33 A2 00 40 3A A0 8E 00 00 01 01 10 
// 7E 00 0D 90 00 7D 33 A2 00 40 3A A0 8E 00 00 01 02 0F 
// 7E 00 0D 90 00 7D 33 A2 00 40 3A A0 8E 00 00 01 03 0E 
// 7E 00 0D 90 00 7D 33 A2 00 40 3A A0 8E 00 00 01 04 0D
// 7E 00 0D 90 00 7D 33 A2 00 40 3A A0 8E 00 00 01 05 0C 
#define START_BYTE 0x7E
#define API_ID 0x90
#define FIRE_TIME 500

/** 
 * Firmware for pyrofyro. Pyrofyro is a plugin card for firecrow used to fire pyrotechnics.
 */
void pyrofyro(int nr_of_channels,int pins[]) {
  int c = 0;
  int i;
  int now;
  int state = 1;

  struct Channel {
    int pin;
    int time;
  };
  
  Channel channels[nr_of_channels];
  
  //setup channels
  for (i=0; i<nr_of_channels; i++) {
    channels[i].pin = pins[i];
    channels[i].time = -1;
    pinMode(pins[i],OUTPUT);
  }
  
  while (1) {
    if (Serial.available()) {
      switch (state) {
        case 0:
          c = Serial.read();
          if (c == START_BYTE) {
           state++;
          }     
        break;
       
        case 1: //MSB
        case 2: //LSB
          c = Serial.read();
          state++;
        break;
       
        case 3:
          c = Serial.read();
            if (c == API_ID) {
              state++;
            } else { //not a RX packet
             state = 0;
             digitalWrite(DEBUG_LED,HIGH);
             delay(10);
             digitalWrite(DEBUG_LED,LOW);
             delay(10);
             digitalWrite(DEBUG_LED,HIGH);
             delay(10);
             digitalWrite(DEBUG_LED,LOW);
             delay(10);
             digitalWrite(DEBUG_LED,HIGH);
             delay(10);
             digitalWrite(DEBUG_LED,LOW);
           }
        break;
        case 4: // 00
       
        case 5: // address
        case 6:
        case 7:
        case 8:
       
        case 9:
        case 10:
        case 11:
        case 12:
       
        case 13: //net address
        case 14:
       
        case 15: //options
          c = Serial.read();
          if (c != START_BYTE) {
            state++;
          } else {
            state = 1; //we got a start byte, start over one step in
          }    
          break;
        case 16: //our data!
          c = Serial.read();
          if (c >= 0 && c < nr_of_channels) {
            //fire
            channels[c].time = millis();
            digitalWrite(channels[c].pin,HIGH); 
           
          } else if (c == 254) {
            //No-op packet
            digitalWrite(DEBUG_LED,HIGH);
            delay(10);
            digitalWrite(DEBUG_LED,LOW);
          } else {
            //SOMETHING IS WRONG....
            for (int i=0; i<10; i++) {
              digitalWrite(DEBUG_LED,HIGH);
              delay(10);
              digitalWrite(DEBUG_LED,LOW);
              delay(10);
              digitalWrite(DEBUG_LED,HIGH);
              delay(10);
              digitalWrite(DEBUG_LED,LOW);
            } 
          }
          //no break, go to default and start over  
        default:
          state = 0;
      }
    }
  
    //check timing, after FIRE_TIME seconds firing we stop
    now = millis();
    for (int i=0; i<nr_of_channels; i++) {
     
      //if time is not -1 then it's firing!
      if (channels[i].time != -1 && (now - channels[i].time) > FIRE_TIME) {
        digitalWrite(channels[i].pin,LOW);
        channels[i].time = -1;
      }
    }   
  } //end of loop
    
}





//firenest
/*

plan for next version
Hardware wise we have a atmega32u2 on a firecrow and the rest of the hardware
on a extension card to the firecrow.

* six buttons and one led each above the buttons
* an "arm" switch with a heartbeat led
* a rotary switch with at least the following position
**  manual firing
**  manual firing - one switch to cycle trough all channels
**  sequence 200ms gap
**  sequence 500ms gap 
**  sequence 1000ms gap
**  ...
**  recorded sequence
**  record sequence

Manual firing
-------------
For manual firing to work you must arm using the arm switch, the heartbeat led will start blinking and when the firenest has
contact with one or more firecrows the lights above the available channel will light up. To fire, press the dead mans switch
and suitable button. The led will go out to signal shot fired and you can't fire again until all available channels are fired, 
to reset before that change the setting on the rotary switch or turn off/on firenest.


Settings in EEPROM
------------------
* recorded sequence

setup
 * setup usb
 * setup baudrates
 * read settings from eeprom
 * node discovery

main loop
 //start of by checking all state except analog compare and serial
 * check rotary encoder for state
 * check if we're armed
 * check buttons
 
 * Depending on rotary encoder do things
   * check if we've changed position. Do a reset if so
   * otherwise enter function for state
   
   Manual
   * if we're armed and one ore more buttons are pressed and they have ready state ()
     * Fire!
   * Heartbeat (if armed)
     * is it time to send?
     * read serial if anything available 
       * cross check heartbeat response with state
   
   Manual -stepping
   * Same as manual, but other button configuration
       
   Sequence
   * if we haven't started and button i pressed and we're armed
     * fire first and start sequence
   * if we have started
     * check if *any* button is pressed or arming is off
       * abort! stop sequence
     * is it time for next in sequence?
       * fire!
   * heartbeat , if armed. see above
 
 ---- old
 Manual
 * check if we're armed
   * do heartbeat pulse if it's time
   * check if there is anything to read from serial
     * read from serial
     * if it's a respoinse from the heartbeat update leds and armed state
   * check buttons (if it's not already fired)
     * fire if needed! 
 
 Sequence
 * check if we're armed
 * do heartbeat pulse if it's time
   * check if there is anything to read from serial
   * check button 
     * fire sequence
       * check if it's time to fire next
         * fire
         * are we done?
       * check for abort
         * check rotary switch
         * check arm
         * check buttons
   
 

*/






/**
 * fireNest - fireCrow transmitter code
 * 6 buttons for 6 channnels and a led for each
 * First button can also fire all channels in succesion
 * Arduino Fio as board
 */

//#include <NewSoftSerial.h>

#define XBEE_BAUD 9600
#define CHANNELS 6
#define THRESHHOLD 10
#define LED_THRESHHOLD 100
#define ND_WAIT_TIME 3000

struct Channel {
  int button_pin;
  int led_pin;
  int state;
  int time;
};



Channel channels[] = { 
  {2,8,0,0}, 
  {3,9,0,0},
  {4,A3,0,0},
  {5,A0,0,0},
  {6,A1,0,0},
  {7,A2,0,0}
};


//prototypes
void discover();
boolean checkNDResponse();
void flashAll(int ms);
void clearLeds();
void nr(uint8_t nr);
uint32_t pack(uint32_t c1, uint32_t c2, uint32_t c3, uint32_t c4);

//NewSoftSerial mySerial(12, 13);

//used when using first button to fire all channels
uint8_t channel_count = 0;
uint8_t fired_channels = 0;

XBee xbee = XBee();

uint8_t payload[] = { 0 };

// SH + SL Address of receiving XBee
uint32_t sh = 0;
uint32_t sl = 0;

//XBeeAddress64 addr64; //XBeeAddress64(0x0013a200, 0x403141DA);
XBeeAddress64 addr64; //XBeeAddress64(0x0013a200, 0x403141DA);
ZBTxRequest zbTx;
ZBTxStatusResponse txStatus = ZBTxStatusResponse();

//for device discovery
uint8_t atCmd[] = {'N','D'};
AtCommandRequest atRequest = AtCommandRequest(atCmd);
AtCommandResponse atResponse = AtCommandResponse();


void setupold() {
  
  //mySerial.begin(4800);
  //mySerial.println("Hello world");
  
  for (int i= 0; i<CHANNELS; i++) {
    pinMode(channels[i].button_pin,INPUT);
    digitalWrite(channels[i].button_pin,HIGH); //enable internal 20K pullup
    
    pinMode(channels[i].led_pin,OUTPUT);
    //blink leds a bit
    digitalWrite(channels[i].led_pin,HIGH);
    delay(200);
    digitalWrite(channels[i].led_pin,LOW);
  }
  
  //debug led
  //pinMode(13,OUTPUT);
  //digitalWrite(13,HIGH);
  //delay(500);
  //digitalWrite(13,LOW);
  
  xbee.begin(XBEE_BAUD);

  //discover the other XBEE's address
  discover();
  zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
  
  //send a no-op packet so that the xbees can do their magic and find each other
  payload[0] = 254;
  xbee.send(zbTx);
  
  //Flash all leds once so the user knows
  flashAll(500);

  //mySerial.println("Discovered address");
  //mySerial.print("MSB: ");
  //mySerial.println(addr64.getMsb());
  //mySerial.println(addr64.getMsb()==0x0013a200?"Yes!":"NO");
  //mySerial.print("LSB: ");
  //mySerial.println(addr64.getLsb());
  //mySerial.println(addr64.getLsb()==0x403141DA?"Yes!":"NO");
}



//State 0 == not pressed, waiting for press

//State 1 == pressed, debouncing time not up
//Fire on press

//State 2 == pressed, waiting for release 

//State 3 == release, debouncing time not up

void loopold() {
  int val;
  int m;
  
  for (uint8_t i= 0; i<CHANNELS; i++) {
    m = millis();
    
    if (channels[i].state == 0 || channels[i].state == 2) {
      val = digitalRead(channels[i].button_pin);
      
      if (channels[i].state == 0 && val == LOW) {
          //a press!, fire!
          uint8_t cc = i;
          
          //special case, we can fire all channels by firing the first button repeatably
          if (i == 0) {
            cc = channel_count;
            channel_count = (channel_count + 1) % CHANNELS;
          } 
          
          //fire!
          payload[0] = cc;
          xbee.send(zbTx);
          
          //set as fired 
          fired_channels |= (1 << cc);  
          digitalWrite(channels[cc].led_pin,HIGH);  
          
          //check if all is fired
          if (fired_channels == B00111111) {
            //wait a bit
            delay(500);
            
            //reset all
            channel_count = 0;
            fired_channels = 0;
            for (int j = 0; j<CHANNELS; j++) {
              channels[j].state = 0;
              digitalWrite(channels[j].led_pin,LOW);
              delay(300);
            }
            break;
          }
      }
      
      if ((channels[i].state == 0 && val == LOW) || (channels[i].state == 2 && val == HIGH)) {
        channels[i].state = (channels[i].state + 1) % 4; //change state 
        channels[i].time = m;
      }
            
    } else if (m - channels[i].time >  THRESHHOLD) {
      channels[i].state = (channels[i].state + 1) % 4; //change state   
    }
  } 
}


//discover target node
void discover() {
  //mySerial.println("discover");
  //if we don't get a address we can't fire
  while (true) {
    //send node discovery
    xbee.send(atRequest);
    
    //default value is that responding XBEE can wait up to six seconds before answering
    //so spamming it with node discoverys might be a bad thing, but waiting so long is booring so
    //we we'll try it and see if it works...
    
    //knight rider on the diodes let's the users know we're looking
    for (int i=0; i<CHANNELS; i++) {
      clearLeds();
      digitalWrite(channels[i % CHANNELS].led_pin,HIGH);

      if (checkNDResponse()) {
        return;
      }      
    }

    for (int i=CHANNELS-1; i>=0; i--) {
      clearLeds();
      digitalWrite(channels[i % CHANNELS].led_pin,HIGH);

      if (checkNDResponse()) {
        return;
      }      
    }
  }
}

boolean checkNDResponse() { 
  //mySerial.println("checkNDResponse");
  // wait a small bit so the animation looks good
  if (xbee.readPacket(ND_WAIT_TIME / 6)) {
    // got a response!

    // should be an AT command response
    if (xbee.getResponse().getApiId() == AT_COMMAND_RESPONSE) {
      xbee.getResponse().getAtCommandResponse(atResponse);

      if (atResponse.isOk()) {
        if (atResponse.getCommand()[0] == atCmd[0] && atResponse.getCommand()[1] == atCmd[1] && atResponse.getValueLength() > 3) {

          //mySerial.println(pack(atResponse.getValue()[2],atResponse.getValue()[3],atResponse.getValue()[4],atResponse.getValue()[5]));          
          //mySerial.println(pack(atResponse.getValue()[6],atResponse.getValue()[7],atResponse.getValue()[8],atResponse.getValue()[9]));
          
          addr64 = XBeeAddress64( pack(atResponse.getValue()[2],atResponse.getValue()[3],atResponse.getValue()[4],atResponse.getValue()[5]),pack(atResponse.getValue()[6],atResponse.getValue()[7],atResponse.getValue()[8],atResponse.getValue()[9]) );
          
          
          return true;
        }
      } 
      else {
        //nss.print("Command return error code: ");
        //nss.println(atResponse.getStatus(), HEX);
        nr(1);
      }
    } else {
      //nss.print("Expected AT response but got ");
      //nss.print(xbee.getResponse().getApiId(), HEX);
      nr(2);
    }   
  } else {
    // at command failed
    if (xbee.getResponse().isError()) {
      //nss.print("Error reading packet.  Error code: ");  
      //nss.println(xbee.getResponse().getErrorCode());
      nr(3);
    } 
    else {
      //nss.print("No response from radio");  
      nr(4);
    }
  }
  return false;
}

//flash leds once, variable time
void flashAll(int ms) {
  for (int i=0;i<CHANNELS; i++) {
    digitalWrite(channels[i].led_pin,HIGH);
  }
  
  delay(ms);
  clearLeds();  
}

//clear all leds
void clearLeds() {
  for (int i=0;i<CHANNELS; i++) {
    digitalWrite(channels[i].led_pin,LOW);
  }
}

//light up a nr, binary code
void nr(uint8_t nr) {
  //TODO: smarter code...
  if (nr & B00000001) {
    digitalWrite(8,HIGH);
  }
  if (nr & B00000010) {
    digitalWrite(9,HIGH);
  }
  if (nr & B00000100) {
    digitalWrite(A3,HIGH);
  }
  if (nr & B00001000) {
    digitalWrite(A0,HIGH);
  }
  if (nr & B00010000) {
    digitalWrite(A1,HIGH);
  }
  if (nr & B00100000) {
    digitalWrite(A2,HIGH);
  }
}
 
uint32_t pack(uint32_t c1, uint32_t c2, uint32_t c3, uint32_t c4) {
    return (c1 << 24) | (c2 << 16) | (c3 << 8) | (c4);
}
