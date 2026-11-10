; CALCULATOR MODE
; Used for performing arithemetic and scientific calculations.

CALC_INFO
	!raw	"CALC", 0, 0, 0, 0	; MODE_I_NAME
	!word	$0000			; MODE_I_AUTHOR
	!word	$0100			; MODE_I_VERSION
	!word	calc_main		; MODE_I_MAIN
	!word	$0000			; MODE_I_ISR

; Calculator general states (bit field)
CALC_STATE_RES	= $01
CALC_STATE_EQU	= $02

; Calculator input entry modes (enum)
CALC_ENTRY_IFIX	= $00			; Sequential infix entry
CALC_ENTRY_RPN	= $01			; Reverse Polish notation (RPN) entry

; Calculator input operations (enum)
CALC_OP_NONE	= $00			; No operation selected
CALC_OP_ADD	= KEY_ADD		; Addition selected
CALC_OP_SUB	= KEY_SUB		; Subtraction selected
CALC_OP_MUL	= KEY_MUL		; Multiplication selected
CALC_OP_DIV	= KEY_DIV		; Division selected
CALC_OP_POW	= KEY_MUL | $80		; Base exponentiation selected

; Calculator top-level menu items
CALC_TOP_MENU
	!word	CALC_FUNC_MSG, calc_funcmenu
	!word	CALC_CONFIG_MSG, calc_configmenu
	!word	$0000

CALC_FUNC_MSG
	!raw	"FUNC", 0

CALC_CONFIG_MSG
	!raw	"CONFIG", 0

; Calculator function menu items
; Using function names directly from index table
CALC_FUNC_MENU
	!word	PROGS_POW2_IDX, $0000
	!word	PROGS_POW3_IDX, $0000
	!word	PROGS_POW_IDX, calc_powop
	!word	$0000

; Calculator function addresses
CALC_FUNCS
	!word	PROGS_POW2
	!word	PROGS_POW3
	!word	PROGS_POW

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
	jsr	calc_xtofio
	jsr	fio_dispinput		; Display current input value of slot X

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
	jsr	calc_xtofio
	jsr	fio_inputkey		; Handle value input behaviour
	jsr	calc_fiotox
	bcs	.render			; If C set then re-render
	bra	.get_key		; Otherwise get next key

.binop_action
	and	#$0F			; Mask key to map to operation value

	jmp	.binop

.top_menu
	jsr	calc_topmenu		; Show top-level menu

	lda	CALC_BINOPFUNC		; If binary operation function selected
	cmp	#CALC_OP_NONE		; If not none, then process as binary
	beq	.render			; operation

	jmp	.binop

.clear
	lda	CALC_FIOSTATE		; Get input states bit field
	and	#FIO_STATE_KEYDN	; Mask to get key state
	bne	.get_key		; If still down then don't do anything

	lda	CALC_FIODIGITS		; If no digits entered or currently zero
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

	lda	CALC_FIOSTATE		; Set key still down flag
	ora	#FIO_STATE_KEYDN
	sta	CALC_FIOSTATE

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

	lda	CALC_STATE		; If previous result still shown
	and	#CALC_STATE_RES
	bne	.binop_transfer		; Then compute with current A and B

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
	sta	CALC_OP			; Store pressed key as operation

	ldy	CALC_STATE		; Store old state in Y
	lda	CALC_STATE

	lda	CALC_STATE		; Clear equals pressed flag
	and	#!CALC_STATE_EQU
	sta	CALC_STATE

	stz	CALC_BINOPFUNC		; Clear binary operation function

	lda	CALC_ENTRY		; Get input entry mode
	cmp	#CALC_ENTRY_RPN		; If RPN entry
	beq	.binop_compute		; Then compute immediately

	tya				; Get old state
	and	#CALC_STATE_EQU		; Mask to get equals pressed flag
	bne	.binop_store_a		; If set then store in register A

	cpx	#CALC_OP_NONE		; If no old op, then store in reg A
	beq	.binop_store_a

	lda	CALC_FIODIGITS		; If no digits entered, store in reg A
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
	jsr	calc_binop		; Move slots Y and X into FP0 and FP1

	lda	CALC_OP			; Get operation
	cmp	#CALC_OP_ADD		; If operation is addition
	bne	.check_sub
	jsr	float_add		; Then add FP0 and FP1 into FP2
	bra	.binop_done

.check_sub
	cmp	#CALC_OP_SUB		; If operation is subtraction
	bne	.check_mul
	jsr	float_sub		; Then subtract FP1 from FP0 into FP2
	bra	.binop_done

.check_mul
	cmp	#CALC_OP_MUL		; If operation is multiplication
	bne	.check_div
	jsr	float_mul		; Then multiply FP0 by FP1 into FP2
	bra	.binop_done

.check_div
	cmp	#CALC_OP_DIV		; If operation is division
	bne	.check_pow
	jsr	float_div		; Then divide FP0 by FP1 into FP2
	bra	.binop_done

.check_pow
	cmp	#CALC_OP_POW		; If operation is base exponentiation
	bne	.binop_done

	lda	#<PROGS_POW		; Then load power program addr
	sta	GP0
	lda	#>PROGS_POW
	sta	GP0 + 1

	jsr	calc_runbinopfunc	; Run program using binary operands

	bra	.binop_done

.binop_done
	jsr	calc_fp2tox		; Move FP2 into slot X

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
	stz	CALC_STATE		; Clear general state
	stz	CALC_FIOSTATE		; Clear input state
	stz	CALC_FIODIGITS		; Clear input digit count
	stz	CALC_ENTRY		; Clear input entry mode
	stz	CALC_BINOPFUNC		; Clear binary operation function

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

!zone	calc_xtofio
; Copy the calculator state and stack slot X value into variables used by
; floating-point input routines.
; INPUT:	None
; OUTPUT:	None
;		Y, GP0, GP1 = Trashed
;		A, C = Kept
calc_xtofio
	php
	pha

	lda	CALC_FIOSTATE		; Transfer calculator state to FIO
	sta	FIO_STATE

	lda	CALC_FIODIGITS		; Transfer input digit count to FIO
	sta	FIO_DIGITS

	lda	#<CALC_STACK_X		; Load address of stack slot X into GP0
	sta	GP0
	lda	#>CALC_STACK_X
	sta	GP0 + 1

	lda	#<FP0			; Load address of FP0 into GP1
	sta	GP1
	lda	#>FP0
	sta	GP1 + 1

	jsr	float_copy		; Copy slot X value into FP0

	pla
	plp

	rts

!zone	calc_fiotox
; Copy the state and variables used by floating-point input routines into the
; calculator state and stack slot X.
; INPUT:	None
; OUTPUT:	None
;		Y, GP0, GP1 = Trashed
;		A, C = Kept
calc_fiotox
	php
	pha

	lda	FIO_DIGITS		; Transfer input digit count from FIO
	sta	CALC_FIODIGITS

	lda	FIO_STATE		; Transfer FIO state into calculator
	sta	CALC_FIOSTATE
	and	#FIO_STATE_DIGEN	; If digit just entered
	beq	.no_dup			; Then check if result is shown

	lda	CALC_STATE		; Get general state
	and	#CALC_STATE_RES		; If result shown while digit entered
	beq	.no_dup			; Then duplicate slot X first

	jsr	calc_dup		; Duplicate and push slot X into Y

	lda	CALC_STATE		; Clear result shown flag
	and	#!CALC_STATE_RES
	sta	CALC_STATE

.no_dup
	lda	#<FP0			; Load address of FP0 into GP0
	sta	GP0
	lda	#>FP0
	sta	GP0 + 1

	lda	#<CALC_STACK_X		; Load address of stack slot X into GP1
	sta	GP1
	lda	#>CALC_STACK_X
	sta	GP1 + 1

	jsr	float_copy		; Copy FP0 value into slot X

	pla
	plp

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
;		A = Trashed
calc_newinput
	stz	CALC_FIOSTATE		; Clear input states bit field
	stz	CALC_FIODIGITS		; Set input digit count to 0

	lda	CALC_STATE		; Clear general states bit field
	and	#CALC_STATE_EQU		; Only store equals pressed flag
	sta	CALC_STATE

	rts

!zone	calc_loadfunc
; Load a program to use as a calculator function.
; INPUT:	GP0 = Address of program contents to run as a function
; OUTPUT:	CALC_INCOUNT = Number of inputs expected by function
;		CALC_OUTCOUNT = Number of outputs expected by function
;		A, Y = Trashed
calc_loadfunc
	jsr	prog_init		; Reinitialise program state

	jsr	prog_load		; Load program from address

	jsr	gfx_clear		; Clear display to indicate working

	stz	CALC_INCOUNT		; Clear input and output value counts
	stz	CALC_OUTCOUNT

	ldy	#PROG_H_SIG		; Use Y as index into signature

.in_loop
	lda	(GP0),y			; Get current character in signature
	beq	.done			; If null then finish counting
	cmp	#'>'			; If delimter then count outputs
	beq	.delimeter

	inc	CALC_INCOUNT
	iny

	cpy	#PROG_H_IBASE		; Repeat for 8 characters
	bcc	.in_loop

.delimeter
	iny				; Skip over delimeter character

.out_loop
	lda	(GP0),y			; Get current character in signature
	beq	.check_incount		; If null then finish counting

	inc	CALC_OUTCOUNT
	iny

	cpy	#PROG_H_IBASE		; Repeat for 8 characters
	bcc	.out_loop

.check_incount
	lda	CALC_INCOUNT		; Check input count
	cmp	#5			; If < 5
	bcc	.check_outcount		; Then check output count

	lda	#4			; Cap input count to 4
	sta	CALC_INCOUNT

.check_outcount
	lda	CALC_OUTCOUNT		; Check output count
	cmp	#5			; If < 5
	bcc	.done			; Then load inputs

	lda	#4			; Cap output count to 4
	sta	CALC_OUTCOUNT

.done
	rts

!zone	calc_runfunc
; Run the loaded function using the calculator stack.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, FP0-3, GP0-2 = Trashed
calc_runfunc
	lda	CALC_ENTRY		; Get calculator input entry mode
	cmp	#CALC_ENTRY_RPN		; If RPN entry
	beq	.load_from_stack	; Then load inputs from stack

	lda	CALC_INCOUNT		; Get number of function inputs
	cmp	#2			; If less than 2 inputs
	bcc	.load_from_stack	; Then load using register A/slot X

	jsr	prog_askinputs		; Otherwise ask user to enter inputs
	bcs	.done			; If cancelled then don't run

	bra	.run

.load_from_stack
	ldx	CALC_INCOUNT		; Use X as count of inputs remaining

.load_inputs_loop
	txa				; Get count of inputs remaining
	beq	.pop_inputs		; If zero then pop from calc stack
	dec				; Decrement to get slot index
	asl				; Shift to get address into calc stack
	asl
	asl

	clc
	adc	#<CALC_STACK		; Add calculator stack base address LSB
	sta	GP0			; to index and store in GP0
	lda	#>CALC_STACK		; Do same for MSB
	adc	#0	
	sta	GP0 + 1

	jsr	prog_pushval		; Push slot value onto value stack
	bcs	.done			; If overflow then early exit (unlikely)

	dex				; Decrement count of inputs remaining
	bra	.load_inputs_loop

.pop_inputs
	lda	CALC_INCOUNT		; Use GP2 as count of inputs remaining
	sta	GP2

.pop_inputs_loop
	lda	GP2			; If no inputs remaining
	beq	.run			; Then run program

	jsr	calc_pop		; Pop value in slot X to shift stack

	dec	GP2			; Decrement count of inputs remaining

	bra	.pop_inputs_loop

.run
	jsr	prog_run		; Run loaded program

	lda	CALC_OUTCOUNT		; Use GP2 as count of outputs remaining
	sta	GP2

.reserve_outputs_loop
	lda	GP2			; If no outputs remaining
	beq	.load_outputs		; Then load outputs

	jsr	calc_dup		; Reserve output slot by duplicating val

	dec	GP2			; Decrement count of outputs remaining

	bra	.reserve_outputs_loop

.load_outputs
	ldx	#0			; Use X as count of outputs processed

.load_outputs_loop
	txa				; Get count of outputs processed
	cmp	CALC_OUTCOUNT		; If equal to number of outputs
	beq	.store_reg		; Then store in store result in register
	asl				; Shift to get address into calc stack
	asl
	asl

	clc
	adc	#<CALC_STACK		; Add calculator stack base address LSB
	sta	GP1			; to index and store in GP1
	lda	#>CALC_STACK		; Do same for MSB
	adc	#0	
	sta	GP1 + 1

	jsr	prog_popval		; Pop from value stack into slot
	bcs	.done			; If underflow then early exit

	inx				; Increment count of outputs processed
	bra	.load_outputs_loop

.store_reg
	lda	CALC_OP			; Get current operation
	cmp	#CALC_OP_NONE		; If operation selected
	bne	.store_b		; Then store result into register B

	jsr	calc_xtoa		; Transfer result into register A

	bra	.done

.store_b
	jsr	calc_xtob		; Transfer result into register B

.done
	jsr	calc_newinput		; Reset input state

	rts

!zone	calc_runbinopfunc
; Run a function from a program using the values from FP0 and FP1 as binary
; operands, with the result stored in FP2.
; INPUT:	GP0 = Address of program contents to run as a function
; OUTPUT:	None
;		A, X, Y, FP0-3, GP0-2 = Trashed
calc_runbinopfunc
	jsr	prog_init		; Reinitialise program state

	jsr	prog_load		; Load program from address

	jsr	gfx_clear		; Clear display to indicate working

	lda	#<FP0			; Store address of FP0 as value to push
	sta	GP0
	lda	#>FP0
	sta	GP0 + 1

	jsr	prog_pushval		; Push FP0 onto value stack
	bcs	.error			; If overflow then return NaN (unlikely)

	lda	#<FP1			; Store address of FP1 as value to push
	sta	GP0
	lda	#>FP1
	sta	GP0 + 1

	jsr	prog_pushval		; Push FP1 onto value stack
	bcs	.error			; If overflow then return NaN (unlikely)

	jsr	prog_run		; Run loaded program

	lda	PROG_EXIT		; Check exit code
	cmp	#PROG_EX_OK		; If error occurred
	bne	.error			; Then set FP2 to NaN

	lda	#<FP2			; Store address of FP2 as destination
	sta	GP1			; for popped value
	lda	#>FP2
	sta	GP1 + 1

	jsr	prog_popval		; Pop value from value stack into FP2
	bcs	.error			; If underflow then return NaN

	rts

.error
	lda	FP2 + FLOAT_S		; Set result float to NaN
	ora	#FLOAT_S_NAN
	sta	FP2 + FLOAT_S

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

!zone	calc_funcmenu
; Show the calculator's function menu.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, FP0-3, GP0-4 = Trashed
calc_funcmenu
	lda	#<CALC_FUNC_MENU	; Load function menu array address
	sta	GP0
	lda	#>CALC_FUNC_MENU
	sta	GP0 + 1

	lda	#0			; Set initial index to 0
	jsr	input_showmenu
	bcs	.done			; If cancelled then early exit

	asl				; Shift selection index to use as index
	tay				; into function addresses table

	lda	GP0 + 1			; If dispatch address LSB is nonzero
	bne	.done			; Then special call made; early exit

	lda	#<CALC_FUNCS		; Store address of function addresses
	sta	GP1			; table in GP1
	lda	#>CALC_FUNCS
	sta	GP1 + 1

	lda	(GP1),y			; Store LSB of address of program
	sta	GP0			; contents from table in GP0
	iny				; Do same for MSB
	lda	(GP1),y
	sta	GP0 + 1

	jsr	calc_loadfunc		; Load function from table

	jsr	calc_runfunc		; Run function from table

.done
	rts

!zone	calc_powop
; Set the calculator state such that the next operation to be performed is base
; exponentiation.
; INPUT:	None
; OUTPUT:	None
calc_powop
	lda	#CALC_OP_POW		; Set binary operation function to
	sta	CALC_BINOPFUNC		; perform

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
	bcs	.done			; If cancelled then early exit
	sta	CALC_ENTRY		; Set mode to selected option

.done
	rts