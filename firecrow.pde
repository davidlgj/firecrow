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
 *  firecrow - mottagare
 *
 */

/*
Flash fuses
$ avrdude -c avrispmkII -P usb -p t4313  -U lfuse:w:0xff:m -U hfuse:w:0xdf:m -U efuse:w:0xff:m

Flash firecrow
$ avrdude -c avrispmkII -P usb -p t4313  -U flash:w:/tmp/build166268485820717316.tmp/firecrow.cpp.hex 

*/

// ATMEL ATTINY2313 (4313)
//
//                  +-\/-+
//            PA2  1|    |29  VCC
// RX   (D 0) PD0  2|    |19  PB7 (D 16)
// TX   (D 1) PD1  3|    |18  PB6 (D 15)
//      (D 2) PA1  4|    |17  PB5 (D 14)
//      (D 3) PA0  5|    |16  PB4 (D 13)
// INT0 (D 4) PD2  6|    |15  PB3 (D 12)
// INT1 (D 5) PD3  7|    |14  PB2 (D 11)
//      (D 6) PD4  8|    |13  PB1 (D 10)
//     *(D 7) PD5  9|    |12  PB0 (D 9)
//            GND 10|    |11  PD6 (D 8)
//                  +----+
//
// * indicates PWM port

// Pinout of firecrow
//       TX
//       PD1 PD2 PD4 PD6 PB1 PB4
//   GND  1   4   6   8   10  13 

//    O   O   O   O   O   O   O   O
//    O   O   O   O   O   O   O   O

//   VCC  0   5   7   9   12  14  15 
//       PD0 PD3 PD5 PB0 PB3 PB5 PB6  
//       RX 


#define XBEE_BAUD 9600
#define FIRE_TIME 500
#define CHANNELS 11
#define CODE 0
#define PIN_NR 1
#define TIME 2
#define DEBUG_LED 11

#define START_BYTE 0x7E
#define API_ID 0x90


struct Channel {
  int pin;
  int time;
};


//pin, time
//Channel channels[] = { 
//  {4,-1},
//  {6,-1},
//  {8,-1},
//  {10,-1},
//  {13,-1},
//  {5,-1},
//  {7,-1},
//  {9,-1},
//  {12,-1},
//  {14,-1},
//  {15,-1}
//};

Channel channels[] = { 
  {5, -1}, //PD3
  {12,-1}, //PB3
  {8, -1},
  {10,-1},
  {13,-1},
  {4, -1},
  {7, -1},
  {9, -1},
  {6, -1},
  {14,-1},
  {15,-1}
};



int c = 0;
int i;
int now;

int state = 1;

void setup() {
  Serial.begin(XBEE_BAUD);
  for (i=0; i<CHANNELS; i++) {
    pinMode(channels[i].pin,OUTPUT);
  }
  //debug
  pinMode(DEBUG_LED,OUTPUT);
  digitalWrite(DEBUG_LED,HIGH);
  delay(500);
  digitalWrite(DEBUG_LED,LOW);
  delay(500);
  digitalWrite(DEBUG_LED,HIGH);
  delay(500);
  digitalWrite(DEBUG_LED,LOW);
}

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

void loop() {
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
       if (c >= 0 && c < CHANNELS) {
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
 for (int i=0; i<CHANNELS; i++) {
 
   //if time is not -1 then it's firing!
   if (channels[i].time != -1 && (now - channels[i].time) > FIRE_TIME) {
     digitalWrite(channels[i].pin,LOW);
     channels[i].time = -1;
   }
 }   
}
