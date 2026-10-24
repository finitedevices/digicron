; FLOATING-POINT
; Operations for 8-byte BCD floating-point values.

; Float data type byte layout:
;    0     1     2     3     4     5     6     7
; +===============================================+	M = Mantissa
; | M.M | M M | M M | M M | M M | M M | E E | S S |	E = Exponent
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

	iny

	cpy	#FLOAT_SIZE		; Swap 8 bytes
	bcc	.loop

	rts

!zone	float_zero
; Set the value of the specified float to zero.
; INPUT:	GP0 = Address of float to set value to zero
; OUTPUT:	None
;		A, Y = Trashed
float_zero
	ldy	#0

.loop
	lda	#0			; Clear byte at index
	sta	(GP0),y
	iny

	cpy	#FLOAT_SIZE		; Clear 8 bytes
	bcc	.loop

	rts

!zone	float_iszero
; Check if the specified float is zero. If it is, then C will be set.
; INPUT:	GP0 = Address of float to check value of
; OUTPUT:	C = Set if float is zero, clear otherwise
;		A, Y = Trashed
float_iszero
	ldy	#FLOAT_S		; Get float states bit field and mask to
	lda	(GP0),y			; get infinity and NaN flags
	and	#FLOAT_S_INF | FLOAT_S_NAN
	bne	.is_nonzero		; If either set then is nonzero

	ldy	#FLOAT_M		; Use Y as index into mantissa

.loop
	lda	(GP0),y			; Get current mantissa digits
	bne	.is_nonzero		; If nonzero, then clear C and return

	iny

	cpy	#FLOAT_E		; 6 bytes containing 12 digits
	bcc	.loop

	sec				; Otherwise set C and return
	rts

.is_nonzero
	clc
	rts

!zone	float_disp
; Show the value of the float in FP0 on the display. The float's value will be
; normalised before it is shown. A can be used to set a minimum number of digits
; to show when the standard notation is used, which is useful for inputting
; floats to ensure that all digits the user has entered are shown (set A to
; number of digits entered). Setting A to -1 ($FF) will always show the value in
; scientific notation instead of standard notation for numbers with exponent in
; range [-4,6]. If neither use case is required, then set A to 0 before calling.
; INPUT:	FP0 = Value of float to show
;		A = Minimum number of digits to display in standard notation
; OUTPUT:	FP0 = Normalised value of shown float 
;		A, X, Y, GP0-5 = Trashed
; VARIABLES:	GP2 = Minimum digits to display
;		GP4 = Total digits to display/column index (LSB), current digit
;		exponent in binary (MSB)
;		GP5 = Index of prepended zero digit (LSB), number of zero digits
;		to prepend (MSB)
float_disp
	sta	GP2			; Save minimum digits to display

	jsr	float_norm		; Normalise FP0 first

	ldy	FP0 + FLOAT_E		; Get exponent and store in Y

	lda	FP0 + FLOAT_S		; Get states bit field
	and	#FLOAT_S_NAN		; Mask to get NaN state
	bne	.nan			; If flag set then show NaN message
	lda	FP0 + FLOAT_S
	and	#FLOAT_S_INF		; Mask to get infinity state
	bne	.inf			; If flag set then show inf message
	lda	GP2			; Get minimum digits to display
	cmp	#-1			; If equal to -1
	beq	.show_scientific	; Then always show scientific notation
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
	bcc	.set_initial_column	; Then cap to 7 digits

	lda	#7			; Cap to 7 digits to ensure sign visible
	sta	GP4

.set_initial_column
	lda	GP4			; Get current total digits to display
	cmp	GP2			; Compare to minimum to display
	bcs	.past_min_digits	; If minimum >, then set as total

	lda	GP2			; Get minimum to display
	cmp	#8			; If minimum number of digits is >= 8
	bcc	.save_min_digits	; Then cap to 7 digits
	
	lda	#7			; Cap to 7 digits to ensure sign visible

.save_min_digits
	sta	GP4			; Store as total digits to display

.past_min_digits
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

	lda	GP4 + 1			; Get current digit exponent
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

!zone	float_norm_fp2
; Normalise the float in FP2 such that the integer part of the mantissa is
; within the range [1, 9]. This subroutine simplifies the post-computation
; normalisation process for floating-point routines that take 2 operands (FP0
; and FP1) and store the result in FP2.
; INPUT:	FP2 = Value of float to normalise
; OUTPUT:	FP2 = Value of normalised float
;		A, X, Y, GP0, FP0 = Trashed
float_norm_fp2
	lda	#FP2 & $FF		; Load address of FP2 in GP0
	sta	GP0
	lda	#FP2 >> 8
	sta	GP0 + 1

	lda	#FP0 & $FF		; Load address of float variable used
	sta	GP1			; for normalisation in GP1
	lda	#FP0 >> 8
	sta	GP1 + 1

	jsr	float_copy		; Copy FP2 into FP0
	jsr	float_norm		; Normalise result of FP0

	lda	#FP0 & $FF		; Load address of float variable used
	sta	GP0			; for normalisation in GP0
	lda	#FP0 >> 8
	sta	GP0 + 1

	lda	#FP2 & $FF		; Load address of FP2 float in GP1
	sta	GP1
	lda	#FP2 >> 8
	sta	GP1 + 1

	jsr	float_copy		; Copy FP0 back into FP2

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
; Add the floats in FP0 and FP1 and store the result in FP2. To ensure maximum
; precision, FP0 and FP1 should be normalised before calling this subroutine.
; The resultant value will be normalised.
; INPUT:	FP0 = Value of first float to add
;		FP1 = Value of second float to add
; OUTPUT:	FP2 = Result of adding FP0 and FP1 together
;		A, X, Y, FP0, FP1, GP0-2 = Trashed
; VARIABLES:	GP2 = Mantissa sign flags (bit 0 = FP0's, bit 1 = FP1's, bit 2
;		set if FP0's mantissa magnitude was < FP1's mantissa magnitude)
float_add
	; Before performing floating-point addition, we'll need to handle the
	; following special cases (commutative):
	; 	NaN + any value	= NaN
	;	infinity + infinity = infinity
	;	-infinity + -infinity = -infinity
	;	infinity + finite value = infinity
	;	-infinity + finite value = -infinity
	;	infinity + -infinity = NaN

	lda	FP0 + FLOAT_S		; If either value is NaN, then return
	ora	FP1 + FLOAT_S		; NaN
	and	#FLOAT_S_NAN
	beq	.not_nan

.handle_nan
	lda	#FLOAT_S_NAN		; Set result value to be NaN
	sta	FP2 + FLOAT_S

	rts

.not_nan
	lda	FP0 + FLOAT_S		; Get FP0 infinity and sign flags
	and	#FLOAT_S_INF | FLOAT_S_MNEG
	sta	GP0			; Store in GP0

	lda	FP1 + FLOAT_S		; Get FP1 infinity and sign flags
	and	#FLOAT_S_INF | FLOAT_S_MNEG
	asl				; Shift into high nibble
	asl
	asl
	asl
	ora	GP0			; Combine with Gp0
	sta	GP0			; Store combined value in GP0

	cmp	#FLOAT_S_INF | ((FLOAT_S_INF | FLOAT_S_MNEG) << 4)
	beq	.handle_nan		; FP0 = inf, FP1 = -inf => NaN
	cmp	#FLOAT_S_INF | FLOAT_S_MNEG | (FLOAT_S_INF << 4)
	beq	.handle_nan		; FP0 = -inf, FP1 = inf => NaN

	and	#FLOAT_S_INF | (FLOAT_S_INF << 4)
	beq	.handle_finite		; Neither is +/- inf, then add numbers

	lda	GP0			; If FP0 -inf, then return -inf
	and	#FLOAT_S_INF | FLOAT_S_MNEG
	cmp	#FLOAT_S_INF | FLOAT_S_MNEG
	beq	.handle_neg_inf

	lda	GP0			; If FP1 -inf, then return -inf
	and	#(FLOAT_S_INF | FLOAT_S_MNEG) << 4
	cmp	#(FLOAT_S_INF | FLOAT_S_MNEG) << 4
	beq	.handle_neg_inf

	lda	#FLOAT_S_INF		; Set result value to be infinity
	sta	FP2 + FLOAT_S

	rts

.handle_neg_inf
	lda	#FLOAT_S_INF | FLOAT_S_MNEG
	sta	FP2 + FLOAT_S		; Set result value to be -infinity

	rts

.handle_finite
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
	ora	FP1 + FLOAT_E		; zero, then finish alignment (special
	beq	.no_align		; case to handle either exponent as -0)

	lda	FP0 + FLOAT_S		; Exclusive OR both float state bit
	eor	FP1 + FLOAT_S		; fields together to determine if exp
	and	#FLOAT_S_ENEG		; signs are same
	bne	.exps_neq		; If not then don't check magnitudes

	lda	FP0 + FLOAT_E		; If exponent magnitudes are equal then
	cmp	FP1 + FLOAT_E		; finish alignment
	beq	.no_align

.exps_neq
	ldx	#FLOAT_E		; Use X as index into FP0
	ldy	#FLOAT_E - 1

.shift_exp_loop
	dex
	dey

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

	cpx	#FLOAT_M		; 6 bytes containing 12 digits
	bne	.shift_exp_loop

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

	lda	FP0 + FLOAT_S		; Copy exponent sign into result states
	and	#FLOAT_S_ENEG
	sta	FP2 + FLOAT_S

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
	sta	GP2

	lda	FP1 + FLOAT_S		; Get second float state bit field
	and	#FLOAT_S_MNEG		; Mask to get mantissa sign
	asl				; Shift into bit 1
	ora	GP2			; Combine with first float exponent sign
	sta	GP2			; Save in GP2 for later

	cmp	#$00			; If both mantissas positive
	beq	.add_mantissas		; Then add both mantissa magnitudes
	cmp	#$03			; If both mantissas negative
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
	beq	.next_cmp_mts		; If FP0's = FP1's, then continue
	bcs	.mts0_gt_mts1		; If FP0's > FP1's, then stop comparing
	bra	.mts0_lt_mts1		; If FP0's < FP1's, then swap

.next_cmp_mts
	inx

	cpx	#FLOAT_E		; 6 bytes containing 12 digits
	bcc	.cmp_mantissas_loop

.mts0_gt_mts1
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
	ldx	#FLOAT_E		; Use X as index into both FP0 and FP1

	sed
	sec

	php

.sub_mantissa_loop
	dex

	plp

	lda	FP0,x			; Subtract FP1 digits from FP0 and store
	sbc	FP1,x			; in result
	sta	FP2,x

	php

	cpx	#FLOAT_M		; 6 bytes containing 12 digits
	bne	.sub_mantissa_loop

	plp

	cld

	; To find the mantissa sign when subtracting magnitudes, bits 0 and 2
	; of GP2 are exclusive ORed together. If the result is 1, then the
	; resultant mantissa is negative.

	lda	FP2 + FLOAT_S		; Clear negative mantissa flag in result
	and	#!FLOAT_S_MNEG		; states bit field
	sta	FP2 + FLOAT_S

	lda	GP2			; Get bits from GP2
	and	#$04			; Mask to get bit 2 (whether swapped)
	lsr				; Shift into bit 0
	lsr
	eor	GP2			; Exclusive OR with bit 0 (FP0 sign)
	and	#$01			; Mask to get bit 0
	ora	FP2 + FLOAT_S		; Combine with current result states
	sta	FP2 + FLOAT_S		; Store bit as FLOAT_S_MNEG

	; Since subtraction could result in leading zeros in the mantissa or -0,
	; normalise the result in FP2.

	jsr	float_norm_fp2		; Normalise the result float

	rts

.add_mantissas
	ldx	#FLOAT_E		; Use X as index into both FP0 and FP1

	sed
	clc

	php

.add_mantissa_loop
	dex

	plp

	lda	FP0,x			; Add FP0 and FP1 digits and store in
	adc	FP1,x			; result
	sta	FP2,x

	php

	cpx	#FLOAT_M		; 6 bytes containing 12 digits
	bne	.add_mantissa_loop

	plp

	cld

	bcc	.no_overflow		; If overflow when adding, shift digits

	ldx	#FLOAT_E		; Use X as index into FP2
	ldy	#FLOAT_E - 1

.shift_mts_loop
	dex
	dey

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

	cpx	#FLOAT_M		; 6 bytes containing 12 digits
	bne	.shift_mts_loop

	ldx	#FLOAT_M
	lda	FP2 + FLOAT_M		; Set high nibble of first byte to 1 as
	and	#$0F			; a result of carry
	ora	#$10
	sta	FP2 + FLOAT_M

	lda	#FP2 & $FF		; Load address of result float in GP2
	sta	GP0
	lda	#FP2 >> 8
	sta	GP0 + 1

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

	; Adding the mantissa magnitudes will result in a value that is already
	; normalised, so we can just return FP2 as it is.

	rts

!zone	float_sub
; Subtract the float in FP1 from FP0 and store the result in FP2. To ensure
; maximum precision, FP0 and FP1 should be normalised before calling this
; subroutine. The resultant value will be normalised.
; INPUT:	FP0 = Value of first float to subtract
;		FP1 = Value of second float to subtract from the first
; OUTPUT:	FP2 = Result of subtracting FP1 from FP0
;		A, X, Y, FP0, FP1, GP0-2 = Trashed
float_sub
	lda	FP1 + FLOAT_S		; Get second float state bit field
	eor	#FLOAT_S_MNEG		; Negate mantissa sign
	sta	FP1 + FLOAT_S		; Store back into second float

	jsr	float_add		; Add floats with FP1 negative

	rts

!zone	float_mul
; Multiply the floats in FP0 and FP1 and store the result in FP2. To ensure
; maximum precision, FP0 and FP1 should be normalised before calling this
; subroutine. The resultant value will be normalised.
; INPUT:	FP0 = Value of first float to multiply
;		FP1 = Value of second float to multiply
; OUTPUT:	FP2 = Result of multiplying FP0 and FP1 together
;		A, X, Y, FP0, FP1, FP3, GP0 = Trashed
; VARIABLES:	GP0 = Current FP1 digit (LSB), digit index into FP1 (MSB)
float_mul
	; Before performing floating-point multiplication, we'll need to handle
	; the following special cases (commutative):
	; 	NaN * any value	= NaN
	;	infinity * infinity = infinity
	;	-infinity * infinity = -infinity
	;	-infinity * -infinity = infinity
	;	+/- infinity * 0 = NaN
	;	infinity * nonzero finite value = infinity
	;	-infinity * nonzero finite value = -infinity

	lda	FP0 + FLOAT_S		; If either value is NaN, then return
	ora	FP1 + FLOAT_S		; NaN
	and	#FLOAT_S_NAN
	beq	.not_nan

.handle_nan
	lda	#FLOAT_S_NAN		; Set result value to be NaN
	sta	FP2 + FLOAT_S

	rts

.not_nan
	lda	FP0 + FLOAT_S		; If both values are infinity, then
	and	FP1 + FLOAT_S		; return infinity with mantissa signs
	and	#FLOAT_S_INF		; exclusive ORed
	beq	.not_both_inf

	lda	#FLOAT_S_INF		; Set result value to be infinity
	sta	FP2 + FLOAT_S

	jmp	.set_signs

.not_both_inf
	lda	FP0 + FLOAT_S		; If FP0 is infinity, then check value
	and	#FLOAT_S_INF		; of FP1
	beq	.not_fp0_inf

	lda	#FP1 & $FF		; Load address of FP1 into GP0
	sta	GP0
	lda	#FP1 >> 8
	sta	GP0 + 1

	jsr	float_iszero		; If FP1 is zero then return NaN
	bcs	.handle_nan

	lda	FP0 + FLOAT_S		; Otherwise set result to infinity with
	sta	FP2 + FLOAT_S		; same sign as FP0

	rts

.not_fp0_inf
	lda	FP1 + FLOAT_S		; If FP1 is infinity, then check value
	and	#FLOAT_S_INF		; of FP0
	beq	.handle_finite

	lda	#FP0 & $FF		; Load address of FP0 into GP0
	sta	GP0
	lda	#FP0 >> 8
	sta	GP0 + 1

	jsr	float_iszero		; If FP0 is zero then return NaN
	bcs	.handle_nan

	lda	FP1 + FLOAT_S		; Otherwise set result to infinity with
	sta	FP2 + FLOAT_S		; same sign as FP1

	rts

.handle_finite
	; First step is to multiply the mantissa digits using long
	; multiplication. To preserve accuracy during the multiplication
	; process, we will initially store the multiplication result in 24
	; digits (12 bytes) before this value is truncated to fit into the
	; result. To achieve this, we will store the result digits in all 8
	; bytes of FP2 and the first 4 bytes of FP3.

	; Long multiplication is achieved by adding FP0 to the result multiple
	; times. For each increasingly significant digit in FP1, we add FP0 to
	; FP2 as many times as that digit's value, and then shift FP2 right
	; before processing the next significant digit in FP1.

	ldx	#0			; Use X as index into result bytes

.clear_loop
	stz	FP2,x			; Clear digits in byte
	inx

	cpx	#12			; 12 bytes containing 24 digits
	bcc	.clear_loop

	lda	#(FLOAT_E * 2) - 1	; Use GP0 MSB as digit index into FP1
	sta	GP0 + 1

.fp1_loop
	lda	GP0 + 1			; Get FP1 digit index
	lsr				; Shift to get byte index
	tay				; Store byte index in Y

	lda	GP0 + 1			; Determine if digit is high or low
	and	#$01			; If index is odd then low digit
	beq	.get_high_digit		; Otherwise high digit

	lda	FP1,y			; Get digits from FP1
	and	#$0F			; Mask to get low digit
	sta	GP0			; Store digit in GP0 LSB

	bra	.process_digit

.get_high_digit
	lda	FP1,y			; Get digits from FP1
	and	#$F0			; Mask to get high digit
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	sta	GP0			; Store digit in GP0 LSB

.process_digit
	ldy	#0			; Use Y as carry from digit addition

.digit_loop
	lda	GP0			; Get current FP1 digit
	beq	.digit_done		; If zero then stop adding

	ldx	#FLOAT_E		; Use X as index into FP0 and result

	sed
	clc
	php

.fp0_loop
	dex

	plp

	lda	FP2,x			; Get current result digits
	adc	FP0,x			; Add FP0 digits
	sta	FP2,x			; Store back into result digits

	php

	cpx	#FLOAT_M
	bne	.fp0_loop

	plp
	bcc	.no_carry

	iny				; Increment carry value

.no_carry
	dec	GP0			; Decrement current FP1 digit (BCD)

	cld

	bra	.digit_loop

.digit_done
	tya				; Get carried value in Y
	asl				; Shift low nibble into high nibble so
	asl				; that carry digit can be placed into
	asl				; first digit of result after shifting
	asl
	sta	GP0			; Store in GP0

	ldx	#12			; Use X as index into result bytes
	ldy	#11

.shift_loop
	dex
	dey

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

	cpx	#0			; 12 bytes containing 24 digits
	bne	.shift_loop

	lda	FP2			; Set first digit of result to carried
	and	#$0F			; value from GP0
	ora	GP0
	sta	FP2

	lda	GP0 + 1			; Get current digit index
	beq	.round_result		; If zero then finish adding mantissas
	dec				; Otherwise decrement index
	sta	GP0 + 1

	bra	.fp1_loop		; Process next digit of FP1

.round_result
	; Next step is to round the result digits so that the result is correct
	; to the nearest 12th digit, since we are discarding the lower 12
	; digits.

	ldx	#12			; Use X as index into result bytes

	sed

.round_loop
	dex

	lda	FP2,x			; Get current digits
	cmp	#$50			; If >= 50, then round higher digits
	bcc	.round_next

	dex				; Increment next highest digits (BCD)
	inc	FP2,x
	inx

.round_next
	cpx	#6			; 6 bytes containing 12 digits (only
	bne	.round_loop		; digits that overflow FP2)

	cld

.add_exponents
	; Next step is to add FP1's exponent to FP0's exponent. We will do this
	; by making repeated calls to float_incexp or float_decexp (depending on
	; FP1's sign), which is a time-inefficient approach, but is a much
	; easier way of handling FP0's exponent crossing the negative-to-
	; positive boundary and vice versa.

	lda	FP0 + FLOAT_E		; Copy FP0's exponent
	sta	FP2 + FLOAT_E		; Store in result float
	lda	FP0 + FLOAT_S		; Copy FP0's state (includes exp sign)
	sta	FP2 + FLOAT_S		; Store in result float

	lda	#FP2 & $FF		; Store FP1's address into GP0 for use
	sta	GP0			; with float_incexp and float_decexp
	lda	#FP2 >> 8
	sta	GP0 + 1

	jsr	float_incexp		; Increment exp to account for shift

.add_exp_loop
	lda	FP1 + FLOAT_E		; Get FP1's exponent
	beq	.set_signs		; If zero then finish adding

	lda	FP1 + FLOAT_S		; Get FP1's state bit field
	and	#FLOAT_S_ENEG		; Mask to get exponent sign
	bne	.dec_exp		; If negative, then decrement result exp

	jsr	float_incexp		; Increment result exponent
	bcs	.add_exp_overflow	; If exponent overflowed then return inf

	sed				; Decrement FP1's exp magnitude (BCD)
	dec	FP1 + FLOAT_E
	cld

	bra	.add_exp_loop

.dec_exp
	jsr	float_decexp		; Decrement result exponent
	bcs	.add_exp_overflow	; If exponent underflowed then ret -inf

	sed				; Decrement FP1's exp magnitude (BCD)
	dec	FP1 + FLOAT_E
	cld

	bra	.add_exp_loop

.add_exp_overflow
	rts				; Early return if result is +/- infinity

.set_signs
	; Next step is to set the mantissa sign of the result. The sign is found
	; by exlusive ORing the mantissa signs of FP0 and FP1, as per
	; multiplication rules:
	;	positive value * positive value = positive result
	;	negative value * positive value = negative result
	;	positive value * negative value = negative result
	;	negative value * negative value = positive result

	lda	FP2 + FLOAT_S		; Clear negative mantissa flag in result
	and	#!FLOAT_S_MNEG		; states bit field
	sta	FP2 + FLOAT_S

	lda	FP0 + FLOAT_S		; Get FP0 states bit field
	eor	FP1 + FLOAT_S		; Exclusive OR with FP1 states bit field
	and	#FLOAT_S_MNEG		; Mask to get mantissa sign flag
	ora	FP2 + FLOAT_S		; Combine with other result bits
	sta	FP2 + FLOAT_S		; Store in result bit field

	; Finally, normalise the result in FP2.

	jsr	float_norm_fp2		; Normalise the result float

	rts

!zone	float_div
; Divide the float in FP0 by FP1 and store the result in FP2. To ensure maximum
; precision, FP0 and FP1 should be normalised before calling this subroutine.
; The resultant value will be normalised.
; INPUT:	FP0 = Value of first float to divide
;		FP1 = Value of second float to divide the first by
; OUTPUT:	FP2 = Result of dividing FP0 by FP1
;		A, X, Y, FP0, FP1, GP0, GP1 = Trashed
; VARIABLES:	GP0 = Count of subtractions to store as digit in result (LSB),
;		current index to place digit in result (MSB)
float_div
	; Before performing floating-point division, we'll need to handle the
	; following special cases:
	; 	NaN / any value	= NaN
	;	any value / NaN = NaN
	;	+/- infinity / +/- infinity = NaN
	;	0 / 0 = NaN
	;	0 / +/- infinity = NaN
	;	positive nonzero finite value / 0 = infinity
	;	negative nonzero finite value / 0 = -infinity
	;	infinity / nonzero positive finite value = infinity
	;	-infinity / nonzero positive finite value = -infinity
	;	infinity / nonzero negative finite value = -infinity
	;	-infinity / nonzero negative finite value = infinity
	;	nonzero finite value / +/- infinity = 0

	lda	FP0 + FLOAT_S		; If either value is NaN, then return
	ora	FP1 + FLOAT_S		; NaN
	and	#FLOAT_S_NAN
	beq	.not_nan

.handle_nan
	lda	#FLOAT_S_NAN		; Set result value to be NaN
	sta	FP2 + FLOAT_S

	rts

.not_nan
	lda	FP0 + FLOAT_S		; If both values are infinity, then
	and	FP1 + FLOAT_S		; return NaN
	and	#FLOAT_S_INF
	bne	.handle_nan

	lda	#FP1 & $FF		; Load address of FP1 into GP0
	sta	GP0
	lda	#FP1 >> 8
	sta	GP0 + 1

	jsr	float_iszero		; If FP1 is zero then return inf or NaN
	bcc	.not_fp0_zero

	lda	#FP0 & $FF		; Load address of FP0 into GP0
	sta	GP0
	lda	#FP0 >> 8
	sta	GP0 + 1

	jsr	float_iszero		; If 0 / 0 then return NaN
	bcs	.handle_nan

	lda	FP0 + FLOAT_S		; Otherwise return infinity with
	and	#FLOAT_S_MNEG		; mantissa sign of FP0 copied
	ora	#FLOAT_S_INF
	sta	FP2 + FLOAT_S

	rts

.not_fp0_zero
	lda	FP0 + FLOAT_S		; If FP0 is infinity, then return
	and	#FLOAT_S_INF		; infinity with mantissa signs exclusive
	beq	.not_fp0_inf		; ORed

	lda	#FLOAT_S_INF		; Set result value to be infinity
	sta	FP2 + FLOAT_S

	jmp	.set_signs

.not_fp0_inf
	lda	FP1 + FLOAT_S		; If FP1 is infinity, then return NaN or
	and	#FLOAT_S_INF		; 0
	beq	.handle_finite

	lda	#FP0 & $FF		; Load address of FP0 into GP0
	sta	GP0
	lda	#FP0 >> 8
	sta	GP0 + 1

	jsr	float_iszero		; If 0 / +/- infinity then return NaN
	bcs	.handle_nan		; Otherwise return 0

	lda	#FP2 & $FF		; Load address of FP2 into GP0
	sta	GP0
	lda	#FP2 >> 8
	sta	GP0 + 1

	jsr	float_zero		; Set result to 0

	rts

.handle_finite
	; Before performing division, FP1 must be normalised so that the first
	; digit is in the range [1,9]. This is required for the multiplication
	; process mentioned later on to work.

	lda	#FP0 & $FF		; Load address of FP0 in GP0
	sta	GP0
	lda	#FP0 >> 8
	sta	GP0 + 1

	lda	#FP1 & $FF		; Load address of FP1 in GP1
	sta	GP1
	lda	#FP1 >> 8
	sta	GP1 + 1

	jsr	float_swap		; Swap values of FP0 and FP1
	jsr	float_norm		; Normalise result of FP0

	lda	#FP0 & $FF		; Load address of FP0 back into GP0
	sta	GP0			; (GP0 was trashed during float_norm)
	lda	#FP0 >> 8
	sta	GP0 + 1

	jsr	float_swap		; Swap values of FP0 and FP1 back

	; First step is to compute each digit of the mantissa by performing
	; repeated subtraction of FP1 from FP0 and counting the number of
	; subtractions made before FP0 goes negative. This is achieved by
	; checking if FP0 is greater than FP1 first to see if a subtraction
	; would still result in a positive value, and then performing the
	; subtraction if so. Once repeated subtraction is complete, the
	; subtraction count is then stored in the next digit of the result's
	; mantissa, and FP1's digits shifted right to compute the next digit.
	; This overall process is completed when all the digits have been
	; written into the result's mantissa.

	; Example:
	;	Divide 1.234 by 5.678
	;	 1. 1.234 < 5.678		so digit #1 is 0
	;	 2. 1.234 > 0.567		so can subtract
	;	 3. 1.234 - 0.567 = 0.667	(subtraction 1)
	;	 4. 0.667 - 0.567 = 0.100	(subtraction 2)
	;	 5. 0.100 < 0.567		so digit #2 is 2
	;	 6. 0.100 > 0.056		so can subtract
	;	 7. 0.100 - 0.056 = 0.044	(subtraction 1)
	;	 8. 0.044 < 0.056		so digit #3 is 1
	;	 9. 0.044 > 0.005		so can subtract
	;	10. 0.044 - 0.005 = 0.039	(subtraction 1)
	;	11. 0.039 - 0.005 = 0.034	(subtraction 2)
	;	12. 0.034 - 0.005 = 0.029	(subtraction 3)
	;	13. 0.029 - 0.005 = 0.024	(subtraction 4)
	;	14. 0.024 - 0.005 = 0.019	(subtraction 5)
	;	15. 0.019 - 0.005 = 0.014	(subtraction 6)
	;	16. 0.014 - 0.005 = 0.009	(subtraction 7)
	;	17. 0.009 - 0.005 = 0.004	(subtraction 8)
	;	18. 0.004 < 0.005		so digit #4 is 8
	;	19. Computed final digit so result is 0.218
	;	    (would be more accurate with larger mantissa and rounding!)

	lda	#FP2 & $FF		; Load address of FP2 into GP0
	sta	GP0
	lda	#FP2 >> 8
	sta	GP0 + 1

	jsr	float_zero		; Set result to 0

	stz	GP0 + 1			; Clear result digit store index

.compute_digit_loop
	stz	GP0			; Clear subtraction count

.cmp_mantissas
	ldx	#FLOAT_M		; Use X as index into both FP0 and FP1

.cmp_mantissas_loop
	lda	FP0,x			; Get current digits from FP0
	cmp	FP1,x			; Compare with current digits from FP1
	beq	.next_cmp_mts		; If FP0's = FP1's, then continue
	bcs	.sub_mantissas		; If FP0's > FP1's, then subtract
	bra	.store_digit		; If FP0's < FP1's, then store digit

.next_cmp_mts
	inx

	cpx	#FLOAT_E		; 6 bytes containing 12 digits
	bcc	.cmp_mantissas_loop

.sub_mantissas
	ldx	#FLOAT_E		; Use X as index into both FP0 and FP1

	sed
	sec

	php

.sub_mantissa_loop
	dex

	plp

	lda	FP0,x			; Subtract FP1 digits from FP0 and store
	sbc	FP1,x			; in FP0
	sta	FP0,x

	php

	cpx	#FLOAT_M		; 6 bytes containing 12 digits
	bne	.sub_mantissa_loop

	plp

	inc	GP0			; Increment subtraction count

	cld

	bra	.cmp_mantissas

.store_digit
	lda	GP0 + 1			; Get result digit store index
	lsr				; Shift to get byte index into mantissa
	tax				; Use X as byte index

	lda	GP0 + 1			; Get result digit store index
	and	#$01			; If digit index is odd then low digit
	beq	.store_high_digit	; Otherwise high digit

	lda	GP0			; Store digit in low nibble alongside
	ora	FP2,x			; current high digit in result
	sta	FP2,x

	bra	.next_digit

.store_high_digit
	lda	GP0			; Get digit
	asl				; Shift low nibble into high nibble
	asl
	asl
	asl
	ora	FP2,x			; Store digit in high nibble alongside
	sta	FP2,x			; current low digit in result

.next_digit
	lda	GP0 + 1			; Get result digit store index
	inc				; Increment it
	sta	GP0 + 1			; Store incremented value
	cmp	#FLOAT_E * 2		; If reached last digit, then stop
	beq	.sub_exponents		; Otherwise, shift divisor and continue

	ldx	#FLOAT_E		; Use X as index into FP1
	ldy	#FLOAT_E - 1

.shift_mts_loop
	dex
	dey

	lsr	FP1,x			; Shift high nibble into low nibble
	lsr	FP1,x
	lsr	FP1,x
	lsr	FP1,x

	lda	FP1,y			; Get low nibble of next byte and shift
	asl				; it into high nibble to insert into
	asl				; current byte
	asl
	asl
	ora	FP1,x
	sta	FP1,x

	cpx	#FLOAT_M		; 6 bytes containing 12 digits
	bne	.shift_mts_loop

	ldx	#FLOAT_M		; Clear high nibble of first byte
	lda	FP1,x			; (setting first digit to 0)
	and	#$0F
	sta	FP1,x

	bra	.compute_digit_loop

.sub_exponents
	; Next step is to subtract FP1's exponent from FP0's exponent. We will
	; do this by making repeated calls to float_decexp or float_incexp
	; (depending on FP1's sign), which is a time-inefficient approach, but
	; is a much easier way of handling FP0's exponent crossing the
	; positive-to-negative boundary and vice versa.

	lda	FP0 + FLOAT_E		; Copy FP0's exponent
	sta	FP2 + FLOAT_E		; Store in result float
	lda	FP0 + FLOAT_S		; Copy FP0's state (includes exp sign)
	sta	FP2 + FLOAT_S		; Store in result float

	lda	#FP2 & $FF		; Store FP1's address into GP0 for use
	sta	GP0			; with float_decexp and float_incexp
	lda	#FP2 >> 8
	sta	GP0 + 1

.sub_exp_loop
	lda	FP1 + FLOAT_E		; Get FP1's exponent
	beq	.set_signs		; If zero then finish subtracting

	lda	FP1 + FLOAT_S		; Get FP1's state bit field
	and	#FLOAT_S_ENEG		; Mask to get exponent sign
	bne	.inc_exp		; If negative, then increment result exp

	jsr	float_decexp		; Decrement result exponent
	bcs	.sub_exp_overflow	; If exponent underflowed then ret -inf

	sed				; Decrement FP1's exp magnitude (BCD)
	dec	FP1 + FLOAT_E
	cld

	bra	.sub_exp_loop

.inc_exp
	jsr	float_incexp		; Increment result exponent
	bcs	.sub_exp_overflow	; If exponent overflowed then return inf

	sed				; Decrement FP1's exp magnitude (BCD)
	dec	FP1 + FLOAT_E
	cld

	bra	.sub_exp_loop

.sub_exp_overflow
	rts				; Early return if result is +/- infinity

.set_signs
	; Next step is to set the mantissa sign of the result. The sign is found
	; by exlusive ORing the mantissa signs of FP0 and FP1, as per division
	; rules:
	;	positive value / positive value = positive result
	;	negative value / positive value = negative result
	;	positive value / negative value = negative result
	;	negative value / negative value = positive result

	lda	FP2 + FLOAT_S		; Clear negative mantissa flag in result
	and	#!FLOAT_S_MNEG		; states bit field
	sta	FP2 + FLOAT_S

	lda	FP0 + FLOAT_S		; Get FP0 states bit field
	eor	FP1 + FLOAT_S		; Exclusive OR with FP1 states bit field
	and	#FLOAT_S_MNEG		; Mask to get mantissa sign flag
	ora	FP2 + FLOAT_S		; Combine with other result bits
	sta	FP2 + FLOAT_S		; Store in result bit field

	; Finally, normalise the result in FP2.

	jsr	float_norm_fp2		; Normalise the result float

	rts