* = $8000

!source "os/structs.asm"
!source "os/mem.asm"

boot
	ldx	#$FF
	txs

	jsr	time_init

loop
	jsr	time_eval100

	lda	INPUT
	bne	keydown

	lda	#CT_TIME & $FF
	sta	GP0
	lda	#CT_TIME >> 8
	sta	GP0 + 1

	lda	#STRBUF0 & $FF
	sta	GP1
	lda	#STRBUF0 >> 8
	sta	GP1 + 1

	jsr	time_tostr

	lda	#STRBUF0 & $FF
	sta	GP0
	lda	#STRBUF0 >> 8
	sta	GP0 + 1

	jsr	gfx_dispstr

	jmp	loop

keydown
	jsr	gfx_clear

	lda	INPUT
	and	#$08
	lsr
	lsr
	lsr
	clc
	adc	#'0'
	ldx	#6
	jsr	gfx_dispchar

	lda	INPUT
	and	#$07
	clc
	adc	#'0'
	ldx	#7
	jsr	gfx_dispchar

waitnokey
	lda	INPUT
	beq	loop

	jmp	waitnokey

nmi_handler
	pha
	php

	jsr	time_increment

	plp
	pla
	rti

!source "os/util.asm"
!source "os/gfx.asm"
!source "os/time.asm"
!source "os/font.asm"

* = $FFFA
!word	nmi_handler

* = $FFFC
!word	boot