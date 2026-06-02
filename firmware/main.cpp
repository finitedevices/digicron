#include <Arduino.h>

#ifdef DC_SIMULATOR
    #include <emscripten.h>
#endif

#include "display.h"
#include "input.h"

void setup() {
    Serial.println("Hello, world!");

    display::init();
}

void loop() {
    char data[40];

    for (unsigned int i = 0; i < 40; i++) {
        data[i] = i % 2 == 0 ? 0xAA : 0x55;
    }

    data[0] = input::value;

    display::render(data);
}

#ifdef DC_SIMULATOR

int main(int argc, char** argv) {
    setup();

    emscripten_set_main_loop(loop, 0, true);

    return 0;
}

#endif