; SYSTEM FONT
; Array of bitmaps for each ASCII character. Each character contains an 8-byte
; bitmap to ensure fast random access.

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