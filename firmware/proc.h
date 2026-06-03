#ifndef PROC_H_
#define PROC_H_

#include <Arduino.h>

namespace proc {
    extern uint8_t ram[0x8000];

    void init();
    void step();
}

#endif