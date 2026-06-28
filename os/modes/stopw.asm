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
	jsr	stopw_update

	lda	#STOPW & $FF
	sta	GP0
	lda	#STOPW >> 8
	sta	GP0 + 1

	lda	#STRBUF0 & $FF
	sta	GP1
	lda	#STRBUF0 >> 8
	sta	GP1 + 1

	jsr	stopw_tostr

	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	ldx	#0
	ldy	#2
	jsr	gfx_movefont

	jsr	gfx_dispstr

	jsr	gfx_resetfont

	jsr	input_getkey

	cmp	#KEY_PRESS | KEY_EQU
	beq	.start_stop

	bra	stopw_main

.start_stop
	lda	STOPW_ACTIVE
	bne	.stop

	jsr	stopw_start

	bra	stopw_main

.stop
	jsr	stopw_stop

	bra	stopw_main

!zone	stopw_update
; Update the current stopwatch value.
; INPUT:	None
; OUTPUT:	None
;		A, GP0 = Trashed
stopw_update
	lda	GP0			; Save current GP0 value
	pha
	lda	GP0 + 1
	pha

	lda	STOPW_ACTIVE		; If stopwatch isn't active, then don't
	beq	.done			; update it

	sec

	lda	CLOCK			; Subtract last updated value from
	sbc	STOPW_UPDATED		; current monotonic value
	sta	GP0

	lda	CLOCK + 1		; Subtract carried result into MSB
	sbc	STOPW_UPDATED + 1
	sta	GP0 + 1

	lda	CLOCK			; Set last updated value
	sta	STOPW_UPDATED
	lda	CLOCK + 1
	sta	STOPW_UPDATED + 1

.increment
	clc

	lda	GP0			; Convert difference to BCD
	jsr	util_tobcd

	sed

	adc	STOPW + TIME_TICK	; Update stopwatch tick value
	sta	STOPW + TIME_TICK

	bcc	.increment_done		; Finish if current tick < 100

	lda	STOPW + TIME_SECOND	; Increment second
	adc	#0			; Carry already set
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

	; FIXME: Not doing repeated subtractions (stopwatch gets stuck when
	; switching away from stopwatch mode)

	lda	GP0 + 1			; If MSB is nonzero, then must be > 100
	bne	.increment_again	; so continue incrementing ticks

	lda	GP0			; If difference >= 100, then keep
	cmp	#100			; incrementing to account for any
	bcs	.increment_again	; differences greater than 1 second

.done
	pla				; Restore GP0 value
	sta	GP0 + 1
	pla
	sta	GP0

	rts

.increment_again
	sec

	lda	GP0			; Take off 100 ticks from difference
	sbc	#100
	sta	GP0

	lda	GP0 + 1			; Subtract carried result into MSB
	sbc	#0
	sta	GP0 + 1

	bra	.increment

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