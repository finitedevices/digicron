; FLOATING-POINT INPUT/OUTPUT ROUTINES
; Routines to display floating-point values and input new values.

; Float input states (bit field)
FIO_STATE_DP	= $01			; Set if decimal point has been entered
FIO_STATE_EXP	= $02			; Set if entering exponent
FIO_STATE_DPEXP = $03			; Mask for decimal point and exponent
FIO_STATE_KEYDN	= $04			; Set if negate key still down
FIO_STATE_DIGEN	= $10			; Set if digit just entered

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
;		A, X, Y, GP0-5, FP0 = Trashed
fio_dispinput
	lda	FIO_STATE		; Get input states bit field
	and	#FIO_STATE_EXP		; Mask to get exponent flag
	bne	.disp_float_exp		; If set then force scientific notation

	lda	FIO_DIGITS		; Use digit count as min digits to disp
	bra	.disp_float

.disp_float_exp
	lda	#-1			; Use special value to force scientific

.disp_float
	jsr	float_disp		; Display current FP0 value

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