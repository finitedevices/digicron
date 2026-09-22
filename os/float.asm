; FLOATING-POINT
; Operations for 8-byte BCD floating-point values.

; Float data type byte layout:
;    0     1     2     3     4     5     6     7
; +===============================================+	M = Mantissa
; | M M | M M | M M | M M | M M | M M | E E | S S |	E = Exponent
; +===============================================+	S = States bit field
;  10^0  10^2  10^4  10^6  10^8  10^10

; Float value offsets
FLOAT_M		= $00			; Mantissa
FLOAT_E		= $06			; Exponent
FLOAT_S		= $07			; States bit field

; Float value size constant
FLOAT_SIZE	= $08

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

	cpx	#4 * FLOAT_SIZE		; 4 floats containing 8 bytes
	bcc	.loop

	rts

!zone	float_disp
; Show the value of the float in FP0 on the display. The float's value should be
; normalised before calling this subroutine.
; INPUT:	FP0 = Value of float to show
; OUTPUT:	None
; VARIABLES:	GP4 = Total digits to display/column index
float_disp
	; TODO: Show static message if infinity or NaN

	ldx	#FLOAT_E		; Get exponent and store in Y
	ldy	FP0,x

	ldx	#FLOAT_S		; Get states bit field
	lda	FP0,x
	and	#FLOAT_S_ENEG		; Mask to get exponent sign
	bne	.negative_exponent	; Handle negative exponent separately

	cpy	#$07			; If 8 or more digits in integer then
	bcs	.show_scientific	; show using scientific notation

	bra	.show_standard

.negative_exponent
	cpy	#$05			; If 4 or more zeros after decimal point
	bcs	.show_scientific	; then show using scientific notation

.show_standard
	lda	#1			; Count total display digits in GP4
	sta	GP4

	ldx	#FLOAT_M
	ldy	#2			; Max digit count for current byte

.count_digits_loop
	lda	FP0,x			; Get current byte (2 digits)
	and	#$F0			; Mask to get upper digit
	beq	.not_upper		; If nonzero then set new total

	sty	GP4			; Set new total from max digit count

	bra	.count_next_byte

.not_upper
	lda	FP0,x			; Get current byte (2 digits)
	and	#$0F			; Mask to get lower digit
	beq	.count_next_byte	; If nonzero then set new total

	sty	GP4			; Set new total from max digit count - 1
	dec	GP4

.count_next_byte
	inx
	iny
	iny

	cpx	#FLOAT_E		; 6 bytes containing 12 digits
	bcc	.count_digits_loop

	sec				; Subtract digit count from number of
	lda	#8			; display columns to get index to start
	sbc	GP4			; displaying number from
	sta	GP4

	ldy	#FLOAT_M << 1		; Use Y as nibble index into mantissa

	jsr	gfx_clear		; Clear display

.show_standard_loop
	tya				; Get nibble idx and convert to byte idx
	lsr
	bcs	.show_upper

	tax				; Use X as byte index into mantissa
	lda	FP0,x
	and	#$0F			; Mask to get lower digit

	bra	.convert_digit

.show_upper
	tax				; Use X as byte index into mantissa
	lda	FP0,x
	and	#$F0			; Mask to get upper digit
	lsr				; Shift into lower nibble
	lsr
	lsr
	lsr

.convert_digit
	clc
	adc	#'0'			; Add ASCII 0

	ldx	GP4			; Store column index in X
	jsr	gfx_dispchar		; Show digit on display
	inc	GP4
	iny

	cpx	#8
	bcc	.show_standard_loop

	rts

.show_scientific
	; TODO: Implement scientific notation rendering

	rts

!zone	float_norm
; Normalise the float in FP0 such that the integer part of the mantissa is
; within the range [1, 9].
; INPUT:	FP0 = Value of float to normalise
; OUTPUT:	FP0 = Value of normalised float
;		A, X, Y, GP0 = Trashed
float_norm
	ldx	#FLOAT_M		; Use X as index for zero checking loop

	lda	FP0 + FLOAT_S		; Check if value is infinity or NaN
	and	#FLOAT_S_INF | FLOAT_S_NAN
	beq	.zero_loop		; If not then normalise

	rts				; Early return to do nothing

.zero_loop
	lda	FP0,x			; Check current byte (2 digits)
	bne	.check_2_digits		; If nonzero then normalise
	inx

	cpx	#FLOAT_E		; 6 bytes containing 12 digits
	bcc	.zero_loop

	stz	FP0 + FLOAT_E		; Set exponent to 0
	stz	FP0 + FLOAT_S		; Clear all state bit fields (negatives)

.check_2_digits
	ldx	#FLOAT_M
	ldy	#FLOAT_M + 1

	lda	FP0,x			; If either of first 2 digits nonzero
	bne	.check_1_digit		; Then only check first digit

.shift_2_loop
	lda	FP0,y			; Copy from next byte to shift 2 digits
	sta	FP0,x
	inx
	iny

	cpx	#FLOAT_E - 1		; 5 bytes containing 10 digits
	bcc	.shift_2_loop

	stz	FP0,x			; Set final 2 digits to 0

	lda	#FP0 & $FF		; Store float address in GP0
	sta	GP0
	lda	#FP0 >> 8
	sta	GP0 + 1

	jsr	float_decexp		; Decrement exponent twice for 2 digits
	jsr	float_decexp

	bra	.check_2_digits		; Now check again

.check_1_digit
	ldx	#FLOAT_M		; Check first digit (low nibble)
	lda	FP0,x
	and	#$0F
	bne	.done			; If first digit is nonzero, then finish

	ldy	#FLOAT_M + 1

.shift_1_loop
	lsr	FP0,x			; Shift high nibble into low nibble
	lsr	FP0,x
	lsr	FP0,x
	lsr	FP0,x

	lda	FP0,y			; Get low nibble of next byte and shift
	asl				; it into high nibble to insert into
	asl				; current byte
	asl
	asl
	ora	FP0,x
	sta	FP0,x

	inx
	iny

	cpx	#FLOAT_E		; 6 bytes containing 12 digits
	bcc	.shift_1_loop

	ldx	#FLOAT_E - 1		; Clear high nibble of last byte
	lda	FP0,x			; (setting final digit to 0)
	and	#$0F
	sta	FP0,x

	lda	#FP0 & $FF		; Store float address in GP0
	sta	GP0
	lda	#FP0 >> 8
	sta	GP0 + 1

	jsr	float_decexp		; Decrement exponent

.done
	rts

!zone	float_incexp
; Increment the exponent value of the given float. If the exponent value
; overflows, then the float will be set to +/- infinity.
; INPUT:	GP0 = Address of float to increment
; OUTPUT:	C = Set if float value was set to +/- infinity due to overflow
;		A, Y = Trashed
float_incexp
	ldy	#FLOAT_S		; Check state bit field
	lda	(GP0),y
	and	#FLOAT_S_ENEG		; Mask to get negative exponent flag
	bne	.negative_exponent	; If set, then decrement value instead

.positive_exponent
	ldy	#FLOAT_E		; Get current exponent value
	lda	(GP0),y
	cmp	#$99			; If already at 99, then set to infinity
	beq	.set_infinity

	sed				; Increment by 1
	clc
	adc	#1
	cld
	sta	(GP0),y			; Store back into exponent value

	bra	.clear_sign		; Ensure negative sign bit is cleared

.negative_exponent
	ldy	#FLOAT_E		; Get current exponent value
	lda	(GP0),y
	beq	.positive_exponent	; If -0, then treat as +0

	sed				; Decrement by 1
	sec
	sbc	#1
	cld
	sta	(GP0),y			; Store back into exponent value
	bne	.done			; If still nonzero then return

.clear_sign
	ldy	#FLOAT_S		; Clear negative sign bit
	lda	(GP0),y
	and	#!FLOAT_S_ENEG
	sta	(GP0),y

.done
	clc
	rts

.set_infinity
	ldy	#FLOAT_S		; Set infinity bit
	lda	(GP0),y
	ora	#FLOAT_S_INF
	sta	(GP0),y

	sec
	rts

!zone	float_decexp
; Decrement the exponent value of the given float. If the exponent value
; underflows, then the float will be set to 0.
; INPUT:	GP0 = Address of float to decrement
; OUTPUT:	C = Set if float value was set to 0 due to underflow
;		A, Y = Trashed
float_decexp
	ldy	#FLOAT_S		; Temporarily invert exponent sign
	lda	(GP0),y
	eor	#FLOAT_S_ENEG
	sta	(GP0),y

	jsr	float_incexp		; Increment exponent value
	bcs	.set_zero		; If overflowed then set to 0

	ldy	#FLOAT_S		; Restore inverted exponent sign
	lda	(GP0),y
	eor	#FLOAT_S_ENEG
	sta	(GP0),y

	clc
	rts

.set_zero
	ldy	#0

.set_zero_loop
	lda	#0			; Clear out all bytes in float
	sta	(GP0),y
	iny

	cpy	#FLOAT_SIZE		; Repeat for 8 bytes
	bcc	.set_zero_loop

	sec
	rts