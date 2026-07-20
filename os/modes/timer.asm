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
	asl				; Multiply timer index by struct size
	asl
	asl
	sta	GP1

	clc

	lda	#TIMERS & $FF		; Load timers array LSB
	adc	GP1			; Add timer address index into LSB
	sta	GP0			; Store in GP0

	lda	#TIMERS >> 8		; Load timers array MSB
	adc	#0			; Add carried result into MSB
	sta	GP0 + 1			; Store in GP0

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
	cmp	#KEY_ADD | KEY_PRESS	; If +, then view next timer
	beq	.next_timer
	cmp	#KEY_SUB | KEY_PRESS	; If -, then view prev timer
	beq	.prev_timer

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

!zone	timer_edit
; Present an editor to modify the timer given by its index. The timer value is
; internally copied into STRBUF1 for editing, but it is committed to GP0 if
; successfully entered. The editor may be cancelled/dismissed by the user by
; pressing KEY_MUL. If this happens, then C will be set.
; INPUT:	A = Index of timer to edit
; OUTPUT:	C = Set if editing was cancelled by the user
timer_edit
	; TODO: Implement this

	rts

!zone	timer_reset
; Reset the timer given by its index to the value it was originally set as.
; INPUT:	A = Index of timer to reset
; OUTPUT:	None
;		A, X, Y = Trashed
timer_reset
	asl				; Multiply timer index by struct size
	asl
	asl
	tax				; Store as X

	ldy	#0

.loop
	lda	TIMERS + 4,x		; Get reset value bytes
	sta	TIMERS,x		; Store in active value bytes
	inx
	iny

	cpy	#3			; Copy 3 bytes
	bcc	.loop

	stz	TIMERS,x		; Clear TIMER_RUNNING property

	rts