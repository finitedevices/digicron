#include <vrEmu6502.h>

#ifndef DC_SIMULATOR
    #include <NRF52TimerInterrupt.h>
#endif

#include "proc.h"
#include "_rom.h"
#include "input.h"

uint8_t proc::ram[0x8000]; // 32 KiB
uint8_t proc::interrupt_flag = 0;

VrEmu6502* cpu;
uint32_t current_time = 0;
uint32_t updated_time = 0;
uint32_t last_second_time = 0;
bool second_interrupt_fired = false;
uint32_t current_time_offset = 0;
bool current_time_offset_set = false;

#ifndef DC_SIMULATOR
    NRF52Timer ITimer(NRF_TIMER_2);
#endif

void second_interrupt_handler() {
    second_interrupt_fired = true;

    if (!current_time_offset_set) {
        current_time_offset = millis();
        current_time_offset_set = true;
    }
}

uint8_t ram_read(uint16_t addr, bool is_debug) {
    if (addr & 0x8000) {
        return rom[addr & 0x7FFF];
    }

    if (addr == 0x7F80) {
        return proc::interrupt_flag;
    }

    if (addr == 0x7F81) {
        return input::value;
    }

    if (addr == 0x7F82) {
        return (updated_time / 10) & 0xFF;
    }

    if (addr == 0x7F83) {
        return (updated_time / 10) >> 8;
    }

    return proc::ram[addr];
}

void ram_write(uint16_t addr, uint8_t data) {
    if (addr & 0x8000) {
        return;
    }

    if (addr == 0x7F80) {
        proc::interrupt_flag = data;
    }

    if (addr == 0x7F84) {
        /*
            Time memory values only update when update handle increases from 0.

            Code requesting the current time must increment this value prior to
            reading the time, and decrement it after having read the time. Since
            the time values are only updated when incrementing from 0, any ISR
            code that additionally increments the time handle will be unable to
            update the time values while the main routine already has the handle
            set to a nonzero value.

            This prevents the ISR from inadvertently updating the time values
            while the main routine is still reading the values.

            Writing 0x80 to this address will instead reset the phase offset at
            which the ISR is called with the SECOND flag set. This is used to
            allow the current time to be set accurately with the seconds in-sync
            with a reference. The ISR will be called when this is set as a means
            of preventing abuse by an external mode whereby repeated writes mean
            that the ISR is never called.
        */

        if (data == 0x80) {
            last_second_time = current_time;

            #ifndef DC_SIMULATOR
                ITimer.attachInterruptInterval(1000 * 1000, second_interrupt_handler);
            #endif

            proc::trigger_interrupt();

            return;
        }

        if (data && !proc::ram[0x7F84]) {
            updated_time = current_time;
        }
    }

    if (addr == 0x2000) {
        printf("data %02x\n", data); // TODO: Remove
    }

    proc::ram[addr] = data;
}

void proc::init() {
    for (unsigned int i = 0; i < sizeof(ram) / sizeof(uint8_t); i++) {
        ram[i] = 0x00;
    }

    cpu = vrEmu6502New(CPU_W65C02, ram_read, ram_write);
    last_second_time = millis();

    #ifndef DC_SIMULATOR
        ITimer.attachInterruptInterval(1000 * 1000, second_interrupt_handler);
    #endif
}

void proc::step() {
    for (unsigned int i = 0; i < PROC_CYCLES; i++) {
        current_time = millis() - current_time_offset;

        #ifdef DC_SIMULATOR
            if (current_time - last_second_time >= 1000) {
                interrupt_flag |= SECOND;
                last_second_time += 1000;

                trigger_interrupt();
            }

            if (current_time - last_second_time >= 10000) {
                last_second_time = current_time;
            }
        #endif

        if (second_interrupt_fired) {
            interrupt_flag |= SECOND;

            trigger_interrupt();

            second_interrupt_fired = false;
        }

        vrEmu6502Tick(cpu);
    }
}

void proc::trigger_interrupt() {
    vrEmu6502Interrupt* nmi = vrEmu6502Nmi(cpu);

    *nmi = IntRequested;
}