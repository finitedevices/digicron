; BUILT-IN TRIGONOMETRY PROGRAMS
; Trigonometry functions for computing the sine, cosine and tangent of values.

PROGS_COS
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_COS_INST		; PROG_H_IBASE
	!word	PROGS_COS_DATA		; PROG_H_DBASE
	!byte	$3B			; PROG_H_ICOUNT
	!byte	$0E			; PROG_H_DCOUNT

PROGS_COS_INST
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_PUSH,	$0A	; Push 2 * PI
	!byte	PROG_OP_DIV,	$00	; Divide input by 2 * PI to get turns
	!byte	PROG_OP_FLOOR,	$00	; Compute floor to get nearest turn
	!byte	PROG_OP_PUSH,	$0A	; Push 2 * PI
	!byte	PROG_OP_MUL,	$00	; Multiply to convert back into radians
	!byte	PROG_OP_SUB,	$00	; Subtract from original to get modulo

	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_PUSH,	$0B	; Push PI
	!byte	PROG_OP_LTN,	$00	; If modulo result < PI
	!byte	PROG_OP_GOIF,	$0E	; Then don't mirror at point of symmetry

	!byte	PROG_OP_PUSH,	$0A	; Push 2 * PI
	!byte	PROG_OP_SWAP,	$00	; Swap with modulo result
	!byte	PROG_OP_SUB,	$00	; Subtract modulo from 2 * PI

	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_MUL,	$00	; Multiply input by itself to square
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'x'	; Store squared input into x
	!byte	PROG_OP_SET,	'n'	; Store in n

	!byte	PROG_OP_PUSH,	$09	; Use i as count of iterations remaining
	!byte	PROG_OP_SET,	'i'

	!byte	PROG_OP_PUSH,	$08	; Push factorials of even numbers from
	!byte	PROG_OP_PUSH,	$07	; 16! to 2! alternating in sign
	!byte	PROG_OP_PUSH,	$06
	!byte	PROG_OP_PUSH,	$05
	!byte	PROG_OP_PUSH,	$04
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

	!byte	PROG_OP_GOIF,	$1E	; If nonzero then process next term

	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_ABS,	$00
	!byte	PROG_OP_PUSH,	$0D	; Push 1E-11 (epsilon)
	!byte	PROG_OP_LTN,	$00	; If result < epsilon
	!byte	PROG_OP_GOIF,	$39	; Then return 0

	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_PUSH,	$0C	; Push -1
	!byte	PROG_OP_GEQ,	$00	; If result >= -1
	!byte	PROG_OP_GOIF,	$FF	; Then return result

	!byte	PROG_OP_POP,	$00	; Otherwise bound result to -1
	!byte	PROG_OP_PUSH,	$0C
	!byte	PROG_OP_RETURN,	$00

	!byte	PROG_OP_POP,	$00	; Otherwise bound result to 0
	!byte	PROG_OP_PUSH,	$0E

PROGS_COS_DATA
	!byte	$10, $00, $00, $00, $00, $00, $00, $00		; 1
	!byte	$20, $00, $00, $00, $00, $00, $00, FLOAT_S_MNEG	; -2!
	!byte	$24, $00, $00, $00, $00, $00, $01, $00		; 4!
	!byte	$72, $00, $00, $00, $00, $00, $02, FLOAT_S_MNEG	; -6!
	!byte	$40, $32, $00, $00, $00, $00, $04, $00		; 8!
	!byte	$36, $28, $80, $00, $00, $00, $06, FLOAT_S_MNEG	; -10!
	!byte	$47, $90, $01, $60, $00, $00, $08, $00		; 12!
	!byte	$87, $17, $82, $91, $20, $00, $10, FLOAT_S_MNEG	; -14!
	!byte	$20, $92, $27, $89, $88, $80, $13, $00		; 16!
	!byte	$80, $00, $00, $00, $00, $00, $00, $00		; 8
	!byte	$62, $83, $18, $53, $07, $18, $00, $00		; 2 * PI
	!byte	$31, $41, $59, $26, $53, $59, $00, $00		; PI
	!byte	$10, $00, $00, $00, $00, $00, $00, FLOAT_S_MNEG	; -1
	!byte	$10, $00, $00, $00, $00, $00, $11, FLOAT_S_ENEG	; 1E-11
	!byte	$00, $00, $00, $00, $00, $00, $00, $00		; 0