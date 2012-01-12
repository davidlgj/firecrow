#include <WProgram.h>
#include <common.h>

void error(int code) {
  //first signal error
  flash(DEBUG_LED,2000);
  delay(500);
  for (int i=0; i<code; i++) {
       flash(DEBUG_LED,500);
       delay(500);
  }
  delay(5000);
}


void inUp(int pin) {
  pinMode(pin,INPUT);
  digitalWrite(pin,HIGH); //enable internal pull-up

}


void flash(int pin,int ms) {
  digitalWrite(pin,HIGH);
  delay(ms);
  digitalWrite(pin,LOW);
}

