; MODE MANAGEMENT
; Controls which mode is currently running, and any data associated with the
; current mode.

MODE_OS_LIST
	!word	CLOCK_INFO
	!word	STOPW_INFO
	!word	TIMER_INFO
	!word	$0000

!zone	mode_init
; Initialise the current mode and switching behaviour.
; INPUT:	None
; OUTPUT:	None
;		A, X = Trashed
mode_init
	stz	CT_MODE
	lda	#KEY_DIV_NONE
	sta	KEY_DIV_BEHAV

	ldx	#0

.mode_list_loop
	lda	MODE_OS_LIST,x		; Read mode info address LSB
	sta	MODE_LIST,x		; Copy into mode list
	inx

	lda	MODE_OS_LIST,x		; Read mode info address MSB
	sta	MODE_LIST,x		; Copy into mode list
	inx

	cmp	#0
	bne	.mode_list_loop		; Continue if MSB outside zero page

.mode_list_fill
	cpx	#MODE_LIST_SIZE		; If offset has passed max list size
	bcs	.mode_list_fill_done	; Then finish filling list

	stz	MODE_LIST,x		; Fill remaining entries with null ptrs
	inx
	stz	MODE_LIST,x
	inx

	bra	.mode_list_fill

.mode_list_fill_done
	rts

!zone	mode_set
; Set the current mode, loading any program code and beginning execution at the
; applicable mode's entry point.
; INPUT:	A = Mode index
; OUTPUT:	Not a subroutine
mode_set
	clc
	cld

	sta	CT_MODE

	ldx	#$FF			; Clear out stack for usage in new mode
	txs

	lda	#KEY_DIV_P_NEXT		; Set default KEY_DIV behaviour to
	sta	KEY_DIV_BEHAV		; switch to next mode when pressed

	stz	CLOCK_UPDHNDL		; Clear clock update signal handle

	jsr	gfx_resetfont		; Reset font rendering parameters

.get_mode_offset
	clc				; Convert mode index into list offset
	lda	CT_MODE
	adc	CT_MODE
	tax

	cpx	#MODE_LIST_SIZE		; Check if at end of list
	bcc	.below_max_mode		; If not, skip mode reset

	stz	CT_MODE			; Reset back to home mode
	ldx	#0

.below_max_mode
	lda	MODE_LIST + 1,x		; If mode info addr MSB is not zero
	bne	.found_mode		; page, then access it

	inc	CT_MODE			; Otherwise, skip over this mode
	bra	.get_mode_offset

.found_mode
	lda	MODE_LIST,x		; Store mode info address in GP0
	sta	GP0
	lda	MODE_LIST + 1,x
	sta	GP0 + 1

	ldy	#MODE_I_REF		; Set offset to reference field (addr)

	lda	(GP0),y			; Load ref addr from field into GP1
	sta	GP1
	iny
	lda	(GP0),y
	sta	GP1 + 1

	jmp	(GP1)			; Jump to mode entry point

!zone	mode_next
; Switch to the next mode by calling mode_set.
; INPUT:	None
; OUTPUT:	Not a subroutine
mode_next
	clc
	cld

	lda	CT_MODE
	adc	#1

	jmp	mode_set

!zone	mode_showname
; Display the name of the current mode.
; INPUT:	GP0 = Address of mode info struct
; OUTPUT:	None
;		A, X, Y, GP0, GP1, GP2, GP3 = Trashed
mode_showname
	jsr	gfx_clear		; Clear the screen

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Display mode name as string

	lda	#50			; Set delay of 50 ticks
	sta	GP0
	stz	GP0 + 1

	jsr	time_wait		; Delay to keep name on screen

	rts

!zone	mode_callisrs
; Call the interrupt service routines of all modes. All modes must restore the
; values of GP0-GP7 and STRBUF0-1 if used, but otherwise may use the A, C, P, X
; and Y registers without needing to restore them.
; INPUT:	None
; OUTPUT:	None
mode_callisrs
	lda	GP0			; Save GP0 and GP1 to stack so it
	pha				; doesn't interfere with non-ISR code
	lda	GP0 + 1
	pha
	lda	GP1
	pha
	lda	GP1 + 1
	pha

	ldx	#0			; Use X as index into mode list

.loop_modes
	phx				; Save X in case it's overwritten

	lda	MODE_LIST,x		; Load mode list entry 
	sta	GP0
	lda	MODE_LIST + 1,x
	beq	.no_isr			; If zero page, then no mode list entry,
	sta	GP0 + 1			; so no ISR either

	ldy	#MODE_I_ISR		; Set offset to reference field (addr)

	lda	(GP0),y			; Load ISR address into GP1
	sta	GP1
	iny
	lda	(GP0),y
	beq	.no_isr			; If zero page, then don't call ISR
	sta	GP1 + 1

	jsr	.call_isr		; Call ISR via trampoline

	cld				; Clear BCD mode in case it was used

.no_isr
	plx				; Pop X from stack

	inx				; Incremnet index to get next entry addr
	inx

	cpx	#MODE_LIST_SIZE		; Loop until reached end of mode list
	bcc	.loop_modes

	pla				; Pop GP0 and GP1 from stack
	sta	GP1 + 1
	pla
	sta	GP1
	pla
	sta	GP0 + 1
	pla
	sta	GP0

	rts

.call_isr
	jmp	(GP1)			; Boing!