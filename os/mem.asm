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

; Abstract definitions to reference current date and time data structures
CT_DATE		= $20
CT_TIME		= $24

; Current date, stored as BCD
; RANGE:	$0020 - $0023
; SIZE:		$04
CT_DATE_YEAR	= CT_DATE + DATE_YEAR	; 2-byte BCD for 4-digit
CT_DATE_MONTH	= CT_DATE + DATE_MONTH
CT_DATE_DAY	= CT_DATE + DATE_DAY

; Current time, stored as BCD
; RANGE:	$0024 - $0027
; SIZE:		$04
CT_TIME_HOUR	= CT_TIME + TIME_HOUR	; 24-hour format
CT_TIME_MINUTE	= CT_TIME + TIME_MINUTE
CT_TIME_SECOND	= CT_TIME + TIME_SECOND
CT_TIME_TICK	= CT_TIME + TIME_TICK	; Hundredths of a second

; Monotonic clock value at start of current second
; RANGE:	$0028 - $0029
; SIZE:		$02
CLOCK_SEC_TOP	= $28			; Hundredths of a second

; Monotonic clock value when the input state last changed
; RANGE:	$002A - $002B
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

; Font write X and Y position offsets
; RANGE:	$0052 - $0053
; SIZE:		$02
FONT_WO_X	= $52
FONT_WO_Y	= $53

; Time format — $00 for 24-hour; $01 for 12-hour (AM/PM); $02 for 12-hour with
; midnight showing 00:00 (used for time editor)
TIME_AMPM	= $54

; Array of modes, with each entry address pointing to mode info struct
; RANGE:	$7000 - $701F
; SIZE:		$20
MODE_LIST	= $7000
MODE_LIST_SIZE	= $20

; Current duration value (time format) measured by the stopwatch
; RANGE:	$7020 - $7023
; SIZE:		$08
STOPW		= $7020

; Monotonic clock value when the stopwatch was last updated
; RANGE:	$7024 - $7025
; SIZE:		$02
STOPW_UPDATED	= $7024

; Whether the stopwatch is active or not
; RANGE:	$7026 - $7026
; SIZE:		$01
STOPW_ACTIVE	= $7026

; Mutex lock to prevent stopwatch from being updated in ISR when also being
; updated via direct call
; RANGE:	$7027 - $7027
; SIZE:		$01
STOPW_LOCK	= $7027

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

; Clock update signal handle; all code requesting the current monotonic clock
; value must increment this value before reading CLOCK and decrement it after
; reading CLOCK; it also serves a purpose of resetting CT_TIME_TICK to zero to
; accurately set the current time when $80 is written to it
; RANGE:	$7F84 - $7F84
; SIZE:		$01
CLOCK_UPDHNDL	= $7F84

; Font array definition — must be aligned to start of page (LSB = 0)
; RANGE:	$C000 - $DFFF
; SIZE:		$2000
FONT		= $C000

; Binary to BCD conversion table
; RANGE:	$E000 - $E006
; SIZE:		$07
BCD_TABLE	= $E000