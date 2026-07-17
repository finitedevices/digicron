; SYSTEM FONT
; Array of bitmaps for each ASCII character. Each character contains an 8-byte
; bitmap to ensure fast random access.

* = FONT + ('"' * 8)
!byte	%.....###
!byte	%........
!byte	%.....###
!byte	%........
!byte	%........

* = FONT + ('\'' * 8)
!byte	%.....###
!byte	%........
!byte	%........
!byte	%........
!byte	%........

* = FONT + ('-' * 8)
!byte	%....#...
!byte	%....#...
!byte	%....#...
!byte	%....#...
!byte	%....#...

* = FONT + ('0' * 8)
!byte	%..#####.
!byte	%.#.....#
!byte	%.#.....#
!byte	%.#.....#
!byte	%..#####.

* = FONT + ('1' * 8)
!byte	%........
!byte	%.#....#.
!byte	%.#######
!byte	%.#......
!byte	%........

* = FONT + ('2' * 8)
!byte	%.#....#.
!byte	%.##....#
!byte	%.#.#...#
!byte	%.#..#..#
!byte	%.#...##.

* = FONT + ('3' * 8)
!byte	%..#...#.
!byte	%.#.....#
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%..##.##.

* = FONT + ('4' * 8)
!byte	%...##...
!byte	%...#.#..
!byte	%...#..#.
!byte	%.#######
!byte	%...#....

* = FONT + ('5' * 8)
!byte	%..#..###
!byte	%.#...#.#
!byte	%.#...#.#
!byte	%.#...#.#
!byte	%..###..#

* = FONT + ('6' * 8)
!byte	%..#####.
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%..##..#.

* = FONT + ('7' * 8)
!byte	%.......#
!byte	%.......#
!byte	%.###...#
!byte	%....#..#
!byte	%.....###

* = FONT + ('8' * 8)
!byte	%..##.##.
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%..##.##.

* = FONT + ('9' * 8)
!byte	%..#..##.
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%..#####.

* = FONT + (':' * 8)
!byte	%........
!byte	%........
!byte	%...#.#..
!byte	%........
!byte	%........

* = FONT + ('A' * 8)
!byte	%.#####..
!byte	%...#..#.
!byte	%...#...#
!byte	%...#..#.
!byte	%.#####..

* = FONT + ('B' * 8)
!byte	%.#######
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%..##.##.

* = FONT + ('C' * 8)
!byte	%..#####.
!byte	%.#.....#
!byte	%.#.....#
!byte	%.#.....#
!byte	%..#...#.

* = FONT + ('D' * 8)
!byte	%.#######
!byte	%.#.....#
!byte	%.#.....#
!byte	%.#.....#
!byte	%..#####.

* = FONT + ('E' * 8)
!byte	%.#######
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%.#.....#

* = FONT + ('F' * 8)
!byte	%.#######
!byte	%....#..#
!byte	%....#..#
!byte	%....#..#
!byte	%.......#

* = FONT + ('G' * 8)
!byte	%..#####.
!byte	%.#.....#
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%..###.#.

* = FONT + ('H' * 8)
!byte	%.#######
!byte	%....#...
!byte	%....#...
!byte	%....#...
!byte	%.#######

* = FONT + ('I' * 8)
!byte	%........
!byte	%.#.....#
!byte	%.#######
!byte	%.#.....#
!byte	%........

* = FONT + ('J' * 8)
!byte	%..#.....
!byte	%.#......
!byte	%.#......
!byte	%.#......
!byte	%..######

* = FONT + ('K' * 8)
!byte	%.#######
!byte	%....#...
!byte	%...#.#..
!byte	%..#...#.
!byte	%.#.....#

* = FONT + ('L' * 8)
!byte	%.#######
!byte	%.#......
!byte	%.#......
!byte	%.#......
!byte	%.#......

* = FONT + ('M' * 8)
!byte	%.#######
!byte	%......#.
!byte	%.....#..
!byte	%......#.
!byte	%.#######

* = FONT + ('N' * 8)
!byte	%.#######
!byte	%.....#..
!byte	%....#...
!byte	%...#....
!byte	%.#######

* = FONT + ('O' * 8)
!byte	%..#####.
!byte	%.#.....#
!byte	%.#.....#
!byte	%.#.....#
!byte	%..#####.

* = FONT + ('P' * 8)
!byte	%.#######
!byte	%....#..#
!byte	%....#..#
!byte	%....#..#
!byte	%.....##.

* = FONT + ('Q' * 8)
!byte	%..#####.
!byte	%.#.....#
!byte	%.#.#...#
!byte	%.##....#
!byte	%.######.

* = FONT + ('R' * 8)
!byte	%.#######
!byte	%....#..#
!byte	%...##..#
!byte	%..#.#..#
!byte	%.#...##.

* = FONT + ('S' * 8)
!byte	%..#..##.
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%.#..#..#
!byte	%..##..#.

* = FONT + ('T' * 8)
!byte	%.......#
!byte	%.......#
!byte	%.#######
!byte	%.......#
!byte	%.......#

* = FONT + ('U' * 8)
!byte	%..######
!byte	%.#......
!byte	%.#......
!byte	%.#......
!byte	%..######

* = FONT + ('V' * 8)
!byte	%...#####
!byte	%..#.....
!byte	%.#......
!byte	%..#.....
!byte	%...#####

* = FONT + ('W' * 8)
!byte	%.#######
!byte	%..#.....
!byte	%...#....
!byte	%..#.....
!byte	%.#######

* = FONT + ('X' * 8)
!byte	%.##...##
!byte	%...#.#..
!byte	%....#...
!byte	%...#.#..
!byte	%.##...##

* = FONT + ('Y' * 8)
!byte	%.......#
!byte	%......#.
!byte	%.#####..
!byte	%......#.
!byte	%.......#

* = FONT + ('Z' * 8)
!byte	%.##....#
!byte	%.#.#...#
!byte	%.#..#..#
!byte	%.#...#.#
!byte	%.#....##

* = FONT + (('0' | $80) * 8)
!byte	%........
!byte	%....###.
!byte	%...#...#
!byte	%...#...#
!byte	%....###.

* = FONT + (('1' | $80) * 8)
!byte	%........
!byte	%........
!byte	%...#..#.
!byte	%...#####
!byte	%...#....

* = FONT + (('2' | $80) * 8)
!byte	%........
!byte	%...##..#
!byte	%...#.#.#
!byte	%...#.#.#
!byte	%...#..#.

* = FONT + (('3' | $80) * 8)
!byte	%........
!byte	%...#...#
!byte	%...#.#.#
!byte	%...#.#.#
!byte	%....#.#.

* = FONT + (('4' | $80) * 8)
!byte	%........
!byte	%......##
!byte	%.....#..
!byte	%.....#..
!byte	%...#####

* = FONT + (('5' | $80) * 8)
!byte	%........
!byte	%...#.###
!byte	%...#.#.#
!byte	%...#.#.#
!byte	%....#..#

* = FONT + (('6' | $80) * 8)
!byte	%........
!byte	%....###.
!byte	%...#.#.#
!byte	%...#.#.#
!byte	%....#...

* = FONT + (('7' | $80) * 8)
!byte	%........
!byte	%.......#
!byte	%...##..#
!byte	%.....#.#
!byte	%......##

* = FONT + (('8' | $80) * 8)
!byte	%........
!byte	%....#.#.
!byte	%...#.#.#
!byte	%...#.#.#
!byte	%....#.#.

* = FONT + (('9' | $80) * 8)
!byte	%........
!byte	%......#.
!byte	%...#.#.#
!byte	%...#.#.#
!byte	%....###.

* = FONT + ($FF * 8)
!byte	%########
!byte	%########
!byte	%########
!byte	%########
!byte	%########