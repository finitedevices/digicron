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
CALC_STATE_EQU	= $20			; Set if equals pressed to show result

; Calculator input entry modes (enum)
CALC_ENTRY_IFIX	= $00			; Sequential infix entry
CALC_ENTRY_RPN	= $01			; Reverse Polish notation (RPN) entry

; Calculator input operations (enum)
CALC_OP_NONE	= $00			; No operation selected
CALC_OP_ADD	= KEY_ADD		; Addition selected
CALC_OP_SUB	= KEY_SUB		; Subtraction selected
CALC_OP_MUL	= KEY_MUL		; Multiplication selected
CALC_OP_DIV	= KEY_DIV		; Division selected

; Calculator top-level menu items
CALC_TOP_MENU
	!word	CALC_CONFIG_MSG, calc_configmenu
	!word	$0000

CALC_CONFIG_MSG
	!raw	"CONFIG", 0

; Calculator configuration menu items
CALC_CONFIG_MENU
	!word	CALC_ENTRY_MSG, calc_entrymenu
	!word	$0000

CALC_ENTRY_MSG
	!raw	"ENTRY", 0

; Calculator entry mode configuration menu items
CALC_ENTRY_MENU
	!word	CALC_INFIX_MSG, $0000
	!word	CALC_RPN_MSG, $0000
	!word	$0000

CALC_INFIX_MSG
	!raw	"INFIX", 0

CALC_RPN_MSG
	!raw	"RPN", 0

!zone	calc_main
; Entry point for the Calculator mode. This mode will be skipped if stack slot X
; is zero. To enter this mode when stack slot X is zero, use calc_show instead.
; INPUT:	None
; OUTPUT:	Not a subroutine
calc_main
	lda	#<(CALC_INFO + MODE_I_NAME)
	sta	GP0			; Store address to mode info struct
	lda	#>(CALC_INFO + MODE_I_NAME)
	sta	GP0 + 1

	jsr	mode_showname		; Display the mode name

.new_input
	jsr	calc_newinput		; Reset input state

.render
	jsr	calc_dispinput		; Display current input value of slot X

.get_key
	jsr	input_getkeypress	; Check currently pressed key
	cmp	#$00			; If no key
	beq	.input_key		; Then pass key value to handler

	tax				; Save key value to X
	lda	#KEY_DIV_H_HOME		; Set KEY_DIV behaviour to prevent mode
	sta	KEY_DIV_BEHAV		; change when pressed
	txa				; Restore key value from X

	cmp	#KEY_HOLD | KEY_EQU	; If = held, then show top-level menu
	beq	.top_menu
	cmp	#KEY_HOLD | KEY_0	; If 0 held, then clear
	beq	.clear
	cmp	#KEY_PRESS | KEY_EQU	; If = pressed, then either push or eval
	beq	.equals
	cmp	#KEY_PRESS | KEY_ADD	; If + pressed, then do addition
	beq	.binop_action
	cmp	#KEY_PRESS | KEY_SUB	; If - pressed, then do subtraction
	beq	.binop_action
	cmp	#KEY_PRESS | KEY_MUL	; If * pressed, then do multiplication
	beq	.binop_action
	cmp	#KEY_PRESS | KEY_DIV	; If / pressed, then do division
	beq	.binop_action

.input_key
	jsr	calc_inputkey		; Handle value input behaviour
	bcs	.render			; If C set then re-render
	bra	.get_key		; Otherwise get next key

.binop_action
	jmp	.binop

.top_menu
	jsr	calc_topmenu		; Show top-level menu

	jsr	.render

.clear
	lda	CALC_STATE		; Get input states bit field
	and	#CALC_STATE_KEYD	; Mask to get key state
	bne	.get_key		; If still down then don't do anything

	lda	CALC_DIGITS		; If no digits entered
	beq	.clear_all		; Then clear all

	lda	#<CALC_STACK_X		; Load address of stack slot X into GP0
	sta	GP0
	lda	#>CALC_STACK_X
	sta	GP0 + 1

	jsr	float_iszero		; If current value is nonzero
	bcc	.clear_slot_x		; Then clear slot X

.clear_all
	jsr	calc_ac			; Otherwise clear stack and registers

	jsr	gfx_clear		; Clear display

	lda	#<.CLEAR_ALL_MSG
	sta	GP0
	lda	#>.CLEAR_ALL_MSG
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Show all clear message

	lda	CALC_STATE		; Set key still down flag
	ora	#CALC_STATE_KEYD
	sta	CALC_STATE

	bra	.get_key

.clear_slot_x
	lda	#KEY_HOLD | KEY_0	; Defer clearing slot X to handled
	bra	.input_key		; behaviour

.equals
	lda	CALC_ENTRY		; Get input entry mode
	cmp	#CALC_ENTRY_RPN		; If RPN entry
	beq	.push_x			; Then push slot X into Y

	lda	CALC_OP			; Check current operation
	cmp	#CALC_OP_NONE		; If no operation
	beq	.signal_action		; Then don't do anything

	lda	CALC_STATE		; Set equals pressed flag
	ora	#CALC_STATE_EQU
	sta	CALC_STATE

	lda	CALC_DIGITS		; If no digits entered
	beq	.binop_transfer		; Then compute with current A and B

	jsr	calc_xtob		; Store current value in B

	bra	.binop_transfer		; Compute with A and B

.push_x
	jsr	calc_normx		; Normalise value in slot X
	jsr	calc_dup		; Duplicate and push slot X into Y

.signal_action
	jsr	gfx_clear		; Clear display to indicate action

	lda	#10
	sta	GP0
	stz	GP0 + 1

	jsr	time_wait		; Delay by 10 ticks (0.1 seconds)

	jmp	.new_input

.binop
	ldx	CALC_OP			; Store old operation in X
	and	#$0F			; Mask key to get value
	sta	CALC_OP			; Store pressed key as operation

	ldy	CALC_STATE		; Store old state in Y
	lda	CALC_STATE

	lda	CALC_STATE		; Clear equals pressed flag
	and	#!CALC_STATE_EQU
	sta	CALC_STATE

	lda	CALC_ENTRY		; Get input entry mode
	cmp	#CALC_ENTRY_RPN		; If RPN entry
	beq	.binop_compute		; Then compute immediately

	tya				; Get old state
	and	#CALC_STATE_EQU		; Mask to get equals pressed flag
	bne	.binop_store_a		; If set then store in register A

	cpx	#CALC_OP_NONE		; If no old op, then store in reg A
	beq	.binop_store_a

	lda	CALC_DIGITS		; If no digits entered, store in reg A
	beq	.binop_store_a

	lda	CALC_OP			; Store new operation as next operation
	sta	CALC_NEXT_OP		; after running total or result computed

	stx	CALC_OP			; Use old operation to compute result

	jsr	calc_xtob		; Transfer current value into register B

	bra	.binop_transfer		; Transfer registers and compute result

.binop_store_a
	jsr	calc_xtoa		; Transfer current value into register A

	bra	.signal_action

.binop_transfer
	jsr	calc_dup		; Duplicate to have 2 slots to write to
	jsr	calc_abtoyx		; Move regs A and B into slots Y and X

.binop_compute
	jsr	gfx_clear		; Clear display to indicate busy
	jsr	calc_normx		; Normalise value in slot X
	jsr	calc_binop		; Move slots Y and X into GP0 and GP1

	lda	CALC_OP			; Get operation
	cmp	#CALC_OP_ADD		; If operation is addition
	bne	.check_sub
	jsr	float_add		; Then add GP0 and GP1 into GP2
	bra	.binop_done

.check_sub
	cmp	#CALC_OP_SUB		; If operation is subtraction
	bne	.check_mul
	jsr	float_sub		; Then subtract GP1 from GP0 into GP2
	bra	.binop_done

.check_mul
	cmp	#CALC_OP_MUL		; If operation is multiplication
	bne	.check_div
	jsr	float_mul		; Then multiply GP0 by GP1 into GP2
	bra	.binop_done

.check_div
	cmp	#CALC_OP_DIV		; If operation is division
	bne	.binop_done
	jsr	float_div		; Then divide GP0 by GP1 into GP2
	bra	.binop_done

.binop_done
	jsr	calc_fp2tox		; Move GP2 into slot X

	jsr	calc_xtoa		; Transfer result into register A

	jsr	calc_newinput		; Reset input state

	lda	CALC_NEXT_OP		; If no next operation then don't set
	beq	.no_next_op		; current operation
	sta	CALC_OP			; Store next operation as current
	lda	#CALC_OP_NONE		; Clear next operation
	sta	CALC_NEXT_OP

.no_next_op
	lda	CALC_STATE		; Set result shown flag
	ora	#CALC_STATE_RES
	sta	CALC_STATE

	jsr	.render

.CLEAR_ALL_MSG
	!raw	"AC     0"

!zone	calc_init
; Initialise the calculator stack, state and configuration values.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0 = Trashed
calc_init
	stz	CALC_STATE		; Clear input state
	stz	CALC_DIGITS		; Clear input digit count
	stz	CALC_ENTRY		; Clear input entry mode

	jsr	calc_ac			; Clear stack and registers

	rts

!zone	calc_ac
; Clear the calculator stack and registers.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0 = Trashed
calc_ac
	lda	#CALC_OP_NONE		; Clear current and next input
	sta	CALC_OP			; operations
	sta	CALC_NEXT_OP

	jsr	calc_clearstack		; Clear stack
 
	lda	#<CALC_REG_A		; Load address of register A into GP0
	sta	GP0
	lda	#>CALC_REG_A
	sta	GP0 + 1

	jsr	float_zero		; Clear register A

	lda	#<CALC_REG_B		; Load address of register B into GP0
	sta	GP0
	lda	#>CALC_REG_B
	sta	GP0 + 1

	jsr	float_zero		; Clear register B

	jsr	calc_newinput		; Reset input state

	rts

!zone	calc_clearstack
; Clear the calculator stack by setting all slots to zero.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0 = Trashed
calc_clearstack
	lda	#<CALC_STACK_X		; Load address of stack slot X into GP0
	sta	GP0
	lda	#>CALC_STACK_X
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
	lda	#<CALC_STACK_Z		; Load address of stack slot Z into GP0
	sta	GP0			; (lower slot)
	lda	#>CALC_STACK_Z
	sta	GP0 + 1

	lda	#<CALC_STACK_T		; Load address of stack slot T into GP1
	sta	GP1			; (upper slot)
	lda	#>CALC_STACK_T
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
	lda	#<CALC_STACK_Y		; Load address of stack slot Y into GP0
	sta	GP0			; (upper slot)
	lda	#>CALC_STACK_Y
	sta	GP0 + 1

	lda	#<CALC_STACK_X		; Load address of stack slot X into GP1
	sta	GP1			; (lower slot)
	lda	#>CALC_STACK_X
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
	lda	#<CALC_STACK_X		; Load address of stack slot X into GP0
	sta	GP0
	lda	#>CALC_STACK_X
	sta	GP0 + 1

	lda	#<FP0			; Load address of FP0 into GP1
	sta	GP1
	lda	#>FP0
	sta	GP1 + 1

	jsr	float_copy		; Copy slot X value into FP0

	jsr	float_norm		; Normalise the value in FP0

	lda	#<FP0			; Load address of FP0 into GP0
	sta	GP0
	lda	#>FP0
	sta	GP0 + 1

	lda	#<CALC_STACK_X		; Load address of stack slot X into GP1
	sta	GP1
	lda	#>CALC_STACK_X
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
	lda	#<CALC_STACK_Y		; Load address of stack slot Y into GP0
	sta	GP0
	lda	#>CALC_STACK_Y
	sta	GP0 + 1

	lda	#<FP0			; Load address of FP0 into GP1
	sta	GP1
	lda	#>FP0
	sta	GP1 + 1

	jsr	float_copy		; Copy slot Y value into FP0

	lda	#<CALC_STACK_X		; Load address of stack slot X into GP0
	sta	GP0
	lda	#>CALC_STACK_X
	sta	GP0 + 1

	lda	#<FP1			; Load address of FP1 into GP1
	sta	GP1
	lda	#>FP1
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
	lda	#<FP2			; Load address of FP2 into GP0
	sta	GP0
	lda	#>FP2
	sta	GP0 + 1

	lda	#<CALC_STACK_X		; Load address of stack slot X into GP1
	sta	GP1
	lda	#>CALC_STACK_X
	sta	GP1 + 1

	jsr	float_copy		; Copy FP2 value into slot X

	rts

!zone	calc_xtoa
; Copy stack slot X into register A.
; INPUT:	None
; OUTPUT:	None
;		A, Y, GP0, GP1 = Trashed
calc_xtoa
	lda	#<CALC_STACK_X		; Load address of stack slot X into GP0
	sta	GP0
	lda	#>CALC_STACK_X
	sta	GP0 + 1

	lda	#<CALC_REG_A		; Load address of register A into GP1
	sta	GP1
	lda	#>CALC_REG_A
	sta	GP1 + 1

	jsr	float_copy		; Copy slot X into register A

	rts

!zone	calc_xtob
; Copy stack slot X into register B.
; INPUT:	None
; OUTPUT:	None
;		A, Y, GP0, GP1 = Trashed
calc_xtob
	lda	#<CALC_STACK_X		; Load address of stack slot X into GP0
	sta	GP0
	lda	#>CALC_STACK_X
	sta	GP0 + 1

	lda	#<CALC_REG_B		; Load address of register B into GP1
	sta	GP1
	lda	#>CALC_REG_B
	sta	GP1 + 1

	jsr	float_copy		; Copy slot X into register B

	rts

!zone	calc_abtoyx
; Copy registers A and B into stack slots Y and X, normalising the value in
; register A.
; INPUT:	None
; OUTPUT:	None
;		A, Y, GP0, GP1 = Trashed
calc_abtoyx
	lda	#<CALC_REG_A		; Load address of register A into GP0
	sta	GP0
	lda	#>CALC_REG_A
	sta	GP0 + 1

	lda	#<FP0			; Load address of FP0 into GP1
	sta	GP1
	lda	#>FP0
	sta	GP1 + 1

	jsr	float_copy		; Copy register A into FP0

	jsr	float_norm		; Normalise the value in FP0

	lda	#<FP0			; Load address of FP0 into GP0
	sta	GP0
	lda	#>FP0
	sta	GP0 + 1

	lda	#<CALC_STACK_Y		; Load address of stack slot Y into GP1
	sta	GP1
	lda	#>CALC_STACK_Y
	sta	GP1 + 1

	jsr	float_copy		; Copy FP0 into slot Y

	lda	#<CALC_REG_B		; Load address of register B into GP0
	sta	GP0
	lda	#>CALC_REG_B
	sta	GP0 + 1

	lda	#<CALC_STACK_X		; Load address of stack slot X into GP1
	sta	GP1
	lda	#>CALC_STACK_X
	sta	GP1 + 1

	jsr	float_copy		; Copy register B into slot X

	rts

!zone	calc_newinput
; Reset the input state to allow the entry of a new value for stack slot X. This
; subroutine does not clear the value of stack slot X; its value will be cleared
; upon the input of the first key to edit the value.
; INPUT:	None
; OUTPUT:	None
calc_newinput
	stz	CALC_DIGITS		; Set input digit count to 0

	lda	CALC_STATE		; Clear input states bit field
	and	#CALC_STATE_EQU		; Only store equals pressed flag
	sta	CALC_STATE

	rts

!zone	calc_dispinput
; Display the current edited value of stack slot X.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0-5, FP0 = Trashed
calc_dispinput
	lda	#<CALC_STACK_X		; Load address of stack slot X into GP0
	sta	GP0
	lda	#>CALC_STACK_X
	sta	GP0 + 1

	lda	#<FP0			; Load address of FP0 into GP1
	sta	GP1
	lda	#>FP0
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

	lda	#<CALC_STACK_X		; Load address of stack slot X into GP0
	sta	GP0
	lda	#>CALC_STACK_X
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
	clc				; check overflow since can only reach
	lda	CALC_STACK_X + FLOAT_E	; max digits
	adc	#1
	sta	CALC_STACK_X + FLOAT_E
	cld

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

	lda	#<CALC_STACK_X		; Load address of stack slot X into GP0
	sta	GP0
	lda	#>CALC_STACK_X
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

	lda	#<CALC_STACK_X		; Load address of stack slot X into GP0
	sta	GP0
	lda	#>CALC_STACK_X
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

!zone	calc_topmenu
; Show the calculator's top-level menu.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0-4 = Trashed
calc_topmenu
	lda	#<CALC_TOP_MENU		; Load top-level menu array address
	sta	GP0
	lda	#>CALC_TOP_MENU
	sta	GP0 + 1

	lda	#0			; Set initial item index to 0
	jsr	input_showmenu

	rts

!zone	calc_configmenu
; Show the calculator's configuration menu.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0-4 = Trashed
calc_configmenu
	lda	#<CALC_CONFIG_MENU	; Load config menu array address
	sta	GP0
	lda	#>CALC_CONFIG_MENU
	sta	GP0 + 1

	lda	#0			; Set initial item index to 0
	jsr	input_showmenu

	rts

!zone	calc_entrymenu
; Show the calculator's entry mode configuration menu.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0-4 = Trashed
calc_entrymenu
	lda	#<CALC_ENTRY_MENU	; Load entry config menu array address
	sta	GP0
	lda	#>CALC_ENTRY_MENU
	sta	GP0 + 1

	lda	CALC_ENTRY		; Set initial item current mode
	jsr	input_showmenu
	bcs	.done			; If cancelled, then early exit
	sta	CALC_ENTRY		; Set mode to selected option

.done
	rts