; BUILT-IN ROUNDING PROGRAMS
; Functions for rounding number to the nearest integer.

PROGS_FLOOR
	!raw	"X>A", 0, 0, 0, 0, 0	; PROG_H_SIG
	!word	PROGS_FLOOR_INST	; PROG_H_IBASE
	!word	$0000			; PROG_H_DBASE
	!byte	$01			; PROG_H_ICOUNT
	!byte	$00			; PROG_H_DCOUNT
	!word	$0000

PROGS_FLOOR_INST
	!byte	PROG_OP_FLOOR,	$00