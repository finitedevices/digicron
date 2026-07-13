; DATE AND TIME MANAGEMENT
; Used to maintain the current date and time, and to perform time-related
; calculations.

DATE_WEEKDAYS
	!raw	"SUN", 0, "MON", 0, "TUE", 0, "WED", 0
	!raw	"THU", 0, "FRI", 0, "SAT", 0

DATE_MONTHS
	!raw	"JAN", 0, "FEB", 0, "MAR", 0, "APR", 0
	!raw	"MAY", 0, "JUN", 0, "JUL", 0, "AUG", 0
	!raw	"SEP", 0, "OCT", 0, "NOV", 0, "DEC", 0

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

	inc	CLOCK_UPDHNDL		; Update current clock value

	lda	CLOCK			; Set clock second top to new value
	sta	CLOCK_SEC_TOP
	lda	CLOCK + 1
	sta	CLOCK_SEC_TOP + 1

	dec	CLOCK_UPDHNDL

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

	inc	CLOCK_UPDHNDL		; Update current clock value

	lda	CLOCK			; Subtract clock sec top from current
	sbc	CLOCK_SEC_TOP		; monotonic value
	sta	GP0

	lda	CLOCK + 1		; Subtract carried result into MSB
	sbc	CLOCK_SEC_TOP + 1
	sta	GP0 + 1

	dec	CLOCK_UPDHNDL

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
;		CT_TIME)
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

!zone	time_wait
; Wait for a specified duration to be elapsed.
; INPUT:	GP0 = Duration to wait for in ticks
; OUTPUT:	None
;		A, GP1, GP2, GP3 = Trashed
; VARIABLES:	GP1 = Monotonic clock value when subroutine was invoked
;		GP2 = Current duration elapsed since subroutine was invoked
;		GP3 = Keyboard input state when subroutine was invoked
time_wait
	inc	CLOCK_UPDHNDL		; Update current clock value

	lda	CLOCK			; Store current monotonic clock time in
	sta	GP1			; GP1 so that we know when this
	lda	CLOCK + 1		; subroutine was invoked
	sta	GP1 + 1

	lda	INPUT
	sta	GP3

	dec	CLOCK_UPDHNDL

.check_loop
	lda	KEY_DIV_BEHAV		; If no KEY_DIV behaviour configured,
	cmp	#KEY_DIV_NONE		; then don't check for KEY_DIV presses
	beq	.skip_key_check		; while waiting

	lda	INPUT			; Check if pressed key is KEY_DIV
	cmp	#KEY_PRESS | KEY_DIV
	beq	.key_div_pressed

	stz	GP3			; Clear initial keyboard input state

.key_div_pressed
	lda	GP3			; If was already pressed when entering
	bne	.skip_key_check		; subroutine, then don't do anything

	jsr	input_getkey		; Delegate KEY_DIV behaviour

.skip_key_check
	sec

	inc	CLOCK_UPDHNDL		; Update current clock value

	lda	CLOCK			; Subtract invocation time from current
	sbc	GP1			; monotonic clock value
	sta	GP2

	lda	CLOCK + 1		; Subtract carried result into MSB
	sbc	GP1 + 1
	sta	GP2 + 1

	dec	CLOCK_UPDHNDL

	lda	GP2 + 1			; If current elapsed duration MSB is
	cmp	GP0 + 1			; less than desired duration MSB, then
	bcc	.check_loop		; keep checking

	lda	GP2			; Do the same for LSBs
	cmp	GP0
	bcc	.check_loop

	rts

!zone	date_evalweekday
; Evaluate the weekday number for the given date. Sunday is weekday number 0,
; with Monday to Friday having weekday numbers 1 to 6.
; INPUT:	GP0 = Address of 4-byte date value stored as BCD (typically
;		CT_DATE)
; OUTPUT:	A = Weekday number for provided date
;		X, GP1, GP2, GP3, GP4 = Trashed
; VARIABLES:	GP1 = Year retrieved from GP0
;		GP2 = Month retrieved from GP0
;		GP3 = Day retrieved from GP0
;		GP4 = 24-bit accumulator for evaluating weekday
;		GP5 = MSB of 24-bit accumulator
date_evalweekday
	sed

	ldy	#0			; Store year LSB and MSB in GP1
	lda	(GP0),y
	sta	GP1
	iny
	lda	(GP0),y
	sta	GP1 + 1
	iny

	lda	(GP0),y			; Store month in GP2
	sta	GP2
	iny

	lda	(GP0),y			; Store day in GP3
	sta	GP3

	lda	GP2			; Only decrement the year if month < 3
	cmp	#3
	bcs	.no_decrement_year

	sec

	lda	GP1			; Decrement the year
	sbc	#1
	sta	GP1

	lda	GP1 + 1			; Subtract carried value into MSB
	sbc	#0
	sta	GP1 + 1

.no_decrement_year
	stz	GP4			; Clear year accumulator
	stz	GP4 + 1

	lda	GP1 + 1			; Get year MSB
	cld
	jsr	util_frombcd		; Convert it into binary
	lsr				; Divide by 2
	pha				; Push result to stack to copy
	sed
	bcc	.no_add_25		; If remainder, add 25 to LSB

	lda	GP4
	adc	#$24			; Carry is already set
	sta	GP4

.no_add_25
	pla				; Pop year MSB binary value
	lsr				; Divide by 2 (total divided 4)
	pha				; Push divided binary result to stack
	sed
	bcc	.no_add_50		; If remainder, add 50 to LSB

	lda	GP4
	adc	#$49			; Carry is already set
	sta	GP4

.no_add_50
	pla				; Pop divided binary result
	jsr	util_tobcd		; Convert it back into BCD
	sta	GP4 + 1			; Store as MSB
	pha				; Push divided MSB to stack to copy

	lda	GP1			; Get year LSB
	jsr	util_frombcd		; Convert it into binary
	lsr				; Divide by 4
	lsr
	jsr	util_tobcd		; Convert it back into BCD

	clc
	sed

	adc	GP4			; Add addition carried from MSB division
	sta	GP4

	lda	GP4 + 1			; Add carried result into next byte
	adc	#0
	sta	GP4 + 1

	lda	GP4 + 2			; Add carried result into MSB
	adc	#0
	sta	GP4 + 2

	clc

	lda	GP4			; Add year LSB to accumulator
	adc	GP1
	sta	GP4

	lda	GP4 + 1			; Add year MSB and carried result
	adc	GP1 + 1
	sta	GP4 + 1

	lda	GP4 + 2			; Add carried result into MSB
	adc	#0
	sta	GP4 + 2

	sec

	lda	GP4			; Subtract year / 100
	sbc	GP1 + 1			; This is done by subtracting year MSB
	sta	GP4			; from accumulator LSB, because BCD

	lda	GP4 + 1			; Subtract carried result into next byte
	sbc	#0
	sta	GP4 + 1

	lda	GP4 + 2			; Subtract carried result into MSB
	sbc	#0
	sta	GP4 + 2

	clc

	pla				; Pop year MSB / 4 from stack
	adc	GP4			; Add year accumulator LSB
	sta	GP4			; Store result into accumulator

	lda	GP4 + 1			; Add carried result into next byte
	adc	#0
	sta	GP4 + 1

	lda	GP4 + 2			; Add carried result into MSB
	adc	#0
	sta	GP4 + 2

	lda	GP2			; Get month
	jsr	util_frombcd		; Convert it into binary
	dec				; Make it zero-indexed
	tax				; Use as index into MONTH_TABLE

	clc

	lda	.MONTH_TABLE,x		; Get magic value
	adc	GP4			; Add year accumulator LSB
	sta	GP4			; Store result into accumulator

	lda	GP4 + 1			; Add carried result into next byte
	adc	#0
	sta	GP4 + 1

	lda	GP4 + 2			; Add carried result into MSB
	adc	#0
	sta	GP4 + 2

	clc

	lda	GP4			; Add day to accumulator
	adc	GP3
	sta	GP4

	lda	GP4 + 1			; Add carried result into MSB
	adc	#0
	sta	GP4 + 1

	lda	GP4 + 2			; Add carried result into next byte
	adc	#0
	sta	GP4 + 2

.check_7_pow_3
	lda	GP4 + 2			; If MSB nonzero, then subtract
	bne	.subtract_7_pow_3

	sec				; Check if GP4 >= 343
	lda	GP4
	sbc	#$34
	lda	GP4 + 1
	sbc	#$03
	bcs	.subtract_7_pow_3	; If so, then subtract

	bra	.check_7_pow_2		; Otherwise, subtract 7 ** 2

.subtract_7_pow_3
	sec

	lda	GP4			; Subtract MSB
	sbc	#$43
	sta	GP4

	lda	GP4 + 1			; Subtract LSB
	sbc	#$03
	sta	GP4 + 1

	bra	.check_7_pow_3		; Now check if can still subtract

.check_7_pow_2
	; MSB will be zero now as part of .subtract_7_pow_3

	lda	GP4 + 1			; If middle byte nonzero, then subtract
	bne	.subtract_7_pow_2

	lda	GP4			; If LSB >= 49, then subtract
	cmp	#$49
	bcs	.subtract_7_pow_2

	bra	.check_7		; Otherwise, subtract 7

.subtract_7_pow_2
	sec

	lda	GP4			; Subtract MSB
	sbc	#$49
	sta	GP4

	lda	GP4 + 1			; Subtract LSB
	sbc	#0
	sta	GP4 + 1

	bra	.check_7		; Now check if can still subtract

.check_7
	; MSB will be zero as part of .subtract_7_pow_3
	; Middle byte will be zero now as part of .subtract_7_pow_2

	lda	GP4			; If LSB < 7, then don't subtract
	cmp	#$07
	bcc	.done

	sec
	sbc	#$07			; Subtact 7 values
	sta	GP4

	bra	.check_7

.done
	lda	GP4

	cld
	rts

.MONTH_TABLE
	!byte	0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4

!zone	date_tostr
; Update the string located at GP1 to contain a formatted version of the date
; value at GP0, excluding the current year.
; INPUT:	GP0 = Address of 4-byte date value stored as BCD (typically
;		CT_DATE)
;		GP1 = Address of string to store formatted date value (must be
;		at least 8 bytes in size)
; OUTPUT:	None
;		A, X, Y = Trashed
;		GP0, GP1 = Kept
date_tostr
	lda	GP1			; Push storage address to stack
	pha
	lda	GP1 + 1
	pha

	jsr	date_evalweekday	; Get offset index to weekday name array
	asl				; Shift to multiply by 4
	asl
	tax				; Store offset in X
	ldy	#0			; Set index for copying to string

	pla				; Pop storage address
	sta	GP1 + 1
	pla
	sta	GP1

.next_weekday_char
	lda	DATE_WEEKDAYS,x		; Get weekday char
	sta	(GP1),y			; Store in string
	inx
	iny

	cpy	#4			; Repeat until index is at 4
	bcc	.next_weekday_char

	ldy	#DATE_DAY		; Get day value
	lda	(GP0),y
	pha				; Push it to stack to copy

	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	clc
	adc	#'0'			; Add ASCII 0
	ldy	#3
	sta	(GP1),y			; Store character in string

	pla				; Pop copied day value
	and	#$0F			; Get low nibble
	adc	#'0'			; Add ASCII 0
	ldy	#4
	sta	(GP1),y			; Store character in string

	ldy	#DATE_MONTH		; Get offset index to month name array
	lda	(GP0),y
	jsr	util_frombcd		; Convert value into binary
	dec				; Decrement to make zero-indexed
	asl				; Shift to multiply by 4
	asl
	tax				; Store offset in X
	ldy	#5			; Set index for copying to string

.next_month_char
	lda	DATE_MONTHS,x		; Get month char
	sta	(GP1),y			; Store in string
	inx
	iny

	cpy	#8			; Repeat until index is at 8
	bcc	.next_month_char

	rts