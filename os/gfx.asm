; GRAPHICS ROUTINES
; Used for displaying text and other graphics on the 8-character display.

; Display a character in a specified cell.
; INPUT:	A = ASCII code for character to display
;		X = Cell index
; OUTPUT:	None
;		A, X, Y = Kept
gfx_dispchar
	cpx	#8			; Prevent cell index out of range
	bcs	.done

	pha				; Save A to stack

	sta	GP0			; ASCII code in indirect address LSB

	lda	#0			; Clear indirect address MSB
	sta	GP0 + 1

	txa				; Save X to stack
	pha

	tya				; Save Y to stack
	pha

	lda	#0			; Multiply X by 5 for cell column index

.loop_dest_idx
	cpx	#0
	beq	.done_dest_idx

	adc	#4			; Add 5 (carry already set to 1)
	dex

	jmp	.loop_dest_idx

.done_dest_idx
	tax				; Store destination index in X

	asl	GP0			; Multiply ASCII code by 8 to get font
	rol	GP0 + 1			; index address
	asl	GP0
	rol	GP0 + 1
	asl	GP0
	rol	GP0 + 1

	ldy	#0

.loop_write_col
	lda	GP0 + 1
	ora	#FONT >> 8
	sta	GP0 + 1

	lda	(GP0),y			; Get column byte from font
	sta	DISPLAY,x		; Store column byte in display memory

	inx				; Increment indexes
	iny

	cpy	#5			; If current font index is less than 5
	bcc	.loop_write_col		; Then write next byte

	pla
	tay				; Restore Y from stack

	pla
	tax				; Restore X from stack

	pla				; Restore A from stack

.done
	rts