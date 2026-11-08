; PROGRAM EXECUTION ENGINE
; Executes stack-based programs using a custom bytecode format.

; Program opcode dispatch table
PROG_OPCODES
	PROG_OP_NONE	= $00
	!word	_prog_none
	PROG_OP_RETURN	= $01
	!word	_prog_return
	PROC_OP_PUSH	= $02
	!word	_prog_push
	PROC_OP_POP	= $03
	!word	_prog_pop
	PROC_OP_DUP	= $04
	!word	_prog_dup
	PROG_OP_GOTO	= $05
	!word	_prog_goto
	PROG_OP_ADD	= $06
	!word	_prog_add
	PROG_OP_SUB	= $07
	!word	_prog_sub
	PROG_OP_MUL	= $08
	!word	_prog_mul
	PROG_OP_DIV	= $09
	!word	_prog_div

PROG_N_OPCODES	= $0A			; Number of opcodes defined in table

PROG_VAL_SIZE	= FLOAT_SIZE		; Size of values on value stack

; Program exit codes (enum)
PROG_EX_OK	= $00			; Exited without error
PROG_EX_ILLEGAL	= $01			; Illegal opcode
PROG_EX_OPERAND	= $02			; Invalid operand value
PROG_EX_VOFLOW	= $03			; Overflow of value stack
PROG_EX_EOFLOW	= $04			; Overflow of execution context stack
PROG_EX_VUFLOW	= $05			; Underflow of value stack

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

	stz	PROG_CTR		; Reset program counter
	stz	PROG_OPERAND		; Reset current operand

	rts

!zone	prog_step
; Step the program that is currently being executed.
; INPUT:	None
; OUTPUT:	C = Set if program execution has finished
;		A, Y, GP0 = Trashed
; VARIABLES:	GP0 = Dispatch address for opcodes table
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

	jmp	(GP0)			; Execute pointed address

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
	sbc	#8			; from stack
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
	lda	PROG_VSTKPTR
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

!zone	_prog_goto
_prog_goto
	lda	PROG_OPCODE		; Load opcode value into instruction
	sta	PROG_CTR		; counter

	clc
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

!zone	prog_floatbinop
; Perform a floating-point operation using binary arguments (top 2 values on
; value stack) and push the result onto the value stack.
; INPUT:	GP2 = Address of floating-point operation routine to call
; OUTPUT:	C = Set if exit code was raised
;		PROG_EXIT = Exit code denoting error encountered during
;		operation (either PROG_EX_VUFLOW or PROG_EX_VOFLOW) if C set
;		A, X, Y, FP0-3, GP0-2 = Trashed
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