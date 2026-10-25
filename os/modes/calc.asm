; CALCULATOR MODE
; Used for performing arithemetic and scientific calculations.

CALC_INFO
	!raw	"CALC", 0, 0, 0, 0	; MODE_I_NAME
	!word	$0000			; MODE_I_AUTHOR
	!word	$0100			; MODE_I_VERSION
	!word	calc_main		; MODE_I_MAIN
	!word	$0000			; MODE_I_ISR

; Calculator input states (bit field)
CALC_STATE_DP	= $01			; Set if decimal point has been entered
CALC_STATE_EXP	= $02			; Set if entering exponent
CALC_STATE_DPEX = $03			; Mask for decimal point and exponent
CALC_STATE_KEYD	= $04			; Set if negate key still down
CALC_STATE_RES	= $10			; Set if result shown (dup X on input)

!zone	calc_main
; Entry point for the Calculator mode. This mode will be skipped if stack slot X
; is zero. To enter this mode when stack slot X is zero, use calc_show instead.
; INPUT:	None
; OUTPUT:	Not a subroutine
calc_main
	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	jsr	float_iszero		; If stack slot X value is nonzero
	bcc	.new_input		; Then bring up calculator

	jmp	mode_next		; Otherwise go to next mode

.new_input
	jsr	calc_newinput		; Reset input state

.render
	jsr	calc_dispinput		; Display current input value of slot X

.get_key
	jsr	input_getkeypress	; Check currently pressed key
	cmp	#$00			; If no key
	beq	.get_key		; Then check again

	tax				; Save key value to X
	lda	#KEY_DIV_H_HOME		; Set KEY_DIV behaviour to prevent mode
	sta	KEY_DIV_BEHAV		; change when pressed
	txa				; Restore key value from X

_calc_key
	cmp	#KEY_PRESS | KEY_EQU	; If = pressed, then push slot X into Y
	beq	.push_x
	cmp	#KEY_PRESS | KEY_ADD	; If + pressed, then do addition
	beq	.binop
	cmp	#KEY_PRESS | KEY_SUB	; If - pressed, then do subtraction
	beq	.binop
	cmp	#KEY_PRESS | KEY_MUL	; If * pressed, then do multiplication
	beq	.binop
	cmp	#KEY_PRESS | KEY_DIV	; If / pressed, then do division
	beq	.binop

.input_key
	jsr	calc_inputkey		; Handle value input behaviour
	bcs	.render			; If C set then re-render
	bra	.get_key		; Otherwise get next key

.push_x
	jsr	calc_normx		; Normalise value in slot X
	jsr	calc_dup		; Duplicate and push slot X into Y

	jsr	gfx_clear		; Clear display to indicate action

	lda	#10
	sta	GP0
	stz	GP0 + 1

	jsr	time_wait		; Delay by 10 ticks (0.1 seconds)

	bra	.new_input

.binop
	sta	GP2			; Store pressed key in GP2

	jsr	gfx_clear		; Clear display to indicate busy
	jsr	calc_normx		; Normalise value in slot X
	jsr	calc_binop		; Move slots Y and X into GP0 and GP1

	lda	GP2			; Get pressed key
	cmp	#KEY_PRESS | KEY_ADD	; If + pressed, then do addition
	bne	.check_sub
	jsr	float_add		; Add GP0 and GP1 into GP2
	bra	.binop_done

.check_sub
	cmp	#KEY_PRESS | KEY_SUB	; If - pressed, then do subtraction
	bne	.check_mul
	jsr	float_sub		; Subtract GP1 from GP0 into GP2
	bra	.binop_done

.check_mul
	cmp	#KEY_PRESS | KEY_MUL	; If * pressed, then do multiplication
	bne	.check_div
	jsr	float_mul		; Multiply GP0 by GP1 into GP2
	bra	.binop_done

.check_div
	cmp	#KEY_PRESS | KEY_DIV	; If / pressed, then do division
	bne	.binop_done
	jsr	float_div		; Divide GP0 by GP1 into GP2
	bra	.binop_done

.binop_done
	jsr	calc_fp2tox		; Move GP2 into slot X

	jsr	calc_newinput		; Reset input state

	lda	CALC_STATE		; Set result shown flag
	ora	#CALC_STATE_RES
	sta	CALC_STATE

	jsr	.render

!zone	calc_show
; Show the calculator mode regardless of whether stack slot X is zero or not.
; Before showing the calculator mode, calc_newinput should be called to ensure
; the current slot X value is overwritten on key entry, and calc_ac should be
; called to clear the calculator stack.
; INPUT:	A = Captured key state to pass to calculator (typically $00)
; OUTPUT:	Not a subroutine
calc_show
	pha				; Save key state to stack

	lda	#KEY_DIV_H_HOME		; Set KEY_DIV behaviour to prevent mode
	sta	KEY_DIV_BEHAV		; change when pressed

	jsr	calc_dispinput		; Display current input value of slot X

	pla				; Restore key state
	jmp	_calc_key		; Jump into entry point

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

	ldx	#3			; Use X as upper stack slot index (T)

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

	cpx	#0			; Repeat down to upper stack slot 1 (Y)
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

	cpx	#4			; Repeat up to upper stack slot 3 (T)
	bne	.loop

	rts

!zone	calc_normx
; Normalise the floating-point value in stack slot X.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0, GP1, FP0 = Trashed
calc_normx
	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	lda	#FP0 & $FF		; Load address of FP0 into GP1
	sta	GP1
	lda	#FP0 >> 8
	sta	GP1 + 1

	jsr	float_copy		; Copy slot X value into FP0

	jsr	float_norm		; Normalise the value in FP0

	lda	#FP0 & $FF		; Load address of FP0 into GP0
	sta	GP0
	lda	#FP0 >> 8
	sta	GP0 + 1

	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP1
	sta	GP1
	lda	#CALC_STACK_X >> 8
	sta	GP1 + 1

	jsr	float_copy		; Copy FP0 value into slot X

	rts

!zone	calc_binop
; Populate stack slots Y and X into FP0 and FP1, respectively, with slot X
; popped so that the operand from slot Y is in slot X, which can then be
; overwritten with the result of the operation.
; INPUT:	None
; OUTPUT:	FP0 = Value of stack slot Y
;		FP1 = Value of stack slot X
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

!zone	calc_newinput
; Reset the input state to allow the entry of a new value for stack slot X. This
; subroutine does not clear the value of stack slot X; its value will be cleared
; upon the input of the first key to edit the value.
; INPUT:	None
; OUTPUT:	None
calc_newinput
	stz	CALC_DIGITS		; Set input digit count to 0
	stz	CALC_STATE		; Clear input states bit field

	rts

!zone	calc_dispinput
; Display the current edited value of stack slot X.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0-5, FP0 = Trashed
calc_dispinput
	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	lda	#FP0 & $FF		; Load address of FP0 into GP1
	sta	GP1
	lda	#FP0 >> 8
	sta	GP1 + 1

	jsr	float_copy		; Copy slot X value into FP0

	lda	CALC_STATE		; Get input states bit field
	and	#CALC_STATE_EXP		; Mask to get exponent flag
	bne	.disp_float_exp		; If set then force scientific notation

	lda	CALC_DIGITS		; Use digit count as min digits to disp
	bra	.disp_float

.disp_float_exp
	lda	#-1			; Use special value to force scientific

.disp_float
	jsr	float_disp		; Display current slot X value

	rts

!zone	calc_inputkey
; Handle the current keypress for editing the value in stack slot X. If C is
; set, then the calling routine should re-render the value of stack slot X by
; calling calc_dispinput, since the value or state of slot X will have been
; changed. If C is clear, then it is not necessary to call calc_dispinput since
; the action taken has not resulted in value or state changes.
; INPUT:	A = Captured key state to handle
; OUTPUT:	C = Set if resultant behaviour requires value re-render
;		A, Y, GP0-2 = Trashed
calc_inputkey
	cmp	#KEY_HOLD | KEY_0	; If 0 held, then clear entry
	beq	.key_0_hold_action
	cmp	#KEY_HOLD | KEY_MUL	; If * held, then enter exponent
	beq	.key_mul_hold_action
	cmp	#KEY_HOLD | KEY_SUB	; If - held, then negate mantissa or exp
	beq	.key_sub_hold_action
	cmp	#KEY_PRESS | KEY_DOT	; If . pressed, then enter decimal point
	beq	.key_dot_action

	clc				; Only accept BCD with pressed keys
	jsr	input_keytobcd		; Convert key to BCD if applicable
	bcc	.bcd_valid		; If not numeric, don't do anything

	lda	CALC_STATE		; Clear key still down flag
	and	#!CALC_STATE_KEYD
	sta	CALC_STATE

	clc				; If key not matched then don't do
	rts				; anything

.key_0_hold_action
	jmp	.clear

.key_mul_hold_action
	jmp	.exponent

.key_sub_hold_action
	jmp	.negate

.key_dot_action
	jmp	.decimal_point

.bcd_valid
	sta	GP2			; Save key value to GP2 LSB

	lda	CALC_STATE		; Get input states bit field
	and	#CALC_STATE_RES		; Mask to get result shown flag
	beq	.input_digit		; If set then push result first

	jsr	calc_dup		; Duplicate and push slot X into Y

	lda	CALC_STATE		; Clear result shown flag
	and	#!CALC_STATE_RES
	sta	CALC_STATE

.input_digit
	lda	CALC_STATE		; Get input states bit field
	and	#CALC_STATE_EXP		; Mask to get exponent flag
	bne	.exponent_digit		; If set then enter digit into exponent

	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	lda	CALC_DIGITS		; If no digits entered yet, then clear
	bne	.digits_entered		; slot X to allow entry of new value

	jsr	float_zero		; Clear slot X (already in GP0)

	lda	GP2			; If first digit entered is 0, then
	bne	.insert_mantissa	; don't enter it

	sec
	rts

.digits_entered
	lda	CALC_DIGITS		; Get count of digits entered
	cmp	#7			; Stop entry when at max digits
	beq	.mantissa_digit_stop	; displayable for mantissa

	lda	CALC_STATE		; Get input states bit field
	and	#CALC_STATE_DP		; Mask to get decimal point flag
	bne	.insert_mantissa	; If not set then increment exponent

	sed				; Increment exponent (BCD) — no need to
	inc	CALC_STACK_X + FLOAT_E	; check overflow since can only reach
	cld				; max digits

.insert_mantissa
	lda	CALC_DIGITS		; Get count of digits entered
	lsr				; Shift to get byte index into mantissa
	clc				; Add byte index to address of slot X
	adc	GP0
	sta	GP0

	lda	GP0 + 1			; Add carried result into MSB
	adc	#0
	sta	GP0 + 1

	lda	CALC_DIGITS		; If current digit count is odd, then
	and	#$01			; insert low digit
	bne	.low_digit		; Otherwise insert high digit

	ldy	#0
	lda	GP2			; Get BCD value
	asl				; Shift low nibble into high nibble
	asl
	asl
	asl
	sta	(GP0),y			; Store into current mantissa byte

	bra	.next_digit

.low_digit
	ldy	#0
	lda	GP2			; Get BCD value
	ora	(GP0),y			; Combine with current digit in slot X
	sta	(GP0),y			; Store into current mantissa byte

.next_digit
	inc	CALC_DIGITS		; Increment digit count

	sec
	rts

.mantissa_digit_stop
	clc
	rts

.exponent_digit
	lda	CALC_DIGITS		; Get count of digits entered
	cmp	#(FLOAT_E * 2) + 2	; Stop entry when entered all exponent
	beq	.exponent_digit_stop	; digits

	lda	CALC_STACK_X + FLOAT_E	; Get current exponent value
	asl				; Shift low nibble into high nibble
	asl
	asl
	asl
	ora	GP2			; Combine with BCD value (low nibble)
	sta	CALC_STACK_X + FLOAT_E	; Store back into exponent value

	bra	.next_digit

.exponent_digit_stop
	clc
	rts

.decimal_point
	lda	CALC_STATE		; Get input states bit field
	and	#CALC_STATE_DPEX	; Mask to get decimal and exp flags
	bne	.decimal_point_done	; If either set then no re-entry allowed

	lda	CALC_STATE		; Set decimal point flag
	ora	#CALC_STATE_DP
	sta	CALC_STATE
	lda	CALC_DIGITS		; If no digits entered, then clear slot
	bne	.decimal_point_done	; X

	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	jsr	float_zero		; Clear slot X

	inc	CALC_DIGITS		; Increment digit count so first is 0

.decimal_point_done
	clc
	rts

.clear
	lda	CALC_STATE		; Get input states bit field
	and	#CALC_STATE_KEYD	; Mask to get key state
	bne	.clear_no_entry		; If still down then don't do anything

	lda	#CALC_STACK_X & $FF	; Load address of stack slot X into GP0
	sta	GP0
	lda	#CALC_STACK_X >> 8
	sta	GP0 + 1

	jsr	float_zero		; Clear slot X

	stz	CALC_DIGITS		; Clear count of digits entered

	lda	#CALC_STATE_KEYD	; Clear state but set key still down
	sta	CALC_STATE		; flag

	sec
	rts

.clear_no_entry
	clc
	rts

.exponent
	lda	CALC_STATE		; Get input states bit field
	and	#CALC_STATE_EXP		; Mask to get exponent flag
	bne	.exponent_no_reentry	; If set then no re-entry allowed

	lda	CALC_DIGITS		; Get digits entered
	beq	.exponent_no_reentry	; If no digits entered then no exp entry

	lda	CALC_STATE		; Set exponent flag
	ora	#CALC_STATE_EXP
	sta	CALC_STATE
	stz	CALC_STACK_X + FLOAT_E	; Clear exp so new one can be entered

	lda	#FLOAT_E * 2		; Set digit count to exponent offset
	sta	CALC_DIGITS

	sec
	rts

.exponent_no_reentry
	clc
	rts

.negate
	lda	CALC_STATE		; Get input states bit field
	and	#CALC_STATE_KEYD	; Mask to get key state
	bne	.negate_no_entry	; If still down then don't do anything

	lda	CALC_DIGITS		; Get digits entered
	beq	.negate_no_entry	; If no digits entered then no negation

	lda	CALC_STATE		; Get input states bit field
	and	#CALC_STATE_EXP		; Mask to get exponent flag
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
	lda	CALC_STATE		; Set key still down flag
	ora	#CALC_STATE_KEYD
	sta	CALC_STATE

	sec
	rts

.negate_no_entry
	clc
	rts