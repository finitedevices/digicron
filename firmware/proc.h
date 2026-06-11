#ifndef PROC_H_
#define PROC_H_

#include <Arduino.h>

#define PROC_CYCLES 256 * 16

namespace proc {
    extern uint8_t ram[0x8000];

    void init();
    void step();
}

#endif