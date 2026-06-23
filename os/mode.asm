; MODE MANAGEMENT
; Controls which mode is currently running, and any data associated with the
; current mode.

!zone	mode_init
; Initialise the current mode and switching behaviour.
mode_init
	stz	CT_MODE
	lda	#KEY_DIV_NONE
	sta	KEY_DIV_BEHAV

	rts

!zone	mode_set
; Set the current mode, loading any program code and beginning execution at the
; applicable mode's entry point.
; INPUT:	A = Mode index
; OUTPUT:	Not a subroutine
mode_set
	clc
	cld

	sta	CT_MODE

	ldx	#$FF			; Clear out stack for usage in new mode
	txs

	lda	#KEY_DIV_P_NEXT		; Set default KEY_DIV behaviour to
	sta	KEY_DIV_BEHAV		; switch to next mode when pressed

	jmp	loop			; TODO: Find entry point of mode

!zone	mode_next
; Switch to the next mode by calling mode_set.
; INPUT:	None
; OUTPUT:	Not a subroutine
mode_next
	clc
	cld

	lda	CT_MODE
	adc	#1

	jmp	mode_set