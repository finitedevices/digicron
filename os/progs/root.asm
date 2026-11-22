; BUILT-IN ROOT FINDING PROGRAMS
; Functions to find the square root and other roots for use within the
; Calculator mode and other programs.

PROGS_SQRT
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_SQRT_INST		; PROG_H_IBASE
	!word	PROGS_SQRT_DATA		; PROG_H_DBASE
	!byte	$17			; PROG_H_ICOUNT
	!byte	$05			; PROG_H_DCOUNT
	!word	$0000

PROGS_SQRT_INST
	!byte	PROG_OP_FSPLIT,	$00	; Split float into mantissa and exponent
	!byte	PROG_OP_SET,	'e'	; Store exponent in e
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'm'	; Store mantissa in m

	!byte	PROG_OP_PUSH,	$00	; Use i as count of iterations remaining
	!byte	PROG_OP_SET,	'i'

	!byte	PROG_OP_PUSH,	$01	; Find initial estimate using formula
	!byte	PROG_OP_MUL,	$00	; (m * 0.28) + 0.89
	!byte	PROG_OP_PUSH,	$02
	!byte	PROG_OP_ADD,	$00

	!byte	PROG_OP_DUP,	$00	; Duplicate current estimate
	!byte	PROG_OP_GET,	'm'	; Get mantissa
	!byte	PROG_OP_SWAP,	$00	; Swap to divide mantissa by estimate
	!byte	PROG_OP_DIV,	$00
	!byte	PROG_OP_ADD,	$00	; Add current estimate
	!byte	PROG_OP_PUSH,	$03	; Divide by 2
	!byte	PROG_OP_DIV,	$00

	!byte	PROG_OP_GET,	'i'	; Decrement iteration count
	!byte	PROG_OP_PUSH,	$04
	!byte	PROG_OP_SUB,	$00
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'i'

	!byte	PROG_OP_GOIF,	$0A	; If nonzero then compute next estimate

PROGS_SQRT_DATA
	!byte	$30, $00, $00, $00, $00, $00, $00, $00		; 3
	!byte	$28, $00, $00, $00, $00, $00, $01, FLOAT_S_ENEG	; 0.28
	!byte	$89, $00, $00, $00, $00, $00, $01, FLOAT_S_ENEG	; 0.89
	!byte	$20, $00, $00, $00, $00, $00, $00, $00		; 2
	!byte	$10, $00, $00, $00, $00, $00, $00, $00		; 1