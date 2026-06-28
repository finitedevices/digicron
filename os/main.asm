* = $8000

!source "os/structs.asm"
!source "os/mem.asm"

boot
	ldx	#$FF
	txs

	jsr	time_init
	jsr	mode_init
	jsr	gfx_resetfont
	jsr	stopw_reset

	lda	#0
	jsr	mode_set

!source "os/util.asm"
!source "os/isr.asm"
!source "os/time.asm"
!source "os/input.asm"
!source "os/gfx.asm"
!source "os/mode.asm"
!source "os/modes/clock.asm"
!source "os/modes/stopw.asm"
!source "os/font.asm"

* = $FFFA
!word	isr_nmi

* = $FFFC
!word	boot