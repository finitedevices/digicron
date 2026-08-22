; ALARM MODE
; Used for setting up to 8 alarms.

ALARM_INFO
	!raw	"ALARM", 0, 0, 0	; MODE_I_NAME
	!word	$0000			; MODE_I_AUTHOR
	!word	$0100			; MODE_I_VERSION
	!word	alarm_main		; MODE_I_REF
	!word	alarm_isr		; MODE_I_ISR

; Alarm states (bit field)
ALARM_S_ACTIVE	= $01			; Set when scheduled to ring today
ALARM_S_ENABLED	= $02			; Toggled by user to turn alarm on/off

; Alarm active days menu items
ALARM_DAYS_MENU
	!word	ALARM_ONCE_MSG
	!word	ALARM_DAILY_MSG
	!word	ALARM_WEEKDAY_MSG
	!word	ALARM_WEEKEND_MSG
	!word	ALARM_CUSTOM_MSG
	!word	$0000

ALARM_ONCE_MSG
	!raw	"ONCE", 0

ALARM_DAILY_MSG
	!raw	"DAILY", 0

ALARM_WEEKDAY_MSG
	!raw	"WEEKDAY", 0

ALARM_WEEKEND_MSG
	!raw	"WEEKEND", 0

ALARM_CUSTOM_MSG
	!raw	"CUSTOM", 0

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
	lda	ALARM_IDX		; Show current alarm
	clc				; Don't show as ringing
	jsr	alarm_render

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

!zone	alarm_isr
; Interrupt service routine handler to check alarms and ring them if required.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y = Trashed
;		GP0 = Kept
alarm_isr
	lda	INT_FLAG		; Only handle every second
	and	#INT_FLAG_SECOND
	beq	.done

	lda	GP0			; Push GP0 to stack
	pha
	lda	GP0 + 1
	pha

	ldx	#0			; Use X as current alarm index

.loop
	txa
	jsr	alarm_getaddr		; Store alarm entry address into GP0
	ldy	#ALARM_STATE
	lda	(GP0),y			; Get alarm state
	and	#ALARM_S_ENABLED
	beq	.next_alarm		; If not enabled, then don't check time

	txa
	jsr	alarm_isupcoming	; Check if alarm is upcoming
	bcs	.is_upcoming		; Haven't reached alarm time yet

	ldy	#ALARM_STATE		; Get active flag value from cached
	lda	(GP0),y			; alarm entry address
	and	#ALARM_S_ACTIVE
	beq	.next_alarm		; If not active, then don't ring

	stx	ALARM_IDX		; Store current index as ringing index

	lda	#alarm_ringctx & $FF	; Store alarm ringing context entry
	sta	GP0			; point address in GP0
	lda	#alarm_ringctx >> 8
	sta	GP0 + 1

	lda	#CTX_PRIO_ALARM		; Set context switching priority

	jsr	isr_rqctxsw		; Request to context-switch

	bra	.next_alarm

.is_upcoming
	ldy	#ALARM_STATE		; Set active flag value in cached alarm
	lda	(GP0),y			; entry address
	ora	#ALARM_S_ACTIVE
	sta	(GP0),y

.next_alarm
	inx

	cpx	#8			; Repeat for 8 alarms
	bcc	.loop

	pla				; Restore GP0 from stack
	sta	GP0 + 1
	pla
	sta	GP0

.done
	rts

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

	stz	ALARMS,x		; Clear ALARM_MINUTE and ALARM_STATE
	inx
	stz	ALARMS,x
	inx
	lda	#$7F			; Set ALARM_WEEKDAYS to be daily
	sta	ALARMS,x
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

!zone	alarm_render
; Render the details of the alarm given by its index to the display.
; INPUT:	A = Index of alarm to display
;		C = Set if alarm is to be shown as ringing
; OUTPUT:	None
;		A, X, Y, GP0-3 = Trashed
alarm_render
	tax				; Store alarm index in X for later

	lda	#0			; Store ringing status in GP2 for later
	adc	#0
	sta	GP2

	txa				; Restore alarm index from X
	clc
	adc	#'1'			; Add ASCII 1
	sta	STRBUF0			; Show alarm index in column 0

	txa				; Restore alarm index from X
	jsr	alarm_getaddr

	ldx	#2			; Blank columns 2-7

.blank_loop
	lda	#' '			; Blank using space characters
	sta	STRBUF0,x
	inx

	cpx	#8			; Blank characters up to column 7
	bcc	.blank_loop

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

	lda	GP2			; If not ringing, then show alarm value
	beq	.set_str_addr

.alarm_ringing
	jsr	time_eval100		; Find current time ticks

	lda	CT_TIME_TICK		; If less than 50, then show time
	cmp	#$50
	bcc	.hide_time

	lda	#CT_TIME & $FF		; Show current time instead of alarm
	sta	GP0			; time (so oversleepers can realise how
	lda	#CT_TIME >> 8		; long they overslept for)
	sta	GP0 + 1

.set_str_addr
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

.hide_time
	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr

	rts

!zone	alarm_edit
; Present an editor to modify the time and active days of the alarm given by its
; index. The alarm value is copied to STRBUF1 for editing, but is committed to
; GP0 if successfully entered. The editor may be cancelled/dismissed by the user
; by pressing KEY_MUL. If this happens, then C will be set. While the alarm time
; is being set, the first two display columns will not be modified, so the alarm
; index and state should ideally be shown in these columns beforehand.
; INPUT:	A = Index of alarm being set (typically ALARM_IDX)
; OUTPUT:	C = Set if editing was cancelled by the user
;		A, X, Y, GP0-6, STRBUF0, STRBUF1 = Trashed
; VARIABLES:	GP6 = Saved index of alarm entry
alarm_edit
	sta	GP6			; Save index in GP6
	jsr	alarm_getaddr		; Get address of alarm entry

	lda	TIME_FORMAT		; Use user-configured time format
	sta	TIME_DSP_FORMAT

	lda	#TIME_EDM_HHMM		; Edit as HH:MM
	jsr	time_edit
	bcs	.done			; If cancelled, then early exit

	beq	.show_menu		; If entry incomplete, then don't delay

	lda	GP6			; Get alarm entry index
	clc				; Don't show as ringing
	jsr	alarm_render		; Show current alarm to hide edit caret

	lda	#50			; Set delay of 50 ticks
	sta	GP0
	stz	GP0 + 1

	jsr	time_wait		; Delay to keep finished entry on screen

.show_menu
	lda	#ALARM_DAYS_MENU & $FF	; Load alarm active days menu array addr
	sta	GP0
	lda	#ALARM_DAYS_MENU >> 8
	sta	GP0 + 1

	lda	#1			; Set initial menu item index

	jsr	input_showmenu

.done
	rts

!zone	alarm_isupcoming
; Determine whether the alarm given by its index is yet to ring today.
; INPUT:	A = Index of alarm to test (typically ALARM_IDX)
; OUTPUT:	C = Set if alarm is upcoming
;		A, Y, GP0 = Trashed
alarm_isupcoming
	jsr	alarm_getaddr		; Get address of alarm entry

	inc	CLOCK_UPDHNDL		; Update current clock value

	clc				; Special case: if exactly midnight,
	lda	CT_TIME_HOUR		; then treat alarm as upcoming (to
	adc	CT_TIME_MINUTE		; ensure that alarms set for midnight
	adc	CT_TIME_SECOND		; have a chance to ring)
	beq	.yes

	ldy	#ALARM_HOUR		; Get hour from alarm entry
	lda	(GP0),y
	cmp	CT_TIME_HOUR		; Check if >= current hour
	beq	.compare_mins		; If =, then compare minutes
	bcc	.no			; If >, then not upcoming

.yes
	dec	CLOCK_UPDHNDL

	sec
	rts

.compare_mins
	ldy	#ALARM_MINUTE		; Get minute from alarm entry
	lda	(GP0),y
	cmp	CT_TIME_MINUTE		; Check if >= current minute
	beq	.no			; If =, then not upcoming
	bcs	.yes			; If >, then is upcoming

.no
	dec	CLOCK_UPDHNDL

	clc
	rts

!zone	alarm_ringctx
; Entry point for secondary context to display the alarm to signal to the user
; that it is ringing. The index of the alarm should be stored in ALARM_IDX prior
; to switching to this context.
; INPUT:	None
; OUTPUT:	Not a subroutine
; VARIABLES:	GP4 = Index of ringing alarm at point of entry
alarm_ringctx
	lda	ALARM_IDX		; Get address of ringing alarm entry
	sta	GP4			; Store index in GP4
	jsr	alarm_getaddr

	ldy	#ALARM_STATE		; Clear alarm active flag
	lda	(GP0),y
	and	#!ALARM_S_ACTIVE
	sta	(GP0),y

.display_loop
	lda	GP4			; Get alarm entry index
	sec				; Show as ringing
	jsr	alarm_render		; Show current alarm

	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_PRESS | KEY_0	; If 0 pressed, then exit context
	beq	.exit
	cmp	#KEY_PRESS | KEY_EQU	; If = pressed, then exit context
	beq	.exit

	jmp	.display_loop

.exit
	jmp	isr_exitctx

!zone	alarm_ackall
; Acknowledge all alarms that are scheduled to ring. This is useful when
; changing the system time to a time in the future, where any alarms scheduled
; prior to the new time would otherwise go off.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0 = Trashed
alarm_ackall
	ldx	#0

.loop
	txa
	jsr	alarm_getaddr		; Get address of alarm entry

	ldy	#ALARM_STATE		; Set clear flag value in alarm entry
	lda	(GP0),y
	and	#!ALARM_S_ACTIVE
	sta	(GP0),y

	inx

	cpx	#8			; Repeat for 8 alarms
	bcc	.loop

	rts