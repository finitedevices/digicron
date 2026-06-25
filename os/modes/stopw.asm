; STOPWATCH MODE
; Used for measuring time durations.

STOPW_INFO
	!raw	"STOPWTCH"		; MODE_I_NAME
	!word	$0000			; MODE_I_AUTHOR
	!word	$0100			; MODE_I_VERSION
	!word	stopw_main		; MODE_I_REF

!zone	stopw_main
; Entry point for the stopwatch mode.
; INPUT:	None
; OUTPUT:	Not a subroutine
stopw_main
	lda	#.STR & $FF
	sta	GP0
	lda	#.STR >> 8
	sta	GP0 + 1

	jsr	gfx_dispstr

	ldx	#0
	ldy	#2
	jsr	gfx_movefont

	jsr	time_eval100

	lda	CT_TIME_TICK
	lsr
	lsr
	lsr
	lsr
	clc
	adc	#'0' | $80
	ldx	#6
	jsr	gfx_dispchar

	lda	CT_TIME_TICK
	and	#$0F
	adc	#'0' | $80
	ldx	#7
	jsr	gfx_dispchar

	jsr	gfx_resetfont

	jsr	input_getkey

	bra	stopw_main

.STR
	!raw	"12'34\"", 0