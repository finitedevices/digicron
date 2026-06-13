#include <vrEmu6502.h>

#include "proc.h"
#include "_rom.h"
#include "input.h"

uint8_t proc::ram[0x8000]; // 32 KiB
VrEmu6502* cpu;
uint32_t current_time = 0;
uint32_t last_second_time = 0;

uint8_t ram_read(uint16_t addr, bool is_debug) {
    if (addr & 0x8000) {
        return rom[addr & 0x7FFF];
    }

    if (addr == 0x7F80) {
        return input::value;
    }

    if (addr == 0x7F82) {
        return current_time & 0xFF;
    }

    if (addr == 0x7F83) {
        return current_time >> 8;
    }

    return proc::ram[addr];
}

void ram_write(uint16_t addr, uint8_t data) {
    if (addr & 0x8000) {
        return;
    }

    proc::ram[addr] = data;
}

void proc::init() {
    for (unsigned int i = 0; i < sizeof(ram) / sizeof(uint8_t); i++) {
        ram[i] = 0x00;
    }

    cpu = vrEmu6502New(CPU_W65C02, ram_read, ram_write);
}

void proc::step() {
    vrEmu6502Interrupt* nmi = vrEmu6502Nmi(cpu);

    for (unsigned int i = 0; i < PROC_CYCLES; i++) {
        current_time = millis() / 10;

        if (current_time - last_second_time >= 100) {
            *nmi = IntRequested;
            last_second_time = current_time;
        }

        vrEmu6502Tick(cpu);
    }
}