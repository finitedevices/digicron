#include <vrEmu6502.h>

#include "proc.h"
#include "_rom.h"

uint8_t proc::ram[0x8000]; // 32 KiB
VrEmu6502* cpu;

uint8_t ram_read(uint16_t addr, bool is_debug) {
    if (addr & 0x8000) {
        return rom[addr & 0x7FFF];
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
    for (unsigned int i = 0; i < 256; i++) {
        vrEmu6502Tick(cpu);
    }
}