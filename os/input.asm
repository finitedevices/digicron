; USER INPUT
; Routines for reading and processing the state of user input from the keyboard.

; Key value mappings (enum)
KEY_7		= $00
KEY_8		= $01
KEY_9		= $02
KEY_DIV		= $03
KEY_4		= $04
KEY_5		= $05
KEY_6		= $06
KEY_MUL		= $07
KEY_1		= $08
KEY_2		= $09
KEY_3		= $0A
KEY_SUB		= $0B
KEY_0		= $0C
KEY_DOT		= $0D
KEY_EQU		= $0E
KEY_ADD		= $0F

; Key state mappings (bit field)
KEY_PRESS	= $10
KEY_HOLD_ONLY	= $80			; Only available from input routines
KEY_HOLD	= KEY_PRESS | KEY_HOLD_ONLY

; KEY_DIV behaviours (enum)
; With the exception of KEY_DIV_NONE, all other behaviours will also result in
; going to mode $00 (clock) when KEY_DIV is held
KEY_DIV_NONE	= $00			; Key does not affect mode
KEY_DIV_P_NEXT	= $01			; Pressing key goes to next mode
KEY_DIV_H_HOME	= $02			; Holding key goes to mode $00 (clock)

!zone	input_getkey
; Get the currently pressed key. This routine may also trigger a mode change if
; KEY_DIV is pressed or held (depending on the value of MODE_DIV_BEHAV).
; INPUT:	None
; OUTPUT:	A = Key state
;		C, X = Kept
input_getkey
	php
	phx

	cld

	lda	INPUT			; Skip button hold check if none pressed
	and	#KEY_PRESS
	beq	.no_key

	lda	INPUT			; Check if pressed key is KEY_DIV
	cmp	#KEY_PRESS | KEY_DIV
	bne	.no_press_next_mode	; If not, then don't check behaviour

	lda	KEY_DIV_BEHAV		; Check if behaviour is to go to next
	cmp	#KEY_DIV_P_NEXT		; mode
	beq	.test_next_mode		; If so, then test if press or hold

.no_press_next_mode
	sec

	inc	CLOCK_UPDHNDL		; Update current clock value

	lda	CLOCK			; Calculate button hold-down duration
	sbc	CLOCK_INPUT_CHG
	tax

	lda	CLOCK + 1
	sbc	CLOCK_INPUT_CHG + 1

	dec	CLOCK_UPDHNDL

	bne	.is_hold		; If subtracted MSB > 0, then is hold

	lda	#0			; Clear all bits for later ORA on INPUT

	cpx	#50			; If LSB is less than 500 ms
	bcc	.no_hold		; Then is not a hold
	beq	.no_hold

.is_hold
	sta	$2001
	lda	INPUT			; Check if pressed key is KEY_DIV
	cmp	#KEY_PRESS | KEY_DIV
	bne	.no_hold_home_mode	; If not, then don't check behaviour

	lda	KEY_DIV_BEHAV		; Check if behaviour is to go to mode
	cmp	#KEY_DIV_H_HOME		; $00
	bne	.no_hold_home_mode	; If not, then don't change mode

	lda	#0
	jmp	mode_set

.no_hold_home_mode
	lda	#KEY_HOLD		; Set bit to signify held key

.no_hold
	plx				; Restore X and state before changing A
	plp				; to ensure Z flag is correctly set

	ora	INPUT

	rts

.no_key
	plx
	plp

	lda	#0

	rts

.test_next_mode
	lda	#KEY_DIV_H_HOME		; Prevent recursion by setting behaviour
	sta	KEY_DIV_BEHAV		; to only change mode on KEY_DIV hold

.test_loop
	jsr	input_getkey		; Check current key state
	bne	.test_loop		; Continue until current key is released

	jmp	mode_next		; If key not held, then go to next mode

!zone	input_getkeypress
; Get the key that was pressed and released during this subroutine call. This
; routine is blocking while a key is being pressed. This routine may also
; trigger a mode change if KEY_DIV is pressed or held (depending on the value of
; MODE_DIV_BEHAV).
; INPUT:	None
; OUTPUT:	A = Key state
;		C, X = Kept
input_getkeypress
	php
	phx

	ldx	#0			; Reset last key state

.check_loop
	jsr	input_getkey		; If key has been released, then finish
	beq	.done

	tax				; Otherwise, store last state in X

	and	#KEY_HOLD_ONLY		; If key has been held, then finish
	bne	.done

	bra	.check_loop

.done
	txa				; Store last key state in A

	plx
	plp
	rts

!zone	input_keytobcd
; Convert the given key state into a binary-coded decimal (BCD) value. If the
; key state does not map to a BCD value, then C will be set; otherwise, it
; will be cleared.
; INPUT:	A = Key state
;		C = Set if should consider holding key as valid BCD mapping
; OUTPUT:	A = BCD value
;		C = Clear only if key state maps to a BCD value
;		X = Kept
input_keytobcd
	phx				; Save X to stack

	bcs	.skip_hold_check	; Only check for hold state if C set
	tax
	and	#KEY_HOLD_ONLY
	bne	.non_mapped
	txa

.skip_hold_check
	cmp	#0			; If no key pressed then not valid BCD
	beq	.non_mapped

	and	#$0F			; Mask out key state
	tax
	lda	.MAPPING_TABLE,x	; Get BCD value from mapping table

	cmp	#$FF			; If key listed as $FF in mapping table
	beq	.non_mapped		; Then is not valid BCD

	plx				; Restore X from stack
	clc
	rts

.non_mapped
	plx				; Restore X from stack
	sec
	rts

.MAPPING_TABLE
	!byte	$07, $08, $09, $FF
	!byte	$04, $05, $06, $FF
	!byte	$01, $02, $03, $FF
	!byte	$00, $FF, $FF, $FF

!zone	input_showmenu
; Show an interactive menu where the user can select an option. The menu items
; must be stored in a table, pointed to by the address in GP0. This table must
; contain menu items in the form of pairs of string pointers and dispatch
; addresses, with each string pointer referencing the string to display for that
; menu item, and each dispatch address referencing the address to call as a
; subroutine if that menu item is selected (if in the zero page then the call
; will not be made, but the address will be retained in GP0 for the caller of
; this routine to inspect).
; INPUT:	A = Index of menu item to initially show
;		GP0 = Null-terminated table of address pairs pointing to null-
;		terminated menu item strings and dispatch subroutines,
;		respectively
; OUTPUT:	A = Index of selected menu item, or of menu item visible when
;		menu was cancelled
;		C = Set if menu selection was cancelled by the user
;		GP0 = Dispatch address used for the menu item that was selected
;		(will be set to dispatch address regardless of changes made to
;		GP0 by the called subroutine, if any), or null ($0000) if menu
;		was cancelled
;		A, X, Y, GP1-4 = Trashed
; VARIABLES:	GP4 = Saved value of GP0
;		GP5 = Current index (LSB) and length of menu table (MSB)
input_showmenu
	sta	GP5			; Store initial index in current index

	lda	GP0			; Copy GP0 into GP4 to save it
	sta	GP4
	lda	GP0 + 1
	sta	GP4 + 1

	ldy	#0			; Use as byte index into table

.length_loop
	lda	(GP0),y			; Check if table string pointer is $0000
	iny
	ora	(GP0),y
	beq	.length_end		; If so, then stop looping
	iny
	iny				; Skip over dispatch address
	iny

	bra	.length_loop

.length_end
	tya				; Get table length and store as GP5 MSB
	lsr
	lsr
	sta	GP5 + 1
	beq	.empty			; If table length is 0, then show empty

	lda	GP5			; If current index < table length
	cmp	GP5 + 1
	bcc	.display_loop		; Then don't cap current index

	lda	GP5 + 1			; Set current index to table length - 1
	dec				; to prevent out-of-bounds index
	sta	GP5

.display_loop
	jsr	gfx_clear		; Clear display

	lda	GP5			; Get offset address into table
	asl
	asl
	clc
	adc	GP4			; Add to table base address LSB
	sta	GP1			; Store as string indirect pointer LSB

	lda	GP4 + 1			; Add carried result into MSB
	adc	#0
	sta	GP1 + 1

	ldy	#0			; Dereference indirect string pointer
	lda	(GP1),y
	sta	GP0
	iny
	lda	(GP1),y
	sta	GP0 + 1

	ldx	#7			; Set max characters to display

	jsr	gfx_dispstr		; Display current menu item

	lda	#':' | $80		; Show menu arrows indicator in column 7
	ldx	#7
	jsr	gfx_dispchar

.input_loop
	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_PRESS | KEY_MUL	; If * pressed, then cancel
	beq	.cancel
	cmp	#KEY_PRESS | KEY_ADD	; If + pressed, then go to next item
	beq	.next_item
	cmp	#KEY_PRESS | KEY_SUB	; If - pressed, then go to prev item
	beq	.prev_item
	cmp	#KEY_PRESS | KEY_EQU	; If = pressed, then confirm selection
	beq	.confirm

	jmp	.input_loop

.empty
	jsr	gfx_clear		; Clear display

	lda	#<.EMPTY_MSG
	sta	GP0
	lda	#>.EMPTY_MSG
	sta	GP0 + 1

	ldx	#8			; Set max characters to display

	jsr	gfx_dispstr		; Show "(Empty)" message

.empty_input_loop
	jsr	input_getkeypress	; Check currently pressed key
	cmp	#KEY_PRESS | KEY_MUL	; If * pressed, then cancel
	bne	.empty_input_loop

	lda	#0
	sec
	rts

.cancel
	stz	GP0			; Clear returned dispatch address value
	stz	GP0 + 1

	lda	GP5			; Load current selection index
	sec
	rts

.confirm
	lda	GP5			; Load current selection index
	pha				; Save to stack

	asl				; Get offset address into array
	asl
	inc				; Offset by 2 bytes to get dispatch addr
	inc
	clc
	adc	GP4			; Add to array base address LSB
	sta	GP1			; Store as indirect address LSB

	lda	GP4 + 1			; Add carried result into MSB
	adc	#0
	sta	GP1 + 1

	ldy	#0			; Dereference indirect dispatch address
	lda	(GP1),y
	sta	GP0
	iny
	lda	(GP1),y
	sta	GP0 + 1
	beq	.no_call		; If in zero page then do not call

	lda	GP0			; Save dispatch address to stack
	pha
	lda	GP0 + 1
	pha

	jsr	.call_dispatch		; Call ISR via trampoline

	pla				; Restore dispatch address from stack
	sta	GP0 + 1
	pla
	sta	GP0

.no_call
	pla				; Restore index from stack
	clc
	rts

.call_dispatch
	jmp	(GP0)			; Boing!

.next_item
	lda	GP5			; Increment current selection index
	inc
	cmp	GP5 + 1			; If index >= array length
	bcc	.not_at_start		; Then reset index to 0

	lda	#0

.not_at_start
	sta	GP5

	jmp	.display_loop

.prev_item
	lda	GP5			; Check current selection index
	cmp	#0			; If index = 0
	bne	.not_at_end		; Then set to array length - 1

	lda	GP5 + 1			; Get array length

.not_at_end
	dec				; Decrement index
	sta	GP5

	jmp	.display_loop

.EMPTY_MSG
	!raw	"(Empty)", 0

!zone	input_menufind
; Find the index of the menu item with the given menu table and dispatch
; address. If the menu item is found, then its index will be stored in A, with C
; clear. If the menu item is not found, then C will be set and A set to the
; count of items in the menu.
; INPUT:	GP0 = Null-terminated array of address pairs pointing to null-
;		terminated menu item strings and dispatch subroutines,
;		respectively
;		GP1 = Dispatch address to find in menu items
; OUTPUT:	A = Index of menu item with matching dispatch address
;		C = Set if unable to find matching menu item
;		A, X, Y = Trashed
input_menufind
	ldx	#0			; Use as index into menu table

.loop
	txa				; Get index
	asl				; Convert to string pointer index
	asl
	tay
	lda	(GP0),y			; Check if string pointer is $0000
	iny
	ora	(GP0),y
	beq	.not_found		; If so then reached end; not found

	txa				; Get index
	asl				; Convert to dispatch value index
	asl
	inc
	inc
	tay

	lda	(GP0),y			; Get current dispatch address LSB
	cmp	GP1			; Check against search dispatch address
	bne	.next			; If no match then move onto next item
	iny
	lda	(GP0),y			; Get current dispatch address MSB
	cmp	GP1 + 1			; Check against search dispatch address
	beq	.found			; If match then return found index

.next
	inx

	bra	.loop

.found
	txa				; Return index of found item in A
	clc
	rts

.not_found
	txa				; Return count of items in A
	sec
	rts