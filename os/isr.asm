; INTERRUPT SERVICE ROUTINES
; Handlers for maskable and non-maskable interrupts.

; Interrupt flags (enum)
INT_FLAG_NONE	= $00
INT_FLAG_SECOND	= $01
INT_FLAG_INPUT	= $02

!zone	isr_nmi
; Interrupt service routine handler for non-maskable interrupts.
; INPUT:	None
; OUTPUT:	None
;		A, C = Kept
isr_nmi
	pha
	php

	lda	INT_FLAG		; Check if incrementing current time
	and	#INT_FLAG_SECOND
	beq	.no_second

	jsr	time_increment		; Increment current time by 1 second

.no_second
	lda	INT_FLAG		; Check if input has changed
	and	#INT_FLAG_INPUT
	beq	.no_input_change

	lda	CLOCK			; Store time at which input changed in a
	sta	CLOCK_INPUT_CHG		; variable so that button press duration
	lda	CLOCK + 1		; can be evaluated
	sta	CLOCK_INPUT_CHG + 1

.no_input_change
	stz	INT_FLAG		; Clear interrupt flags

	plp
	pla
	rti