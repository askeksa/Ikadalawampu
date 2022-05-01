;              T         T               T

	include	4k:System.S

	ONCE	Palette

	INCFILE

	FastField	PalTemp,	3*16+1
	FastSpace		32
	FastField	PalTemp2,	3*256+1

;	include	4k:Scripting.S

	CODE

;	moveq.l	#0*2,d0
;	moveq.l	#1*2,d1
;	moveq.l	#30,d2

MakePalette macro
	; D0 = Pal 0
	; D1 = Pal 1
	; D2 = Weight
	; A5 = Dest
	baselea	PalTemp2,a3
	add.l	d0,d0
	add.l	d1,d1
	add.l	d2,d2
	move.l	#0,d3	; Color component shift
.comploop:	datalea	PalColors,a1
	lea.l	8(a1,d0.l*4),a0
	lea.l	8(a1,d1.l*4),a1
	moveq.l	#3,d4	; Color corner
.cornloop:	move.w	-(a0),d5
	move.w	-(a1),d6
	lsr.w	d3,d5
	lsr.w	d3,d6
	lsl.b	#4,d5
	lsl.b	#4,d6
	move.b	d6,-(a3)
	move.b	d5,-(a3)
	dbf	d4,.cornloop
	addq.w	#4,d3
	cmp.w	#12,d3
	blt.b	.comploop

	move.l	a3,a1
	move.l	a3,a0
	moveq.l	#1,d0
	moveq.l	#3*4,d1
	moveq.l	#1,d4
	bsr.w	Interpolate

	baselea	PalTemp,a1
	move.l	a3,a0
	moveq.l	#1,d0
	moveq.l	#3*2,d1
	moveq.l	#0,d2
	moveq.l	#17,d3
	moveq.l	#16,d4
	bsr.w	Interpolate

	baselea	PalTemp,a0
	move.l	a5,a1
	moveq.l	#16,d0
	moveq.l	#3,d1
	moveq.l	#0,d2
	moveq.l	#17,d3
	moveq.l	#16,d4
	bsr.w	Interpolate
;	rts
	endm

Interpolate:
	; A0 = Source
	; A1 = Dest
	; D0 = Block size
	; D1 = Num of blocks
	; D2 = Inter start
	; D3 = Inter step
	; D4 = Inter num

	mulu.w	d0,d1
	lea.l	(a0,d1.l*2),a6
.bloop:
	move.l	d0,d1
	subq.l	#1,d1
.vloop:
	clr.l	d5
	clr.l	d6
	move.b	(a0)+,d5
	move.b	-1(a0,d0.l),d6
	sub.l	d5,d6
	move.l	d6,d7
	muls.w	d2,d6
	muls.w	d3,d7
	asl.l	#8,d5
	add.l	d6,d5

	move.l	d4,d6
	subq.l	#1,d6
.iloop:	move.w	d5,(a1)
	addq.l	#1,a1
	add.l	d7,d5
	dbf	d6,.iloop

	dbf	d1,.vloop
	add.l	d0,a0
	cmp.l	a6,a0
	blo.b	.bloop
	rts

	endc
