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

!zone	float_copy
; Copy the value of the float to a destination.
; INPUT:	GP0 = Address of float to copy value of
;		GP1 = Address of destination to copy value to
; OUTPUT:	None
;		A, Y = Trashed
float_copy
	ldy	#0

.loop
	lda	(GP0),y			; Get byte from source address
	sta	(GP1),y			; Set byte at destination address
	iny

	cpy	#FLOAT_SIZE		; Copy 8 bytes
	bcc	.loop

	rts

!zone	float_disp
; Show the value of the float in FP0 on the display. The float's value will be
; normalised before it is shown.
; INPUT:	FP0 = Value of float to show
; OUTPUT:	FP0 = Normalised value of shown float 
;		A, X, Y, GP0, GP1, GP4, GP5 = Trashed
; VARIABLES:	GP4 = Total digits to display/column index (LSB), current digit
;		exponent in binary (MSB)
;		GP5 = Index of prepended zero digit (LSB), number of zero digits
;		to prepend (MSB)
float_disp
	jsr	float_norm		; Normalise FP0 first

	ldx	#FLOAT_E		; Get exponent and store in Y
	ldy	FP0,x

	ldx	#FLOAT_S		; Get states bit field
	lda	FP0,x
	and	#FLOAT_S_NAN		; Mask to get NaN state
	bne	.nan			; If flag set then show NaN message
	lda	FP0,x
	and	#FLOAT_S_INF		; Mask to get infinity state
	bne	.inf			; If flag set then show inf message
	lda	FP0,x
	and	#FLOAT_S_ENEG		; Mask to get exponent sign
	bne	.negative_exponent	; Handle negative exponent separately

	cpy	#$06			; If 7 or more digits in integer then
	bcs	.show_scientific	; show using scientific notation

	bra	.show_standard

.negative_exponent
	cpy	#$05			; If 4 or more zeros after decimal point
	bcs	.show_scientific	; then show using scientific notation

	bra	.show_standard

.nan
	jsr	gfx_clear		; Clear display

	lda	#.NAN_MSG & 0xFF
	sta	GP0
	lda	#.NAN_MSG >> 8
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Show "NAN" message

	rts

.inf
	jsr	gfx_clear		; Clear display

	lda	#.INF_MSG & 0xFF
	sta	GP0
	lda	#.INF_MSG >> 8
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Show "INF" message

	ldx	#FLOAT_S		; Get states bit field
	lda	FP0,x
	and	#FLOAT_S_MNEG		; Mask to get mantissa sign
	beq	.inf_done		; If negative then show negative sign

	lda	#'-' | $80		; Show negative sign
	ldx	#4
	jsr	gfx_dispchar

.inf_done
	rts

.show_scientific
	; TODO: Implement scientific notation rendering

	rts

.show_standard
	lda	#1			; Count total display digits in GP4
	sta	GP4

	ldx	#FLOAT_M
	ldy	#2			; Max digit count for current byte

.count_digits_loop
	lda	FP0,x			; Get current byte (2 digits)
	and	#$0F			; Mask to get lower digit
	beq	.not_upper		; If nonzero then set new total

	sty	GP4			; Set new total from max digit count

	bra	.count_next_byte

.not_upper
	lda	FP0,x			; Get current byte (2 digits)
	and	#$F0			; Mask to get upper digit
	beq	.count_next_byte	; If nonzero then set new total

	sty	GP4			; Set new total from max digit count - 1
	dec	GP4

.count_next_byte
	inx
	iny
	iny

	cpx	#FLOAT_E		; 6 bytes containing 12 digits
	bcc	.count_digits_loop

	lda	#$7F			; Set invalid prepended zero digit index
	sta	GP5			; to indicate not in use
	stz	GP5 + 1			; Clear number of zeros to prepend

	lda	FP0,x			; Get exponent (X already = FLOAT_E)
	jsr	util_frombcd		; Convert it into binary
	sta	GP4 + 1			; Store in GP4 MSB
	beq	.positive_exponent	; If zero then treat as positive exp

	ldx	#FLOAT_S		; Check if exponent is negative
	lda	FP0,x
	and	#FLOAT_S_ENEG
	beq	.positive_exponent	; If so then set # of zeros to prepend

	lda	GP4 + 1			; Get exponent
	sta	GP5 + 1			; Use as number of zeros to prepend

	clc				; Add exponent to number of digits to
	adc	GP4			; display for leading or trailing zeros
	sta	GP4

	eor	#$FF			; Negate as two's complement value
	inc
	sta	GP4 + 1

	stz	GP5			; Clear prepended zero digit index

	bra	.set_initial_column

.positive_exponent
	lda	GP4 + 1			; Get exponent
	inc
	cmp	GP4			; If exponent > number of digits
	bcc	.set_initial_column	; Then add trailing zeros
	sta	GP4			; Done by setting # of digits to exp

.set_initial_column
	sec				; Subtract digit count from number of
	lda	#8			; display columns to get index to start
	sbc	GP4			; displaying from
	sta	GP4
	cmp	#1			; Check if column index is out of range
	bcs	.column_in_range	; If so then set lower bound

	lda	#1			; Set lower bound leaving space for
	sta	GP4			; negative sign

.column_in_range
	ldy	#FLOAT_M << 1		; Use Y as nibble index into mantissa

	jsr	gfx_clear		; Clear display

	ldx	#FLOAT_S		; Get states bit field
	lda	FP0,x
	and	#FLOAT_S_MNEG		; Mask to get mantissa sign
	beq	.show_standard_loop	; If negative then show negative sign

	ldx	GP4			; Show negative sign in column before
	dex				; that of first digit

	lda	#'-' | $80		; Show negative sign
	jsr	gfx_dispchar

.show_standard_loop
	lda	GP5 + 1			; Get current number of zeros to prepend
	beq	.get_digit		; If nonzero then insert leading zero

	dec	GP5 + 1			; Decrease number of zeros to prepend
	dey				; Prevent increase of float digit index

	lda	GP5			; Get current zero digit index
	cmp	#0			; If first zero digit
	beq	.initial_zero		; Then show it as before decimal point

	lda	#0
	bra	.convert_digit

.initial_zero
	ldx	#'0'
	bra	.in_integer

.get_digit
	tya				; Get nibble idx and convert to byte idx
	lsr
	bcc	.show_upper

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
	tax				; Store in X for now

	lda	GP4 + 1			; If GP4 MSB is negative, then after
	and	#$80			; decimal place
	beq	.in_integer

	txa				; Get ASCII value from X
	ora	#$80			; Use small digits after decimal place
	tax				; Store back into X

.in_integer
	txa				; Get ASCII value from X
	ldx	GP4			; Set X to column index
	jsr	gfx_dispchar		; Show digit on display

	lda	GP5			; Get prepended zero digit index
	cmp	#1			; If 2nd digit then show decimal point
	beq	.show_decimal

	lda	GP4 + 1			; Get current digit exponnet
	cmp	#-1			; If at -1 then show decimal point
	beq	.show_decimal

	bra	.no_decimal

.show_decimal
	txa				; Get current column index
	asl				; Shift left twice to multiply by 4
	asl
	clc
	adc	GP4			; Add column index to multiply by 5
	tax				; Use as index into display memory

	lda	DISPLAY,x		; Get pixel column byte
	ora	#$40			; Set bottommost pixel
	sta	DISPLAY,x		; Write back into pixel column byte

.no_decimal
	inc	GP4			; Increment column index
	dec	GP4 + 1			; Decrement current digit exponent
	inc	GP5			; Increase prepended zero digit index
	iny				; Increment mantissa nibble index

	ldx	GP4			; Get column index
	cpx	#8			; Repeat for 8 columns
	bcc	.show_standard_loop

	rts

; TODO: Implement lowercase characters in font to display "NaN" and "Inf"

.NAN_MSG
	!raw	"     NAN"

.INF_MSG
	!raw	"     INF"

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

	rts

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
	ldx	#FLOAT_M		; Check first digit (high nibble)
	lda	FP0,x
	and	#$F0
	bne	.done			; If first digit is nonzero, then finish

	ldy	#FLOAT_M + 1

.shift_1_loop
	asl	FP0,x			; Shift low nibble into high nibble
	asl	FP0,x
	asl	FP0,x
	asl	FP0,x

	lda	FP0,y			; Get high nibble of next byte and shift
	lsr				; it into low nibble to insert into
	lsr				; current byte
	lsr
	lsr
	ora	FP0,x
	sta	FP0,x

	inx
	iny

	cpx	#FLOAT_E		; 6 bytes containing 12 digits
	bcc	.shift_1_loop

	ldx	#FLOAT_E - 1		; Clear low nibble of last byte
	lda	FP0,x			; (setting final digit to 0)
	and	#$F0
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