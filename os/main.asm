* = $8000

!source "os/structs.asm"
!source "os/mem.asm"

boot
	ldx	#$FF			; Set stack pointer to start of stack
	txs

	jsr	isr_init		; Initialise all featuers
	jsr	time_init
	jsr	mode_init
	jsr	gfx_resetfont
	jsr	alarm_init
	jsr	stopw_reset
	jsr	timer_init

	cli				; Enable interrupts

	lda	#0			; Set current mode to first (clock)
	jsr	mode_set

!source "os/util.asm"
!source "os/isr.asm"
!source "os/time.asm"
!source "os/input.asm"
!source "os/gfx.asm"
!source "os/mode.asm"
!source "os/modes/clock.asm"
!source "os/modes/alarm.asm"
!source "os/modes/stopw.asm"
!source "os/modes/timer.asm"
!source "os/font.asm"

* = $FFFA
!word	isr_nmi

* = $FFFC
!word	boot