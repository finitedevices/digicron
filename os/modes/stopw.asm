; STOPWATCH MODE
; Used for measuring time durations.

STOPW_INFO
	!raw	"STOPWTCH"		; MODE_I_NAME
	!word	$0000			; MODE_I_AUTHOR
	!word	$0100			; MODE_I_VERSION
	!word	stopw_main		; MODE_I_REF

!zone	stopw_main
; Entry point for the stopwatch mode.
; INPUT:	None
; OUTPUT:	Not a subroutine
stopw_main
	jsr	stopw_update		; Update stopwatch value

	lda	STOPW_ACTIVE		; Always show value if stopwatch active
	bne	.show_value

	lda	STOPW + TIME_HOUR	; Always show value if stopwatch has
	bne	.not_reset		; been reset (value is 00:00'00"00)
	lda	STOPW + TIME_MINUTE
	bne	.not_reset
	lda	STOPW + TIME_SECOND
	bne	.not_reset
	lda	STOPW + TIME_TICK
	bne	.not_reset

	bra	.show_value

.not_reset
	jsr	time_eval100		; Find current time ticks

	lda	CT_TIME_TICK		; If less than 50, then show value
	cmp	#$50
	bcc	.show_value

	jsr	gfx_clear		; Otherwise show a blank screen

	bra	.check_input		; Then check input

.show_value
	lda	#STOPW & $FF		; Use current stopwatch value as source
	sta	GP0
	lda	#STOPW >> 8
	sta	GP0 + 1

	lda	#STRBUF0 & $FF		; Use STRBUF0 as destination
	sta	GP1
	lda	#STRBUF0 >> 8
	sta	GP1 + 1

	jsr	stopw_tostr		; Convert value to string

	lda	#STRBUF0 & $FF		; Use converted string for displaying
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	ldx	#6			; Set max characters to display

	jsr	gfx_dispstr		; Display stopwatch value as string

	lda	STOPW + TIME_HOUR	; Don't modify font if hours are shown
	bne	.showing_hours		; as this otherwise affects second disp.

	ldx	#0			; Align small digits in font to baseline
	ldy	#2
	jsr	gfx_movefont

.showing_hours
	lda	STRBUF0 + 6		; Render 1/10 sec place char
	ldx	#6
	jsr	gfx_dispchar

	lda	STRBUF0 + 7		; Render 1/100 sec place char
	ldx	#7
	jsr	gfx_dispchar

	jsr	gfx_resetfont		; Reset font parameters

.check_input
	jsr	input_getkey		; Check currently pressed key
	cmp	#KEY_PRESS | KEY_EQU	; If =, then start/stop stopwatch
	beq	.start_stop
	cmp	#KEY_PRESS | KEY_0	; If 0, then reset stopwatch
	beq	.reset

	jmp	stopw_main

.start_stop
	lda	STOPW_ACTIVE		; Determine if need to start or stop
	bne	.stop			; If STOPW_ACTIVE is 1, then is running

.start_keydown
	jsr	input_getkey		; Keep getting key until none is pressed
	bne	.start_keydown

	jsr	stopw_start		; Start the stopwatch once key released

	jmp	stopw_main

.stop
	jsr	stopw_stop		; Stop the stopwatch as soon as pressed

.stop_keydown
	jsr	input_getkey		; Keep getting key until none is pressed
	bne	.stop_keydown

	jmp	stopw_main

.reset
	jsr	stopw_reset		; Reset the stopwatch

	jmp	stopw_main

!zone	stopw_update
; Update the current stopwatch value.
; INPUT:	None
; OUTPUT:	None
;		A, GP0 = Trashed
stopw_update
	lda	STOPW_LOCK		; If mutex locked, then don't update
	bne	.locked

	lda	#1			; Acquire mutex lock
	sta	STOPW_LOCK

	lda	GP0			; Save current GP0 value
	pha
	lda	GP0 + 1
	pha

	lda	STOPW_ACTIVE		; If stopwatch isn't active, then don't
	beq	.done			; update it

	sec

	inc	CLOCK_UPDHNDL		; Update current clock value

	lda	CLOCK			; Push monotonic value LSB to stack
	pha
	sbc	STOPW_UPDATED		; Subtract last updated value from
	sta	GP0			; current monotonic value

	lda	CLOCK + 1		; Push monotonic value MSB to stack
	pha
	sbc	STOPW_UPDATED + 1	; Subtract carried result into MSB
	sta	GP0 + 1

	dec	CLOCK_UPDHNDL

	pla				; Update stopwatch last updated value
	sta	STOPW_UPDATED + 1	; using values from stack
	pla
	sta	STOPW_UPDATED

.increment_loop
	lda	GP0 + 1			; If MSB is nonzero, then must be > 100
	bne	.ge_second		; so increment by a second at a time

	lda	GP0			; If difference >= 100, then increment
	cmp	#100			; by a second at a time
	bcs	.ge_second

.increment_tick
	clc

	lda	GP0			; Convert difference to BCD
	jsr	util_tobcd
	sta	$5002

	sed

	adc	STOPW + TIME_TICK	; Update stopwatch tick value
	sta	STOPW + TIME_TICK

	bcc	.done			; Finish if current tick < 100

	jsr	.increment_second	; Otherwise increment carried second

.done
	cld

	pla				; Restore GP0 value
	sta	GP0 + 1
	pla
	sta	GP0

	stz	STOPW_LOCK		; Release mutex lock

.locked
	rts

.ge_second
	sec

	lda	GP0			; Take off 100 ticks from difference
	sbc	#100
	sta	GP0

	lda	GP0 + 1			; Subtract carried result into MSB
	sbc	#0
	sta	GP0 + 1

	jsr	.increment_second

	bra	.increment_loop

.increment_second
	sed
	clc

	lda	STOPW + TIME_SECOND	; Increment second
	adc	#1
	sta	STOPW + TIME_SECOND

	cmp	#$60			; Finish if current second < 60
	bcc	.increment_done

	stz	STOPW + TIME_SECOND	; Reset second to 0

	lda	STOPW + TIME_MINUTE	; Increment minute
	adc	#0			; Carry already set
	sta	STOPW + TIME_MINUTE

	cmp	#$60			; Finish if current minute < 60
	bcc	.increment_done

	stz	STOPW + TIME_MINUTE	; Reset minute to 0

	lda	STOPW + TIME_HOUR	; Increment hour (overflows at 99)
	adc	#0			; Carry already set
	sta	STOPW + TIME_HOUR

.increment_done
	cld
	rts

!zone	stopw_start
; Start the stopwatch.
; INPUT:	None
; OUTPUT:	None
;		A = Trashed
stopw_start
	lda	CLOCK			; Set last updated value
	sta	STOPW_UPDATED
	lda	CLOCK + 1
	sta	STOPW_UPDATED + 1

	lda	#1			; Set active flag
	sta	STOPW_ACTIVE

	rts

!zone	stopw_stop
; Stop the stopwatch.
; INPUT:	None
; OUTPUT:	None
stopw_stop
	stz	STOPW_ACTIVE		; Unset active flag

	rts

!zone	stopw_reset
; Reset the stopwatch.
; INPUT:	None
; OUTPUT:	None
stopw_reset
	stz	STOPW + TIME_HOUR	; Set stopwatch value to 00:00'00"00
	stz	STOPW + TIME_MINUTE
	stz	STOPW + TIME_SECOND
	stz	STOPW + TIME_TICK

	stz	STOPW_ACTIVE		; Unset active flag
	stz	STOPW_LOCK		; Release mutex

!zone	stopw_tostr
; Update the string located at GP1 to contain a formatted version of the
; stopwatch time value at GP0. The tick (hundredths of a second) value will only
; be shown if the global stopwatch duration is less than 1 hour.
; INPUT:	GP0 = Address of 4-byte time value stored as BCD (typically
;		STOPW)
;		GP1 = Address of string to store formatted time value (must be
;		at least 8 bytes in size)
; OUTPUT:	None
;		A, Y = Trashed
;		GP0, GP1 = Kept
stopw_tostr
	lda	STOPW + TIME_HOUR	; If hour is 0, then proceed to render
	beq	.show_tick		; using MM'SS"TT

	jmp	time_tostr		; Otherwise, just use HH:MM:SS

.show_tick
	ldy	#TIME_TICK

	lda	(GP0),y			; Load tick BCD byte
	pha				; Push it to stack twice
	pha
	dey

	lda	(GP0),y			; Load second BCD byte
	pha				; Push it to stack twice
	pha
	dey

	lda	(GP0),y			; Load minute BCD byte
	pha				; Push it to stack
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	clc
	adc	#'0'			; Add ASCII 0
	ldy	#0			; Reset index back to start of string
	sta	(GP1),y			; Store character in string
	iny

	pla				; Pop minute byte
	and	#$0F			; Get low nibble
	adc	#'0'			; Add ASCII 0
	sta	(GP1),y			; Store character in string
	iny

	lda	#'\''			; Add ASCII single quote to string
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
	iny

	lda	#'"'			; Add ASCII double quote to string
	sta	(GP1),y
	iny

	pla				; Pop tick byte
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	clc
	adc	#'0' | $80		; Add small text 0 digit character
	sta	(GP1),y			; Store character in string
	iny

	pla				; Pop tick byte
	and	#$0F			; Get low nibble
	adc	#'0' | $80		; Add small text 0 digit character
	sta	(GP1),y			; Store character in string

	rts