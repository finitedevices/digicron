; FLOATING-POINT INPUT/OUTPUT ROUTINES
; Routines to display floating-point values and input new values.

; Float input states (bit field)
FIO_STATE_DP	= $01			; Set if decimal point has been entered
FIO_STATE_EXP	= $02			; Set if entering exponent
FIO_STATE_DPEXP = $03			; Mask for decimal point and exponent
FIO_STATE_KEYDN	= $04			; Set if negate key still down
FIO_STATE_DIGEN	= $10			; Set if digit just entered

!zone	fio_disp
; Show the value of the float in FP0 on the display. The float's value will be
; normalised before it is shown. A can be used to set a minimum number of digits
; to show when the standard notation is used, which is useful for inputting
; floats to ensure that all digits the user has entered are shown (set A to
; number of digits entered). Setting A to -1 ($FF) will always show the value in
; scientific notation instead of standard notation for numbers with exponent in
; range [-4,6]. If neither use case is required, then set A to 0 before calling.
; INPUT:	FP0 = Value of float to show
;		A = Minimum number of digits to display in standard notation
; OUTPUT:	FP0 = Normalised value of shown float rounded to number of
;		displayable digits
;		A, X, Y, GP0-5 = Trashed
; VARIABLES:	GP2 = Minimum digits to display
;		GP3 = Rounding pass completed flag
;		GP4 = Total digits to display/column index (LSB) and current
;		digit exponent in binary (MSB)
;		GP5 = Index of prepended zero digit (LSB) and number of zero
;		digits to prepend (MSB)
fio_disp
	sta	GP2			; Save minimum digits to display

	stz	GP3			; Clear rounding pass completed flag

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

	cpy	#7			; If 8 or more digits in integer then
	bcs	.show_scientific	; show using scientific notation

	jmp	.show_standard

.negative_exponent
	cpy	#7			; If 7 or more zeros after decimal point
	bcs	.show_scientific	; then show using scientific notation

	jmp	.show_standard

.nan
	jsr	gfx_clear		; Clear display

	lda	#<.NAN_MSG
	sta	GP0
	lda	#>.NAN_MSG
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Show "NAN" message

	rts

.inf
	jsr	gfx_clear		; Clear display

	lda	#<.INF_MSG
	sta	GP0
	lda	#>.INF_MSG
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
	lda	#4			; Round to 4 displayable digits
	jsr	float_round

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

	bra	.round_displayable

.positive_exponent
	lda	GP4 + 1			; Get exponent
	inc
	cmp	GP4			; If exponent > number of digits
	bcc	.no_trailing_zeros	; Then add trailing zeros
	sta	GP4			; Done by setting # of digits to exp

.no_trailing_zeros
	lda	GP4			; If total number of digits is >= 8
	cmp	#8
	bcc	.round_displayable	; Then cap to 7 digits

	lda	#7			; Cap to 7 digits to ensure sign visible
	sta	GP4

.round_displayable
	lda	GP3			; Get rounding pass completed flag
	bne	.set_initial_column	; If set then don't round

	sec
	lda	#7			; Round to 7 displayable digits
	sbc	GP5 + 1			; Subtract by number of prepended zeros
	jsr	float_round

	lda	#1			; Set rounding pass completed flag
	sta	GP3

	bra	.show_standard

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

!zone	fio_newinput
; Reset the input state to allow the entry of a new value for FP0. This
; subroutine does not clear the value of FP0; its value will be cleared upon the
; input of the first key to edit the value.
; INPUT:	None
; OUTPUT:	None
;		A = Trashed
fio_newinput
	stz	FIO_STATE		; Clear input states bit field
	stz	FIO_DIGITS		; Set input digit count to 0

	rts

!zone	fio_dispinput
; Display the current edited value of FP0.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0-5, FP1 = Trashed
fio_dispinput
	lda	#<FP0			; Store address of FP0 in GP0
	sta	GP0
	lda	#>FP0
	sta	GP0 + 1

	lda	#<FP1			; Store address of FP1 in GP1
	sta	GP1
	lda	#>FP1
	sta	GP1 + 1

	jsr	float_copy		; Copy value of FP0 to FP1 to retain it

	lda	FIO_STATE		; Get input states bit field
	and	#FIO_STATE_EXP		; Mask to get exponent flag
	bne	.disp_float_exp		; If set then force scientific notation

	lda	FIO_DIGITS		; Use digit count as min digits to disp
	bra	.disp_float

.disp_float_exp
	lda	#-1			; Use special value to force scientific

.disp_float
	jsr	fio_disp		; Display current FP0 value

	lda	#<FP1			; Store address of FP1 in GP0
	sta	GP0
	lda	#>FP1
	sta	GP0 + 1

	lda	#<FP0			; Store address of FP0 in GP1
	sta	GP1
	lda	#>FP0
	sta	GP1 + 1

	jsr	float_copy		; Copy value of FP1 to FP0 to restore it

	rts

!zone	fio_inputkey
; Handle the current keypress for editing the value in FP0. If C is set, then
; the calling routine should re-render the value of FP0 by calling
; fio_dispinput, since the value or state of FP0 will have been changed. If C is
; clear, then it is not necessary to call fio_dispinput since the action taken
; has not resulted in value or state changes.
; INPUT:	A = Captured key state to handle
; OUTPUT:	C = Set if resultant behaviour requires value re-render
;		A, Y, GP0-2 = Trashed
fio_inputkey
	cmp	#KEY_HOLD | KEY_0	; If 0 held, then clear entry
	beq	.key_0_hold_action
	cmp	#KEY_HOLD | KEY_MUL	; If * held, then enter exponent
	beq	.key_mul_hold_action
	cmp	#KEY_HOLD | KEY_SUB	; If - held, then negate mantissa or exp
	beq	.key_sub_hold_action
	cmp	#KEY_PRESS | KEY_DOT	; If . pressed, then enter decimal point
	beq	.key_dot_action

	clc				; Only accept BCD with pressed keys
	jsr	input_keytobcd		; Convert key to BCD if applicable
	bcc	.bcd_valid		; If not numeric, don't do anything

	lda	FIO_STATE		; Clear key still down and digit flags
	and	#!FIO_STATE_KEYDN | FIO_STATE_DIGEN
	sta	FIO_STATE

	clc				; If key not matched then don't do
	rts				; anything

.key_0_hold_action
	jmp	.clear

.key_mul_hold_action
	jmp	.exponent

.key_sub_hold_action
	jmp	.negate

.key_dot_action
	jmp	.decimal_point

.bcd_valid
	sta	GP2			; Save key value to GP2 LSB

	lda	FIO_STATE		; Set digit entered flag
	ora	#FIO_STATE_DIGEN
	sta	FIO_STATE

.input_digit
	lda	FIO_STATE		; Get input states bit field
	and	#FIO_STATE_EXP		; Mask to get exponent flag
	bne	.exponent_digit		; If set then enter digit into exponent

	lda	#<FP0			; Load address of FP0 into GP0
	sta	GP0
	lda	#>FP0
	sta	GP0 + 1

	lda	FIO_DIGITS		; If no digits entered yet, then clear
	bne	.digits_entered		; FP0 to allow entry of new value

	jsr	float_zero		; Clear FP0 (already in GP0)

	lda	GP2			; If first digit entered is 0, then
	bne	.insert_mantissa	; don't enter it

	sec
	rts

.digits_entered
	lda	FIO_DIGITS		; Get count of digits entered
	cmp	#7			; Stop entry when at max digits
	beq	.mantissa_digit_stop	; displayable for mantissa

	lda	FIO_STATE		; Get input states bit field
	and	#FIO_STATE_DP		; Mask to get decimal point flag
	bne	.insert_mantissa	; If not set then increment exponent

	sed				; Increment exponent (BCD) — no need to
	clc				; check overflow since can only reach
	lda	FP0 + FLOAT_E		; max digits
	adc	#1
	sta	FP0 + FLOAT_E
	cld

.insert_mantissa
	lda	FIO_DIGITS		; Get count of digits entered
	lsr				; Shift to get byte index into mantissa
	clc				; Add byte index to address of FP0
	adc	GP0
	sta	GP0

	lda	GP0 + 1			; Add carried result into MSB
	adc	#0
	sta	GP0 + 1

	lda	FIO_DIGITS		; If current digit count is odd, then
	and	#$01			; insert low digit
	bne	.low_digit		; Otherwise insert high digit

	ldy	#0
	lda	GP2			; Get BCD value
	asl				; Shift low nibble into high nibble
	asl
	asl
	asl
	sta	(GP0),y			; Store into current mantissa byte

	bra	.next_digit

.low_digit
	ldy	#0
	lda	GP2			; Get BCD value
	ora	(GP0),y			; Combine with current digit in FP0
	sta	(GP0),y			; Store into current mantissa byte

.next_digit
	inc	FIO_DIGITS		; Increment digit count

	sec
	rts

.mantissa_digit_stop
	clc
	rts

.exponent_digit
	lda	FIO_DIGITS		; Get count of digits entered
	cmp	#(FLOAT_E * 2) + 2	; Stop entry when entered all exponent
	beq	.exponent_digit_stop	; digits

	lda	FP0 + FLOAT_E		; Get current exponent value
	asl				; Shift low nibble into high nibble
	asl
	asl
	asl
	ora	GP2			; Combine with BCD value (low nibble)
	sta	FP0 + FLOAT_E		; Store back into exponent value

	bra	.next_digit

.exponent_digit_stop
	clc
	rts

.decimal_point
	lda	FIO_STATE		; Get input states bit field
	and	#FIO_STATE_DPEXP	; Mask to get decimal and exp flags
	bne	.decimal_point_done	; If either set then no re-entry allowed

	lda	FIO_STATE		; Set decimal point flag
	ora	#FIO_STATE_DP
	sta	FIO_STATE
	lda	FIO_DIGITS		; If no digits entered, then clear FP0
	bne	.decimal_point_done

	lda	#<FP0			; Load address of FP0 into GP0
	sta	GP0
	lda	#>FP0
	sta	GP0 + 1

	jsr	float_zero		; Clear FP0

	inc	FIO_DIGITS		; Increment digit count so first is 0

.decimal_point_done
	clc
	rts

.clear
	lda	FIO_STATE		; Get input states bit field
	and	#FIO_STATE_KEYDN	; Mask to get key state
	bne	.clear_no_entry		; If still down then don't do anything

	lda	#<FP0			; Load address of FP0 into GP0
	sta	GP0
	lda	#>FP0
	sta	GP0 + 1

	jsr	float_zero		; Clear FP0

	stz	FIO_DIGITS		; Clear count of digits entered

	lda	#FIO_STATE_KEYDN	; Clear state but set key still down
	sta	FIO_STATE		; flag

	sec
	rts

.clear_no_entry
	clc
	rts

.exponent
	lda	FIO_STATE		; Get input states bit field
	and	#FIO_STATE_EXP		; Mask to get exponent flag
	bne	.exponent_no_reentry	; If set then no re-entry allowed

	lda	FIO_DIGITS		; Get digits entered
	beq	.exponent_no_reentry	; If no digits entered then no exp entry

	lda	FIO_STATE		; Set exponent flag
	ora	#FIO_STATE_EXP
	sta	FIO_STATE
	stz	FP0 + FLOAT_E		; Clear exp so new one can be entered

	lda	#FLOAT_E * 2		; Set digit count to exponent offset
	sta	FIO_DIGITS

	jsr	float_round		; Round to determine exponent shift
	bcs	.use_rounded

	sec
	rts

.exponent_no_reentry
	clc
	rts

.use_rounded
	stz	FP0 + FLOAT_E		; Reset exponent

	lda	FP0 + FLOAT_S		; Clear negative exponent sign
	and	#!FLOAT_S_ENEG
	sta	FP0 + FLOAT_S

	sec
	rts

.negate
	lda	FIO_STATE		; Get input states bit field
	and	#FIO_STATE_KEYDN	; Mask to get key state
	bne	.negate_no_entry	; If still down then don't do anything

	lda	FIO_DIGITS		; Get digits entered
	beq	.negate_no_entry	; If no digits entered then no negation

	lda	FIO_STATE		; Get input states bit field
	and	#FIO_STATE_EXP		; Mask to get exponent flag
	bne	.negate_exponent	; If set then negate exponent

	lda	FP0 + FLOAT_S		; Get float states bit field
	eor	#FLOAT_S_MNEG		; Invert mantissa sign
	sta	FP0 + FLOAT_S		; Store back into bit field

	bra	.negate_done

.negate_exponent
	lda	FP0 + FLOAT_S		; Get float states bit field
	eor	#FLOAT_S_ENEG		; Invert exponent sign
	sta	FP0 + FLOAT_S		; Store back into bit field

.negate_done
	lda	FIO_STATE		; Set key still down flag
	ora	#FIO_STATE_KEYDN
	sta	FIO_STATE

	sec
	rts

.negate_no_entry
	clc
	rts

!zone	fio_input
; Wait for the user to enter a floating-point value. This routine does not
; update the display until the user has pressed a key, meaning that any
; information displayed prior to entering this routine will be retained until
; the user starts entering a value. This is useful to display a prompt or
; contextual information for the user to know before entering a value.
; INPUT:	None
; OUTPUT:	C = Set if entry was cancelled by the user
;		FP0 = Floating-point value entered by the user
;		A, X, Y, GP0-5, FP1 = Trashed
fio_input
	jsr	fio_newinput		; Reset input state

.get_first_key
	jsr	input_getkeypress	; Check first pressed key
	beq	.get_first_key		; If not pressed yet then wait
	cmp	#KEY_PRESS | KEY_SUB	; If - pressed, then negate
	beq	.negate

	bra	.handle_key

.get_key
	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_PRESS | KEY_MUL	; If * pressed, then cancel
	beq	.cancel
	cmp	#KEY_PRESS | KEY_EQU	; If = pressed, then confirm entry
	beq	.confirm
	cmp	#KEY_PRESS | KEY_SUB	; If - pressed, then negate
	beq	.negate

.handle_key
	jsr	fio_inputkey		; Handle pressed key
	bcc	.get_key		; If C clear then no need to re-render

	jsr	fio_dispinput		; Display current input state

	bra	.get_key

.negate
	lda	#KEY_HOLD | KEY_SUB	; Treat pressing - as holding to negate

	bra	.handle_key

.cancel
	sec
	rts

.confirm
	clc
	rts