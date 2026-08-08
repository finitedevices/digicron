#ifndef INPUT_H_
#define INPUT_H_

#define BUTTON_A_PIN 5
#define BUTTON_B_PIN 6

namespace input {
    extern char value;

    void set(char value);
    void init();
    void poll();
}

#endif