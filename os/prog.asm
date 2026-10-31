; PROGRAM EXECUTION ENGINE
; Executes stack-based programs using a custom bytecode format.

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

	rts