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


namespace PyroFyro {

    struct Channel {
        int pin;
        int time;
    };

    void pyrofyro(int nr_of_channels,int pins[]);
}
