#include <Arduino.h>

#ifndef DC_SIMULATOR
    #include "Adafruit_TinyUSB.h"
#else
    #include <emscripten.h>
#endif

#include "display.h"
#include "input.h"
#include "proc.h"

void setup() {
    display::init();
    input::init();
    proc::init();
}

void loop() {
    input::poll();
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