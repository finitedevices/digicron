; BUILT-IN PROGRAM INDEX
; A table of names of built-in programs and addresses to their contents.

PROGS
PROGS_POW2_IDX
	!raw	"X", '2' | $80, 0, 0, 0, 0, 0, 0
	!word	PROGS_POW2
PROGS_POW3_IDX
	!raw	"X", '3' | $80, 0, 0, 0, 0, 0, 0
	!word	PROGS_POW3
PROGS_POW_IDX
	!raw	"B^X", 0, 0, 0, 0, 0
	!word	PROGS_POW
	!byte	$00

PROGS_POW2
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_POW2_INST		; PROG_H_IBASE
	!word	$0000			; PROG_H_DBASE
	!byte	$03			; PROG_H_ICOUNT
	!byte	$00			; PROG_H_DCOUNT
	!word	$0000

PROGS_POW2_INST
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_MUL,	$00
	!byte	PROG_OP_RETURN,	$00

PROGS_POW3
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_POW3_INST		; PROG_H_IBASE
	!word	$0000			; PROG_H_DBASE
	!byte	$05			; PROG_H_ICOUNT
	!byte	$00			; PROG_H_DCOUNT
	!word	$0000

PROGS_POW3_INST
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_MUL,	$00
	!byte	PROG_OP_MUL,	$00
	!byte	PROG_OP_RETURN,	$00

PROGS_POW
	!raw	"BX>A", 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_POW_INST		; PROG_H_IBASE
	!word	PROGS_POW_DATA		; PROG_H_DBASE
	!byte	$13			; PROG_H_ICOUNT
	!byte	$01			; PROG_H_DCOUNT
	!word	$0000

; TODO: Make POW program compute non-integer powers

PROGS_POW_INST
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_GOIF,	$05
	!byte	PROG_OP_POP,	$00
	!byte	PROG_OP_PUSH,	$00
	!byte	PROG_OP_RETURN, $00
	!byte	PROG_OP_SET,	'x'
	!byte	PROG_OP_DUP,	$00
	!byte	PROG_OP_SET,	'b'
	!byte	PROG_OP_GET,	'x'
	!byte	PROG_OP_PUSH,	$00
	!byte	PROG_OP_EQU,	$00
	!byte	PROG_OP_GOIF,	$04
	!byte	PROG_OP_GET,	'b'
	!byte	PROG_OP_MUL,	$00
	!byte	PROG_OP_GET,	'x'
	!byte	PROG_OP_PUSH,	$00
	!byte	PROG_OP_SUB,	$00
	!byte	PROG_OP_SET,	'x'
	!byte	PROG_OP_GOTO,	$08

PROGS_POW_DATA
	!byte	$10, $00, $00, $00, $00, $00, $00, $00