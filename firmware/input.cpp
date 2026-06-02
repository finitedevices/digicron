#ifdef DC_SIMULATOR
    #include <emscripten.h>
    #include <emscripten/bind.h>
#endif

#include "input.h"

char input::value = 0;

#ifdef DC_SIMULATOR
    void set(char value) {
        input::value = value;
    }

    EMSCRIPTEN_BINDINGS(dc_input) {
        emscripten::function("input_set", set);
    }
#endif