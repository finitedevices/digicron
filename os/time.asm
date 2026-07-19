; DATE AND TIME MANAGEMENT
; Used to maintain the current date and time, and to perform time-related
; calculations.

DATE_WEEKDAYS
	!raw	"SUN", 0, "MON", 0, "TUE", 0, "WED", 0
	!raw	"THU", 0, "FRI", 0, "SAT", 0, "---", 0

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

	stz	TIME_AMPM

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

	stz	CT_TIME_MINUTE		; Reset minute to 0

	lda	CT_TIME_HOUR		; Increment hour
	adc	#0			; Carry already set
	sta	CT_TIME_HOUR

	cmp	#$24			; Finish if current hour < 24
	bcc	.done

	stz	CT_TIME_HOUR		; Reset hour to 0

	lda	CT_DATE_DAY		; Increment day
	adc	#0			; Carry already set
	sta	CT_DATE_DAY

	phx				; Push X, Y, GP0 and GP1 to stack
	phy
	lda	GP0
	pha
	lda	GP0 + 1
	pha
	lda	GP1
	pha
	lda	GP1 + 1
	pha

	lda	#CT_DATE & $FF		; Load current date to check month len
	sta	GP0
	lda	#CT_DATE >> 8
	sta	GP0 + 1

	jsr	date_monthlen
	cmp	CT_DATE_DAY		; If month length >= incremented day
	bcs	.no_reset_day		; Then don't reset day

	lda	#$01			; Reset day to 1
	sta	CT_DATE_DAY

.no_reset_day
	pla				; Restore X, Y, GP0 and GP1 from stack
	sta	GP1 + 1
	pla
	sta	GP1
	pla
	sta	GP0 + 1
	pla
	sta	GP0
	ply
	plx

	lda	CT_DATE_DAY
	cmp	#$01			; Finish if day was not reset to 1
	bne	.done

	lda	CT_DATE_MONTH		; Increment month
	adc	#0			; Carry already set
	sta	CT_DATE_MONTH

	cmp	#$13			; Finish if current month < 13
	bcc	.done

	lda	#$01			; Reset month to 1
	sta	CT_DATE_MONTH

	lda	CT_DATE_YEAR		; Increment year LSB
	adc	#0			; Carry already set
	sta	CT_DATE_YEAR

	lda	CT_DATE_YEAR + 1	; Add carried result into MSB
	adc	#0
	sta	CT_DATE_YEAR + 1
	bne	.done			; Finish if MSB is nonzero

	lda	CT_DATE_YEAR		; Finish if LSB is nonzero
	bne	.done

	lda	#$01			; Overflow year 9999 to 1
	sta	CT_DATE_YEAR

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

!zone	time_tostr
; Update the string located at GP1 to contain a formatted version of the time
; value at GP0, excluding the current tick.
; INPUT:	GP0 = Address of 4-byte time value stored as BCD (typically
;		CT_TIME)
;		GP1 = Address of string to store formatted time value (must be
;		at least 8 bytes in size)
; OUTPUT:	None
;		A, X, Y = Trashed
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
	tax				; Store 24-hour value in X

	lda	TIME_AMPM		; If using 24-hour time format
	beq	.no_12_hr_sub		; Then show 24-hour value

	txa				; Get 24-hour value
	cmp	#$00			; If hour is 0 (midnight)
	beq	.midnight_to_12_am	; Then convert to 12 AM
	cmp	#$13			; If time is in afternoon (except 12:00)
	bcc	.done_12_hr_conversion	; Then subtract 12 hours

	sec
	sed
	sbc	#$12
	cld

	bra	.done_12_hr_conversion

.midnight_to_12_am
	lda	TIME_AMPM		; If time format is in mode 2, then show
	cmp	#2			; midnight as hour 0 (used to make
	beq	.show_as_0_am		; editing time easier)

	lda	#$12

	bra	.done_12_hr_conversion

.show_as_0_am
	lda	#$00

	bra	.done_12_hr_conversion

.no_12_hr_sub
	txa

.done_12_hr_conversion
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

	lda	TIME_AMPM		; If using 24-hour time format
	beq	.show_24_hr_colon	; Then use colon as indicator

	lda	#'A' | $80		; Show 'A' indicator
	cpx	#$12			; Only if time is before afternoon
	bcc	.show_indicator

	lda	#'P' | $80		; Otherwise show 'P' indicator

	bra	.show_indicator

.show_24_hr_colon
	lda	#':'

.show_indicator
	sta	(GP1),y			; Add indicator to string
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

!zone	time_edit
; Present an editor to modify a specific time value. The time value is
; internally copied into STRBUF1 for editing, but is committed to GP0 if
; successfully entered. The editor may be cancelled/dismissed by the user by
; pressing KEY_MUL. If this happens, then C will be set.
; INPUT:	GP0 = Address of 4-byte time value to edit stored as BCD
;		(typically CT_TIME)
; OUTPUT:	C = Set if editing was cancelled by the user
;		GP1 = TIME_AMPM state chosen by user when editing time
;		A, X, Y, GP4, GP5, STRBUF0, STRBUF1 = Trashed
;		GP0 = Kept
; VARIABLES:	GP1 = Shifted key input BCD value (LSB) and bit mask (MSB)
;		GP4 = Saved value of GP0
;		GP5 = Editing caret index (LSB) and orig. TIME_AMPM value (MSB)
;		STRBUF0 = String buffer used to display time
;		STRBUF1 = String buffer used to hold raw time value
time_edit
	lda	GP0			; Copy GP0 into GP4 to save it
	sta	GP4
	lda	GP0 + 1
	sta	GP4 + 1

	stz	GP5			; Set caret to start

	lda	TIME_AMPM		; Save original TIME_AMPM value
	sta	GP5 + 1

	ldy	#0			; Index for reading time bytes
	ldx	#0			; Index for writing time bytes

.copy_into_buffer
	lda	(GP4),y			; Copy byte into string buffer
	sta	STRBUF1,x
	iny				; Increment indexes
	inx

	cpy	#4			; Copy 4 bytes
	bcc	.copy_into_buffer

.show_value
	lda	GP5			; If caret is not editing minutes, then
	cmp	#3			; show updated time value in minutes
	bcs	.no_update_minutes	; column

	ldy	#TIME_MINUTE		; Copy minutes from time value into
	lda	(GP4),y			; editing buffer
	sta	STRBUF1 + TIME_MINUTE

.no_update_minutes
	lda	GP5			; If caret is not editing seconds, then
	cmp	#5			; show updated time value in seconds
	bcs	.no_update_seconds	; column

	ldy	#TIME_SECOND		; Copy seconds from time value into
	lda	(GP4),y			; editing buffer
	sta	STRBUF1 + TIME_SECOND

.no_update_seconds
	lda	#STRBUF1 & $FF		; String buffer containing raw time
	sta	GP0
	lda	#STRBUF1 >> 8
	sta	GP0 + 1

	lda	#STRBUF0 & $FF		; String buffer to write ASCII time
	sta	GP1
	lda	#STRBUF0 >> 8
	sta	GP1 + 1

	jsr	time_tostr		; Write time into string buffer

	jsr	time_eval100		; Find current time ticks

	lda	CT_TIME_TICK		; If less than 50, then show caret
	cmp	#$50
	bcs	.no_show_caret

	ldx	GP5			; Load caret position

	cpx	#2			; If caret is after first colon
	bcc	.no_skip_colon_1
	inx				; Skip caret past first colon

.no_skip_colon_1
	cpx	#5			; If caret is after second colon
	bcc	.no_skip_colon_2
	inx				; Skip caret past second colon

.no_skip_colon_2
	lda	#$FF			; Use block character
	sta	STRBUF0,x

.no_show_caret
	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Display time

.get_key
	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_PRESS | KEY_MUL	; If *, then cancel
	beq	.key_mul_action
	cmp	#KEY_PRESS | KEY_EQU	; If =, then save
	beq	.key_equ_action
	cmp	#KEY_PRESS | KEY_DOT	; If ., then change time format
	beq	.key_dot_action

	jsr	input_keytobcd		; Convert key to BCD if applicable
	bcc	.bcd_valid		; If not numeric, don't do anything

.bad_entry
	jmp	.show_value

.key_mul_action
	jmp	.cancel

.key_equ_action
	jmp	.save

.key_dot_action
	jmp	.change_time_format

.bcd_valid
	sta	GP1			; Save key value to GP1 LSB

	ldx	GP5			; If key value exceeds limit for place
	cmp	.TIME_VALUE_LIMITS,x	; value, then don't allow it to be typed
	bcs	.bad_entry

	cpx	#1			; Special case to prevent hour unit > 4		
	bne	.no_limit_hour_units	; when hour >= 20

	ldx	STRBUF1 + TIME_HOUR
	cpx	#$20
	bcc	.no_limit_hour_units

	cmp	#$04
	bcs	.bad_entry

.no_limit_hour_units
	ldx	GP5			; Get caret position
	cpx	#0			; If caret is in hour tens column
	beq	.check_hour_tens	; Then use 24-hour format if key = 2
	cpx	#1			; If caret is in hour units column
	beq	.check_hour_units	; Then use 24-hour if hour > 12

	bne	.no_check_24_hr

.check_hour_tens
	cmp	#$02			; If hour >= 20, then convert
	beq	.use_24_hr

	bne	.no_check_24_hr

.check_hour_units
	ldx	STRBUF1 + TIME_HOUR	; If hour < 10, then don't convert
	cpx	#$10
	bcc	.no_check_24_hr

	cmp	#$03			; If hour >= 13, then convert
	bcs	.use_24_hr

	bra	.no_check_24_hr

.use_24_hr
	stz	TIME_AMPM

.no_check_24_hr
	lda	#$F0			; Create mask for existing time value
	sta	GP1 + 1

	lda	GP5			; Divide by 2 since BCD is packed
	lsr
	tax				; Use divided result as byte index
	bcs	.no_shift		; If in units column then don't shift

	lda	GP1			; Shift BCD value into tens column
	asl
	asl
	asl
	asl
	sta	GP1

	lda	GP1 + 1			; Shift bit mask into units column
	lsr
	lsr
	lsr
	lsr
	sta	GP1 + 1

.no_shift
	lda	STRBUF1,x		; Get time value byte
	and	GP1 + 1			; Mask to clear edited column
	ora	GP1			; Insert shifted BCD value
	sta	STRBUF1,x		; Save to time value byte

	lda	GP5			; Increment caret position
	inc
	sta	GP5
	cmp	#1			; If in hr units col, then special case
	beq	.special_12_hr_format
	cmp	#2			; If hour done, then restore time format
	beq	.regular_12_hr_format
	cmp	#6			; If 6 characters entered, then save
	bcs	.save_and_sync

	jmp	.show_value

.special_12_hr_format
	lda	TIME_AMPM		; If time format is 12-hour, then use
	asl				; special mode (midnight is 00:00 AM)
	sta	TIME_AMPM		; so zero in tens col can be shown

	jmp	.show_value

.regular_12_hr_format
	lda	TIME_AMPM		; If time is in special 12-hour format
	lsr				; (midnight is 00:00 AM), then now use
	sta	TIME_AMPM		; regular format (12:00 AM)

	jmp	.show_value

.change_time_format
	lda	TIME_AMPM		; If time format is currently 24-hour
	bne	.change_in_12_hr	; Then change to 12-hour

	ldx	GP5			; If caret is in hour unit column, then
	cpx	#1			; change to special 12-hour (midnight
	beq	.change_to_12_hr_edit	; is 00:00 AM)

	lda	#1			; Otherwise change to regular 12-hour
	sta	TIME_AMPM

	jmp	.show_value

.change_to_12_hr_edit
	lda	#2
	sta	TIME_AMPM

	jmp	.show_value

.change_in_12_hr
	lda	STRBUF1 + TIME_HOUR	; If time is in morning (AM)
	cmp	#$12
	bcc	.change_to_pm		; Then change time to PM

	sec				; Otherwise if time is in afternoon,
	sed				; then convert to morning in 24-hour
	sbc	#$12			; representation
	sta	STRBUF1 + TIME_HOUR
	cld

	lda	#0			; Then switch to 24-hour format
	sta	TIME_AMPM

	jmp	.show_value

.change_to_pm
	clc				; Add 12 hours to change from AM to PM
	sed
	adc	#$12
	sta	STRBUF1 + TIME_HOUR
	cld

	jmp	.show_value

.save_and_sync
	lda	GP4			; If LSB not CT_TIME LSB, then don't
	cmp	#CT_TIME & $FF		; sync seconds
	bne	.save

	lda	GP4 + 1			; Check same for MSB
	cmp	#CT_TIME >> 8
	bne	.save

	lda	#$80			; Reset CT_TIME_TICK to sync seconds
	sta	CLOCK_UPDHNDL

.save
	lda	TIME_AMPM		; Get user-selected time format
	lsr				; Convert special format 2 into 1
	adc	#0			; If was format 1, then still return 1
	sta	GP1			; Return as GP1
	stz	GP1 + 1

	lda	GP5 + 1			; Restore original TIME_AMPM value
	sta	TIME_AMPM

	ldx	#0			; Index for reading time bytes
	ldy	#0			; Index for writing time bytes

.save_loop
	lda	STRBUF1,x		; Copy byte into time value
	sta	(GP4),y
	inx				; Increment indexes
	iny

	cpx	#4			; Copy 4 bytes
	bcc	.save_loop

	clc
	rts

.cancel
	jsr	input_getkey
	bne	.cancel

	lda	GP5 + 1			; Restore original TIME_AMPM value
	sta	TIME_AMPM
	sta	GP1			; Also reteurn as GP1 (user-selected
	stz	GP1 + 1			; time format is original format)

	sec
	rts

.TIME_VALUE_LIMITS
	!byte	$03, $0A, $06, $0A, $06, $0A

!zone	time_wait
; Wait for a specified duration to be elapsed.
; INPUT:	GP0 = Duration to wait for in ticks
; OUTPUT:	None
;		A, GP1-3 = Trashed
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
;		X, GP1-5 = Trashed
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
	stz	GP5

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

	lda	GP4			; Subtract LSB
	sbc	#$43
	sta	GP4

	lda	GP4 + 1			; Subtract next byte
	sbc	#$03
	sta	GP4 + 1

	lda	GP4 + 2			; Subtract MSB
	sbc	#0
	sta	GP4 + 2

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

	lda	GP4			; Subtract LSB
	sbc	#$49
	sta	GP4

	lda	GP4 + 1			; Subtract next byte
	sbc	#0
	sta	GP4 + 1

	lda	GP4 + 2			; Subtract MSB
	sbc	#0
	sta	GP4 + 2

	bra	.check_7_pow_2		; Now check if can still subtract

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

!zone	date_monthlen
; Get the length of the month (in BCD) specified by the date value at GP0. That
; is, the largest value of DATE_DAY valid for the given DATE_MONTH and DATE_YEAR
; combination. If DATE_YEAR is a leap year and DATE_MONTH is February ($02),
; then the length will be 29 to reflect the extra day.
; INPUT:	GP0 = Address of 4-byte date value stored as BCD (typically
;		CT_DATE)
; OUTPUT:	A = Length of the month in days
;		X, Y, GP1 = Trashed
; VARIABLES:	GP1 = Year retrieved from GP0
date_monthlen
	ldy	#0			; Store year LSB and MSB in GP1
	lda	(GP0),y
	sta	GP1
	iny
	lda	(GP0),y
	sta	GP1 + 1
	iny

	lda	(GP0),y			; Store month in X
	jsr	util_frombcd		; Convert it into binary
	tax

	cmp	#$02			; If February, then treat as special
	beq	.eval_feb		; case

.not_leap_year
	dex				; Make index zero-based
	lda	.MONTH_LENGTHS,x	; Get month length from array

	rts

.eval_feb
	lda	GP1 + 1			; Get year MSB
	jsr	util_frombcd		; Convert it into binary
	and	#$03			; If year divisible by 400 (MSB MOD 4
	beq	.is_div_400		; = 0), then is a leap year

	lda	GP1			; If year divisible by 100 (LSB = $00)
	beq	.not_leap_year		; Then not a leap year

.is_div_400
	lda	GP1
	jsr	util_frombcd		; Convert year LSB into binary
	and	#$03			; If year divisible by 4
	bne	.not_leap_year		; Then is a leap year

.is_leap_year
	lda	#$29

	rts

.MONTH_LENGTHS
	!byte	$31, $28, $31, $30	; JAN, FEB, MAR, APR
	!byte	$31, $30, $31, $31	; MAY, JUN, JUL, AUG
	!byte	$30, $31, $30, $31	; SEP, OCT, NOV, DEC

!zone	date_tostr
; Update the string located at GP1 to contain a formatted version of the date
; value at GP0, excluding the current year.
; INPUT:	GP0 = Address of 4-byte date value stored as BCD (typically
;		CT_DATE)
;		GP1 = Address of string to store formatted date value (must be
;		at least 8 bytes in size)
; OUTPUT:	None
;		A, X, Y, GP2-5 = Trashed
;		GP0, GP1 = Kept
date_tostr
	lda	GP1			; Push storage address to stack
	pha
	lda	GP1 + 1
	pha

	jsr	date_monthlen		; Check length of month
	ldy	#DATE_DAY
	cmp	(GP0),y			; If day is out of month's bounds
	lda	#7			; Then set weekday index to be invalid
	bcc	.invalid_date		; (shows "---")

	jsr	date_evalweekday	; Get offset index to weekday name array

.invalid_date
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

!zone	date_edit
; Present an editor to modify a specific date value. The date value is
; internally copied into STRBUF1 for editing, but is committed to GP0 if
; successfully entered. The editor may be cancelled/dismissed by the user by
; pressing KEY_MUL. If this happens, then C will be set.
; INPUT:	GP0 = Address of 4-byte date value to edit stored as BCD
;		(typically CT_DATE)
; OUTPUT:	C = Set if editing was cancelled by the user
;		A, X, Y, GP1-7, STRBUF0, STRBUF1 = Trashed
;		GP0 = Kept
; VARIABLES:	GP6 = Saved value of GP0
;		GP7 = Editing caret index
;		STRBUF0 = String buffer used to display date
;		STRBUF1 = String buffer used to hold raw date value
date_edit
	lda	GP0			; Copy GP0 into GP4 to save it
	sta	GP6
	lda	GP0 + 1
	sta	GP6 + 1

	stz	GP7			; Set caret to start

	ldy	#0			; Index for reading date bytes
	ldx	#0			; Index for writing date bytes

.copy_into_buffer
	lda	(GP6),y			; Copy byte into string buffer
	sta	STRBUF1,x
	iny				; Increment indexes
	inx

	cpy	#4			; Copy 4 bytes
	bcc	.copy_into_buffer

.show_value
	lda	GP7			; If caret is currently in year, then
	cmp	#4			; show year
	bcs	.no_show_year		; Otherwise, show day and month

.show_year
	lda	#'Y'			; Show "YEAR" to left of year entry
	sta	STRBUF0
	lda	#'E'
	sta	STRBUF0 + 1
	lda	#'A'
	sta	STRBUF0 + 2
	lda	#'R'
	sta	STRBUF0 + 3

	lda	STRBUF1 + DATE_YEAR + 1	; Load BCD year MSB
	pha				; Push to stack to copy
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	clc
	adc	#'0'			; Add ASCII 0
	sta	STRBUF0 + 4		; Store character in string

	pla				; Pop copied year byte value
	and	#$0F			; Get low nibble
	adc	#'0'			; Add ASCII 0
	sta	STRBUF0 + 5		; Store character in string

	lda	STRBUF1 + DATE_YEAR	; Load BCD year LSB
	pha				; Push to stack to copy
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	clc
	adc	#'0'			; Add ASCII 0
	sta	STRBUF0 + 6		; Store character in string

	pla				; Pop copied year byte value
	and	#$0F			; Get low nibble
	adc	#'0'			; Add ASCII 0
	sta	STRBUF0 + 7		; Store character in string

	lda	GP7			; If caret now past year, then show the
	cmp	#4			; year for a bit longer
	beq	.show_year_pause

	bra	.check_caret

.show_year_pause
	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Display year

	lda	#50
	sta	GP0
	stz	GP0 + 1

	jsr	time_wait		; Delay by 50 ticks (0.5 seconds)

	bra	.get_key

.no_show_year
	lda	#STRBUF1 & $FF		; String buffer containing raw date
	sta	GP0
	lda	#STRBUF1 >> 8
	sta	GP0 + 1

	lda	#STRBUF0 & $FF		; String buffer to write ASCII date
	sta	GP1
	lda	#STRBUF0 >> 8
	sta	GP1 + 1

	jsr	date_tostr		; Write date into string buffer

.check_caret
	jsr	time_eval100		; Find current time ticks

	lda	CT_TIME_TICK		; If less than 50, then show caret
	cmp	#$50
	bcs	.no_show_caret

	ldx	GP7			; Load caret position

	cpx	#4			; If caret is editing year
	bcs	.no_year_position
	inx				; Shift caret right to be after "YEAR"
	inx
	inx
	inx

	bra	.show_caret

.no_year_position
	dex				; Caret position 4 should be column 3

.show_caret
	lda	#$FF			; Use block character
	sta	STRBUF0,x

.no_show_caret
	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Display date

.get_key
	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_PRESS | KEY_ADD	; If +, then increment day or month
	beq	.key_add_action
	cmp	#KEY_PRESS | KEY_SUB	; If -, then decrement day or month
	beq	.key_sub_action
	cmp	#KEY_PRESS | KEY_MUL	; If *, then cancel
	beq	.key_mul_action
	cmp	#KEY_PRESS | KEY_EQU	; If =, then skip to next entry or save
	beq	.key_equ_action

	jsr	input_keytobcd		; Convert key to BCD if applicable
	bcc	.bcd_valid		; If not numeric, don't do anything

.bad_entry
	jmp	.show_value

.key_add_action
	jmp	.increment

.key_sub_action
	jmp	.decrement

.key_mul_action
	jmp	.cancel

.key_equ_action
	jmp	.next_or_save

.bcd_valid
	sta	GP1			; Save key value to GP1 LSB

	lda	GP7
	cmp	#6			; Don't allow numeric entry for month
	bcs	.bad_entry
	cmp	#3			; Limit 1-9 in year units if year < 10
	beq	.year_units
	cmp	#4			; Limit 0-3 if in day tens column
	beq	.day_tens
	cmp	#5			; Limit 1-9 if in day units and tens
	beq	.day_units		; column is 0; or 0-1 if tens is 3

	bra	.entry_allowed

.year_units
	lda	STRBUF1 + DATE_YEAR + 1	; If year MSB is zero, then don't limit
	bne	.entry_allowed

	lda	STRBUF1 + DATE_YEAR	; If year LSB tens column is zero, then
	and	#$F0			; don't limit
	bne	.entry_allowed

	lda	GP1			; Limit 1-9 (allow units > 0)
	bne	.entry_allowed

	bra	.bad_entry

.day_tens
	lda	GP1
	cmp	#$04
	bcs	.bad_entry

	bra	.entry_allowed

.day_units
	lda	STRBUF1 + DATE_DAY
	cmp	#$10			; If tens column < 10, then limit 1-9
	bcc	.day_units_below_10
	cmp	#$30			; If tens column >= 30, then limit 0-1	
	bcs	.day_units_above_30

	bra	.entry_allowed

.day_units_below_10
	lda	GP1
	cmp	#$00
	beq	.bad_entry

	bra	.entry_allowed

.day_units_above_30
	lda	GP1
	cmp	#$02
	bcs	.bad_entry

	bra	.entry_allowed

.entry_allowed
	lda	#$F0			; Create mask for existing date value
	sta	GP1 + 1

	lda	GP7			; Divide by 2 since BCD is packed
	lsr
	tax				; Use divided result as byte index
	bcs	.no_shift		; If in units column then don't shift

	lda	GP1			; Shift BCD value into tens column
	asl
	asl
	asl
	asl
	sta	GP1

	lda	GP1 + 1			; Shift bit mask into units column
	lsr
	lsr
	lsr
	lsr
	sta	GP1 + 1

.no_shift
	lda	.CARET_TO_INDEX_MAP,x	; Convert caret pos to value index
	tax
	lda	STRBUF1,x		; Get date value byte
	and	GP1 + 1			; Mask to clear edited column
	ora	GP1			; Insert shifted BCD value
	sta	STRBUF1,x		; Save to date value byte

	lda	GP7			; Increment caret position
	inc
	sta	GP7

	cmp	#4			; Pause to show completed year once
	bne	.skip_year_pause	; year has been entered

	jmp	.show_year

.skip_year_pause
	jmp	.show_value

.increment
	lda	GP7			; Check caret position
	cmp	#4			; If in a day column, then increment day
	beq	.increment_day
	cmp	#5
	beq	.increment_day
	cmp	#6			; If in month column, then incr month
	beq	.increment_month

	jmp	.show_value

.increment_day
	lda	#STRBUF1 & 0xFF		; Pass date being edited into GP0
	sta	GP0
	lda	#STRBUF1 >> 8
	sta	GP0 + 1

	jsr	date_monthlen		; Work out day upper bound

	sed

	inc				; Increment to get exclusive bound
	sta	GP0

	lda	STRBUF1 + DATE_DAY
	clc
	adc	#1
	cmp	GP0
	bcs	.day_overflow		; If overflow, reset to 1 and incr month
	sta	STRBUF1 + DATE_DAY

	cld

	jmp	.show_value

.day_overflow
	lda	#1
	sta	STRBUF1 + DATE_DAY

.increment_month
	sed

	lda	STRBUF1 + DATE_MONTH
	clc
	adc	#1
	cmp	#$13			; If overflow, reset to January
	bcc	.no_month_overflow
	lda	#1

.no_month_overflow
	sta	STRBUF1 + DATE_MONTH

	cld

	jmp	.show_value

.decrement
	lda	GP7			; Check caret position
	cmp	#4			; If in a day column, then decrement day
	beq	.decrement_day
	cmp	#5
	beq	.decrement_day
	cmp	#6			; If in month column, then decr month
	beq	.decrement_month

	jmp	.show_value

.decrement_day
	sed

	lda	STRBUF1 + DATE_DAY
	sec
	sbc	#1
	beq	.day_underflow		; If underflow, go to end and decr month
	sta	STRBUF1 + DATE_DAY

	cld

	jmp	.show_value

.day_underflow
	ldx	#1			; Set flag to modify day value too

	bra	.decrement_month_value

.decrement_month
	ldx	#0			; Skip day value modification

.decrement_month_value
	sed

	lda	STRBUF1 + DATE_MONTH
	sec
	sbc	#1
	bne	.no_month_underflow	; If underflow, set to December
	lda	#$12

.no_month_underflow
	sta	STRBUF1 + DATE_MONTH

	cld

	cpx	#0			; Check flag to see if also need to
	beq	.done_decrement_month	; set day value to last day of month

	lda	#STRBUF1 & 0xFF		; Pass date being edited into GP0
	sta	GP0
	lda	#STRBUF1 >> 8
	sta	GP0 + 1

	jsr	date_monthlen		; Work out day upper bound

	sta	STRBUF1 + DATE_DAY	; Store in buffer

.done_decrement_month
	jmp	.show_value

.next_or_save
	lda	GP7
	cmp	#4			; Check if year being entered
	bcc	.jump_to_day		; If so, then skip to day entry
	cmp	#6			; Check if day being entered
	bcc	.jump_to_month		; If so, then skip to month entry

	bra	.save

.jump_to_day
	lda	#4			; Jump caret to day entry
	sta	GP7

	jmp	.show_value

.jump_to_month
	lda	#6			; Jump caret to month entry
	sta	GP7

	jmp	.show_value

.save
	lda	#STRBUF1 & 0xFF		; Pass date to save into GP0
	sta	GP0
	lda	#STRBUF1 >> 8
	sta	GP0 + 1

	jsr	date_monthlen

	cmp	STRBUF1 + DATE_DAY	; Check if day is within bounds
	bcc	.bad_date		; If not then show error

	ldx	#0			; Index for reading date bytes
	ldy	#0			; Index for writing date bytes

.save_loop
	lda	STRBUF1,x		; Copy byte into date value
	sta	(GP6),y
	inx				; Increment indexes
	iny

	cpx	#4			; Copy 4 bytes
	bcc	.save_loop

	clc
	rts

.bad_date
	lda	#.BAD_DATE_MSG & 0xFF
	sta	GP0
	lda	#.BAD_DATE_MSG >> 8
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Show "BAD DATE" message

	lda	#100
	sta	GP0
	stz	GP0 + 1

	jsr	time_wait		; Delay by 100 ticks (1 second)

	stz	GP7			; Reset caret to start

	jmp	.show_value

.cancel
	jsr	input_getkey
	bne	.cancel

	sec
	rts

.BAD_DATE_MSG
	!raw	"BAD DATE"

.CARET_TO_INDEX_MAP
	!byte	$01, $00, $03