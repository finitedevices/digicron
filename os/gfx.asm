; Display a character in a specified cell.
; INPUT:	A = ASCII code for character to display
;		X = Cell index
; OUTPUT:	None
;		A, X, Y = Kept
gfx_dispchar
	cpx	#8			; Prevent cell index out of range
	bcs	.done

	pha				; Save A to stack

	sta	$02			; ASCII code in indirect address LSB

	lda	#0			; Clear indirect address MSB
	sta	$03

	txa				; Save X to stack
	pha

	tya				; Save Y to stack
	pha

	lda	#0			; Multiply X by 5 for cell column index

.loop_dest_idx
	cpx	#0
	beq	.done_dest_idx

	adc	#4			; Carry already set to 1
	dex

	jmp	.loop_dest_idx

.done_dest_idx
	tax				; Store destination index in X

	asl	$02			; Multiply ASCII code by 8 to get font
	rol	$03			; index address
	asl	$02
	rol	$03
	asl	$02
	rol	$03

	ldy	#0

.loop_write_col
	lda	$03
	ora	#$E0
	sta	$03

	lda	($02),y			; Get column byte from font
	sta	$7F00,x			; Store column byte in display memory

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