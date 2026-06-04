; SYSTEM FONT
; Array of bitmaps for each ASCII character. Each character contains an 8-byte
; bitmap to ensure fast random access.

* = FONT + ('0' * 8)
!byte	$3E,$41,$41,$41,$3E

* = FONT + ('1' * 8)
!byte	$00,$42,$7F,$40,$00

* = FONT + ('2' * 8)
!byte	$42,$61,$51,$49,$46

* = FONT + ('3' * 8)
!byte	$22,$41,$49,$49,$36

* = FONT + ('4' * 8)
!byte	$18,$14,$12,$7F,$10

* = FONT + ('5' * 8)
!byte	$27,$45,$45,$45,$39

* = FONT + ('6' * 8)
!byte	$3E,$49,$49,$49,$32

* = FONT + ('7' * 8)
!byte	$01,$01,$71,$09,$07