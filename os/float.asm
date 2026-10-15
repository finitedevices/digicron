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

!zone	float_swap
; Swap the values of two floats.
; INPUT:	GP0 = Address of first float to swap with second
;		GP1 = Address of second float to swap with first
; OUTPUT:	None
;		A, X, Y = Trashed
float_swap
	ldy	#0

.loop
	lda	(GP1),y			; Get byte from second float
	tax				; Store second float byte in X
	lda	(GP0),y			; Get byte from first float
	sta	(GP1),y			; Store first float byte in second float
	txa				; Retrieve second float byte from X
	sta	(GP0),y			; Store second float byte in first float

	cpy	#FLOAT_SIZE		; Swap 8 bytes
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

	ldy	FP0 + FLOAT_E		; Get exponent and store in Y

	lda	FP0 + FLOAT_S		; Get states bit field
	and	#FLOAT_S_NAN		; Mask to get NaN state
	bne	.nan			; If flag set then show NaN message
	lda	FP0 + FLOAT_S
	and	#FLOAT_S_INF		; Mask to get infinity state
	bne	.inf			; If flag set then show inf message
	lda	FP0 + FLOAT_S
	and	#FLOAT_S_ENEG		; Mask to get exponent sign
	bne	.negative_exponent	; Handle negative exponent separately

	cpy	#$07			; If 8 or more digits in integer then
	bcs	.show_scientific	; show using scientific notation

	jmp	.show_standard

.negative_exponent
	cpy	#$05			; If 4 or more zeros after decimal point
	bcs	.show_scientific	; then show using scientific notation

	jmp	.show_standard

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

	lda	FP0 + FLOAT_S		; Get states bit field
	and	#FLOAT_S_MNEG		; Mask to get mantissa sign
	beq	.inf_done		; If negative then show negative sign

	lda	#'-' | $80		; Show negative sign
	ldx	#4
	jsr	gfx_dispchar

.inf_done
	rts

.show_scientific
	jsr	gfx_clear		; Clear display

	lda	FP0 + FLOAT_M		; Get first digit (in first byte)
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	clc
	adc	#'0'			; Add ASCII 0
	ldx	#1
	jsr	gfx_dispchar		; Show digit on display

	lda	FP0 + FLOAT_M		; Get second digit (in first byte)
	and	#$0F			; Mask to get low nibble
	clc
	adc	#'0' | $80		; Add small text 0 digit character
	ldx	#2
	jsr	gfx_dispchar		; Show digit on display

	lda	DISPLAY + (2 * 5)	; Get pixel column byte
	ora	#$40			; Set bottommost pixel for decimal point
	sta	DISPLAY + (2 * 5)	; Write back into pixel column byte

	lda	FP0 + FLOAT_M + 1	; Get third digit (in second byte)
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	clc
	adc	#'0' | $80		; Add small text 0 digit character
	ldx	#3
	jsr	gfx_dispchar		; Show digit on display

	lda	FP0 + FLOAT_M + 1	; Get fourth digit (in second byte)
	and	#$0F			; Mask to get low nibble
	clc
	adc	#'0' | $80		; Add small text 0 digit character
	ldx	#4
	jsr	gfx_dispchar		; Show digit on display

	lda	FP0 + FLOAT_E		; Get exponent tens digit
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	clc
	adc	#'0'			; Add ASCII 0
	ldx	#6
	jsr	gfx_dispchar		; Show digit on display

	lda	FP0 + FLOAT_E		; get exponent units digit
	clc
	and	#$0F			; Mask to get low nibble
	adc	#'0'			; Add ASCII 0
	ldx	#7
	jsr	gfx_dispchar		; Show digit on display

.check_mantissa_sign
	lda	FP0 + FLOAT_S		; Get states bit field
	and	#FLOAT_S_MNEG		; Mask to get mantissa sign
	beq	.check_exponent_sign	; If negative then show negative sign

	lda	#'-' | $80		; Show negative sign
	ldx	#0
	jsr	gfx_dispchar

.check_exponent_sign
	lda	FP0 + FLOAT_S		; Get states bit field
	and	#FLOAT_S_ENEG		; Mask to get exponent sign
	beq	.done			; If negative then show negative sign

	lda	#'-' | $80		; Show negative sign
	ldx	#5
	jsr	gfx_dispchar

.done
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

	lda	FP0 + FLOAT_E		; Get exponent
	jsr	util_frombcd		; Convert it into binary
	sta	GP4 + 1			; Store in GP4 MSB
	beq	.positive_exponent	; If zero then treat as positive exp

	lda	FP0 + FLOAT_S		; Check if exponent is negative
	and	#FLOAT_S_ENEG
	beq	.positive_exponent	; If so then set # of zeros to prepend

	lda	GP4 + 1			; Get exponent
	sta	GP5 + 1			; Use as number of zeros to prepend

	clc				; Add exponent to number of digits to
	adc	GP4			; display for leading or trailing zeros

	cmp	#8			; If total number of digits is >= 8
	bcc	.negate_digit_count	; Then cap to 7 digits

	lda	#7			; Cap to 7 digits to ensure sign visible

.negate_digit_count
	sta	GP4			; Store as total digits to display

	eor	#$FF			; Negate as two's complement value
	inc
	sta	GP4 + 1			; Store as current digit exponent

	stz	GP5			; Clear prepended zero digit index

	bra	.set_initial_column

.positive_exponent
	lda	GP4 + 1			; Get exponent
	inc
	cmp	GP4			; If exponent > number of digits
	bcc	.no_trailing_zeros	; Then add trailing zeros
	sta	GP4			; Done by setting # of digits to exp

.no_trailing_zeros
	lda	GP4			; If total number of digits is >= 8
	cmp	#8
	bcc	.negate_digit_count	; Then cap to 7 digits

	lda	#7			; Cap to 7 digits to ensure sign visible
	sta	GP4

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

	lda	FP0 + FLOAT_S		; Get states bit field
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

.NAN_MSG
	!raw	"     NaN"

.INF_MSG
	!raw	"     Inf"

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

!zone	float_add
; Add the floats in FP0 and FP1 and store the result in FP2.
; INPUT:	FP0 = Value of first float to add
;		FP1 = Value of second float to add
; OUTPUT:	FP2 = Result of adding FP0 and FP1 together
;		A, X, Y, FP0, FP1, GP0-2 = Trashed
; VARIABLES:	GP2 = Mantissa sign flags (bit 0 = FP0's, bit 1 = FP1's, bit 2
;		set if FP0's mantissa magnitude was < FP1's mantissa magnitude)
float_add
	; TODO: Add infinity and NaN checks

	; First step is to align the two floats so that they can be cleanly
	; added together. To ensure maximum precision, the float with the lowest
	; exponent value shall be aligned so that its exponent value becomes
	; equal with the other float's. In order to achieve this, FP0 shall be
	; designated as the value with the lower exponent. If it originally has
	; the higher exponent, then it will be swapped with FP1 so that it then
	; has the lower exponent. FP0's mantissa will then be shifted rightwards
	; and exponent increased until it matches FP1's exponent.

	; Example:
	;   1.234000000 08				  1.234000000 08
	; + 5.678000000 04	Lowest exp, so align:	+ 0.000567800 08
	;						  ==============
	; Result following subsequent steps:		  1.234567800 08

	lda	FP0 + FLOAT_S		; Get first float state bit field
	and	#FLOAT_S_ENEG		; Mask to get exponent sign
	lsr				; Shift into bit 0
	sta	GP0

	lda	FP1 + FLOAT_S		; Get second float state bit field
	and	#FLOAT_S_ENEG		; Mask to get exponent sign
	ora	GP0			; Combine with first float exponent sign

	cmp	#$01			; If first exp -ve, second exp +ve
	beq	.align			; Then don't swap floats
	cmp	#$02			; If first exp +ve, second exp -ve
	beq	.exp_swap		; Then swap floats
	tax				; Otherwise save combination for later

	lda	FP0 + FLOAT_E		; Get first float exponent magnitude
	cmp	FP1 + FLOAT_E		; Compare against second float exponent
	beq	.no_align		; If equal, then don't align
	bcc	.exp0_lt_exp1		; If >, then swap if exps positive

	cpx	#$03			; If both exponents are negative
	beq	.align			; Then don't swap floats
	bra	.exp_swap		; Otherwise, swap floats

.exp0_lt_exp1
	cpx	#$03			; If both exponents are negative
	beq	.exp_swap		; Then swap floats
	bra	.align			; Otherwise, don't swap floats

.exp_swap
	lda	#FP0 & $FF		; Load address of first float in GP0
	sta	GP0
	lda	#FP0 >> 8
	sta	GP0 + 1

	lda	#FP1 & $FF		; Load address of second float in GP1
	sta	GP1
	lda	#FP1 >> 8
	sta	GP1 + 1

	jsr	float_swap		; Swap both floats

.align
	lda	FP0 + FLOAT_E		; If both float exponent magnitudes are
	and	FP0 + FLOAT_E		; zero, then finish alignment (special
	beq	.no_align		; case to handle either exponent as -0)

	lda	FP0 + FLOAT_S		; Exclusive OR both float state bit
	eor	FP1 + FLOAT_S		; fields together to determine if exp
	and	#FLOAT_S_ENEG		; signs are same
	bne	.exps_neq		; If not then don't check magnitudes

	lda	FP0 + FLOAT_E		; If exponent magnitudes are equal then
	cmp	FP1 + FLOAT_E		; finish alignment
	beq	.no_align

.exps_neq
	ldx	#FLOAT_E - 1		; Use X as index into FP0
	ldy	#FLOAT_E - 2

.shift_exp_loop
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

	dex
	dey

	cpx	#FLOAT_M		; 6 bytes containing 12 digits
	bcs	.shift_exp_loop

	ldx	#FLOAT_M		; Clear high nibble of first byte
	lda	FP0,x			; (setting first digit to 0)
	and	#$0F
	sta	FP0,x

	lda	#FP0 & $FF		; Load address of first float in GP0
	sta	GP0
	lda	#FP0 >> 8
	sta	GP0 + 1

	jsr	float_incexp		; Increment exponent

	bra	.align

.no_align
	lda	FP0 + FLOAT_E		; Copy aligned exponent into result
	sta	FP2 + FLOAT_E

	; Next step is to determine if an addition or subtraction operation is
	; required for the mantissa. A subtraction operation is required if only
	; one of the float mantissas is negative; otherwise an addition
	; operation is required.

	; Examples:
	; 3 + 2 = 5	Both mantissas +ve	Mantissas added (3 + 2 = 5)
	; -3 + -2 = -5	Both mantissas -ve	Mantissas added (3 + 2 = 5)
	; 3 + -2 = 1	First +ve, second -ve	Mantissas subtracted (3 - 2 = 1)
	; -3 + 2 = -1	First -ve, second +ve	Mantissas subtracted (3 - 2 = 1)

	lda	FP0 + FLOAT_S		; Get first float state bit field
	and	#FLOAT_S_MNEG		; Mask to get mantissa sign
	lsr				; Shift into bit 0
	sta	GP2

	lda	FP1 + FLOAT_S		; Get second float state bit field
	and	#FLOAT_S_MNEG		; Mask to get mantissa sign
	ora	GP2			; Combine with first float exponent sign
	sta	GP2			; Save in GP2 for later

	cmp	#$00			; If both mantissas positive
	beq	.add_mantissas		; Then add both mantissa magnitudes
	cmp	#$02			; If both mantissas negative
	beq	.add_mantissas		; Then add both mantissa magnitudes

	; If we're subtracting mantissa mangitudes, then to prevent underflow,
	; we will subtract the lower magnitude from the higher one. To achieve
	; this, we will assign FP0 as the higher magnitude and FP1 as the lower,
	; so that the final magnitude will be FP0 - FP1. We'll store a flag to
	; denote if FP0 and FP1 were swapped (where FP1 originally had the
	; higher magnitude but now has the lower) as bit 2 in GP2 as this is
	; later used to determine the sign of the result.

	ldx	#FLOAT_M		; Use X as index into both FP0 and FP1

.cmp_mantissas_loop
	lda	FP0,x			; Get current digits from FP0
	cmp	FP1,x			; Compare with current digits from FP1
	bcc	.mts0_lt_mts1		; If FP0's < FP1's, then stop comparing

	cpx	#FLOAT_M		; 6 bytes containing 12 digits
	bcs	.cmp_mantissas_loop

	lda	GP2			; Clear bit 2 of GP2 to denote no swap
	and	#!$04
	sta	GP2

	bra	.sub_mantissas		; If FP0 mts < FP1 mts, then swap

.mts0_lt_mts1
	lda	#FP0 & $FF		; Load address of first float in GP0
	sta	GP0
	lda	#FP0 >> 8
	sta	GP0 + 1

	lda	#FP1 & $FF		; Load address of second float in GP1
	sta	GP1
	lda	#FP1 >> 8
	sta	GP1 + 1

	jsr	float_swap		; Swap both floats

	lda	GP2			; Set bit 2 of GP2 to denote swap
	ora	#$04
	sta	GP2

.sub_mantissas
	ldx	#FLOAT_E - 1		; Use X as index into both FP0 and FP1

	sed
	sec

.sub_mantissa_loop
	lda	FP0,x			; Subtract FP1 digits from FP0 and store
	sbc	FP1,x			; in result
	sta	FP2,x

	dex

	cpx	#FLOAT_M		; 6 bytes containing 12 digits
	bcs	.sub_mantissa_loop

	cld

	; To find the mantissa sign when subtracting magnitudes, bits 0 and 2
	; of GP2 are exclusive ORed together. If the result is 1, then the
	; resultant mantissa is negative.

	lda	FP2 + FLOAT_S		; Clear negative mantissa flag in result
	and	#!FLOAT_S_MNEG		; states bit field
	sta	FP2 + FLOAT_S

	lda	GP2			; Get bits from GP2
	and	#$04			; Mask to get bit 2 (whether swapped)
	bsr				; Shift into bit 0
	bsr
	eor	GP2			; Exclusive OR with bit 0 (FP0 sign)
	and	#$01			; Mask to get bit 0
	ora	FP2 + FLOAT_S		; Combine with current result states
	sta	FP2 + FLOAT_S		; Store bit as FLOAT_S_MNEG

	rts

.add_mantissas
	ldx	#FLOAT_E - 1		; Use X as index into both FP0 and FP1

	sed
	clc

.add_mantissa_loop
	lda	FP0,x			; Add FP0 and FP1 digits and store in
	adc	FP1,x			; result
	sta	FP2,x

	dex

	cpx	#FLOAT_M		; 6 bytes containing 12 digits
	bcs	.add_mantissa_loop

	cld

	bcc	.no_overflow		; If overflow when adding, shift digits

	ldx	#FLOAT_E - 1		; Use X as index into FP0
	ldy	#FLOAT_E - 2

.shift_mts_loop
	lsr	FP2,x			; Shift high nibble into low nibble
	lsr	FP2,x
	lsr	FP2,x
	lsr	FP2,x

	lda	FP2,y			; Get low nibble of next byte and shift
	asl				; it into high nibble to insert into
	asl				; current byte
	asl
	asl
	ora	FP2,x
	sta	FP2,x

	dex
	dey

	cpx	#FLOAT_M		; 6 bytes containing 12 digits
	bcs	.shift_mts_loop

	ldx	#FLOAT_M		; Set high nibble of first byte to 1 as
	lda	FP2,x			; a result of carry
	and	#$0F
	ora	$10
	sta	FP2,x

	lda	#FP2 & $FF		; Load address of first float in GP2
	sta	GP0
	lda	#FP0 >> 8
	sta	GP2 + 1

	jsr	float_incexp		; Increment exponent

.no_overflow
	; Since the mantissa signs are the same for FP0 and FP1, either sign can
	; be used to determine the sign of the result's magnitude in FP2.

	lda	FP2 + FLOAT_S		; Clear negative mantissa flag in result
	and	#!FLOAT_S_MNEG		; states bit field
	sta	FP2 + FLOAT_S

	lda	GP2			; Get bits from GP2
	and	#$01			; Mask to get bit 0 (FP0 mantissa sign)
	ora	FP2 + FLOAT_S		; Combine with current result states
	sta	FP2 + FLOAT_S		; Store bit as FLOAT_S_MNEG

	rts