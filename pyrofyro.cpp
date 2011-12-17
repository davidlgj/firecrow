#include <WProgram.h>
#include <common.h>
#include <pyrofyro.h>


namespace PyroFyro {
    /** 
     * Firmware for pyrofyro. Pyrofyro is a plugin card for firecrow used to fire pyrotechnics.
     */
    void pyrofyro(int nr_of_channels,int pins[]) {
      int c = 0;
      int i;
      int now;
      int state = 1;
      
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
}
