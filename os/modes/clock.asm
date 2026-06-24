; CLOCK MODE
; The default home mode, displaying the current time.

CLOCK_INFO
	!raw	"CLOCK", 0, 0, 0	; MODE_I_NAME
	!word	$0000			; MODE_I_AUTHOR
	!word	$0100			; MODE_I_VERSION
	!word	clock_main		; MODE_I_REF

!zone	clock_main
; Entry point for the clock mode.
; INPUT:	None
; OUTPUT:	Not a subroutine
clock_main
	lda	#CT_TIME & $FF
	sta	GP0
	lda	#CT_TIME >> 8
	sta	GP0 + 1

	lda	#STRBUF0 & $FF
	sta	GP1
	lda	#STRBUF0 >> 8
	sta	GP1 + 1

	jsr	time_tostr		; Write current time into string buffer

	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	jsr	gfx_dispstr		; Display current time

	jsr	input_getkey

	jmp	clock_main