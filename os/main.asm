* = $8000

!source "os/mem.asm"

boot
	ldx	#$FF
	txs

	jsr	time_init

loop
	jsr	time_eval100

	lda	#CURRENT_TIME & $FF
	sta	GP0
	lda	#CURRENT_TIME >> 8
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

	; lda	INPUT
	; and	#$07
	; clc
	; adc	#'0'
	; ldx	#7
	; jsr	gfx_dispchar

	jmp	loop

nmi_handler
	pha
	php

	jsr	time_increment

	plp
	pla
	rti

!source "os/gfx.asm"
!source "os/time.asm"
!source "os/font.asm"
!source "os/tables.asm"

* = $FFFA
!word	nmi_handler

* = $FFFC
!word	boot