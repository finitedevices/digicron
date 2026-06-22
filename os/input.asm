; USER INPUT
; Routines for reading and processing the state of user input from the keyboard.

; Key value mappings (enum)
KEY_7		= $00
KEY_8		= $01
KEY_9		= $02
KEY_DIV		= $03
KEY_4		= $04
KEY_5		= $05
KEY_6		= $06
KEY_MUL		= $07
KEY_1		= $08
KEY_2		= $09
KEY_3		= $0A
KEY_SUB		= $0B
KEY_0		= $0C
KEY_DOT		= $0D
KEY_EQU		= $0E
KEY_ADD		= $0F

; Key state mappings (enum)
KEY_PRESS	= $10
KEY_HOLD	= $80			; Only available from input routines

!zone	input_getkey
; Get the currently pressed key. This routine may also trigger a mode change if
; KEY_DIV is held.
; INPUT:	None
; OUTPUT:	A = Key status
;		C, X = Kept
input_getkey
	php
	phx

	cld

	lda	INPUT			; Skip button hold check if none pressed
	and	#KEY_PRESS
	beq	.no_key

	sec

	lda	CLOCK			; Calculate button hold-down duration
	sbc	CLOCK_INPUT_CHG
	tax

	lda	CLOCK + 1
	sbc	CLOCK_INPUT_CHG + 1

	bne	.no_hold		; If subtracted MSB = 0, then is hold

	lda	#0			; Clear all bits for later ORA on INPUT

	cpx	#50			; 500 ms
	bcc	.no_hold
	beq	.no_hold

	lda	#KEY_HOLD		; Set bit to signify held key

.no_hold
	plx				; Restore X and state before changing A
	plp				; to ensure Z flag is correctly set

	ora	INPUT

	rts

.no_key
	lda	#0

	plx
	plp
	rts