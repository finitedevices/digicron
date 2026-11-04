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
	PROG_OP_GOTO	= $03
	!word	_prog_goto

PROG_N_OPCODES	= $04			; Number of opcodes defined in table

PROG_VAL_SIZE	= FLOAT_SIZE		; Size of values on value stack

; Program exit codes (enum)
PROG_EX_OK	= $00			; Exited without error
PROG_EX_ILLEGAL	= $01			; Illegal opcode
PROG_EX_OPERAND	= $02			; Invalid operand value
PROG_EX_VOFLOW	= $03			; Overflow of value stack
PROG_EX_EOFLOW	= $04			; Overflow of execution context stack

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

_prog_none
	clc
	rts

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

_prog_push
	jsr	prog_getoperand		; Get address value to push in GP0
	bcs	.invalid_operand	; If out of range then invalid operand

	jsr	prog_pushval		; Push retrieved value onto stack
	bcs	.overflow		; If no space left then is overflow

	clc
	rts

.overflow
	lda	#PROG_EX_EOFLOW		; Set exit code to indicate overflow
	sta	PROG_EXIT

	sec
	rts

.invalid_operand
	lda	#PROG_EX_OPERAND	; Set exit code to indicate invalid
	sta	PROG_EXIT		; operand

	sec
	rts

_prog_goto
	lda	PROG_OPCODE		; Load opcode value into instruction
	sta	PROG_CTR		; counter

	clc
	rts

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