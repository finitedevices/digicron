#include <Arduino.h>

#ifdef DC_SIMULATOR
    #include <emscripten.h>
#endif

#include "display.h"
#include "input.h"
#include "proc.h"

void setup() {
    display::init();
    proc::init();
}

void loop() {
    proc::step();

    display::render(proc::ram + 0x7F00);
}

#ifdef DC_SIMULATOR

int main(int argc, char** argv) {
    setup();

    emscripten_set_main_loop(loop, 0, true);

    return 0;
}

#endif