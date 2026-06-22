#ifdef DC_SIMULATOR
    #include <emscripten.h>
    #include <emscripten/bind.h>
#endif

#include "input.h"
#include "proc.h"

char input::value = 0;

#ifdef DC_SIMULATOR
    void set(char value) {
        bool value_changed = input::value != value;

        input::value = value;

        if (value_changed) {
            proc::interrupt_flag |= proc::INPUT_CHANGE;

            proc::trigger_interrupt();
        }
    }

    EMSCRIPTEN_BINDINGS(dc_input) {
        emscripten::function("input_set", set);
    }
#endif