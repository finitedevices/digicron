; BUILT-IN TRIGONOMETRY PROGRAMS
; Trigonometry functions for computing the sine, cosine and tangent of values.

PROGS_COS
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_COS_INST		; PROG_H_IBASE
	!word	PROGS_COS_DATA		; PROG_H_DBASE
	!byte	$1F			; PROG_H_ICOUNT
	!byte	$07			; PROG_H_DCOUNT

PROGS_COS_INST
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_MUL,	$00	; Multiply input by itself to square
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'x'	; Store squared input into x
	!byte	PROG_OP_SET,	'n'	; Store in n

	!byte	PROG_OP_PUSH,	$06	; Use i as count of iterations remaining
	!byte	PROG_OP_SET,	'i'

	!byte	PROG_OP_PUSH,	$05	; Push factorials of even numbers from
	!byte	PROG_OP_PUSH,	$04	; 10! to 2! alternating in sign
	!byte	PROG_OP_PUSH,	$03
	!byte	PROG_OP_PUSH,	$02
	!byte	PROG_OP_PUSH,	$01
	!byte	PROG_OP_PUSH,	$00	; Push starting value of 1

	!byte	PROG_OP_SWAP,	$00	; Swap result with factorial to use
	!byte	PROG_OP_GET,	'n'	; Get current numerator
	!byte	PROG_OP_SWAP,	$00	; Swap to divide numerator by factorial
	!byte	PROG_OP_DIV,	$00
	!byte	PROG_OP_ADD,	$00	; Add to result

	!byte	PROG_OP_GET,	'n'	; Get current numerator
	!byte	PROG_OP_GET,	'x'	; Get input as squared factor
	!byte	PROG_OP_MUL,	$00	; Multiply to increment power by 2
	!byte	PROG_OP_SET,	'n'	; Store back as current numerator

	!byte	PROG_OP_GET,	'i'	; Decrement iteration count
	!byte	PROG_OP_PUSH,	$00
	!byte	PROG_OP_SUB,	$00
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'i'

	!byte	PROG_OP_GOIF,	$0D	; If nonzero then process next term

	!byte	PROG_OP_RETURN,	$00

PROGS_COS_DATA
	!byte	$10, $00, $00, $00, $00, $00, $00, $00		; 1
	!byte	$20, $00, $00, $00, $00, $00, $00, FLOAT_S_MNEG	; -2!
	!byte	$24, $00, $00, $00, $00, $00, $01, $00		; 4!
	!byte	$72, $00, $00, $00, $00, $00, $02, FLOAT_S_MNEG	; -6!
	!byte	$40, $32, $00, $00, $00, $00, $04, $00		; 8!
	!byte	$36, $28, $80, $00, $00, $00, $06, FLOAT_S_MNEG	; -10!
	!byte	$50, $00, $00, $00, $00, $00, $00, $00		; 5