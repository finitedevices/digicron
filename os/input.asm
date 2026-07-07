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

; KEY_DIV behaviours (enum)
; With the exception of KEY_DIV_NONE, all other behaviours will also result in
; going to mode $00 (clock) when KEY_DIV is held
KEY_DIV_NONE	= $00			; Key does not affect mode
KEY_DIV_P_NEXT	= $01			; Pressing key goes to next mode
KEY_DIV_H_HOME	= $02			; Holding key goes to mode $00 (clock)

!zone	input_getkey
; Get the currently pressed key. This routine may also trigger a mode change if
; KEY_DIV is pressed or held (depending on the value of MODE_DIV_BEHAV).
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

	lda	INPUT			; Check if pressed key is KEY_DIV
	cmp	#KEY_PRESS | KEY_DIV
	bne	.no_press_next_mode	; If not, then don't check behaviour

	lda	KEY_DIV_BEHAV		; Check if behaviour is to go to next
	cmp	#KEY_DIV_P_NEXT		; mode
	beq	.test_next_mode		; If so, then test if press or hold

.no_press_next_mode
	sec

	inc	CLOCK_UPDHNDL		; Update current clock value

	lda	CLOCK			; Calculate button hold-down duration
	sbc	CLOCK_INPUT_CHG
	tax

	lda	CLOCK + 1
	sbc	CLOCK_INPUT_CHG + 1

	dec	CLOCK_UPDHNDL

	bne	.is_hold		; If subtracted MSB > 0, then is hold

	lda	#0			; Clear all bits for later ORA on INPUT

	cpx	#50			; If LSB is less than 500 ms
	bcc	.no_hold		; Then is not a hold
	beq	.no_hold

.is_hold
	lda	INPUT			; Check if pressed key is KEY_DIV
	cmp	#KEY_PRESS | KEY_DIV
	bne	.no_hold_home_mode	; If not, then don't check behaviour

	lda	KEY_DIV_BEHAV		; Check if behaviour is to go to mode
	cmp	#KEY_DIV_H_HOME		; $00
	bne	.no_hold_home_mode	; If not, then don't change mode

	lda	#0
	jmp	mode_set

.no_hold_home_mode
	lda	#KEY_HOLD		; Set bit to signify held key

.no_hold
	plx				; Restore X and state before changing A
	plp				; to ensure Z flag is correctly set

	ora	INPUT

	rts

.no_key
	plx
	plp

	lda	#0

	rts

.test_next_mode
	lda	#KEY_DIV_H_HOME		; Prevent recursion by setting behaviour
	sta	KEY_DIV_BEHAV		; to only change mode on KEY_DIV hold

.test_loop
	jsr	input_getkey		; Check current key status
	bne	.test_loop		; Continue until current key is released

	jmp	mode_next		; If key not held, then go to next mode