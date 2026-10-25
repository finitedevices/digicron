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
	stz	GP6			; Use GP6 LSB as count of digits entered
	stz	GP6 + 1			; Use GP6 MSB as input states bit field

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

	lda	GP6 + 1			; Get input states bit field
	and	#.STATE_EXP		; Mask to get exponent flag
	bne	.disp_float_exp		; If set then force scientific notation

	lda	GP6			; Use digit count as min digits to disp
	bra	.disp_float

.disp_float_exp
	lda	#-1			; Use special value to force scientific

.disp_float
	jsr	float_disp		; Display current slot X value

.get_key
	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_HOLD | KEY_MUL	; If * held, then enter exponent
	beq	.key_mul_hold_action
	cmp	#KEY_HOLD | KEY_SUB	; If - held, then negate mantissa or exp
	beq	.key_sub_hold_action
	cmp	#KEY_PRESS | KEY_DOT	; If . pressed, then enter decimal point
	beq	.key_dot_action

	clc				; Only accept BCD with pressed keys
	jsr	input_keytobcd		; Convert key to BCD if applicable
	bcc	.bcd_valid		; If not numeric, don't do anything

	lda	GP6 + 1			; Clear negate key still down flag
	and	#!.STATE_NEG_DOWN
	sta	GP6 + 1

	bra	.get_key

.key_mul_hold_action
	jmp	.exponent

.key_sub_hold_action
	jmp	.negate

.key_dot_action
	jmp	.decimal_point

.bcd_valid
	sta	GP1			; Save key value to GP1 LSB

	lda	GP6 + 1			; Get input states bit field
	and	#.STATE_EXP		; Mask to get exponent flag
	bne	.exponent_digit		; If set then enter digit into exponent

	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	lda	GP6			; If no digits entered yet, then clear
	bne	.digits_entered		; slot X to allow entry of new value

	jsr	float_zero		; Clear slot X (already in GP0)

	lda	GP1			; If first digit entered is 0, then
	beq	.render			; don't do anything

	bra	.insert_mantissa

.digits_entered
	lda	GP6			; Get count of digits entered
	cmp	#7			; Stop entry when at max digits
	beq	.get_key		; displayable for mantissa

	lda	GP6 + 1			; Get input states bit field
	and	#.STATE_DP		; Mask to get decimal point flag
	bne	.insert_mantissa	; If not set then increment exponent

	sed				; Increment exponent (BCD) — no need to
	inc	CALC_STACK_X + FLOAT_E	; check overflow since can only reach
	cld				; max digits

.insert_mantissa
	lda	GP6			; Get count of digits entered
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

	jmp	.render

.exponent_digit
	lda	GP6			; Get count of digits entered
	cmp	#(FLOAT_E * 2) + 2	; Stop entry when entered all exponent
	beq	.exponent_digit_stop	; digits

	lda	CALC_STACK_X + FLOAT_E	; Get current exponent value
	asl				; Shift low nibble into high nibble
	asl
	asl
	asl
	ora	GP1			; Combine with BCD value (low nibble)
	sta	CALC_STACK_X + FLOAT_E	; Store back into exponent value

	bra	.next_digit

.exponent_digit_stop
	jmp	.get_key

.decimal_point
	lda	GP6 + 1			; Get input states bit field
	and	#.STATE_DP | .STATE_EXP	; Mask to get decimal and exp flags
	bne	.decimal_point_done	; If either set then no re-entry allowed

	lda	GP6 + 1			; Set decimal point flag
	ora	#.STATE_DP
	sta	GP6 + 1

	lda	GP6			; If no digits entered, then clear slot
	bne	.decimal_point_done	; X

	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	jsr	float_zero		; Clear slot X

	inc	GP6			; Increment digit count so first is 0

.decimal_point_done
	jmp	.get_key

.exponent
	lda	GP6 + 1			; Get input states bit field
	and	#.STATE_EXP		; Mask to get exponent flag
	bne	.exponent_no_reentry	; If set then no re-entry allowed

	lda	GP6			; Get digits entered
	beq	.exponent_no_reentry	; If no digits entered then no exp entry

	lda	GP6 + 1			; Set exponent flag
	ora	#.STATE_EXP
	sta	GP6 + 1

	stz	CALC_STACK_X + FLOAT_E	; Clear exp so new one can be entered

	lda	#FLOAT_E * 2		; Set digit count to exponent offset
	sta	GP6

	jmp	.render

.exponent_no_reentry
	jmp	.get_key

.negate
	lda	GP6 + 1			; Get input states bit field
	and	#.STATE_NEG_DOWN	; Mask to get negate key state
	bne	.negate_no_entry	; If still down then don't do anything

	lda	GP6			; Get digits entered
	beq	.negate_no_entry	; If no digits entered then no negation

	lda	GP6 + 1			; Get input states bit field
	and	#.STATE_EXP		; Mask to get exponent flag
	bne	.negate_exponent	; If set then negate exponent

	lda	CALC_STACK_X + FLOAT_S	; Get float states bit field
	eor	#FLOAT_S_MNEG		; Invert mantissa sign
	sta	CALC_STACK_X + FLOAT_S	; Store back into bit field

	bra	.negate_done

.negate_exponent
	lda	CALC_STACK_X + FLOAT_S	; Get float states bit field
	eor	#FLOAT_S_ENEG		; Invert exponent sign
	sta	CALC_STACK_X + FLOAT_S	; Store back into bit field

.negate_done
	lda	GP6 + 1			; Set negate key still down flag
	ora	#.STATE_NEG_DOWN
	sta	GP6 + 1

	jmp	.render

.negate_no_entry
	jmp	.get_key

; Input states (bit field)
.STATE_DP	= $01			; Set if decimal point has been entered
.STATE_EXP	= $02			; Set if entering exponent
.STATE_NEG_DOWN	= $04			; Set if negate key still down

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