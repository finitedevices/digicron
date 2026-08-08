#ifdef DC_SIMULATOR
    #include <emscripten.h>
    #include <emscripten/bind.h>
#endif

#include "input.h"
#include "proc.h"

char input::value = 0;

void input::set(char value) {
    bool value_changed = input::value != value;

    input::value = value;

    if (value_changed) {
        proc::interrupt_flag |= proc::INPUT_CHANGE;

        proc::trigger_interrupt();
    }
}

#ifndef DC_SIMULATOR
    void input::init() {
        pinMode(BUTTON_A_PIN, INPUT_PULLUP);
        pinMode(BUTTON_B_PIN, INPUT_PULLUP);
    }

    void input::poll() {
        char c = Serial.read();
        static long last_press = 0;
        static bool long_press = false;
        static bool long_press_used = false;
        bool button_pressed = true;

        if (c != 0xFF) {
            switch (c) {
                case '7': set(0x10 | 0); break;
                case '8': set(0x10 | 1); break;
                case '9': set(0x10 | 2); break;
                case '/': case 'm': case 'M': set(0x10 | 3); break;
                case '4': set(0x10 | 4); break;
                case '5': set(0x10 | 5); break;
                case '6': set(0x10 | 6); break;
                case '*': case 's': case 'S': set(0x10 | 7); break;
                case '1': set(0x10 | 8); break;
                case '2': set(0x10 | 9); break;
                case '3': set(0x10 | 10); break;
                case '-': set(0x10 | 11); break;
                case '0': set(0x10 | 12); break;
                case '.': set(0x10 | 13); break;
                case '=': case '\r': set(0x10 | 14); break;
                case '+': set(0x10 | 15); break;
                case ' ': long_press = true; long_press_used = false; break;
                default: button_pressed = false; break;
            }
        } else if (!digitalRead(BUTTON_A_PIN)) {
            set(0x10 | 3);
        } else if (!digitalRead(BUTTON_B_PIN)) {
            set(0x10 | 7);
        } else {
            if (millis() - last_press >= (long_press ? 750 : 100)) {
                set(0);

                if (long_press_used) {
                    long_press = false;
                    long_press_used = false;
                }
            }

            button_pressed = false;
        }

        if (button_pressed) {
            last_press = millis();
            long_press_used = true;
        }
    }
#else
    void input::init() {}
    void input::poll() {}

    EMSCRIPTEN_BINDINGS(dc_input) {
        emscripten::function("input_set", input::set);
    }
#endif