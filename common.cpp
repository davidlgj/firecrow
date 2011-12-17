#include <WProgram.h>
#include <common.h>

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


void inUp(int pin) {
  pinMode(pin,INPUT);
  digitalWrite(pin,HIGH); //enable internal pull-up

}


void flash(int pin,int ms) {
  digitalWrite(pin,HIGH);
  delay(ms);
  digitalWrite(pin,LOW);
}

