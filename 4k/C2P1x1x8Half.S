;                 T         T                         T

; 6 5 2 3 4 1 0
; 2   6
;   3   5
;   1       3
; 0           2
; x x 6 5 4 3 2

; 6 5 3 2 4 1 0
; 3   6
;   2   5
; 1         3
;   0         2
; x x 6 5 4 3 2

	include	4k:System.S

	ONCE	C2P

	INCFILE

	include	4k:Chunky.S

	CODE

C2P_LOAD4	macro
	; Interleave
	move.l	a1,d6
	move.l	(a6)+,d0
	move.l	(a6)+,d2
	move.l	(a6)+,d1
	move.l	(a6)+,d3
	and.l	d6,d0
	and.l	d6,d1
	and.l	d6,d2
	and.l	d6,d3
	tst.l	d6
	bmi.b	.channel0\@
	lsl.l	#8,d0
	lsl.l	#8,d1
	bra.b	.channel\@
.channel0\@:	lsr.l	#8,d2
	lsr.l	#8,d3
.channel\@:	or.l	d2,d0
	or.l	d3,d1

	; Saturate
	move.l	#$40404040,d6
	move.l	d6,d5
	move.l	d0,d2
	move.l	d1,d3
	and.l	d6,d2
	and.l	d6,d3
	lsr.l	#6,d2
	lsr.l	#6,d3
	sub.l	d2,d5
	sub.l	d3,d6
	or.l	d5,d0
	or.l	d6,d1

	; Dither (assume minimum value 3)
	move.l	#$03030303,d6
	and.l	d7,d6
	sub.l	d6,d0
	sub.l	d6,d1
	move.l	#$3c3c3c3c,d6
	and.l	d6,d0
	and.l	d6,d1
	lsl.l	#2,d0
	lsr.l	#2,d1
	or.l	d1,d0
	move.l	d0,-(a7)

	; Random
	ror.l	d7,d7
	subq.l	#1,d7
	endm

C2P_MERGE	macro
	move.l	d0,d4
	move.l	d1,d5
	lsl.l	d7,d4
	lsl.l	d7,d5
	eor.l	d2,d4
	eor.l	d3,d5
	and.l	d6,d4
	and.l	d6,d5
	eor.l	d4,d2
	eor.l	d5,d3
	lsr.l	d7,d4
	lsr.l	d7,d5
	eor.l	d4,d0
	eor.l	d5,d1
	endm

C2P_NEXT_MERGE	macro
	lsr.l	#1,d7
	move.l	d6,d5
	lsr.l	d7,d5
	eor.l	d5,d6
	exg.l	d1,d2
	endm

C2P:
	; A1 = Channel mask ($ff00ff00 or $00ff00ff)
	; A3 = Random
	; A5 = Dest
	baselea	Chunky,a6
	lea.l	SCREENWIDTH*2(a6),a2
.c2ploop:
	move.l	a3,d7
	C2P_LOAD4
	C2P_LOAD4
	C2P_LOAD4
	C2P_LOAD4
	move.l	d7,a3

	move.l	(a7)+,d3
	move.l	(a7)+,d2
	move.l	(a7)+,d1
	move.l	(a7)+,d0

	move.l	#$ffff0000,d6
	moveq.l	#16,d7

	; Merge 16
	C2P_MERGE
	C2P_NEXT_MERGE
	; Merge 8
	C2P_MERGE
	C2P_NEXT_MERGE
	C2P_NEXT_MERGE
	; Merge 2
	C2P_MERGE
	C2P_NEXT_MERGE
	; Merge 1
	C2P_MERGE

	move.l	d0,SCREENWIDTH/8*3(a5)
	move.l	d2,SCREENWIDTH/8*2(a5)
	move.l	d1,SCREENWIDTH/8*1(a5)
	move.l	d3,(a5)+

	cmp.l	a2,a6
	blo.w	.c2ploop
	lea.l	SCREENWIDTH/8*3(a5),a5
	rts

	endc
