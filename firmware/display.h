#ifndef DISPLAY_H_
#define DISPLAY_H_

#ifndef DC_SIMULATOR
    #include "HCMS39xx.h"
#endif

#define DATA_PIN A0
#define RS_PIN A1
#define CLOCK_PIN A2
#define ENABLE_PIN A3
#define BLANK_PIN A4

namespace display {
    #ifndef DC_SIMULATOR
        extern HCMS39xx driver;
    #endif

    const unsigned int CHAR_COLUMNS = 5;
    const unsigned int CHAR_ROWS = 7;
    const unsigned int CHARS = 8;
    const unsigned int DATA_SIZE = CHAR_COLUMNS * CHARS;

    void init();
    void render(char data[DATA_SIZE]);
}

#endif