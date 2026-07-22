; CLOCK MODE
; The default home mode, displaying the current time.

CLOCK_INFO
	!raw	"CLOCK", 0, 0, 0	; MODE_I_NAME
	!word	$0000			; MODE_I_AUTHOR
	!word	$0100			; MODE_I_VERSION
	!word	clock_main		; MODE_I_REF
	!word	$0000			; MODE_I_ISR

!zone	clock_main
; Entry point for the clock mode.
; INPUT:	None
; OUTPUT:	Not a subroutine
clock_main
	lda	#CT_TIME & $FF
	sta	GP0
	lda	#CT_TIME >> 8
	sta	GP0 + 1

	lda	#STRBUF0 & $FF
	sta	GP1
	lda	#STRBUF0 >> 8
	sta	GP1 + 1

	lda	TIME_FORMAT		; Use user-configured time format
	sta	TIME_DSP_FORMAT

	jsr	time_tostr		; Write current time into string buffer

	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Display current time

	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_HOLD | KEY_MUL	; If * held, then set time
	beq	.set_time
	cmp	#KEY_PRESS | KEY_MUL	; If * pressed, then view date
	beq	.go_to_date

	jmp	clock_main

.set_time
	lda	#CT_TIME & $FF
	sta	GP0
	lda	#CT_TIME >> 8
	sta	GP0 + 1

	jsr	time_edit
	bcs	.cancelled

	lda	TIME_DSP_FORMAT		; Get user-selected time format
	sta	TIME_FORMAT		; Save as user-configured time format

.cancelled
	jmp	clock_main

.go_to_date
	jsr	input_getkey
	bne	.go_to_date

	jmp	clock_date

!zone	clock_date
; State for showing the current date.
; INPUT:	None
; OUTPUT:	Not a subroutine
clock_date
	lda	#CT_DATE & $FF
	sta	GP0
	lda	#CT_DATE >> 8
	sta	GP0 + 1

	lda	#STRBUF0 & $FF
	sta	GP1
	lda	#STRBUF0 >> 8
	sta	GP1 + 1

	jsr	date_tostr		; Write current date into string buffer

	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Display current date

	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_HOLD | KEY_MUL	; If * held, then set date
	beq	.set_date
	cmp	#KEY_PRESS | KEY_MUL	; If * pressed, then view time
	beq	.go_to_main

	jmp	clock_date

.set_date
	lda	#CT_DATE & $FF
	sta	GP0
	lda	#CT_DATE >> 8
	sta	GP0 + 1

	jsr	date_edit

	jmp	clock_date

.go_to_main
	jsr	input_getkey
	bne	.go_to_main

	jmp	clock_main