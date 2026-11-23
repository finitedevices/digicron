; BUILT-IN ROOT FINDING PROGRAMS
; Functions to find the square root and other roots for use within the
; Calculator mode and other programs.

PROGS_SQRT
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_SQRT_INST		; PROG_H_IBASE
	!word	PROGS_SQRT_DATA		; PROG_H_DBASE
	!byte	$32			; PROG_H_ICOUNT
	!byte	$08			; PROG_H_DCOUNT
	!word	$0000

PROGS_SQRT_INST
	!byte	PROG_OP_FSPLIT,	$00	; Split float into mantissa and exponent
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'e'	; Store exponent in e

	!byte	PROG_OP_ABS,	$00	; Find abs value in order to use floor
	!byte	PROG_OP_PUSH,	$03	; Divide exponent by 2
	!byte	PROG_OP_DIV,	$00
	!byte	PROG_OP_DUP,	$00	; Duplicate divided exponent
	!byte	PROG_OP_FLOOR,	$00	; Find floor of divided exponent
	!byte	PROG_OP_EQU,	$00	; Check if no remainder
	!byte	PROG_OP_GOIF,	$17	; If so then is even; no change needed

	!byte	PROG_OP_GET,	'e'	; Get exponent
	!byte	PROG_OP_PUSH,	$04	; Decrement by 1
	!byte	PROG_OP_SUB,	$00
	!byte	PROG_OP_SET,	'e'

	!byte	PROG_OP_PUSH,	$05	; Push 10
	!byte	PROG_OP_MUL,	$00	; Multiply mantissa by 10
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'm'	; Store mantissa in m

	!byte	PROG_OP_PUSH,	$06	; Find initial estimate using formula
	!byte	PROG_OP_MUL,	$00	; (m * 0.089) + 2.8
	!byte	PROG_OP_PUSH,	$07
	!byte	PROG_OP_ADD,	$00

	!byte	PROG_OP_GOTO,	$1D	; Start estimate computation

	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'm'	; Store mantissa in m

	!byte	PROG_OP_PUSH,	$01	; Find initial estimate using formula
	!byte	PROG_OP_MUL,	$00	; (m * 0.28) + 0.89
	!byte	PROG_OP_PUSH,	$02
	!byte	PROG_OP_ADD,	$00

	!byte	PROG_OP_PUSH,	$00	; Use i as count of iterations remaining
	!byte	PROG_OP_SET,	'i'

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

	!byte	PROG_OP_GOIF,	$1F	; If nonzero then compute next estimate

	!byte	PROG_OP_FSPLIT,	$00	; Split result float
	!byte	PROG_OP_GET,	'e'	; Get input exponent
	!byte	PROG_OP_PUSH,	$03	; Divide exponent by 2
	!byte	PROG_OP_DIV,	$00
	!byte	PROG_OP_ADD,	$00	; Add input exponent to result
	!byte	PROG_OP_FJOIN,	$00	; Join to form scaled result float

PROGS_SQRT_DATA
	!byte	$30, $00, $00, $00, $00, $00, $00, $00		; 3
	!byte	$28, $00, $00, $00, $00, $00, $01, FLOAT_S_ENEG	; 0.28
	!byte	$89, $00, $00, $00, $00, $00, $01, FLOAT_S_ENEG	; 0.89
	!byte	$20, $00, $00, $00, $00, $00, $00, $00		; 2
	!byte	$10, $00, $00, $00, $00, $00, $00, $00		; 1
	!byte	$10, $00, $00, $00, $00, $00, $01, $00		; 10
	!byte	$89, $00, $00, $00, $00, $00, $02, FLOAT_S_ENEG	; 0.089
	!byte	$28, $00, $00, $00, $00, $00, $00, $00		; 2.8