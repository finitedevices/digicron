; UTILITY ROUTINES
; Common functionality for use in different operating system features.

!zone	util_tobcd
; Convert the binary value stored in GP0 into binary coded decimal (BCD).
; INPUT:	A = Binary value to convert
; OUTPUT:	A = Value converted into BCD
;		X, GP0 = Kept
util_tobcd
	php
	phx

	ldx	GP0			; Save current GP0 LSB value
	phx

	sed

	sta	GP0

	lda	#0			; Result accumulator
	ldx	#7			; Bit index

.convert_loop
	lsr	GP0			; Get bit
	bcc	.convert_0		; Don't add if bit not set
	adc	.BCD_TABLE - 1,x	; Add bit value

.convert_0
	dex				; Decrement bit index
	bne	.convert_loop		; Continue if not at last index

	tax				; Store result in X

	pla				; Restore GP0 LSB value
	sta	GP0

	txa				; Store result in A

	cld

	plx
	plp

	rts

.BCD_TABLE
!byte	$63, $31, $15, $07, $03, $01, $00