* = $8000

!source "os/structs.asm"
!source "os/mem.asm"

boot
	ldx	#$FF
	txs

	jsr	time_init
	jsr	mode_init

loop
	jsr	time_eval100

	jsr	input_getkey
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

	jsr	input_getkey
	and	#$08
	lsr
	lsr
	lsr
	clc
	adc	#'0'
	ldx	#6
	jsr	gfx_dispchar

	jsr	input_getkey
	and	#$07
	clc
	adc	#'0'
	ldx	#7
	jsr	gfx_dispchar

waitnokey
	jsr	input_getkey
	beq	loop

	and	#KEY_HOLD
	beq	nohold

	lda	#'H'
	ldx	#0
	jsr	gfx_dispchar

nohold
	jmp	waitnokey

!source "os/util.asm"
!source "os/isr.asm"
!source "os/time.asm"
!source "os/input.asm"
!source "os/gfx.asm"
!source "os/font.asm"
!source "os/mode.asm"

* = $FFFA
!word	isr_nmi

* = $FFFC
!word	boot