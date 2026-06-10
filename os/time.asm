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
	sta	DATE_YEAR + 1
	lda	#$26
	sta	DATE_YEAR

	lda	#$01
	sta	DATE_MONTH
	sta	DATE_DAY

	lda	#$00
	sta	TIME_HOUR
	sta	TIME_MINUTE
	sta	TIME_SECOND
	sta	TIME_TICK

	rts

!zone	time_increment
; Increment the current time by 1 tick.
; INPUT:	None
; OUTPUT:	None
time_increment
	sed
	clc

	lda	TIME_TICK		; Increment tick
	adc	#1
	sta	TIME_TICK
	bcc	.done			; Finish if tick does not roll over

	lda	TIME_SECOND		; Increment second
	adc	#0			; Carry already set
	sta	TIME_SECOND

	cmp	#$60			; Finish if current second < 60
	bcc	.done

	lda	#0			; Reset second to 0
	sta	TIME_SECOND

	lda	TIME_MINUTE		; Increment minute
	adc	#0			; Carry already set
	sta	TIME_MINUTE

	cmp	#$60			; Finish if current minute < 60
	bcc	.done

	lda	#0			; Reset minute to 0
	sta	TIME_MINUTE

	lda	TIME_HOUR		; Increment hour
	adc	#0			; Carry already set
	sta	TIME_HOUR

	cmp	#$24			; Finish if current hour < 24
	bcc	.done

	lda	#0			; Reset hour to 0
	sta	TIME_HOUR

	; TODO: Increment day in date as part of date/time addition routine
.done
	cld
	rts