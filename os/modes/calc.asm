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
	stz	GP6			; Use GP6 as count of digits entered

.render
	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	lda	#FP0 & $FF		; Load address of FP0 into GP1
	sta	GP1
	lda	#FP0 >> 8
	sta	GP1 + 1

	jsr	float_copy		; Copy slot X value into FP0

	lda	GP6			; Use digit count as min digits to disp
	jsr	float_disp		; Display current slot X value

.get_key
	jsr	input_getkeypress	; Check currently pressed key

	clc				; Only accept BCD with pressed keys
	jsr	input_keytobcd		; Convert key to BCD if applicable
	bcc	.bcd_valid		; If not numeric, don't do anything

	bra	.get_key

.bcd_valid
	sta	GP1			; Save key value to GP1 LSB

	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	lda	GP6			; If no digits entered yet, then clear
	bne	.digits_entered		; slot X to allow entry of new value

	jsr	float_zero		; Clear slot X (already in GP0)

.digits_entered
	cmp	#7			; Stop entry when display at max digits
	beq	.get_key

	lsr				; Shift to get byte index into mantissa
	clc				; Add byte index to address of slot X
	adc	GP0
	sta	GP0

	lda	GP0 + 1			; Add carried result into MSB
	adc	#0
	sta	GP0 + 1

	lda	GP6			; If current digit count is odd, then
	and	#$01			; insert low digit
	bne	.low_digit		; Otherwise insert high digit

	ldy	#0
	lda	GP1			; Get BCD value
	asl				; Shift low nibble into high nibble
	asl
	asl
	asl
	sta	(GP0),y			; Store into current mantissa byte

	bra	.next_digit

.low_digit
	ldy	#0
	lda	GP1			; Get BCD value
	ora	(GP0),y			; Combine with current digit in slot X
	sta	(GP0),y			; Store into current mantissa byte

.next_digit
	inc	GP6			; Increment digit count

	bra	.render

!zone	calc_ac
; Initialise the calculator stack by clearing all values.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0 = Trashed
calc_ac
	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	ldx	#0			; Use X as stack slot index

.loop
	jsr	float_zero		; Reset current stack slot to zero

	clc

	lda	GP0			; Add float size (8 bytes) to current
	adc	#FLOAT_SIZE		; address to visit next stack slot
	sta	GP0

	lda	GP0 + 1			; Add carried result into MSB
	adc	#0
	sta	GP0 + 1

	inx

	cpx	#4			; Repeat for 4 stack slots
	bcc	.loop

	rts

!zone	calc_dup
; Duplicate the current value in stack slot X into slot Y, pushing further
; values into slots Z and T.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0, GP1 = Trashed
calc_dup
	lda	#CALC_STACK_Z & $FF	; Load address of stack slot Z into GP0
	sta	GP0			; (lower slot)
	lda	#CALC_STACK_Z >> 8
	sta	GP0 + 1

	lda	#CALC_STACK_T & $FF	; Load address of stack slot T into GP1
	sta	GP1			; (upper slot)
	lda	#CALC_STACK_T >> 8
	sta	GP1 + 1

	ldx	#2			; Use X as lower stack slot index (Z)

.loop
	jsr	float_copy		; Copy lower stack slot into upper slot

	sec

	lda	GP0			; Subtract float size (8 bytes) from
	sbc	#FLOAT_SIZE		; current lower slot
	sta	GP0

	lda	GP0 + 1			; Subtract carried result into MSB
	sbc	#0
	sta	GP0 + 1

	sec

	lda	GP1			; Subtract float size (8 bytes) from
	sbc	#FLOAT_SIZE		; current upper slot
	sta	GP1

	lda	GP1 + 1			; Subtract carried result into MSB
	sbc	#0
	sta	GP1 + 1

	dex

	cpx	#0			; Repeat until lower stack slot is 0 (X)
	bne	.loop

	rts

!zone	calc_pop
; Pop the current value in stack slot X, with further values shifting down and
; the value of slot T duplicated into Z.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0, GP1 = Trashed
calc_pop
	lda	#CALC_STACK_Y & $FF	; Load address of stack slot Y into GP0
	sta	GP0			; (upper slot)
	lda	#CALC_STACK_Y >> 8
	sta	GP0 + 1

	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP1
	sta	GP1			; (lower slot)
	lda	#CALC_STACK_X >> 8
	sta	GP1 + 1

	ldx	#1			; Use X as upper stack slot index (Y)

.loop
	jsr	float_copy		; Copy lower stack slot into upper slot

	clc

	lda	GP0			; Add float size (8 bytes) to upper slot
	adc	#FLOAT_SIZE
	sta	GP0

	lda	GP0 + 1			; Add carried result into MSB
	adc	#0
	sta	GP0 + 1

	clc

	lda	GP1			; Add float size (8 bytes) to lower slot
	adc	#FLOAT_SIZE
	sta	GP1

	lda	GP1 + 1			; Add carried result into MSB
	adc	#0
	sta	GP1 + 1

	inx

	cpx	#3			; Repeat until upper stack slot is 3 (T)
	bne	.loop

	rts

!zone	calc_binop
; Populate stack slots Y and X into FP0 and FP1, respectively, with slot X
; popped so that the operand from slot Y is in slot X, which can then be
; overwritten with the result of the operation.
; INPUT:	None
; OUTPUT:	None
;		A, Y, GP0, GP1 = Trashed
calc_binop
	lda	#CALC_STACK_Y & $FF	; Load address of stack slot Y into GP0
	sta	GP0
	lda	#CALC_STACK_Y >> 8
	sta	GP0 + 1

	lda	#FP0 & $FF		; Load address of FP0 into GP1
	sta	GP1
	lda	#FP0 >> 8
	sta	GP1 + 1

	jsr	float_copy		; Copy slot Y value into FP0

	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	lda	#FP1 & $FF		; Load address of FP1 into GP1
	sta	GP1
	lda	#FP1 >> 8
	sta	GP1 + 1

	jsr	float_copy		; Copy slot X value into FP1

	jsr	calc_pop		; Pop current X value

	rts

!zone	calc_fp2tox
; Copy the result of an operation stored in FP2 into stack slot X.
; INPUT:	None
; OUTPUT:	None
;		A, Y, GP0, GP1 = Trashed
calc_fp2tox
	lda	#FP2 & $FF		; Load address of FP2 into GP0
	sta	GP0
	lda	#FP2 >> 8
	sta	GP0 + 1

	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP1
	sta	GP1
	lda	#CALC_STACK_X >> 8
	sta	GP1 + 1

	jsr	float_copy		; Copy FP2 value into slot X

	rts