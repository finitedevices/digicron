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
	!byte	$42			; PROG_H_ICOUNT
	!byte	$0E			; PROG_H_DCOUNT
	!word	$0000

PROGS_TAN_INST
	!byte	PROG_OP_DUP,	$00	; Save pre-modulo input for later
	!byte	PROG_OP_ABS,	$00	; Use abs value for improved accuracy
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_PUSH,	$0A	; Push PI
	!byte	PROG_OP_DIV,	$00	; Divide input by PI to get half turns
	!byte	PROG_OP_FLOOR,	$00	; Compute floor to get nearest half turn
	!byte	PROG_OP_PUSH,	$0A	; Push PI
	!byte	PROG_OP_MUL,	$00	; Multiply to convert back into radians
	!byte	PROG_OP_SUB,	$00	; Subtract from original to get modulo

	!byte	PROG_OP_DUP,	$00	; Save pre-mirrored input for later
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_PUSH,	$0B	; Push PI / 2
	!byte	PROG_OP_LTN,	$00	; If modulo result < PI / 2
	!byte	PROG_OP_GOIF,	$11	; Then don't mirror at point of symmetry

	!byte	PROG_OP_PUSH,	$0A	; Push PI
	!byte	PROG_OP_SWAP,	$00	; Swap with modulo result
	!byte	PROG_OP_SUB,	$00	; Subtract modulo from PI

	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'n'	; Store input into n
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_MUL,	$00	; Multiply input by itself to square
	!byte	PROG_OP_SET,	'x'	; Store squared input into x

	!byte	PROG_OP_PUSH,	$09	; Use i as count of iterations remaining
	!byte	PROG_OP_SET,	'i'

	!byte	PROG_OP_PUSH,	$07	; Push denominators for cot(x) Taylor
	!byte	PROG_OP_PUSH,	$06	; series
	!byte	PROG_OP_PUSH,	$05
	!byte	PROG_OP_PUSH,	$04
	!byte	PROG_OP_PUSH,	$03
	!byte	PROG_OP_PUSH,	$02
	!byte	PROG_OP_PUSH,	$01
	!byte	PROG_OP_PUSH,	$00

	!byte	PROG_OP_PUSH,	$08	; Push starting value of 1 / X
	!byte	PROG_OP_GET,	'n'
	!byte	PROG_OP_DIV,	$00

	!byte	PROG_OP_SWAP,	$00	; Swap result with denominator to use
	!byte	PROG_OP_GET,	'n'	; Get current numerator
	!byte	PROG_OP_SWAP,	$00	; Swap to divide numerator by denom
	!byte	PROG_OP_DIV,	$00
	!byte	PROG_OP_SUB,	$00	; Subtract from result

	!byte	PROG_OP_GET,	'n'	; Get current numerator
	!byte	PROG_OP_GET,	'x'	; Get input as squared factor
	!byte	PROG_OP_MUL,	$00	; Multiply to increment power by 2
	!byte	PROG_OP_SET,	'n'	; Store back as current numerator

	!byte	PROG_OP_GET,	'i'	; Decrement iteration count
	!byte	PROG_OP_PUSH,	$08
	!byte	PROG_OP_SUB,	$00
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'i'

	!byte	PROG_OP_GOIF,	$23	; If nonzero then process next term

	!byte	PROG_OP_PUSH,	$08	; Find reciprocal, since
	!byte	PROG_OP_SWAP,	$00	; tan(x) = 1 / cot(x)
	!byte	PROG_OP_DIV,	$00

	!byte	PROG_OP_SWAP,	$00	; Swap to get pre-mirrored input
	!byte	PROG_OP_PUSH,	$0B	; Push PI / 2
	!byte	PROG_OP_LTN,	$00	; If pre-mirrored result < PI / 2
	!byte	PROG_OP_GOIF,	$3B	; Then don't negate

	!byte	PROG_OP_PUSH,	$0D	; Multiply by -1 to negate result past
	!byte	PROG_OP_MUL,	$00	; point of symmetry

	!byte	PROG_OP_SWAP,	$00	; Swap to get pre-modulo input
	!byte	PROG_OP_PUSH,	$0C	; Push 0
	!byte	PROG_OP_LTN,	$00	; If pre-modulo result < 0
	!byte	PROG_OP_GOIF,	$40	; Then negate

	!byte	PROG_OP_RETURN,	$00	; Don't negate

	!byte	PROG_OP_PUSH,	$0D	; Multiply by -1 to negate result for
	!byte	PROG_OP_MUL,	$00	; negative inputs

PROGS_TAN_DATA
	!byte	$30, $00, $00, $00, $00, $00, $00, $00		; 3
	!byte	$45, $00, $00, $00, $00, $00, $01, $00		; 45
	!byte	$47, $25, $00, $00, $00, $00, $02, $00		; 945 / 2
	!byte	$47, $25, $00, $00, $00, $00, $03, $00		; 4725
	!byte	$46, $77, $75, $00, $00, $00, $04, $00		; 93555 / 2
	!byte	$46, $20, $20, $89, $36, $32, $05, $00		; 6.39E8 / 1382
	!byte	$45, $60, $80, $62, $50, $00, $06, $00		; 1.82E7 / 4
	!byte	$45, $01, $54, $22, $48, $41, $07, $00		; 1.62E11 / 3617
	!byte	$10, $00, $00, $00, $00, $00, $00, $00		; 1
	!byte	$80, $00, $00, $00, $00, $00, $00, $00		; 8
	!byte	$31, $41, $59, $26, $53, $59, $00, $00		; PI
	!byte	$15, $70, $79, $63, $26, $80, $00, $00		; PI / 2
	!byte	$00, $00, $00, $00, $00, $00, $00, $00		; 0
	!byte	$10, $00, $00, $00, $00, $00, $00, FLOAT_S_MNEG	; -1

PROGS_ASIN
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_ASIN_INST		; PROG_H_IBASE
	!word	PROGS_ASIN_DATA		; PROG_H_DBASE
	!byte	$2D			; PROG_H_ICOUNT
	!byte	$0D			; PROG_H_DCOUNT
	!word	$0000

PROGS_ASIN_INST
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_ABS,	$00	; Get absolute value of input
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_PUSH,	$00
	!byte	PROG_OP_EQU,	$00	; If |X| = 1
	!byte	PROG_OP_GOIF,	$0C	; Then compute approximation
	!byte	PROG_OP_PUSH,	$00
	!byte	PROG_OP_LTN,	$00	; If |X| < 1
	!byte	PROG_OP_GOIF,	$0C	; Then compute approximation

	!byte	PROG_OP_POP,	$00
	!byte	PROG_OP_PUSH,	$0C	; Return NaN instead (outside of domain
	!byte	PROG_OP_RETURN, $00	; [-1, 1])

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

	!byte	PROG_OP_GOIF,	$1E	; If nonzero then process next term

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
	!byte	$90, $00, $00, $00, $00, $00, $00, $00		; 9
	!byte	$00, $00, $00, $00, $00, $00, $00, $00		; 0
	!byte	$00, $00, $00, $00, $00, $00, $00, FLOAT_S_NAN	; NaN