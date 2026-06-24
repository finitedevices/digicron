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
	lda	#.NAME & $FF
	sta	GP0
	lda	#.NAME >> 8
	sta	GP0 + 1

	jsr	gfx_dispstr

.loop
	jsr	input_getkey

	bra	.loop

.NAME
	!raw	"STOPWTCH", 0