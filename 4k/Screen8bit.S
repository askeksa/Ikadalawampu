;              T         T               T

	include	4k:System.S

	ONCE	Screen

	INCFILE

SCREEN_BUFFERS	=	16
SCREEN_STRIDE	=	65536
PALETTE_STRIDE	=	65536

	include	4k:Chunky.S
;	include	4k:C2P2x1x8Blitter.S
	include	4k:Palette.S

	ChipField	Screen,SCREEN_BUFFERS*SCREEN_STRIDE
	FastField	Palettes,SCREEN_BUFFERS*PALETTE_STRIDE

	DATA

copreg	set	$000
copline	macro
	dc.w	\1-copreg,\2
copreg	set	\1+2
	endm

Copper:
	copline	$08e,($ac81-(SCREENHEIGHT/2)<<8)&$ffff
	copline	$090,($acc1+(SCREENHEIGHT/2)<<8)&$ffff
	copline	$092,$0038
	copline	$094,$00b0
;	copline	$096,$8300
	copline	$100,$0211
	copline	$102,$0000
	copline	$104,$0000
	copline	$106,$0000
	copline	$108,$0118
	copline	$10a,$0118
	copline	$10c,$0000
;	copline	$180,$000f
;	copline	$182,$00f0
	copline	$1fc,$0003
Copper_End:

	CODE

ScreenSetup macro
	; A3 = $dff000
;	baselea	BlitCopper,a2
;	lea.l	C2PBlitCommands\.end-C2PBlitCommands(a2),a2
;	move.l	a2,$dff080

	datalea	Copper,a0
	moveq.l	#(Copper_End-Copper)/4-1,d7
.cloop:	add.w	(a0)+,a3
	move.w	(a0)+,(a3)+
	dbf	d7,.cloop

;	move.l	#256-1,d7
;.cols:	moveq.l	#32-1,d6
;	and.l	d7,d6
;	move.l	d7,d5
;	lsr.l	#5,d5
;	ror.w	#3,d5
;	move.w	d5,$106-copreg(a3)
;	move.w	d7,$180-copreg(a3,d6.w*2)
;	dbf	d7,.cols

;	rts
	endm

ScreenInterrupt macro
	; A3 = $dff000
	move.l	b_VBlank(a4),d2
	move.l	b_Frame(a4),d3	; Ready frame
	move.l	d2,d6
	add.l	d6,d6
	addq.l	#1,d6
	moveq.l	#2,d4
	moveq.l	#SCREEN_BUFFERS,d5
	divu.w	#5,d6
	ext.l	d6	; Frame to show if ready
	cmp.l	d6,d3
	blt.w	.behind
	move.l	d6,d3
.behind:
	; D3 = Frame to show

	baselea	Screen,a5
	move.l	#SCREEN_BUFFERS-1,d5
	and.l	d5,d3	; Queue entry
	swap.w	d3
	add.l	d3,a5

	move.l	#SCREENWIDTH/8/4,d0
	move.l	#$0e0/4,d4

	move.l	a5,(a3,d4.l*4)
	rept	7
	lea.l	(a5,d0.l*4),a5
	addq.l	#1,d4
	move.l	a5,(a3,d4.l*4)
	endr

PaletteInterrupt:
;	lsr.l	#6,d3
	clr.l	d7
.orderloop:
	baselea	Palettes,a5
	add.l	d3,a5
	move.l	#$0020,d6
.bankloop:	
	move.l	d7,d0
	lsl.w	#7,d0
	or.w	d6,d0
	move.w	d0,$106(a3)

	lea.l	$180(a3),a2
	moveq.l	#32-1,d5
.colorloop:	move.b	(a5)+,d0
	move.b	256-1(a5),d1
	move.b	2*256-1(a5),d2
	lsl.b	d7,d0
	lsl.b	d7,d1
	lsl.b	d7,d2
	lsl.w	#4,d0
	move.b	d1,d0
	lsl.w	#4,d0
	move.b	d2,d0
	lsr.w	#4,d0
	move.w	d0,(a2)+
	dbf	d5,.colorloop

	add.w	#$2000,d6
	bcc.b	.bankloop

	eor.w	#4,d7
	bne.b	.orderloop

	move.w	#$0020,$dff106
;	rts
	endm

	endc
