* = $8000

!source "os/mem.asm"

boot
	ldx	#$FF
	txs

	jsr	time_init

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
	lda	#str & $FF
	sta	GP0
	lda	#str >> 8
	sta	GP0 + 1

	jsr	gfx_dispstr

	lda	INPUT
	and	#$07
	clc
	adc	#'0'
	ldx	#7
	jsr	gfx_dispchar

	jsr	time_increment		; Have this called as part of NMI

	jmp	end

str
	!pet	"7321",0

!source "os/gfx.asm"
!source "os/font.asm"
!source "os/time.asm"

* = $FFFC

!word	$8000