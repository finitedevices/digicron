; BUILT-IN TRIGONOMETRY PROGRAMS
; Trigonometry functions for computing the sine, cosine and tangent of values.

PROGS_SIN
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_SIN_INST		; PROG_H_IBASE
	!word	PROGS_SIN_DATA		; PROG_H_DBASE
	!byte	$04			; PROG_H_ICOUNT
	!byte	$02			; PROG_H_DCOUNT
	!word	$0000

PROGS_SIN_INST
	!byte	PROG_OP_PUSH,	$00	; Push PI / 2
	!byte	PROG_OP_SWAP,	$00
	!byte	PROG_OP_SUB,	$00	; Subtract input from PI / 2
	!byte	PROG_OP_CALL,	$01	; Call COS function

PROGS_SIN_DATA
	!byte	$15, $70, $79, $63, $26, $80, $00, $00		; PI / 2
	!raw	"COS", 0, 0, 0, 0, 0

PROGS_COS
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_COS_INST		; PROG_H_IBASE
	!word	PROGS_COS_DATA		; PROG_H_DBASE
	!byte	$3C			; PROG_H_ICOUNT
	!byte	$0F			; PROG_H_DCOUNT
	!word	$0000

PROGS_COS_INST
	!byte	PROG_OP_ABS,	$00	; Get absolute value of input
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
	!byte	PROG_OP_GOIF,	$0F	; Then don't mirror at point of symmetry

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

	!byte	PROG_OP_GOIF,	$1F	; If nonzero then process next term

	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_ABS,	$00
	!byte	PROG_OP_PUSH,	$0D	; Push 1E-11 (epsilon)
	!byte	PROG_OP_LTN,	$00	; If result < epsilon
	!byte	PROG_OP_GOIF,	$3A	; Then return 0

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

PROGS_TAN
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_TAN_INST		; PROG_H_IBASE
	!word	PROGS_TAN_DATA		; PROG_H_DBASE
	!byte	$05			; PROG_H_ICOUNT
	!byte	$02			; PROG_H_DCOUNT
	!word	$0000

PROGS_TAN_INST
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_CALL,	$00	; Compute sine of input
	!byte	PROG_OP_SWAP,	$00
	!byte	PROG_OP_CALL,	$01	; Compute cosine of input
	!byte	PROG_OP_DIV,	$00	; Divide sine by cosine to get tangent

PROGS_TAN_DATA
	!raw	"SIN", 0, 0, 0, 0, 0
	!raw	"COS", 0, 0, 0, 0, 0

PROGS_ASIN
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_ASIN_INST		; PROG_H_IBASE
	!word	PROGS_ASIN_DATA		; PROG_H_DBASE
	!byte	$4C			; PROG_H_ICOUNT
	!byte	$10			; PROG_H_DCOUNT
	!word	$0000

PROGS_ASIN_INST
	!byte	PROG_OP_DUP,	$00	; Keep original input on stack
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_ABS,	$00	; Get absolute value of input
	!byte	PROG_OP_PUSH,	$00
	!byte	PROG_OP_EQU,	$00	; If |X| = 1
	!byte	PROG_OP_GOIF,	$14	; Then compute identity approximation
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_ABS,	$00	; Get absolute value of input
	!byte	PROG_OP_PUSH,	$0D
	!byte	PROG_OP_LTN,	$00	; If |X| < 0.7071
	!byte	PROG_OP_GOIF,	$1A	; Then compute regular approximation
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_ABS,	$00	; Get absolute value of input
	!byte	PROG_OP_PUSH,	$00
	!byte	PROG_OP_LTN,	$00	; If |X| < 1
	!byte	PROG_OP_GOIF,	$14	; Then compute identity approximation

	!byte	PROG_OP_POP,	$00
	!byte	PROG_OP_POP,	$00
	!byte	PROG_OP_PUSH,	$0C	; Return NaN instead (outside of domain
	!byte	PROG_OP_RETURN, $00	; [-1, 1])

	!byte	PROG_OP_DUP,	$00	; Square input
	!byte	PROG_OP_MUL,	$00
	!byte	PROG_OP_PUSH,	$00	; Push 1
	!byte	PROG_OP_SWAP,	$00	; Swap 1 with squared input
	!byte	PROG_OP_SUB,	$00	; Compute 1 - (input ^ 2)
	!byte	PROG_OP_CALL,	$0E	; Call square root function

	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'n'	; Store input into n
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_MUL,	$00	; Multiply input by itself to square
	!byte	PROG_OP_SET,	'x'	; Store squared input into x

	!byte	PROG_OP_PUSH,	$0A	; Use i as count of iterations remaining
	!byte	PROG_OP_SET,	'i'

	!byte	PROG_OP_PUSH,	$09	; Push denominators for asin(x) Taylor
	!byte	PROG_OP_PUSH,	$08	; series
	!byte	PROG_OP_PUSH,	$07
	!byte	PROG_OP_PUSH,	$06
	!byte	PROG_OP_PUSH,	$05
	!byte	PROG_OP_PUSH,	$04
	!byte	PROG_OP_PUSH,	$03
	!byte	PROG_OP_PUSH,	$02
	!byte	PROG_OP_PUSH,	$01
	!byte	PROG_OP_PUSH,	$00

	!byte	PROG_OP_PUSH,	$0B	; Push starting value of 0

	!byte	PROG_OP_SWAP,	$00	; Swap result with denominator to use
	!byte	PROG_OP_GET,	'n'	; Get current numerator
	!byte	PROG_OP_SWAP,	$00	; Swap to divide numerator by denom
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

	!byte	PROG_OP_GOIF,	$2C	; If nonzero then process next term

	!byte	PROG_OP_SWAP,	$00	; Get original input
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'n'	; Now use n to store original input
	!byte	PROG_OP_ABS,	$00	; Get absolute value of input
	!byte	PROG_OP_PUSH,	$0D
	!byte	PROG_OP_LTN,	$00	; If |X| < 0.7071
	!byte	PROG_OP_GOIF,	$FF	; Then return as is

	!byte	PROG_OP_GET,	'n'	; Get original input
	!byte	PROG_OP_PUSH,	$0B	; Push 0
	!byte	PROG_OP_LTN,	$00	; If original input is negative
	!byte	PROG_OP_GOIF,	$4A	; Then use negative identity

	!byte	PROG_OP_PUSH,	$0F	; Push PI / 2
	!byte	PROG_OP_SWAP,	$00	; Swap PI / 2 with result
	!byte	PROG_OP_SUB,	$00	; Subtract result from PI / 2
	!byte	PROG_OP_RETURN,	$00

	!byte	PROG_OP_PUSH,	$0F	; Push PI / 2
	!byte	PROG_OP_SUB,	$00	; Sub PI / 2 from result (to make -ve)

PROGS_ASIN_DATA
	!byte	$10, $00, $00, $00, $00, $00, $00, $00		; 1
	!byte	$60, $00, $00, $00, $00, $00, $00, $00		; 6
	!byte	$13, $33, $33, $33, $33, $33, $01, $00		; 40 / 3
	!byte	$22, $40, $00, $00, $00, $00, $01, $00		; 112 / 5
	!byte	$32, $91, $42, $85, $71, $43, $01, $00		; 1152 / 35
	!byte	$44, $69, $84, $12, $69, $84, $01, $00		; 2816 / 63
	!byte	$57, $62, $77, $05, $62, $77, $01, $00		; 13312 / 231
	!byte	$71, $60, $83, $91, $60, $84, $01, $00		; 10240 / 143
	!byte	$86, $56, $65, $88, $96, $66, $01, $00		; 557056 / 6435
	!byte	$86, $56, $65, $88, $96, $66, $01, $00		; 1.25E6 / 12155
	!byte	$10, $00, $00, $00, $00, $00, $01, $00		; 10
	!byte	$00, $00, $00, $00, $00, $00, $00, $00		; 0
	!byte	$00, $00, $00, $00, $00, $00, $00, FLOAT_S_NAN	; NaN
	!byte	$70, $71, $06, $78, $11, $87, $01, FLOAT_S_ENEG	; 1 / SQRT(2)
	!raw	"SQRT", 0, 0, 0, 0
	!byte	$15, $70, $79, $63, $26, $80, $00, $00		; PI / 2