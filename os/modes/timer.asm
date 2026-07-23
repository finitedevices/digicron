; TIMER MODE
; Used for setting up to 8 countdown timers.

TIMER_INFO
	!raw	"TIMER", 0, 0, 0	; MODE_I_NAME
	!word	$0000			; MODE_I_AUTHOR
	!word	$0100			; MODE_I_VERSION
	!word	timer_main		; MODE_I_REF
	!word	$0000			; MODE_I_ISR

!zone	timer_main
; Entry point for timer mode.
; INPUT:	None
; OUTPUT:	Not a subroutine
timer_main
	lda	#(TIMER_INFO + MODE_I_NAME) & $FF
	sta	GP0			; Store address to mode info struct
	lda	#(TIMER_INFO + MODE_I_NAME) >> 8
	sta	GP0 + 1

	jsr	mode_showname		; Display the mode name

.render_showing_index
	inc	CLOCK_UPDHNDL		; Update current clock value

	lda	CLOCK			; Save initial render time to GP4
	sta	GP4
	lda	CLOCK + 1
	sta	GP4 + 1

	dec	CLOCK_UPDHNDL

.render
	lda	TIMER_IDX
	jsr	timer_getaddr

	lda	#STRBUF0 & $FF
	sta	GP1
	lda	#STRBUF0 >> 8
	sta	GP1 + 1

	lda	#TIME_100_HOUR		; Use 100-hour time format
	sta	TIME_DSP_FORMAT

	jsr	time_tostr		; Write timer value into string buffer

	ldy	#TIMER_HOUR
	lda	(GP0),y
	beq	.show_index

	inc	CLOCK_UPDHNDL		; Update current clock value

	sec				; Subtract current time from initial
	lda	CLOCK			; render time
	sbc	GP4
	sta	GP0
	lda	CLOCK + 1
	sbc	GP4 + 1
	sta	GP0 + 1

	dec	CLOCK_UPDHNDL

	lda	GP0 + 1			; If MSB is nonzero, then will be > 100
	bne	.no_show_index
	lda	GP0			; If LSB > 100 ticks (1 second), then
	cmp	#100			; hide index
	bcs	.no_show_index

.show_index
	lda	#'T'			; Show T in column 0
	sta	STRBUF0

	clc
	lda	TIMER_IDX
	adc	#'1'			; Add ASCII 1
	sta	STRBUF0 + 1		; Show timer index in column 1

	lda	#' '			; Show space in column 2
	sta	STRBUF0 + 2

.no_show_index
	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	ldx	#8

	jsr	gfx_dispstr

	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_HOLD | KEY_MUL	; If * held, then set timer
	beq	.set_timer
	cmp	#KEY_PRESS | KEY_ADD	; If + pressed, then view next timer
	beq	.next_timer
	cmp	#KEY_PRESS | KEY_SUB	; If - pressed, then view prev timer
	beq	.prev_timer

	jmp	.render

.set_timer
	lda	TIMER_IDX
	jsr	timer_edit

	jmp	.render_showing_index

.next_timer
	clc
	lda	TIMER_IDX
	adc	#1			; Increment timer index
	and	#$07			; Limit to 0-7
	sta	TIMER_IDX

	jmp	.render_showing_index

.prev_timer
	sec
	lda	TIMER_IDX
	sbc	#1			; Decrement timer index
	and	#$07			; Limit to 0-7
	sta	TIMER_IDX

	jmp	.render_showing_index

!zone	timer_init
; Initialise all timer states.
; INPUT:	None
; OUTPUT:	None
;		X = Trashed
timer_init
	stz	TIMER_IDX		; Reset viewed timer to first

	ldx	#0

.loop
	stz	TIMERS,x		; Clear out all timer states
	inx

	cpx	#8 * 8			; 8 timer states containing 8 properties
	bcc	.loop

	rts

!zone	timer_getaddr
; Get the address of the timer entry given by its index.
; INPUT:	A = Index of timer to get the address of (typically TIMER_IDX)
; OUTPUT:	GP0 = Address of the timer entry
;		A = Trashed
timer_getaddr
	asl				; Multiply timer index by struct size
	asl
	asl
	sta	GP0

	clc

	lda	#TIMERS & $FF		; Load timers array LSB
	adc	GP0			; Add timer address index into LSB
	sta	GP0			; Store in GP0

	lda	#TIMERS >> 8		; Load timers array MSB
	adc	#0			; Add carried result into MSB
	sta	GP0 + 1			; Store in GP0

	rts

!zone	timer_edit
; Present an editor to modify the timer given by its index. The timer value is
; internally copied into STRBUF1 for editing, but it is committed to GP0 if
; successfully entered. The editor may be cancelled/dismissed by the user by
; pressing KEY_MUL. If this happens, then C will be set.
; INPUT:	A = Index of timer to edit (typically TIMER_IDX)
; OUTPUT:	C = Set if editing was cancelled by the user
;		A, X, Y, GP0-5 = Trashed
; VARIABLES:	GP1 = Key input BCD value
;		GP4 = Address of timer entry
;		GP5 = Timer index (LSB) and carried min from sec overflow (MSB)
;		STRBUF0 = String buffer used to display time and hold capped
;		timer value when saving
;		STRBUF1 = String buffer used to hold raw timer value
timer_edit
	sta	GP5			; Store timer index for later

	jsr	timer_getaddr		; Get address of timer entry

	lda	GP0			; Copy address into GP4
	sta	GP4
	lda	GP0 + 1
	sta	GP4 + 1

	stz	STRBUF1 + TIMER_HOUR	; Reset all values to 0
	stz	STRBUF1 + TIMER_MINUTE
	stz	STRBUF1 + TIMER_SECOND

.show_value
	lda	#STRBUF1 & $FF
	sta	GP0
	lda	#STRBUF1 >> 8
	sta	GP0 + 1

	lda	#STRBUF0 & $FF
	sta	GP1
	lda	#STRBUF0 >> 8
	sta	GP1 + 1

	lda	#TIME_100_HOUR		; Use 100-hour time format
	sta	TIME_DSP_FORMAT

	jsr	time_tostr		; Write timer value into string buffer

	jsr	time_eval100		; Find current time ticks

	lda	CT_TIME_TICK		; If less than 50, then hide second cols
	cmp	#$50
	bcs	.no_show_caret

	lda	#' '			; Show space character in second cols
	sta	STRBUF0 + 6
	sta	STRBUF0 + 7

.no_show_caret
	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	ldx	#8

	jsr	gfx_dispstr

.get_key
	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_PRESS | KEY_MUL	; If *, then cancel
	beq	.key_mul_action
	cmp	#KEY_PRESS | KEY_EQU	; If =, then save
	beq	.key_equ_action

	jsr	input_keytobcd		; Convert key into BCD if applicable
	bcc	.bcd_valid		; If not numeric, don't do anything

.bad_entry
	jmp	.show_value

.key_mul_action
	jmp	.cancel

.key_equ_action
	jmp	.save

.bcd_valid
	sta	GP1			; Save key value to GP1

	ldx	#0

.digit_shift_loop
	asl	STRBUF1 + TIMER_SECOND	; Shift digits into more significant col
	rol	STRBUF1 + TIMER_MINUTE
	rol	STRBUF1 + TIMER_HOUR
	inx

	cpx	#4			; 4 bits per BCD digit
	bcc	.digit_shift_loop

	lda	STRBUF1 + TIMER_SECOND	; Insert key value into second unit col
	ora	GP1
	sta	STRBUF1 + TIMER_SECOND

	jmp	.show_value

.save
	lda	STRBUF1 + TIMER_HOUR
	sta	STRBUF0 + TIMER_HOUR
	lda	STRBUF1 + TIMER_MINUTE
	sta	STRBUF0 + TIMER_MINUTE
	lda	STRBUF1 + TIMER_SECOND
	sta	STRBUF0 + TIMER_SECOND

	sed

.cap_second
	stz	GP5 + 1			; Reset flag for whether to add minute

	lda	STRBUF0 + TIMER_SECOND	; If second value is less than 60, then
	cmp	#$60			; is not overflowing, so no need to cap
	bcc	.cap_minute

	sbc	#$60			; Subtract 60 so second is in 0-59 range
	sta	STRBUF0 + TIMER_SECOND	; Carry already set

	lda	#1			; Carry overflowed second into minute
	sta	GP5 + 1

.cap_minute
	lda	STRBUF0 + TIMER_MINUTE	; If minute value is less than 60, then
	cmp	#$60			; is not overflowing, so no need to cap
	bcc	.add_carried_minute

	sbc	#$60			; Subtract 60 so minute is in 0-59 range
	sta	STRBUF0 + TIMER_MINUTE	; Carry already set

	lda	STRBUF0 + TIMER_HOUR	; Check if can overflow minute into hour
	cmp	#$99
	beq	.too_long		; Otherwise, show error

	clc				; Carry overflowed minute into hour
	lda	STRBUF0 + TIMER_HOUR
	adc	#1
	sta	STRBUF0 + TIMER_HOUR

.add_carried_minute
	lda	GP5 + 1			; If still need to add carried minute,
	beq	.done_capping		; then do so and check again

	clc
	lda	STRBUF0 + TIMER_MINUTE
	adc	#1
	sta	STRBUF0 + TIMER_MINUTE

	bra	.cap_second

.done_capping
	cld

	ldy	#TIMER_RS_HOUR		; Copy edited values into reset values
	lda	STRBUF0 + TIMER_HOUR
	sta	(GP4),y

	ldy	#TIMER_RS_MINUTE
	lda	STRBUF0 + TIMER_MINUTE
	sta	(GP4),y

	ldy	#TIMER_RS_SECOND
	lda	STRBUF0 + TIMER_SECOND
	sta	(GP4),y

	lda	GP5			; Reset timer to ensure edited value is
	jsr	timer_reset		; populated in displayed time

	clc
	rts

.too_long
	cld

	lda	#.TOO_LONG_MSG & 0xFF
	sta	GP0
	lda	#.TOO_LONG_MSG >> 8
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Show "TOO LONG" message

	lda	#100
	sta	GP0
	stz	GP0 + 1

	jsr	time_wait		; Delay by 100 ticks (1 second)

	jmp	.show_value

.cancel
	sec
	rts

.TOO_LONG_MSG
	!raw	"TOO LONG"

!zone	timer_reset
; Reset the timer given by its index to the value it was originally set as.
; INPUT:	A = Index of timer to reset (typically TIMER_IDX)
; OUTPUT:	None
;		A, X, Y = Trashed
timer_reset
	asl				; Multiply timer index by struct size
	asl
	asl
	tax				; Store as X

	ldy	#0

.loop
	lda	TIMERS + TIMER_RS_HOUR,x
	sta	TIMERS,x		; Store reset value into active value
	inx				; Increment indexes
	iny

	cpy	#3			; Copy 3 bytes
	bcc	.loop

	stz	TIMERS,x		; Clear TIMER_RUNNING property

	rts