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

; 8-byte BCD floating-point variables in zero page
; RANGE:	$0020 - $003F
; SIZE:		$20
FP0		= $20
FP1		= $28
FP2		= $30
FP3		= $38

; Abstract definitions to reference current date and time data structures
CT_DATE		= $40
CT_TIME		= $44

; Current date, stored as BCD
; RANGE:	$0040 - $0043
; SIZE:		$04
CT_DATE_YEAR	= CT_DATE + DATE_YEAR	; 2-byte BCD for 4-digit
CT_DATE_MONTH	= CT_DATE + DATE_MONTH
CT_DATE_DAY	= CT_DATE + DATE_DAY

; Current time, stored as BCD
; RANGE:	$0044 - $0047
; SIZE:		$04
CT_TIME_HOUR	= CT_TIME + TIME_HOUR	; 24-hour format
CT_TIME_MINUTE	= CT_TIME + TIME_MINUTE
CT_TIME_SECOND	= CT_TIME + TIME_SECOND
CT_TIME_TICK	= CT_TIME + TIME_TICK	; Hundredths of a second

; Monotonic clock value at start of current second
; RANGE:	$0048 - $0049
; SIZE:		$02
CLOCK_SEC_TOP	= $48			; Hundredths of a second

; Monotonic clock value when the input state last changed
; RANGE:	$004A - $004B
; SIZE:		$02
CLOCK_INPUT_CHG	= $4A			; Hundredths of a second

; General-purpose string buffers
; RANGE:	$0050 - $006F
; SIZE:		$20
STRBUF0		= $50
STRBUF1		= $60

; Current mode index
; RANGE:	$0070 - $0070
; SIZE:		$01
CT_MODE		= $70

; Behaviour of KEY_DIV in switching modes
; RANGE:	$0071 - $0071
; SIZE:		$01
KEY_DIV_BEHAV	= $71

; Font write X and Y position offsets
; RANGE:	$0072 - $0073
; SIZE:		$02
FONT_WO_X	= $72
FONT_WO_Y	= $73

; User-configured time format — $00 for 24-hour; $01 for 12-hour (AM/PM); $02
; for 12-hour with midnight showing 00:00 (used for time editor)
; RANGE:	$0074 - $0074
; SIZE:		$01
TIME_FORMAT	= $74

; Time format to use when calling display routines — typically set to same value
; as TIME_FORMAT
; RANGE:	$0075 - $0075
; SIZE:		$01
TIME_DSP_FORMAT	= $75

; Context switching address, current highest priority and in-use flag
; RANGE:	$0076 - $0079
; SIZE:		$04
ISR_CTXSW_ADDR	= $76
ISR_CTXSW_PRIO	= $78
ISR_CTXSW_INUSE = $79

; Index of alarm currently being viewed
; RANGE:	$007A - $007A
; SIZE:		$01
ALARM_IDX	= $7A

; Time remaining on snoozed alarm, stored as BCD
; RANGE:	$007B - $007D
; SIZE:		$03
ALM_ZZZ_MINUTE	= $7B
ALM_ZZZ_SECOND	= $7C
ALM_ZZZ_STATE	= $7D

; Index of timer currently being viewed
; RANGE:	$007F - $007F
; SIZE:		$01
TIMER_IDX	= $7F

; Address of array containing user's preferred weekday order
; RANGE:	$0080 - $0081
; SIZE:		$02
DATE_WKDYORDER	= $80

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

; Array of alarm states
; RANGE:	$7040 - $705F
; SIZE:		$20
ALARMS		= $7040

; Array of timer states
; RANGE:	$7060 - $709F
; SIZE:		$40
TIMERS		= $7060

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