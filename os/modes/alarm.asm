; ALARM MODE
; Used for setting up to 8 alarms.

ALARM_INFO
	!raw	"ALARM", 0, 0, 0	; MODE_I_NAME
	!word	$0000			; MODE_I_AUTHOR
	!word	$0100			; MODE_I_VERSION
	!word	alarm_main		; MODE_I_REF
	!word	$0000			; MODE_I_ISR

; Alarm states (enum)
ALARM_S_ACTIVE	= $01			; Set when scheduled to ring today
ALARM_S_ENABLED	= $02			; Toggled by user to turn alarm on/off

!zone	alarm_main
; Entry point for alarm mode.
; INPUT:	None
; OUTPUT:	Not a subroutine
alarm_main
	lda	#(ALARM_INFO + MODE_I_NAME) & $FF
	sta	GP0			; Store address to mode info struct
	lda	#(ALARM_INFO + MODE_I_NAME) >> 8
	sta	GP0 + 1

	jsr	mode_showname		; Display the mode name

.render
	clc
	lda	ALARM_IDX
	adc	#'1'			; Add ASCII 1
	sta	STRBUF0			; Show alarm index in column 0

	lda	ALARM_IDX
	jsr	alarm_getaddr

	lda	#'-' | $80		; Show alarm state indicator in column 1
	sta	STRBUF0 + 1

	ldy	#ALARM_STATE
	lda	(GP0),y
	and	#ALARM_S_ENABLED
	beq	.not_enabled

	lda	#'B' | $80		; Show alarm enabled indicator in col 1
	sta	STRBUF0 + 1

.not_enabled
	lda	#' '			; Show space in column 2
	sta	STRBUF0 + 2

	lda	#(STRBUF0 + 2) & $FF	; Offset written time by 2 to display
	sta	GP1			; alongside alarm index and indicator
	lda	#(STRBUF0 + 2) >> 8
	sta	GP1 + 1

	lda	TIME_FORMAT		; Use user-configured time format
	sta	TIME_DSP_FORMAT

	bne	.show_ampm		; Hide second colon if 24-hour format

	inc	GP1			; No carry needed; buf addr in zero page

.show_ampm
	jsr	time_tostr		; Write alarm value into string buffer

	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	ldx	#8

	jsr	gfx_dispstr

	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_HOLD | KEY_MUL	; If * held, then set alarm time
	beq	.set_alarm
	cmp	#KEY_PRESS | KEY_ADD	; If + pressed, then view next alarm
	beq	.next_alarm
	cmp	#KEY_PRESS | KEY_SUB	; If - pressed, then view prev alarm
	beq	.prev_alarm
	cmp	#KEY_PRESS | KEY_EQU	; If = pressed, then toggle enabled
	beq	.toggle_enabled

	jmp	.render

.set_alarm
	lda	ALARM_IDX
	jsr	alarm_edit		; Edit current alarm
	bcs	.edit_cancelled		; If cancelled, then don't set it

	lda	ALARM_IDX
	jsr	alarm_getaddr

	ldy	#ALARM_STATE		; Set alarm enabled flag
	lda	(GP0),y
	ora	#ALARM_S_ENABLED
	sta	(GP0),y

.edit_cancelled
	jmp	.render

.next_alarm
	clc
	lda	ALARM_IDX
	adc	#1			; Increment alarm index
	and	#$07			; Limit to 0-7
	sta	ALARM_IDX

	jmp	.render

.prev_alarm
	sec
	lda	ALARM_IDX
	sbc	#1			; Decrement alarm index
	and	#$07			; Limit to 0-7
	sta	ALARM_IDX

	jmp	.render

.toggle_enabled
	lda	ALARM_IDX
	jsr	alarm_getaddr

	ldy	#ALARM_STATE		; Negate alarm enabled flag
	lda	(GP0),y
	eor	#ALARM_S_ENABLED
	sta	(GP0),y

	jmp	.render

!zone	alarm_init
; Initialise all alarm states.
; INPUT:	None
; OUTPUT:	None
;		X = Trashed
alarm_init
	stz	ALARM_IDX		; Reset viewed alarm to first

	ldx	#0

.loop
	lda	#8			; Set ALARM_HOUR to 8 (default to 08:00)
	sta	ALARMS,x
	inx

	stz	ALARMS,x		; Clear ALARM_MINUTE, ALARM_STATE and
	inx				; ALARM_WEEKDAYS
	stz	ALARMS,x
	inx
	stz	ALARMS,x
	inx

	cpx	#8 * 4			; 8 alarm states containing 4 properties
	bcc	.loop

	rts

!zone	alarm_getaddr
; Get the address of the alarm entry given by its index.
; INPUT:	A = Index of alarm to get the address of (typically ALARM_IDX)
; OUTPUT:	GP0 = Address of the alarm entry
;		A = Trashed
alarm_getaddr
	asl				; Multiply alarm index by struct size
	asl
	sta	GP0

	clc

	lda	#ALARMS & $FF		; Load alarms array LSB
	adc	GP0			; Add alarm address index into LSB
	sta	GP0			; Store in GP0

	lda	#ALARMS >> 8		; Load alarms array MSB
	adc	#0			; Add carried result into MSB
	sta	GP0 + 1			; Store in GP0

	rts

!zone	alarm_edit
; Present an editor to modify the time of the alarm given its index. The alarm
; value is copied to STRBUF1 for editing, but is committed to GP0 if
; successfully entered. The editor may be cancelled/dismissed by the user by
; pressing KEY_MUL. If this happens, then C will be set. While the alarm time is
; being set, the first two display columns will not be modified, so the alarm
; index and state should ideally be shown in these columns beforehand.
; INPUT:	A = Index of alarm being set (typically ALARM_IDX)
; OUTPUT:	C = Set if editing was cancelled by the user
;		A, X, Y, GP1, GP4-6, STRBUF0, STRBUF1 = Trashed
alarm_edit
	jsr	alarm_getaddr		; Get address of alarm entry

	lda	TIME_FORMAT		; Use user-configured time format
	sta	TIME_DSP_FORMAT

	lda	#TIME_EDM_HHMM		; Edit as HH:MM
	jsr	time_edit

	rts