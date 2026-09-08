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

; Alarm snooze states (bit field)
ALM_ZZZ_S_IDX	= $0F			; Index of snoozed alarm ($0F if none)
ALM_ZZZ_S_LEN	= $F0			; User-configured default snooze length

; Alarm active days menu items
ALARM_DAYS_MENU
	!word	ALARM_ONCE_MSG
	!word	ALARM_DAILY_MSG
	!word	ALARM_WEEKDAY_MSG
	!word	ALARM_WEEKEND_MSG
	!word	ALARM_CUSTOM_MSG
	!word	$0000

; Alarm active weekday bit fields
ALARM_DAYS_VALUES
	!byte	$00			; ONCE		-------
	!byte	$7F			; DAILY		SMTWTFS
	!byte	$3E			; WEEKDAY	-MTWTF-
	!byte	$41			; WEEKEND	S-----S

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

	; TODO: Deactivate snooze when turning off alarm

	jmp	.render

!zone	alarm_isr
; Interrupt service routine handler to check alarms and ring them if required.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y = Trashed
;		GP0-5 = Kept
alarm_isr
	lda	INT_FLAG		; Only handle every second
	and	#INT_FLAG_SECOND
	bne	.handle

	rts

.handle
	lda	GP0			; Push GP0 to stack
	pha
	lda	GP0 + 1
	pha

	lda	GP1			; Push GP1 to stack
	pha
	lda	GP1 + 1
	pha

	lda	GP2			; Push GP2 to stack
	pha
	lda	GP2 + 1
	pha

	lda	GP3			; Push GP3 to stack
	pha
	lda	GP3 + 1
	pha

	lda	GP4			; Push GP4 to stack
	pha
	lda	GP4 + 1
	pha

	lda	GP5			; Push GP5 to stack
	pha
	lda	GP5 + 1
	pha

	ldx	#0			; Use X as current alarm index

.loop
	lda	ALM_ZZZ_STATE		; Get snooze state
	and	#ALM_ZZZ_S_IDX		; Mask to get active snoozed alarm index
	sta	GP0			; Store snoozed alarm index in GP0
	cpx	GP0			; Compare current index with snoozed
	bne	.not_snoozed		; If snoozed, check if time ran out

	sed
	sec

	lda	ALM_ZZZ_SECOND		; Decrement second
	sbc	#1
	sta	ALM_ZZZ_SECOND

	cmp	#$99			; Finish if no second underflow
	bne	.snooze_not_ended

	lda	#$59			; Reset second to 59
	sta	ALM_ZZZ_SECOND

	sec

	lda	ALM_ZZZ_MINUTE		; Decrement minute
	sbc	#1
	sta	ALM_ZZZ_MINUTE

	cmp	#$99			; Finish if no minute underflow
	bne	.snooze_not_ended

	cld

	stx	ALARM_IDX		; Store current index as ringing index

	lda	#alarm_zzzctx & $FF	; Store alarm snooze ringing context
	sta	GP0			; entry point address in GP0
	lda	#alarm_zzzctx >> 8
	sta	GP0 + 1

	lda	#CTX_PRIO_ALARM		; Set context switching priority

	jsr	isr_rqctxsw		; Request to context-switch

.snooze_not_ended
	cld

.not_snoozed
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

	ldy	#ALARM_WEEKDAYS		; Get current weekday bit field from
	lda	(GP0),y			; alarm entry
	beq	.ring_alarm		; If bit field = $00, is one-time alarm
	pha				; Save weekday bit field to stack

	phx				; Save X to stack

	lda	#CT_DATE & $FF		; Use today's date to check weekday
	sta	GP0
	lda	#CT_DATE >> 8
	sta	GP0 + 1

	jsr	date_evalweekday	; Get today's weekday index
	tax
	lda	DATE_WKDYMASK,x		; Convert index to weekday bit field
	sta	GP0			; Store bit field in GP0

	plx				; Restore X from stack

	pla				; Restore weekday bit field from stack
	and	GP0			; Mask today's bit field with alarm's
	bne	.ring_alarm		; If $00, then don't ring alarm today

	txa
	jsr	alarm_getaddr		; Store alarm entry address into GP0

	ldy	#ALARM_STATE		; Clear active flag value in alarm
	lda	(GP0),y			; entry
	and	#!ALARM_S_ACTIVE
	sta	(GP0),y

	bra	.next_alarm

.ring_alarm
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
	bcs	.done

	jmp	.loop

.done
	pla				; Restore GP5 from stack
	sta	GP5 + 1
	pla
	sta	GP5

	pla				; Restore GP4 from stack
	sta	GP4 + 1
	pla
	sta	GP4

	pla				; Restore GP3 from stack
	sta	GP3 + 1
	pla
	sta	GP3

	pla				; Restore GP2 from stack
	sta	GP2 + 1
	pla
	sta	GP2

	pla				; Restore GP1 from stack
	sta	GP1 + 1
	pla
	sta	GP1

	pla				; Restore GP0 from stack
	sta	GP0 + 1
	pla
	sta	GP0

	rts

!zone	alarm_init
; Initialise all alarm states.
; INPUT:	None
; OUTPUT:	None
;		X = Trashed
alarm_init
	stz	ALARM_IDX		; Reset viewed alarm to first
	stz	ALM_ZZZ_MINUTE		; Reset snooze minutes remaining
	stz	ALM_ZZZ_SECOND		; Reset snooze seconds remaining
	lda	#$AF			; Set snooze default length to 10 mins
	sta	ALM_ZZZ_STATE		; and active state to not snoozing

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

	lda	GP2			; If ringing, then always show enabled
	bne	.is_enabled		; indicator even if one-time alarm

	lda	#'-' | $80		; Show alarm state indicator in column 1
	sta	STRBUF0 + 1

	ldy	#ALARM_STATE		; Check if alarm is enabled
	lda	(GP0),y
	and	#ALARM_S_ENABLED
	beq	.not_enabled		; If not then don't show indicator

.is_enabled
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
	lda	GP6			; Get alarm entry index
	jsr	alarm_getaddr		; Get address of alarm entry

	ldx	#0			; Use as index into menu values array

.loop_find_item
	ldy	#ALARM_WEEKDAYS		; Get current weekday bit field from
	lda	(GP0),y			; alarm entry

	cmp	ALARM_DAYS_VALUES,x	; Check against current menu item value
	beq	.found_item		; If so, then use as index
	inx

	cpx	#4			; Check 4 entries (ONCE/DAILY/WKDY/WKND)
	bcc	.loop_find_item		; Otherwise use index 4 (CUSTOM)

.found_item
	lda	#ALARM_DAYS_MENU & $FF	; Load alarm active days menu array addr
	sta	GP0
	lda	#ALARM_DAYS_MENU >> 8
	sta	GP0 + 1

	txa				; Load initial menu item index

	jsr	input_showmenu
	bcs	.done			; If cancelled, then early exit
	cmp	#4			; If active days entry is CUSTOM
	beq	.sel_weekdays		; Then have user select weekdays

	tax				; Save selected index into X

	lda	GP6			; Get alarm entry index
	jsr	alarm_getaddr		; Get address of alarm entry

	lda	ALARM_DAYS_VALUES,x	; Find weekday value bit field from idx
	ldy	#ALARM_WEEKDAYS		; Store in alarm entry
	sta	(GP0),y

	clc
	rts

.sel_weekdays
	lda	GP6			; Get alarm entry index
	jsr	alarm_getaddr		; Get address of alarm entry

	ldy	#ALARM_WEEKDAYS		; Get current weekday bit field from
	lda	(GP0),y			; alarm entry

	jsr	date_selweekdays	; Ask the user which days to ring on
	bcs	.done			; If cancelled, then early exit
	tax				; Save weekday bit field into X

	lda	GP6			; Get alarm entry index
	jsr	alarm_getaddr		; Get address of alarm entry

	txa				; Restore weekday bit field from X
	ldy	#ALARM_WEEKDAYS		; Store selected weekdays in alarm entry
	sta	(GP0),y

.done
	rts

!zone	alarm_isupcoming
; Determine whether the alarm given by its index is yet to ring today. This
; subroutine does not take into account the alarm's active weekdays.
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
; Entry point for secondary context to display an alarm to signal to the user
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

	ldy	#ALARM_WEEKDAYS		; Get alarm weekdays bit field
	lda	(GP0),y
	bne	.display_loop		; If not $00, then not one-time alarm
	ldy	#ALARM_STATE		; Otherwise clear alarm enabled flag
	lda	(GP0),y
	and	#!ALARM_S_ENABLED
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
	cmp	#KEY_PRESS | KEY_ADD	; If + pressed, then snooze alarm
	beq	.snooze

	jmp	.display_loop

.exit
	jmp	isr_exitctx

.snooze
	lda	ALM_ZZZ_STATE		; Get user-configured snooze length by
	and	#ALM_ZZZ_S_LEN		; masking from snooze state
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	jsr	util_tobcd		; Convert to BCD
	sta	ALM_ZZZ_MINUTE		; Store in snooze minutes remaining
	stz	ALM_ZZZ_SECOND		; Clear snooze seconds remaining

	lda	ALM_ZZZ_STATE		; Get current snooze state
	and	#$F0			; Clear snoozed alarm index
	ora	GP4			; Use ringing alarm index as snoozed idx
	sta	ALM_ZZZ_STATE		; Save modified snooze state

	lda	#'Z'			; Show "ZZZ" next to alarm index
	ldx	#2
	jsr	gfx_dispchar
	ldx	#3
	jsr	gfx_dispchar
	ldx	#4
	jsr	gfx_dispchar

	lda	ALM_ZZZ_MINUTE		; Get snoozed minutes
	lsr				; Shift high nibble into low nibble
	lsr
	lsr
	lsr
	beq	.no_minute_tens		; Don't show tens column if zero
	clc
	adc	#'0'			; Add ASCII 0

.no_minute_tens
	ldx	#5
	jsr	gfx_dispchar

	lda	ALM_ZZZ_MINUTE		; Get snoozed minutes
	and	#$0F			; Get low nibble
	clc
	adc	#'0'			; Add ASCII 0
	ldx	#6
	jsr	gfx_dispchar

	lda	#'\''			; Show ASCII single quote after mins
	ldx	#7
	jsr	gfx_dispchar

.snooze_loop
	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_PRESS | KEY_EQU	; If = pressed, then exit context
	beq	.exit_snooze
	cmp	#KEY_PRESS | KEY_ADD	; If + pressed, then add min to snooze
	beq	.increment_snooze
	cmp	#KEY_PRESS | KEY_SUB	; If - pressed, then sub min from snooze
	beq	.decrement_snooze

	lda	ALM_ZZZ_SECOND		; Get snoozed seconds
	beq	.snooze_loop		; If zero then continue to get input
	cmp	#$56			; If < 56 then exit snooze screen (auto-
	bcc	.exit_snooze		; dismiss after 5 seconds of inactivity)

	jmp	.snooze_loop

.exit_snooze
	jmp	isr_exitctx

.increment_snooze
	lda	ALM_ZZZ_STATE		; Get user-configured snooze length by
	and	#ALM_ZZZ_S_LEN		; masking from snooze state
	cmp	#$F0			; If = 15 mins, then don't increment
	beq	.snooze_loop

	clc				; Increment high nibble
	lda	ALM_ZZZ_STATE
	adc	#$10
	sta	ALM_ZZZ_STATE

	jmp	.snooze			; Update current snooze state again

.decrement_snooze
	lda	ALM_ZZZ_STATE		; Get user-configured snooze length by
	and	#ALM_ZZZ_S_LEN		; masking from snooze state
	cmp	#$10			; If = 1 min, then don't decrement
	beq	.snooze_loop

	sec				; Decrement high nibble
	lda	ALM_ZZZ_STATE
	sbc	#$10
	sta	ALM_ZZZ_STATE

	jmp	.snooze			; Update current snooze state again

!zone	alarm_zzzctx
; Entry point for secondary context to clear an alarm that has reached the end
; of its snooze duration and display the alarm to signal to the user that it is
; running. The index of the alarm should be storedin ALARM_IDX prior to
; switching to this context.
; INPUT:	None
; OUTPUT:	Not a subroutine
alarm_zzzctx
	lda	ALM_ZZZ_STATE		; Set active snoozed alarm index to $0F
	ora	#$0F			; to mark as no alarm snoozed
	sta	ALM_ZZZ_STATE

	jmp	alarm_ringctx		; Now show alarm as ringing

!zone	alarm_ackall
; Acknowledge all alarms that are scheduled to ring today. This is useful when
; changing the system time to a time in the future, where any active alarms
; scheduled prior to the new time would otherwise go off.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, GP0 = Trashed
alarm_ackall
	ldx	#0

.loop
	txa
	jsr	alarm_getaddr		; Get address of alarm entry

	ldy	#ALARM_STATE		; Clear active flag in alarm entry
	lda	(GP0),y
	and	#!ALARM_S_ACTIVE
	sta	(GP0),y

	inx

	cpx	#8			; Repeat for 8 alarms
	bcc	.loop

	rts