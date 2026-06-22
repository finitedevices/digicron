#ifndef PROC_H_
#define PROC_H_

#include <Arduino.h>

#define PROC_CYCLES 256 * 16

namespace proc {
    enum InterruptFlag {
        NONE            = 0x00,
        SECOND          = 0x01,
        INPUT_CHANGE    = 0x02
    };

    extern uint8_t ram[0x8000];
    extern uint8_t interrupt_flag;

    void init();
    void step();
    inline void trigger_interrupt();
}

#endif