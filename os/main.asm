* = $8000

!source "os/mem.asm"

boot
	ldx	#$FF
	txs

	jsr	time_init

loop
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

	jsr	time_increment		; TODO: Have this called as part of NMI

	jmp	loop

!source "os/gfx.asm"
!source "os/font.asm"
!source "os/time.asm"

* = $FFFC

!word	$8000