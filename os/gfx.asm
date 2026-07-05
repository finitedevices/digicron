; GRAPHICS ROUTINES
; Used for displaying text and other graphics on the 8-character display.

!zone	gfx_resetfont
; Reset the font rendering parameters.
; INPUT:	None
; OUTPUT:	None
gfx_resetfont
	stz	FONT_WO_X
	stz	FONT_WO_Y

	rts

!zone	gfx_movefont
; Modify the font rendering parameters to move pixels by an offset.
; INPUT:	X = Rendered X position offset
;		Y = Rendered Y position offset
; OUTPUT:	None
;		X, Y = Kept
gfx_movefont
	stx	FONT_WO_X
	sty	FONT_WO_Y

	rts

!zone	gfx_clear
; Clear the display.
; INPUT:	None
; OUTPUT:	None
;		X = Kept
gfx_clear
	phx				; Save X to stack

	ldx	#8 * 5			; Store display memory length as index

.loop
	dex
	stz	DISPLAY,x		; Clear display column byte at address

	cpx	#0			; If index is not 0
	bne	.loop			; Then clear next byte

	plx				; Restore X from stack

	rts

!zone	gfx_dispchar
; Display a character in a specified cell.
; INPUT:	A = ASCII code for character to display
;		X = Cell index
; OUTPUT:	None
;		GP0, GP1 = Trashed
;		A, X, Y = Kept
; VARIABLES:	GP0 = Font character starting column address
;		GP1 = Font character column data
gfx_dispchar
	cpx	#8			; Prevent cell index out of range
	bcs	.done

	pha				; Save A to stack

	sta	GP0			; ASCII code in indirect address LSB
	lda	#0			; Clear indirect address MSB
	sta	GP0 + 1

	phx				; Save X to stack
	phy				; Save Y to stack

	lda	#0			; Multiply X by 5 for cell column index

.loop_dest_idx
	cpx	#0
	beq	.dest_idx_done

	adc	#4			; Add 5 (carry already set to 1)
	dex

	jmp	.loop_dest_idx

.dest_idx_done
	clc
	adc	FONT_WO_X		; Add destination X position offset
	tax				; Store destination index in X

	asl	GP0			; Multiply ASCII code by 8 to get font
	rol	GP0 + 1			; index address
	asl	GP0
	rol	GP0 + 1
	asl	GP0
	rol	GP0 + 1

	ldy	#0

	lda	GP0 + 1			; Turn index into font column address
	ora	#FONT >> 8
	sta	GP0 + 1

.loop_write_col
	lda	(GP0),y			; Get column byte from font
	sta	GP1

	lda	FONT_WO_Y

.loop_shift_col
	beq	.loop_shift_done

	asl	GP1			; Shift pixel bits by Y position offset

	dec
	bra	.loop_shift_col

.loop_shift_done
	lda	GP1
	sta	DISPLAY,x		; Store column byte in display memory

	inx				; Increment indexes
	iny

	cpy	#5			; If current font index is less than 5
	bcc	.loop_write_col		; Then write next byte

	ply				; Restore registers from stack
	plx
	pla

.done
	rts

!zone	gfx_dispstr
; Display a null-terminated string.
; INPUT:	GP0 = Pointer to string to display
;		X = Maximum number of characters to display (capped at 8)
; OUTPUT:	None
;		A, X, Y, GP0 = Kept
;		GP1, GP2, GP3 = Trashed
; VARIABLES:	X = Source string index
;		GP1 = Font character current column address
;		GP2 = Destination display memory address
;		GP3 = Current display cell column index (LSB); maximum number
;		of characters to display (MSB)
gfx_dispstr
	pha				; Save registers to stack
	phx
	phy

	cpx	#8			; Limit max characters to 8
	bcc	.no_set_max
	ldx	#8

.no_set_max
	stx	GP3 + 1			; Store max characters to display

	ldx	#0			; Source string index

	lda	#0			; Destination display memory address
	sta	GP2
	lda	#DISPLAY >> 8
	sta	GP2 + 1

.loop_str
	txa				; Load ASCII character
	tay
	lda	(GP0),y

	cmp	#0			; Stop on null terminator
	beq	.done

	sta	GP1			; ASCII code in indirect address LSB
	lda	#0			; Clear indirect address MSB
	sta	GP1 + 1

	asl	GP1			; Multiply ASCII code by 8 to get font
	rol	GP1 + 1			; index address
	asl	GP1
	rol	GP1 + 1
	asl	GP1
	rol	GP1 + 1

	ldy	#0

	lda	GP1 + 1			; Turn index into font column address
	ora	#FONT >> 8
	sta	GP1 + 1

	lda	#0
	sta	GP3

.loop_write_col
	lda	(GP1),y			; Get column byte from font
	sta	(GP2),y			; Store column byte in display memory

	inc	GP1			; Increment font column address
	inc	GP2			; Increment display column address
	inc	GP3			; Increment current cell column index

	lda	GP3
	cmp	#5			; If current cell index is less than 5
	bcc	.loop_write_col		; Then write next byte

	inx				; Increment character index
	cpx	GP3 + 1			; If less than max chars to display
	bcc	.loop_str		; Then process next character

.done
	ply				; Restore registers from stack
	plx
	pla

	rts