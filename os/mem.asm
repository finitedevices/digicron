; MEMORY LAYOUT DEFINITIONS
; Layout information, including constants containing addresses to use to access
; common variables.

; General-purpose 16-bit variables in zero page
; RANGE:	$0010 - $0017
; SIZE:		$08
GP0		= $10
GP1		= $12
GP2		= $14
GP3		= $16

; Mapped display memory
; RANGE:	$7F00 - $7F27
; SIZE:		$28
DISPLAY		= $7F00

; Font array definition — must be aligned to start of page (LSB = 0)
; RANGE:	$C000 - $DFFF
; SIZE:		$2000
FONT		= $C000