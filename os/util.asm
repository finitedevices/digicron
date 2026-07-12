; UTILITY ROUTINES
; Common functionality for use in different operating system features.

!zone	util_frombcd
; Convert the binary coded decimal (BCD) value stored in A into binary.
; INPUT:	A = BCD value to convert
; OUTPUT:	A = Value converted into binary
;		X, GP0 = Kept
util_frombcd
	php
	phx

	cld

	ldx	GP0			; Push GP0 to stack
	phx

	pha				; Push BCD value to stack to copy

	and	#$F0			; Get high nibble
	lsr				; Divide by 2
	sta	GP0			; Store in temporary variable

	lsr				; Divide by 4 (total divided 8)
	lsr
	adc	GP0			; Add BCD value / 2
	sta	GP0			; Store in temporary variable

	pla				; Pop original BCD value
	and	#$0F			; Get low nibble
	adc	GP0			; Add shifted value

	plx				; Pop GP0 from stack
	stx	GP0

	plx
	plp
	rts

!zone	util_tobcd
; Convert the binary value stored in A into binary coded decimal (BCD). Input
; must be between 0 and 100 ($00 and $64); all values 101 to 255 ($65 to $FF)
; will otherwise be shown modulo 100.
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