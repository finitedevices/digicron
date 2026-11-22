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
PROGS_SQRT_IDX
	!raw	"SQRT", 0, 0, 0, 0
	!word	PROGS_SQRT
PROGS_FLOOR_IDX
	!raw	"FLOOR", 0, 0, 0
	!word	PROGS_FLOOR
PROGS_SIN_IDX
	!raw	"SIN", 0, 0, 0, 0, 0
	!word	PROGS_SIN
PROGS_COS_IDX
	!raw	"COS", 0, 0, 0, 0, 0
	!word	PROGS_COS
PROGS_TAN_IDX
	!raw	"TAN", 0, 0, 0, 0, 0
	!word	PROGS_TAN
PROGS_ASIN_IDX
	!raw	"ASIN", 0, 0, 0, 0
	!word	PROGS_ASIN
	!byte	$00