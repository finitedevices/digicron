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
PROGS_FLOOR_IDX
	!raw	"FLOOR", 0, 0, 0
	!word	PROGS_FLOOR
PROGS_COS_IDX
	!raw	"COS", 0, 0, 0, 0, 0
	!word	PROGS_COS
	!byte	$00