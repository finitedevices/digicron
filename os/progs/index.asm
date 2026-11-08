; BUILT-IN PROGRAM INDEX
; A table of names of built-in programs and addresses to their contents.

PROGS
	!raw	"TEST", 0, 0
	!word	PROGS_TEST
	!byte	$00

PROGS_TEST
	!raw	"AB>C", 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_TEST_INST		; PROG_H_IBASE
	!word	PROGS_TEST_DATA		; PROG_H_DBASE
	!byte	$04			; PROG_H_ICOUNT
	!byte	$01			; PROG_H_DCOUNT
	!word	$0000

PROGS_TEST_INST
	!byte	PROG_OP_PUSH,	$00
	!byte	PROG_OP_MUL,	$00
	!byte	PROG_OP_ADD,	$00
	!byte	PROG_OP_RETURN,	$00

PROGS_TEST_DATA
	!byte	$20, $00, $00, $00, $00, $00, $00, $00