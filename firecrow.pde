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

#include <common.h>
#include <pyrofyro.h>

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


//prototypes
//main
void setupIdentification();
byte identify();
byte ordering();



//main functions
void setup() {
  Serial1.begin(9600);
  
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
      PyroFyro::pyrofyro(4,channels);
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

