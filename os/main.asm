* = $8000

boot
	ldx	#$FF
	txs

	ldx	#0

loop
	txa
	clc
	adc	#'0'

	jsr	gfx_dispchar

	inx

	cpx	#8
	bcc	loop

end
	jmp	end

!source "os/gfx.asm"
!source "os/font.asm"

* = $FFFC

!word	$8000