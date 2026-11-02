; PROGRAM EXECUTION ENGINE
; Executes stack-based programs using a custom bytecode format.

; Program opcode dispatch table
PROG_OPCODES
	PROG_OP_NONE	= $00
	!word	_prog_none
	PROG_OP_RETURN	= $01
	!word	_prog_return
	PROG_OP_GOTO	= $02
	!word	_prog_goto

PROG_N_OPCODES	= $03

; Program exit codes (enum)
PROG_EX_OK	= $00			; Exited without error
PROG_EX_ILLEGAL	= $01			; Exit caused by illegal opcode

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

_prog_goto
	lda	PROG_OPCODE		; Load opcode value into instruction
	sta	PROG_CTR		; counter

	clc
	rts