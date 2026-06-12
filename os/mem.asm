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

; Current date, stored as BCD
; RANGE:	$0020 - $0023
; SIZE:		$04
DATE_YEAR	= $20			; BCD word for 4-digit year
DATE_MONTH	= $22
DATE_DAY	= $23

; Current time, stored as BCD
; RANGE:	$24 - $27
; SIZE:		$04
TIME_HOUR	= $24			; 24-hour format
TIME_MINUTE	= $25
TIME_SECOND	= $26
TIME_TICK	= $27			; Hundredths of a second

; Abstract definitiosn to reference current date and time data as a blocks
CURRENT_DATE	= DATE_YEAR
CURRENT_TIME	= TIME_HOUR

; Monotonic clock value at start of current second
; RANGE:	$28 - $29
; SIZE:		$02
CLOCK_SEC_TOP	= $28			; Hundredths of a second

; General-purpose string buffers
; RANGE:	$0030 - $004F
; SIZE:		$20
STRBUF0		= $30
STRBUF1		= $40

; Mapped display memory
; RANGE:	$7F00 - $7F27
; SIZE:		$28
DISPLAY		= $7F00

; Mapped keyboard input
; RANGE:	$7F80 - $7F80
; SIZE:		$01
INPUT		= $7F80

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