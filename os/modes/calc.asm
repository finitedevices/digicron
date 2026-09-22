; CALCULATOR MODE
; Used for performing arithemetic and scientific calculations.

CALC_INFO
	!raw	"CALC", 0, 0, 0, 0	; MODE_I_NAME
	!word	$0000			; MODE_I_AUTHOR
	!word	$0100			; MODE_I_VERSION
	!word	calc_main		; MODE_I_MAIN
	!word	$0000			; MODE_I_ISR

!zone	calc_main
; Entry point for the Calculator mode.
; INPUT:	None
; OUTPUT:	Not a subroutine
calc_main
	lda	#.test_value & $FF
	sta	GP0
	lda	#.test_value >> 8
	sta	GP0 + 1

	lda	#FP0 & $FF
	sta	GP1
	lda	#FP0 >> 8
	sta	GP1 + 1

	jsr	float_copy

	jsr	float_norm
	jsr	float_disp

.get_key
	jsr	input_getkeypress	; Check currently pressed key

	bra	.get_key

.test_value
	!byte	$12, $34, $56, $00, $00, $00, $02, $00