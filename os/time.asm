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

	sec

	lda	CLOCK			; Subtract clock sec top from current
	sbc	CLOCK_SEC_TOP		; monotonic value
	sta	GP0

	lda	CLOCK + 1		; Subtract carried result into MSB
	sbc	CLOCK_SEC_TOP + 1
	sta	GP0 + 1

	lda	GP0
	jsr	util_tobcd
	sta	CT_TIME_TICK

	clc

	pla
	rts

!zone	time_add
; Add the given time delta to the given date and time.
; INPUT:	GP0 = Address of 8-byte date and time value stored as BCD
;		GP1 = Address of time delta to add to given date and time value
; OUTPUT:	GP0 = Address of resultant date and time value (data stored at
;		address given as input will be updated in-place)
;		A, X, Y, GP2, GP3 = Trashed
; VARIABLES:	GP2 = Address of current byte in use in time delta for addition
;		GP3 = Address of current incrementation subroutine
time_add
	lda	GP0			; Store current time delta byte address
	sta	GP2
	lda	GP0 + 1
	sta	GP2 + 1

	clc

	lda	GP2			; Add offset to access tick byte
	adc	#DT_TICK
	sta	GP2

	lda	GP2 + 1			; Add carried result into MSB
	adc	#0
	sta	GP2 + 1

	lda	#.INCREMENT_SUBS & 0xFF	; Initialise pointer to current routine
	sta	GP3
	lda	#.INCREMENT_SUBS >> 8
	sta	GP3

.add_load_counter
	lda	(GP2),y			; Load counter from current byte into X
	tax

	sed

.add_loop
	cpx	#0			; If counter is zero
	beq	.add_loop_done		; Then we're done for this byte

	jmp	(GP3)			; Call current incrementation routine

.increment_done
	dex
	bra	.add_loop

.add_loop_done
	cld
	sec

	lda	GP2			; Decrement current byte address
	sbc	#1
	sta	GP2

	lda	GP2 + 1			; Subtract carried result into MSB
	sbc	#0
	sta	GP2 + 1

	clc

	lda	GP3			; Point to next incrementation routine
	adc	#2
	sta	GP3

	lda	GP3 + 1			; Add carried result into MSB
	adc	#0
	sta	GP3 + 1

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

	clc
	lda	(GP0),y
	adc	#1
	sta	(GP0),y

	bcc	.increment_done

.increment_second
	ldy	#DT_SECOND

	clc
	lda	(GP0),y
	adc	#1
	sta	(GP0),y

	cmp	#$60
	bcc	.increment_done

	lda	#0
	sta	(GP0),y

.increment_minute
	ldy	#DT_MINUTE

	clc
	lda	(GP0),y
	adc	#1
	sta	(GP0),y

	cmp	#$60
	bcc	.increment_done

	lda	#0
	sta	(GP0),y

.increment_hour
	ldy	#DT_HOUR

	clc
	lda	(GP0),y
	adc	#1
	sta	(GP0),y

	cmp	#$24
	bcc	.increment_done

	lda	#0
	sta	(GP0),y

	bra	.increment_done

; TODO: Implement date incrementation

.INCREMENT_SUBS
	!word	.increment_tick
	!word	.increment_second
	!word	.increment_minute
	!word	.increment_hour

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