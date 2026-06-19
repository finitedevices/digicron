; DATE AND TIME MANAGEMENT
; Used to maintain the current date and time, and to perform time-related
; calculations.

!zone	time_init
; Initialise the current date and time.
; INPUT:	None
; OUTPUT:	None
;		A = Trashed
time_init
	lda	#$20			; Store 2026 as BCD in year (MSB first)
	sta	CT_DATE_YEAR + 1
	lda	#$26
	sta	CT_DATE_YEAR

	lda	#$01
	sta	CT_DATE_MONTH
	sta	CT_DATE_DAY

	lda	#$00
	sta	CT_TIME_HOUR
	sta	CT_TIME_MINUTE
	sta	CT_TIME_SECOND
	sta	CT_TIME_TICK

	rts

!zone	time_increment
; Increment the current time by 1 second.
; INPUT:	None
; OUTPUT:	None
;		A = Trashed
time_increment
	sed
	clc

	lda	CLOCK			; Set clock second top to new value
	sta	CLOCK_SEC_TOP
	lda	CLOCK + 1
	sta	CLOCK_SEC_TOP + 1

	stz	CT_TIME_TICK		; Reset tick to 0

	lda	CT_TIME_SECOND		; Increment second
	adc	#1
	sta	CT_TIME_SECOND

	cmp	#$60			; Finish if current second < 60
	bcc	.done

	stz	CT_TIME_SECOND		; Reset second to 0

	lda	CT_TIME_MINUTE		; Increment minute
	adc	#0			; Carry already set
	sta	CT_TIME_MINUTE

	cmp	#$60			; Finish if current minute < 60
	bcc	.done

	lda	#0			; Reset minute to 0
	sta	CT_TIME_MINUTE

	lda	CT_TIME_HOUR		; Increment hour
	adc	#0			; Carry already set
	sta	CT_TIME_HOUR

	cmp	#$24			; Finish if current hour < 24
	bcc	.done

	lda	#0			; Reset hour to 0
	sta	CT_TIME_HOUR

	; TODO: Increment day in date as part of date/time addition routine

.done
	cld
	rts

!zone	time_eval100
; Evaluate the current time's tick value.
; INPUT:	None
; OUTPUT:	TIME_TICK = Updated current tick value
;		GP0 = Trashed
;		A, X = Kept
; VARIABLES:	GP0 = Ticks (in binary format) since top of second
time_eval100
	pha
	phx

	sec

	lda	CLOCK			; Subtract clock sec top LSB
	sbc	CLOCK_SEC_TOP
	sta	GP0

	lda	CLOCK + 1		; Subtract clock sec top MSB
	sbc	CLOCK_SEC_TOP + 1
	sta	GP0 + 1

	lda	GP0
	sta	GP7

	sed

	lda	#0			; Result accumulator
	ldx	#7			; Bit index

.convert_loop
	lsr	GP0			; Get bit
	bcc	.convert_0		; Don't add if bit not set
	adc	BCD_TABLE - 1,x		; Add bit value

.convert_0
	dex				; Decrement bit index
	bne	.convert_loop		; Continue if not at last index

	sta	CT_TIME_TICK		; Store BCD value

	cld
	plx
	pla
	rts

!zone	time_add
; Add the given time delta to the given date and time.
; INPUT:	GP0 = Address of 8-byte date and time value stored as BCD
;		GP1 = Address of time delta to add to given date and time value
; OUTPUT:	GP0 = Address of resultant date and time value (data stored at
;		address given as input will be updated in-place)
;		A, X, Y, GP2 = Trashed
; VARIABLES:	GP2 = Address of current byte in use in time delta for addition
time_add
	lda	GP0			; Store current time delta byte address
	sta	GP2
	lda	GP0 + 1
	sta	GP2 + 1

	clc				; Add offset to access tick byte
	lda	GP2
	adc	#DT_TICK
	sta	GP2

	lda	GP2 + 1			; Add carried result into MSB
	adc	#0
	sta	GP2 + 1

.add_load_counter
	lda	(GP2),y			; Load counter from current byte into X
	tax

	sed

.add_loop
	cpx	#0			; If counter is zero
	beq	.done_add_loop		; Then we're done for this byte

	jsr	.increment_tick

	dex
	bra	.add_loop

.done_add_loop
	cld
	sec

	lda	GP2			; Decrement current byte address LSB
	sbc	#1
	sta	GP2

	lda	GP2 + 1			; Decrement current byte address MSB
	sbc	#0
	sta	GP2 + 1

	clc				; If current time delta byte is not the
	lda	GP2			; one referencing the week yet, then
	sbc	#TDELTA_WEEK		; continue with next byte
	cmp	GP0
	bne	.add_load_counter

.done
	cld
	rts

.increment_tick
	ldy	#DT_TICK

	lda	(GP0),y
	adc	#1
	sta	(GP0),y

	bcc	.increment_done
	clc

.increment_second
	ldy	#DT_SECOND

	lda	(GP0),y
	adc	#1
	sta	(GP0),y

	cmp	#$60
	bcc	.increment_done
	clc

.increment_minute
	ldy	#DT_MINUTE

	lda	(GP0),y
	adc	#1
	sta	(GP0),y

	cmp	#$60
	bcc	.increment_done
	clc

.increment_hour
	ldy	#DT_HOUR

	lda	(GP0),y
	adc	#1
	sta	(GP0),y

	cmp	#$24
	bcc	.increment_done

; TODO: Implement date incrementation

.increment_done
	rts

!zone	time_tostr
; Update the string located at GP1 to contain a formatted version of the time
; value at GP0, excluding the current tick.
; INPUT:	GP0 = Address of 4-byte time value stored as BCD (typically
;		CURRENT_TIME)
;		GP1 = Address of string to store formatted time value (must be
;		at least 8 bytes in size)
; OUTPUT:	None
;		A, Y = Trashed
;		GP0, GP1 = Kept
time_tostr
	ldy	#TIME_SECOND

	lda	(GP0),y			; Load second BCD byte
	pha				; Push it to stack twice
	pha
	dey

	lda	(GP0),y			; Load minute BCD byte
	pha				; Push it to stack twice
	pha
	dey

	lda	(GP0),y			; Load hour BCD byte
	pha				; Push it to stack
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	clc
	adc	#'0'			; Add ASCII 0
	sta	(GP1),y			; Store character in string
	iny

	pla				; Pop hour byte
	and	#$0F			; Get low nibble
	adc	#'0'			; Add ASCII 0
	sta	(GP1),y			; Store character in string
	iny

	lda	#':'			; Add ASCII colon to string
	sta	(GP1),y
	iny

	pla				; Pop minute byte
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	clc
	adc	#'0'			; Add ASCII 0
	sta	(GP1),y			; Store character in string
	iny

	pla				; Pop minute byte
	and	#$0F			; Get low nibble
	adc	#'0'			; Add ASCII 0
	sta	(GP1),y			; Store character in string
	iny

	lda	#':'			; Add ASCII colon to string
	sta	(GP1),y
	iny

	pla				; Pop second byte
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	clc
	adc	#'0'			; Add ASCII 0
	sta	(GP1),y			; Store character in string
	iny

	pla				; Pop second byte
	and	#$0F			; Get low nibble
	adc	#'0'			; Add ASCII 0
	sta	(GP1),y			; Store character in string

	rts