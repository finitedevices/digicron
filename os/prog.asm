; PROGRAM EXECUTION ENGINE
; Executes stack-based programs using a custom bytecode format.

; Program opcode dispatch table
PROG_OPCODES
	PROG_OP_NONE	= $00
	!word	_prog_none
	PROG_OP_RETURN	= $01
	!word	_prog_return
	PROG_OP_PUSH	= $02
	!word	_prog_push
	PROG_OP_POP	= $03
	!word	_prog_pop
	PROG_OP_DUP	= $04
	!word	_prog_dup
	PROG_OP_SWAP	= $05
	!word	_prog_swap
	PROG_OP_GOTO	= $06
	!word	_prog_goto
	PROG_OP_GOIF	= $07
	!word	_prog_goif
	PROG_OP_GET	= $08
	!word	_prog_get
	PROG_OP_SET	= $09
	!word	_prog_set
	PROG_OP_ADD	= $0A
	!word	_prog_add
	PROG_OP_SUB	= $0B
	!word	_prog_sub
	PROG_OP_MUL	= $0C
	!word	_prog_mul
	PROG_OP_DIV	= $0D
	!word	_prog_div
	PROG_OP_EQU	= $0E
	!word	_prog_equ
	PROG_OP_LTN	= $0F
	!word	_prog_ltn
	PROG_OP_GEQ	= $10
	!word	_prog_geq
	PROG_OP_FLOOR	= $11
	!word	_prog_floor
	PROG_OP_ABS	= $12
	!word	_prog_abs

PROG_N_OPCODES	= $13			; Number of opcodes defined in table

PROG_VAL_SIZE	= FLOAT_SIZE		; Size of values on value stack
PROG_E_SIZE	= $20			; Size of execution context frame

; Program exit codes (enum)
PROG_EX_OK	= $00			; Exited without error
PROG_EX_ILLEGAL	= $01			; Illegal opcode
PROG_EX_OPERAND	= $02			; Invalid operand value
PROG_EX_VOFLOW	= $03			; Overflow of value stack
PROG_EX_EOFLOW	= $04			; Overflow of execution context stack
PROG_EX_VUFLOW	= $05			; Underflow of value stack
PROG_EX_NOLOCAL	= $06			; Local not defined with label
PROG_EX_NFLOCAL	= $07			; No free space to define local

!zone	prog_init
; Initialise program stacks and state variables.
; INPUT:	None
; OUTPUT:	None
;		A = Trashed
prog_init
	lda	#<PROG_STACK_END	; Set value stack pointer to region end
	sta	PROG_VSTKPTR
	lda	#>PROG_STACK_END
	sta	PROG_VSTKPTR + 1

	lda	#<PROG_STACK		; Set execution context stack pointer to
	sta	PROG_ESTKPTR		; region start
	lda	#>PROG_STACK
	sta	PROG_ESTKPTR + 1

	stz	PROG_IBASE		; Clear instruction and data bases to
	stz	PROG_IBASE + 1		; indicate no program loaded
	stz	PROG_DBASE
	stz	PROG_DBASE + 1

	rts

!zone	prog_step
; Step the program that is currently being executed.
; INPUT:	None
; OUTPUT:	C = Set if program execution has finished
;		A, X, Y, FP0-3, GP0-2 = Trashed
; VARIABLES:	GP0 = Current address pointing to opcode dispatch table
;		GP1 = Dispatch address from opcode dispatch table
prog_step
	lda	#<PROG_OPCODES		; Load opcodes table base addr into GP0
	sta	GP0
	lda	#>PROG_OPCODES
	sta	GP0 + 1

	lda	PROG_CTR		; Use instruction counter as index
	cmp	PROG_ICOUNT		; Check if counter in instruction range
	bcs	_prog_return		; If not then perform return instruction
	asl				; Shift left to point to opcode-operand
	tay				; pair

	lda	(PROG_IBASE),y		; Get opcode
	sta	PROG_OPCODE		; Store in variable
	iny
	lda	(PROG_IBASE),y		; Get operand index into data base
	sta	PROG_OPERAND		; Store in variable

	inc	PROG_CTR		; Increment instruction counter

	lda	PROG_OPCODE		; Get opcode
	cmp	#PROG_N_OPCODES		; Check if opcode is in table bounds
	bcs	.illegal		; If not, then illegal opcode
	asl				; Shift to use opcode as address index
	clc
	adc	GP0			; Add to base address LSB
	sta	GP0
	lda	GP0 + 1			; Add carried result into MSB
	adc	#0
	sta	GP0 + 1

	ldy	#0			; Get dispatch address by dereferencing
	lda	(GP0),y			; address into opcode dispatch table
	sta	GP1
	iny
	lda	(GP0),y
	sta	GP1 + 1

	jmp	(GP1)			; Execute dispatch address

.illegal
	lda	#PROG_EX_ILLEGAL	; Set exit code to indicate illegal
	sta	PROG_EXIT		; opcode encountered

	sec
	rts

!zone	_prog_none
_prog_none
	clc
	rts

!zone	_prog_return
_prog_return
	lda	PROG_ESTKPTR		; Check if execution stack pointer LSB
	cmp	#<PROG_STACK		; is at base
	bne	.pop_estack		; If not then pop from stack
	lda	PROG_ESTKPTR + 1	; Check same for MSB
	cmp	#>PROG_STACK
	bne	.pop_estack

	lda	#PROG_EX_OK		; Set exit code to indicate no error
	sta	PROG_EXIT

	sec
	rts

.pop_estack
	sec
	lda	PROG_ESTKPTR		; Subtract execution context frame size
	sbc	#PROG_E_SIZE		; from stack
	sta	PROG_ESTKPTR
	lda	PROG_ESTKPTR + 1	; Subtract carried result into MSB
	sbc	#0
	sta	PROG_ESTKPTR

	ldx	#PROG_E_IBASE		; Load instruction base address into
	lda	PROG_ESTKPTR,x		; current variable
	sta	PROG_IBASE
	ldx	#PROG_E_IBASE + 1
	lda	PROG_ESTKPTR,x
	sta	PROG_IBASE + 1

	ldx	#PROG_E_DBASE		; Load data base address into current
	lda	PROG_ESTKPTR,x		; variable
	sta	PROG_DBASE
	ldx	#PROG_E_DBASE + 1
	lda	PROG_ESTKPTR,x
	sta	PROG_DBASE + 1

	ldx	#PROG_E_CTR		; Load instruction counter into current
	lda	PROG_ESTKPTR,x		; variable
	sta	PROG_CTR

	ldx	#PROG_E_LOCLBL0		; Load local labels into current
	lda	PROG_ESTKPTR,x		; variables
	sta	PROG_LOCLBL0
	inx
	sta	PROG_LOCLBL1
	inx
	sta	PROG_LOCLBL2

	ldx	#PROG_E_LOCAL0
	ldy	#0

.copy_locals_loop
	lda	PROG_ESTKPTR,x		; Copy local values into current
	sta	PROG_LOCALS,y		; variables

	inx
	iny

	cpx	#PROG_E_SIZE		; 24 bytes containing 3 locals
	bcc	.copy_locals_loop

	clc
	rts

!zone	_prog_push
_prog_push
	jsr	prog_getoperand		; Get address value to push in GP0
	bcs	.invalid_operand	; If out of range then invalid operand

	jsr	prog_pushval		; Push retrieved value onto stack
	bcs	.overflow		; If no space left then is overflow

	clc
	rts

.overflow
	lda	#PROG_EX_VOFLOW		; Set exit code to indicate overflow
	sta	PROG_EXIT

	sec
	rts

.invalid_operand
	lda	#PROG_EX_OPERAND	; Set exit code to indicate invalid
	sta	PROG_EXIT		; operand

	sec
	rts

!zone	_prog_pop
_prog_pop
	stz	GP1			; Clear destination address to indicate
	stz	GP1 + 1			; no copying needed

	jsr	prog_popval		; Pop from value stack
	bcs	.underflow		; If no value to pop then is underflow

	clc
	rts

.underflow
	lda	#PROG_EX_VUFLOW		; Set exit code to indicate underflow
	sta	PROG_EXIT

	sec
	rts

!zone	_prog_dup
_prog_dup
	lda	PROG_VSTKPTR		; Check if value stack pointer LSB is at
	cmp	#<PROG_STACK_END	; base
	bne	.dup			; If not then duplicate stack value
	lda	PROG_VSTKPTR + 1	; Check same for MSB
	cmp	#>PROG_STACK_END
	bne	.dup

	lda	#PROG_EX_VUFLOW		; Set exit code to indicate underflow
	sta	PROG_EXIT

	sec
	rts

.dup
	lda	PROG_VSTKPTR		; Use pointer to current top stack value
	sta	GP0			; as value to push to stack
	lda	PROG_VSTKPTR + 1
	sta	GP0 + 1

	jsr	prog_pushval		; Push top value onto stack
	bcs	.overflow		; If no space left then is overflow

	clc
	rts

.overflow
	lda	#PROG_EX_VOFLOW		; Set exit code to indicate overflow
	sta	PROG_EXIT

	sec
	rts

!zone	_prog_swap
_prog_swap
	lda	#<FP0			; Load address of FP0 into GP1
	sta	GP1
	lda	#>FP0
	sta	GP1 + 1

	jsr	prog_popval		; Store top value into FP0
	bcs	.underflow		; If no value to pop then is underflow

	lda	#<FP1			; Load address of FP1 into GP1
	sta	GP1
	lda	#>FP1
	sta	GP1 + 1

	jsr	prog_popval		; Store second value into FP1
	bcs	.underflow		; If no value to pop then is underflow

	lda	#<FP0			; Load address of FP0 into GP0
	sta	GP0
	lda	#>FP0
	sta	GP0 + 1

	jsr	prog_pushval		; Push top value from FP0 onto stack
	bcs	.overflow		; If no space left then is overflow

	lda	#<FP1			; Load address of FP1 into GP0
	sta	GP0
	lda	#>FP1
	sta	GP0 + 1

	jsr	prog_pushval		; Push second value from FP1 onto stack
	bcs	.overflow		; If no space left then is overflow

	clc
	rts

.underflow
	lda	#PROG_EX_VUFLOW		; Set exit code to indicate underflow
	sta	PROG_EXIT

	sec
	rts

.overflow
	lda	#PROG_EX_VOFLOW		; Set exit code to indicate overflow
	sta	PROG_EXIT

	sec
	rts

!zone	_prog_goto
_prog_goto
	lda	PROG_OPERAND		; Load operand value into instruction
	sta	PROG_CTR		; counter

	clc
	rts

!zone	_prog_goif
_prog_goif
	lda	#<FP0			; Use FP0 as destination for popped
	sta	GP1			; value to test
	lda	#>FP0
	sta	GP1 + 1

	jsr	prog_popval		; Pop value into FP0
	bcs	.underflow		; If no value to pop then is underflow

	lda	#<FP0			; Store FP0 address in GP0
	sta	GP0
	lda	#>FP0
	sta	GP0 + 1

	jsr	float_iszero		; Check if value is zero
	bcc	_prog_goto		; If nonzero then go to destination

	clc
	rts

.underflow
	lda	#PROG_EX_VUFLOW		; Set exit code to indicate underflow
	sta	PROG_EXIT

	sec
	rts

!zone	_prog_get
_prog_get
	lda	#>PROG_LOCALS		; Store same shared MSB of local
	sta	GP0 + 1			; variable addresses in GP0

	lda	PROG_OPERAND		; Get opcode value (label character)
	cmp	PROG_LOCLBL0		; If matches local 0 label character
	beq	.local0			; Then retrieve local 0
	cmp	PROG_LOCLBL1		; If matches local 1 label character
	beq	.local1			; Then retrieve local 1
	cmp	PROG_LOCLBL2		; If matches local 2 label character
	beq	.local2			; Then retrieve local 2

	lda	#PROG_EX_NOLOCAL	; Set exit code to indicate no local
	sta	PROG_EXIT

.local0
	lda	#<PROG_LOCAL0		; Load local 0 address LSB into GP0
	sta	GP0

	bra	.push

.local1
	lda	#<PROG_LOCAL1		; Load local 1 address LSB into GP0
	sta	GP0

	bra	.push

.local2
	lda	#<PROG_LOCAL2		; Load local 2 address LSB into GP0
	sta	GP0

.push
	jsr	prog_pushval		; Push local value to stack
	bcs	.overflow		; If no space left then is overflow

	clc
	rts

.overflow
	lda	#PROG_EX_VOFLOW		; Set exit code to indicate overflow
	sta	PROG_EXIT

	sec
	rts

!zone	_prog_set
_prog_set
	lda	#>PROG_LOCALS		; Store same shared MSB of local
	sta	GP1 + 1			; variable addresses in GP1

	lda	PROG_OPERAND		; Get operand value (label character)
	cmp	PROG_LOCLBL0		; If matches local 0 label character
	beq	.local0			; Then store value in local 0
	cmp	PROG_LOCLBL1		; If matches local 1 label character
	beq	.local1			; Then store value in local 1
	cmp	PROG_LOCLBL2		; If matches local 2 label character
	beq	.local2			; Then store value in local 2

	lda	PROG_LOCLBL0		; If local 0 label is not defined
	beq	.reserve_local0		; Then use local 0
	lda	PROG_LOCLBL1		; If local 1 label is not defined
	beq	.reserve_local1		; Then use local 1
	lda	PROG_LOCLBL2		; If local 2 label is not defined
	beq	.reserve_local2		; Then use local 2

	lda	#PROG_EX_NFLOCAL	; Set exit code to indicate no space
	sta	PROG_EXIT

.reserve_local0
	lda	PROG_OPERAND		; Store character as local 0 label
	sta	PROG_LOCLBL0

.local0
	lda	#<PROG_LOCAL0		; Load local 0 address LSB into GP1
	sta	GP1

	bra	.pop

.reserve_local1
	lda	PROG_OPERAND		; Store character as local 1 label
	sta	PROG_LOCLBL1

.local1
	lda	#<PROG_LOCAL1		; Load local 1 address LSB into GP1
	sta	GP1

	bra	.pop

.reserve_local2
	lda	PROG_OPERAND		; Store character as local 2 label
	sta	PROG_LOCLBL2

.local2
	lda	#<PROG_LOCAL2		; Load local 2 address LSB into GP1
	sta	GP1

.pop
	jsr	prog_popval		; Pop stack value into local value
	bcs	.underflow		; If no value to pop then is underflow

	clc
	rts

.underflow
	lda	#PROG_EX_VUFLOW		; Set exit code to indicate underflow
	sta	PROG_EXIT

	sec
	rts

!zone	_prog_add
_prog_add
	lda	#<float_add		; Load address of addition routine
	sta	GP2
	lda	#>float_add
	sta	GP2 + 1

	jsr	prog_floatbinop		; Perform binary operation

	rts				; Return with exit status already set

!zone	_prog_sub
_prog_sub
	lda	#<float_sub		; Load address of subtraction routine
	sta	GP2
	lda	#>float_sub
	sta	GP2 + 1

	jsr	prog_floatbinop		; Perform binary operation

	rts				; Return with exit status already set

!zone	_prog_mul
_prog_mul
	lda	#<float_mul		; Load address of multiplication routine
	sta	GP2
	lda	#>float_mul
	sta	GP2 + 1

	jsr	prog_floatbinop		; Perform binary operation

	rts				; Return with exit status already set

!zone	_prog_div
_prog_div
	lda	#<float_div		; Load address of division routine
	sta	GP2
	lda	#>float_div
	sta	GP2 + 1

	jsr	prog_floatbinop		; Perform binary operation

	rts				; Return with exit status already set

!zone	_prog_equ
_prog_equ
	lda	#<float_equ		; Load address of equality check routine
	sta	GP2
	lda	#>float_equ
	sta	GP2 + 1

	jsr	prog_floatbinop		; Perform binary operation

	rts				; Return with exit status already set

!zone	_prog_ltn
_prog_ltn
	lda	#<float_ltn		; Load address of equality check routine
	sta	GP2
	lda	#>float_ltn
	sta	GP2 + 1

	jsr	prog_floatbinop		; Perform binary operation

	rts				; Return with exit status already set

!zone	_prog_geq
_prog_geq
	lda	#<float_geq		; Load address of equality check routine
	sta	GP2
	lda	#>float_geq
	sta	GP2 + 1

	jsr	prog_floatbinop		; Perform binary operation

	rts				; Return with exit status already set

!zone	_prog_floor
_prog_floor
	lda	#<float_floorint	; Load address of floor routine
	sta	GP2
	lda	#>float_floorint
	sta	GP2 + 1

	jsr	prog_floatunop		; Perform unary operation

	rts				; Return with exit status already set

!zone	_prog_abs
_prog_abs
	lda	#<float_abs		; Load address of abs routine
	sta	GP2
	lda	#>float_abs
	sta	GP2 + 1

	jsr	prog_floatunop		; Perform unary operation

	rts				; Return with exit status already set

!zone	prog_getoperand
; Get the address of the operand data value for the current instruction.
; INPUT:	PROG_OPERAND = Index of the data value to get the address of
; OUTPUT:	C = Set if the operand index is out of range
;		GP0 = Address of operand data value
;		A = Trashed
prog_getoperand
	lda	PROG_OPERAND		; Check operand index
	cmp	PROG_DCOUNT		; If >= data value count
	bcs	.done			; Then return with C set

	sta	GP0			; Store index in GP0
	stz	GP0 + 1

	asl	GP0			; Multiply index by 8 to get data value
	rol	GP0 + 1			; address offset
	asl	GP0
	rol	GP0 + 1
	asl	GP0
	rol	GP0 + 1

	clc
	lda	GP0			; Add data base address to offset
	adc	PROG_DBASE
	sta	GP0
	lda	GP0 + 1			; Add carried result into MSB
	adc	PROG_DBASE + 1
	sta	GP0 + 1

	clc

.done
	rts

!zone	prog_pushval
; Push a value onto the value stack.
; INPUT:	GP0 = Address of value to push onto value stack
; OUTPUT:	C = Set if no space on stack to push value
;		A, Y, GP0 = Trashed
prog_pushval
	sec
	lda	PROG_VSTKPTR		; Subtract value size from value stack
	sbc	#PROG_VAL_SIZE		; to reserve space
	sta	PROG_VSTKPTR
	lda	PROG_VSTKPTR + 1	; Subtract carried result into MSB
	sbc	#0
	sta	PROG_VSTKPTR + 1

	lda	PROG_VSTKPTR + 1	; Check if value stack pointer MSB <
	cmp	PROG_ESTKPTR + 1	; execution context stack pointer
	bcc	.overflow		; If so then is overflow
	lda	PROG_VSTKPTR		; Check same for LSB
	cmp	PROG_ESTKPTR
	bcc	.overflow

	lda	PROG_VSTKPTR		; Set GP1 to address of free stack slot
	sta	GP1
	lda	PROG_VSTKPTR + 1
	sta	GP1 + 1

	jsr	float_copy		; Copy data value into stack slot

	clc
	rts

.overflow
	clc
	lda	PROG_VSTKPTR		; Add value size to value stack to
	adc	#PROG_VAL_SIZE		; restore previous value
	sta	PROG_VSTKPTR
	lda	PROG_VSTKPTR + 1	; Add carried result into MSB
	adc	#0
	sta	PROG_VSTKPTR + 1

	sec
	rts

!zone	prog_popval
; Pop a value from the value stack.
; INPUT:	GP1 = Address to copy popped value to (if $0000 then value will
;		not be copied)
; OUTPUT:	C = Set if no value is on stack
;		A, Y, GP0 = Trashed
prog_popval
	lda	PROG_VSTKPTR		; Check if value stack pointer LSB is at
	cmp	#<PROG_STACK_END	; base
	bne	.pop_vstack		; If not then pop from stack
	lda	PROG_VSTKPTR + 1	; Check same for MSB
	cmp	#>PROG_STACK_END
	bne	.pop_vstack

	sec
	rts

.pop_vstack
	lda	GP1			; If GP1 LSB != $00, then copy value
	bne	.copy
	lda	GP1 + 1			; Check same for MSB
	bne	.copy

	bra	.move_pointer

.copy
	lda	PROG_VSTKPTR		; Copy pointed value stack address to
	sta	GP0			; GP0
	lda	PROG_VSTKPTR + 1
	sta	GP0 + 1

	jsr	float_copy		; Copy value into destination address

.move_pointer
	clc
	lda	PROG_VSTKPTR		; Add value size to stack to free space
	adc	#PROG_VAL_SIZE
	sta	PROG_VSTKPTR
	lda	PROG_VSTKPTR + 1	; Add carried result into MSB
	adc	#0
	sta	PROG_VSTKPTR + 1

	clc
	rts

!zone	prog_floatunop
; Perform a floating-point operation using a unary argument (top value on value
; stack) and push the result onto the value stack.
; INPUT:	GP2 = Address of floating-point operation routine to call
; OUTPUT:	C = Set if exit code was raised
;		PROG_EXIT = Exit code denoting error encountered during
;		operation (either PROG_EX_VUFLOW or PROG_EX_VOFLOW) if C set
prog_floatunop
	lda	#<FP0			; Use FP0 as destination address for
	sta	GP1			; popped value
	lda	#>FP0
	sta	GP1 + 1

	jsr	prog_popval		; Pop value from stack into FP1
	bcs	.underflow		; If no value to pop then is underflow

	jsr	.call_routine		; Call float routine via trampoline

	lda	#<FP0			; Use FP0 as float value to push to
	sta	GP0			; value stack (result of float op)
	lda	#>FP0
	sta	GP0 + 1

	jsr	prog_pushval		; Push result in FP0 onto stack
	bcs	.overflow		; If no space left then is overflow

	clc
	rts

.call_routine
	jmp	(GP2)			; Boing!

.underflow
	lda	#PROG_EX_VUFLOW		; Set exit code to indicate underflow
	sta	PROG_EXIT

	sec
	rts

.overflow
	lda	#PROG_EX_VOFLOW		; Set exit code to indicate overflow
	sta	PROG_EXIT

	sec
	rts

!zone	prog_floatbinop
; Perform a floating-point operation using binary arguments (top 2 values on
; value stack) and push the result onto the value stack.
; INPUT:	GP2 = Address of floating-point operation routine to call
; OUTPUT:	C = Set if exit code was raised
;		PROG_EXIT = Exit code denoting error encountered during
;		operation (either PROG_EX_VUFLOW or PROG_EX_VOFLOW) if C set
;		A, X, Y, FP0-3, GP0, GP1 = Trashed (other values may also be
;		trashed yb called floating-point operation)
prog_floatbinop
	lda	#<FP1			; Use FP1 as destination address for
	sta	GP1			; popped value
	lda	#>FP1
	sta	GP1 + 1

	jsr	prog_popval		; Pop value from stack into FP1
	bcs	.underflow		; If no value to pop then is underflow

	lda	#<FP0			; Use FP0 as destination address for
	sta	GP1			; popped value
	lda	#>FP0
	sta	GP1 + 1

	jsr	prog_popval		; Pop value from stack into FP0
	bcs	.underflow		; If no value to pop then is underflow

	jsr	.call_routine		; Call float routine via trampoline

	lda	#<FP2			; Use FP2 as float value to push to
	sta	GP0			; value stack (result of float op)
	lda	#>FP2
	sta	GP0 + 1

	jsr	prog_pushval		; Push result in FP2 onto stack
	bcs	.overflow		; If no space left then is overflow

	clc
	rts

.call_routine
	jmp	(GP2)			; Boing!

.underflow
	lda	#PROG_EX_VUFLOW		; Set exit code to indicate underflow
	sta	PROG_EXIT

	sec
	rts

.overflow
	lda	#PROG_EX_VOFLOW		; Set exit code to indicate overflow
	sta	PROG_EXIT

	sec
	rts

!zone	prog_load
; Load the program from the contents data pointed to in GP0.
; INPUT:	GP0 = Address of program contents to load
; OUTPUT:	None
;		A, Y = Trashed
prog_load
	ldy	#PROG_H_IBASE		; Load instruction base address LSB
	lda	(GP0),y
	sta	PROG_IBASE
	iny				; Do same for MSB
	lda	(GP0),y
	sta	PROG_IBASE + 1

	ldy	#PROG_H_DBASE		; Load data base address LSB
	lda	(GP0),y
	sta	PROG_DBASE
	iny				; Do same for MSB
	lda	(GP0),y
	sta	PROG_DBASE + 1

	ldy	#PROG_H_ICOUNT		; Load count of instructions
	lda	(GP0),y
	sta	PROG_ICOUNT

	ldy	#PROG_H_DCOUNT		; Load count of data values
	lda	(GP0),y
	sta	PROG_DCOUNT

	stz	PROG_CTR		; Reset program counter
	stz	PROG_OPERAND		; Reset current operand

	stz	PROG_LOCLBL0		; Clear local labels
	stz	PROG_LOCLBL1
	stz	PROG_LOCLBL2

	rts

!zone	prog_run
; Run the currently loaded program through to completion.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, FP0-3, GP0-2 = Trashed
prog_run
	jsr	prog_step		; Step current program
	bcc	prog_run		; If not finished then step again

	rts

!zone	prog_builtin
; Find a built-in program based on its name (maximum 8 characters) and load it
; as the program currently being executed.
; INPUT:	GP0 = Address of program name string to load
; OUTPUT:	C = Set if no built-in program with the provided name exists
;		GP0 = Address of found program contents
;		A, Y, GP0, GP1 = Trashed
; VARIABLES:	GP1 = Address of current entry in program table
prog_builtin
	lda	#<PROGS			; Store address of program table in GP1
	sta	GP1
	lda	#>PROGS
	sta	GP1 + 1

.find_loop
	ldy	#0			; Use Y as index into current entry
	lda	(GP1),y			; Get first byte of current entry
	beq	.not_found		; If null then end of table

.str_loop
	lda	(GP0),y			; Get character from search string
	cmp	(GP1),y			; Compare with char from current entry
	bne	.next_entry		; If not same then go to next entry
	cmp	#0			; If both are null chars then found
	beq	.found

	iny

	cpy	#8			; Repeat for 8 characters
	bcc	.str_loop

	bra	.found

.next_entry
	clc
	lda	GP1
	adc	#$0A
	sta	GP1
	lda	GP1 + 1
	adc	#0
	sta	GP1 + 1

	bra	.find_loop

.found
	ldy	#8			; Store contents address LSB in GP0 LSB
	lda	(GP1),y
	sta	GP0
	iny				; Do same for MSB
	lda	(GP1),y
	sta	GP0 + 1

	jsr	prog_load		; Load program using contents address

	clc
	rts

.not_found
	sec
	rts

!zone	prog_askinputs
; Ask for values to use as inputs to a program to run based on the program's
; signature referenced in GP0, and push those inputs to the stack.
; INPUT:	GP0 = Address of signature to read
; OUTPUT:	C = Set if the user cancelled input entry
;		A, X, Y, GP0-7, FP0, CALC_STACK_X = Trashed
prog_askinputs
	lda	GP0			; Store signature address in GP6
	sta	GP6
	lda	GP0 + 1
	sta	GP6 + 1

	stz	GP7			; Use GP7 as index into signature

.loop
	jsr	gfx_clear		; Clear display

	ldy	GP7			; Transfer index into Y
	lda	(GP6),y			; Get current character in signature
	beq	.confirm		; If null then finish asking for inputs
	cmp	#'>'			; If delimter then also finish
	beq	.confirm

	ldx	#0
	jsr	gfx_dispchar		; Show signature character as prompt

	lda	#'?'
	ldx	#1
	jsr	gfx_dispchar		; Display question mark after character

	jsr	fio_input		; Wait for user to enter float value
	bcs	.cancel			; If cancelled, then don't ask next val

	lda	#<FP0			; Load address of entered value into GP0
	sta	GP0
	lda	#>FP0
	sta	GP0 + 1

	jsr	prog_pushval		; Push entered value to value stack
	bcs	.cancel			; If no space then cancel (unlikely)

	inc	GP7

	bra	.loop

.cancel
	sec
	rts

.confirm
	clc
	rts