; FLOATING-POINT
; Operations for 8-byte BCD floating-point values.

; Float data type byte layout:
;    0     1     2     3     4     5     6     7
; +===============================================+
; | M M | M M | M M | M M | M M | M M | E E | S S |
; +===============================================+
;  10^0  10^2  10^4  10^6  10^8  10^10

; Float states (bit field)
FLOAT_S_MNEG	= $01			; Set if mantissa is negative
FLOAT_S_ENEG	= $02			; Set if exponent is negative
FLOAT_S_INF	= $04			; Set if value is +/- infinity
FLOAT_S_NAN	= $08			; Set if value is not a number

!zone	float_init
; Initialise all floating-point variables.
; INPUT:	None
; OUTPUT:	None
;		X = Trashed
float_init
	ldx	#0

.loop
	stz	FP0,x			; Clear out all float bytes
	inx

	cpx	#4 * 8			; 4 floats containing 8 bytes
	bcc	.loop

	rts