; INTERRUPT SERVICE ROUTINES
; Handlers for maskable and non-maskable interrupts.

; Interrupt flags (enum)
INT_FLAG_NONE	= $00
INT_FLAG_SECOND	= $01
INT_FLAG_INPUT	= $02

; Context switching request priorities (enum)
CTX_PRIO_NORMAL	= $80
CTX_PRIO_ALARM	= $E0

!zone	isr_init
; Initialise interrupt context switching variables.
; INPUT:	None
; OUTPUT:	None
isr_init
	stz	ISR_CTXSW_ADDR
	stz	ISR_CTXSW_ADDR + 1
	stz	ISR_CTXSW_PRIO
	stz	ISR_CTXSW_INUSE

	rts

!zone	isr_nmi
; Interrupt service routine for non-maskable interrupts.
; INPUT:	None
; OUTPUT:	None
;		A, X, Y, C = Kept
isr_nmi
	pha
	phx
	phy

	lda	INT_FLAG		; Check if incrementing current time
	and	#INT_FLAG_SECOND
	beq	.no_second

	jsr	time_increment		; Increment current time by 1 second

	jsr	mode_callisrs		; Call ISRs for each mode

.no_second
	lda	INT_FLAG		; Check if input has changed
	and	#INT_FLAG_INPUT
	beq	.no_input_change

	inc	CLOCK_UPDHNDL		; Update current clock value

	lda	CLOCK			; Store time at which input changed in a
	sta	CLOCK_INPUT_CHG		; variable so that button press duration
	lda	CLOCK + 1		; can be evaluated
	sta	CLOCK_INPUT_CHG + 1

	dec	CLOCK_UPDHNDL

.no_input_change
	stz	INT_FLAG		; Clear interrupt flags

	tsx

	lda	ISR_CTXSW_INUSE		; Check if already in secondary context
	bne	.done			; If so, then don't switch

	lda	ISR_CTXSW_ADDR + 1	; Load context switching address MSB
	beq	.done			; If zero page, then don't switch to it

	lda	#isr_enterctx & $FF	; Otherwise, overwrite stack return addr
	sta	$0100 + 5,x		; to perform context switch
	lda	#isr_enterctx >> 8	; Base is $0100 + A + X + Y + P + 1
	sta	$0100 + 6,x

.done
	ply
	plx
	pla
	rti

!zone	isr_rqctxsw
; Request to context-switch — jumping to the specified address if the request is
; granted by the operating system. A context switching request is only granted
; if the given priority is the highest out of all calls to this subroutine
; during ISR handling, and only if we are currently in the main context and not
; a secondary one.
; INPUT:	A = Priority of request (typically CTX_PRIO_NORMAL)
;		GP0 = Address to jump to if the request is granted
; OUTPUT:	None
;		A = Trashed
isr_rqctxsw
	cmp	ISR_CTXSW_PRIO		; Deny if prio <= current highest prio
	bcc	.denied
	beq	.denied

	sta	ISR_CTXSW_PRIO		; Set current higest prio to this one

	lda	GP0			; Copy jump address into variable
	sta	ISR_CTXSW_ADDR
	lda	GP0 + 1
	sta	ISR_CTXSW_ADDR + 1

.denied
	rts

!zone	isr_enterctx
; Enter the secondary context with the entry point address determined by
; ISR_CTXSW_ADDR.
; INPUT:	ISR_CTXSW_ADDR = Address of secondary context entry point
; OUTPUT:	Not a subroutine
isr_enterctx
	ldx	#$FF			; Clear out stack for usage in new ctx
	txs

	lda	#1			; Mark secondary context as in-use
	sta	ISR_CTXSW_INUSE

	jsr	isr_initctx		; Reinitialise context-specific vars

	jmp	(ISR_CTXSW_ADDR)	; Jump to context entry point address

!zone	isr_exitctx
; Exit the current secondary context and return to the main context, going back
; to the current mode.
; INPUT:	None
; OUTPUT:	Not a subroutine
isr_exitctx
	lda	CT_MODE			; Jump to whatever the current mode is
	jmp	mode_set		; This also clears context-switch vars

!zone	isr_initctx
; Initialise the current context by resetting context-specific variables to
; their initial state.
; INPUT:	None
; OUTPUT:	None
;		A = Trashed
isr_initctx
	lda	#KEY_DIV_P_NEXT		; Set default KEY_DIV behaviour to
	sta	KEY_DIV_BEHAV		; switch to next mode when pressed

	stz	CLOCK_UPDHNDL		; Clear clock update signal handle

	jsr	gfx_resetfont		; Reset font rendering parameters

	rts