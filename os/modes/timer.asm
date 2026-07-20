; TIMER MODE
; Used for setting up to 8 countdown timers.

TIMER_INFO
	!raw	"TIMER", 0, 0, 0	; MODE_I_NAME
	!word	$0000			; MODE_I_AUTHOR
	!word	$0100			; MODE_I_VERSION
	!word	timer_main		; MODE_I_REF

!zone	timer_main
; Entry point for timer mode.
; INPUT:	None
; OUTPUT:	Not a subroutine
timer_main
	lda	#(TIMER_INFO + MODE_I_NAME) & $FF
	sta	GP0			; Store address to mode info struct
	lda	#(TIMER_INFO + MODE_I_NAME) >> 8
	sta	GP0 + 1

	jsr	mode_show_name		; Display the mode name

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

	lda	#'T'			; Show T in column 0
	sta	STRBUF0

	clc
	lda	TIMER_IDX
	adc	#'1'			; Add ASCII 1
	sta	STRBUF0 + 1		; Show timer index in column 1

	lda	#' '			; Show space in column 2
	sta	STRBUF0 + 2

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

	jmp	.render

.next_timer
	clc
	lda	TIMER_IDX
	adc	#1			; Increment timer index
	and	#$07			; Limit to 0-7
	sta	TIMER_IDX

	jmp	.render

.prev_timer
	sec
	lda	TIMER_IDX
	sbc	#1			; Decrement timer index
	and	#$07			; Limit to 0-7
	sta	TIMER_IDX

	jmp	.render

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
; VARIABLES:	GP1 = Key input BCD value
;		GP2 = Address of timer entry
;		STRBUF1 = String buffer used to hold raw timer value
timer_edit
	jsr	timer_getaddr		; Get address of timer entry

	lda	GP0			; Copy address into GP2
	sta	GP2
	lda	GP0 + 1
	sta	GP2 + 1

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
	clc
	rts

.cancel
	sec
	rts

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