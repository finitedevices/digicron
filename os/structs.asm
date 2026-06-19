; DATA STRUCTURE DEFINITIONS
; Defines data structures used by the operating system, and the sizes and
; offsets of their fields.

; Date (BCD)
; SIZE:		$04
DATE_YEAR	= $00			; 2-byte BCD for 4-digit
DATE_MONTH	= $02
DATE_DAY	= $03

; Time (BCD)
; SIZE:		$04
TIME_HOUR	= $00			; 24-hour format
TIME_MINUTE	= $01
TIME_SECOND	= $02
TIME_TICK	= $03			; Hundredths of a second

; Date and time (BCD)
; SIZE:		$08
DT_YEAR		= $00			; 2-byte BCD for 4-digit
DT_MONTH	= $02
DT_DAY		= $03
DT_HOUR		= $04			; 24-hour format
DT_MINUTE	= $05
DT_SECOND	= $06
DT_TICK		= $07			; Hundredths of a second

; Time delta (binary)
TDELTA_YEAR	= $00
TDELTA_WEEK	= $01
TDELTA_DAY	= $02			; 2-byte to cover range 0-366
TDELTA_HOUR	= $04
TDELTA_MINUTE	= $05
TDELTA_SECOND	= $06
TDELTA_TICK	= $07