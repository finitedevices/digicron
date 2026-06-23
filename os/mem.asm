; MEMORY LAYOUT DEFINITIONS
; Layout information, including constants containing addresses to use to access
; common variables.

; General-purpose 16-bit variables in zero page
; RANGE:	$0010 - $001F
; SIZE:		$10
GP0		= $10
GP1		= $12
GP2		= $14
GP3		= $16
GP4		= $18
GP5		= $1A
GP6		= $1C
GP7		= $1E

; Abstract definitiosn to reference current date and time data structures
CT_DATE	= $20
CT_TIME	= $24

; Current date, stored as BCD
; RANGE:	$20 - $23
; SIZE:		$04
CT_DATE_YEAR	= CT_DATE + DATE_YEAR	; 2-byte BCD for 4-digit
CT_DATE_MONTH	= CT_DATE + DATE_MONTH
CT_DATE_DAY	= CT_DATE + DATE_DAY

; Current time, stored as BCD
; RANGE:	$24 - $27
; SIZE:		$04
CT_TIME_HOUR	= CT_TIME + TIME_HOUR	; 24-hour format
CT_TIME_MINUTE	= CT_TIME + TIME_MINUTE
CT_TIME_SECOND	= CT_TIME + TIME_SECOND
CT_TIME_TICK	= CT_TIME + TIME_TICK	; Hundredths of a second

; Monotonic clock value at start of current second
; RANGE:	$28 - $29
; SIZE:		$02
CLOCK_SEC_TOP	= $28			; Hundredths of a second

; Monotonic clock value when the input state last changed
; RANGE:	$2A-2B
; SIZE:		$02
CLOCK_INPUT_CHG	= $2A			; Hundredths of a second

; General-purpose string buffers
; RANGE:	$0030 - $004F
; SIZE:		$20
STRBUF0		= $30
STRBUF1		= $40

; Current mode index
; RANGE:	$0050 - $0050
; SIZE:		$01
CT_MODE		= $50

; Behaviour of KEY_DIV in switching modes
; RANGE:	$0051 - $0051
; SIZE:		$01
KEY_DIV_BEHAV	= $51

; Mapped display memory
; RANGE:	$7F00 - $7F27
; SIZE:		$28
DISPLAY		= $7F00

; Mapped interrupt flag
; RANGE:	$7F80 - $7F80
; SIZE:		$01
INT_FLAG	= $7F80

; Mapped keyboard input
; RANGE:	$7F81 - $7F81
; SIZE:		$01
INPUT		= $7F81

; Monotonic clock
; RANGE:	$7F82 - $7F83
; SIZE:		$02
CLOCK		= $7F82			; Hundredths of a second

; Font array definition — must be aligned to start of page (LSB = 0)
; RANGE:	$C000 - $DFFF
; SIZE:		$2000
FONT		= $C000

; Binary to BCD conversion table
; RANGE:	$E000 - $E006
; SIZE:		$07
BCD_TABLE	= $E000