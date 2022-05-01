;              T         T               T

	include	4k:System.S

	ONCE	Particles

	INCFILE

COLOR_TABLES	=	32*32
COLOR_TABLE_SIZE=	63
COLOR_TABLE_STRIDE=	72
MAX_PARTICLES	=	16384
MAX_PARTICLES_PER_LINE=	987

;	PRECALC
;	pcall	InitFrame
	include	4k:Interpreter.S

	include	4k:Constants.S
	include	4k:C2P1x1x8Half.S

	FastField	ActiveParticles,MAX_PARTICLES*4
	FastField	ParticleSpace,SCREENHEIGHT*MAX_PARTICLES_PER_LINE*32
	FastField	LineNextParticle,SCREENHEIGHT*4
	FastField	ColorTables,COLOR_TABLES*COLOR_TABLE_STRIDE*2

	rsreset
p_tp_ycurv	rs.l	1	; 11.21
p_xcurv	rs.l	1	; 11.21
p_tp_xpos	rs.l	1	; 25.7
p_xradius	rs.l	1	; 25.7
p_x0	rs.l	1	; 25.7
p_y0	rs.l	1	; 25.7
p_maxy	rs.l	1
p_colortable	rs.l	1

	PROFDEF	PutParticle

	PROFDEF	AddParticles
	PROFDEF	Clear
	PROFDEF	DrawParticle
	PROFDEF	FillParticle
	PROFDEF	C2P

	PRECALC

MakeColorTables:
	baselea	ColorTables,a3

	datalea	Constants,a6
	fmove.s	c_ColorFalloff(a6),fp7

	move.l	#0,d6
.c0loop:	move.l	#0,d7
.c1loop:	fmove.l	d6,fp0
	fmove.l	d7,fp1
	move.l	#COLOR_TABLE_SIZE-1,d5
.colortableloop:
	clr.l	d0
	clr.l	d1
	fmove.b	fp0,d0
	fmove.b	fp1,d1
	asr.l	#1,d0
	asr.l	#1,d1
	fmul	fp7,fp0
	fmul	fp7,fp1

	lsl.w	#8,d1
	or.w	d1,d0
	move.w	d0,(a3)+
	dbf	d5,.colortableloop
	lea.l	(COLOR_TABLE_STRIDE-COLOR_TABLE_SIZE)*2(a3),a3
	addq.b	#8,d7
	bne.w	.c1loop
	addq.b	#8,d6
	bne.w	.c0loop

	CODE

InitFrame:
	baselea	ParticleSpace,a1
	baselea	LineNextParticle,a2

	; Initialize LineNextParticle
	move.l	#SCREENHEIGHT-1,d7
.lnploop:	move.l	a1,(a2)+
	lea.l	MAX_PARTICLES_PER_LINE*32(a1),a1
	dbf	d7,.lnploop
	rts

PutParticle:
	; FP0/FP1 = Color
	; A5 = Matrix

	PROFILE	PutParticle

	baselea	ColorTables,a3
	datalea	Constants,a6
	fmove.s	c_ColorFac(a6),fp7
	fmul	fp7,fp0
	fmul	fp7,fp1
	clr.l	d0
	clr.l	d1
	fmove.b	fp0,d0
	fmove.b	fp1,d1
	asr.l	#2,d0
	asr.l	#2,d1
	asl.l	#5,d0
	add.l	d1,d0
	muls.w	#COLOR_TABLE_STRIDE*2,d0
	add.l	d0,a3

	; Invert matrix
	fmove.s	0(a5),fp0	; a
	fmove.s	4(a5),fp1	; c
	fmove.s	8(a5),fp2	; b
	fmove.s	12(a5),fp3	; d
	fmove.s	16(a5),fp4	; x0
	fmove.s	20(a5),fp5	; y0

	fmove	fp0,fp6
	fmove	fp1,fp7
	fmul	fp3,fp6
	fmul	fp2,fp7
	fsub	fp7,fp6
	fmove.s	c_FloatOne(a6),fp7
	fdiv	fp6,fp7
	fmul	fp7,fp0	; h
	fmul	fp7,fp1	; -g
	fmul	fp7,fp2	; -f
	fmul	fp7,fp3	; e

	; Calculate draw coefficients
	fmove	fp0,fp6
	fmove	fp3,fp7
	fmul	fp1,fp6	; -gh
	fmul	fp2,fp7	; -ef
	fadd	fp7,fp6	; -C
	fmul	fp0,fp0	; h²
	fmul	fp1,fp1	; g²
	fmul	fp2,fp2	; f²
	fmul	fp3,fp3	; e²
	fadd	fp2,fp0	; B
	fadd	fp3,fp1	; A

	fmove	fp6,fp2
	fdiv	fp1,fp2	; -C/A
	fmul	fp2,fp6
	fsub	fp6,fp0	; B-C²/A

	fmove.s	fp1,d0
	move.l	#$5f400000,d1
	asr.l	#1,d0
	sub.l	d0,d1
	fmove.s	d1,fp3	; sqrt(1/A) = x radius

	fmove.s	fp0,d0
	move.l	#$5f400000,d1
	asr.l	#1,d0
	sub.l	d0,d1
	fmove.s	d1,fp6	; top point y radius

	; Convert to fix point
	fmove.s	c_CurvFac(a6),fp7
	fmul	fp7,fp0
	fmul	fp7,fp1
	fmove.s	c_ToFixFac(a6),fp7
	fmul	fp7,fp2
	fmul	fp7,fp3
	fmul	fp7,fp4
	fmul	fp7,fp5
	fmul	fp7,fp6
	fmove.l	fp0,d0
	fmove.l	fp1,d1
	fmove.l	fp2,d2
	fmove.l	fp3,d3
	fmove.l	fp4,d4
	fmove.l	fp5,d5
	fmove.l	fp6,d6

	; Max/min y
	move.l	d6,d7
	add.l	d5,d6	; maxy
	ble.w	.no_particle
	sub.l	d5,d7
	neg.l	d7	; miny
	bge.w	.posy
	clr.l	d7
.posy:	asr.l	#7,d6
	asr.l	#7,d7
	cmp.l	#SCREENHEIGHT,d7
	bge.w	.no_particle

	; Write particle info
	baselea	LineNextParticle,a2
	move.l	(a2,d7.l*4),a6
	ASSERT	l,a6,hs,#ParticleSpace
	ASSERT	l,a6,lo,#ParticleSpace+SCREENHEIGHT*MAX_PARTICLES_PER_LINE*32
;	move.l	d0,p_tp_ycurv(a6)
;	move.l	d1,p_xcurv(a6)
;	move.l	d2,p_tp_xpos(a6)
;	move.l	d3,p_xradius(a6)
;	move.l	d4,p_x0(a6)
;	move.l	d5,p_y0(a6)
;	move.l	d6,p_maxy(a6)
;	move.l	a3,p_colortable(a6)
;;	movem.l	d0-d6/a3,(a6)
;	lea.l	8*4(a6),a6
	move.l	d0,(a6)+
	move.l	d1,(a6)+
	move.l	d2,(a6)+
	move.l	d3,(a6)+
	move.l	d4,(a6)+
	move.l	d5,(a6)+
	move.l	d6,(a6)+
	move.l	a3,(a6)+
	move.l	a6,(a2,d7.l*4)

.no_particle:
	rts

RenderParticles:
	; A3 = Random
	; A5 = Screen
;	move.w	#$f00,$dff180
	clr.l	d7
	baselea	ActiveParticles,a0
.lineloop:
	PROFILE	AddParticles
	baselea	ParticleSpace,a1
	baselea	LineNextParticle,a2
	move.l	#MAX_PARTICLES_PER_LINE*8,d0
	mulu.w	d7,d0
	lea.l	(a1,d0.l*4),a6
	bra.w	.addparticleslend
.addparticlesloop:
	move.l	a6,(a0)+
	lea.l	8*4(a6),a6
.addparticleslend:
	cmp.l	(a2,d7.l*4),a6
	blo.b	.addparticlesloop
	clr.l	(a0)

	; Clear
	PROFILE	Clear
	baselea	Chunky,a6
	move.l	#$03030303,d6
	move.l	#SCREENWIDTH*2/4/4-1,d5
.clearloop:	rept	4
	move.l	d6,(a6)+
	endr
	dbf	d5,.clearloop

	baselea	ActiveParticles,a0
	move.l	a0,a2
	bra.w	.nextparticle
.particleloop:
	move.l	(a2)+,a6
	cmp.l	p_maxy(a6),d7
	bge.w	.nextparticle
	move.l	a6,(a0)+

	PROFILE	DrawParticle

	; Draw particle
	move.l	p_tp_ycurv(a6),d0
	move.l	p_xcurv(a6),d1
	move.l	p_tp_xpos(a6),d2
	move.l	p_xradius(a6),d3
	move.l	p_x0(a6),d4
	move.l	p_y0(a6),d5
	move.l	d7,d6
	asl.l	#7,d6
	sub.l	d5,d6
	muls.l	d6,d2
	asr.l	#7,d2
	add.l	d4,d2	; tp xpos
	move.l	d2,d4
	move.l	d2,d5
	add.l	d3,d4
	sub.l	d3,d5

	asr.l	#8,d4	; Max x doublepixel
	asr.l	#8,d5	; Min x doublepixel
	bge.w	.minx_ok
	clr.l	d5
.minx_ok:	move.l	#SCREENWIDTH/2-1,d3
	cmp.l	d3,d4
	ble.w	.maxx_ok
	move.l	d3,d4
.maxx_ok:	sub.l	d5,d4
	blt.w	.nextparticle

	asr.l	#4,d2
	asr.l	#4,d6
	asl.l	#4,d5
	sub.l	d5,d2
	asr.l	#4,d5
	move.l	d2,d3
	add.l	d2,d2
	subq.l	#1<<3,d2
	muls.w	d3,d3
	muls.w	d6,d6
	muls.l	d1,d2
	muls.l	d1,d3
	muls.l	d0,d6
	asr.l	#3,d2
	asr.l	#6,d3
	asr.l	#6,d6
	add.l	d1,d1
	add.l	d6,d3
	move.l	d1,a3

	moveq.l	#15,d1
	sub.l	#63<<15,d3

	move.l	p_colortable(a6),a1
	baselea	Chunky,a6
	lea.l	(a6,d5.l*4),a6

;	move.w	#$ff0,$dff180
	PROFILE	FillParticle
	PROFILE	FillParticle,d4
.pixelloop:
	move.l	d3,d5
	sub.l	d2,d3
	move.l	d3,d6
	asr.l	d1,d5
	move.l	d5,d0
	asr.l	d1,d5
	asr.l	d1,d6
	and.l	d0,d5
	move.l	d6,d0
	asr.l	d1,d6
	sub.l	a3,d2
	and.l	d0,d6
	sub.l	d2,d3
	sub.l	a3,d2
	move.w	63*2(a1,d5.l*2),d5
	swap.w	d5
	move.w	63*2(a1,d6.l*2),d5
	add.l	(a6),d5
	move.l	d5,d6
	and.l	#$80808080,d5
	lsr.l	#1,d5
	sub.l	d5,d6
	move.l	d6,(a6)+
	dbf	d4,.pixelloop
;	move.w	#$f00,$dff180
	PROFILE	AddParticles,#0

.nextparticle:
	tst.l	(a2)
	bne.w	.particleloop

	ifd	SHOWQUEUE
	move.l	b_VBlank(a4),d2
	move.l	b_Frame(a4),d3	; Ready frame
	move.l	d2,d6
	add.l	d6,d6
	addq.l	#1,d6
	divu.w	#5,d6
	ext.l	d6	; Frame to show if ready
	sub.l	d6,d3	; Queue depth
	muls.w	#12,d3
	move.l	#196,d0
	sub.l	d3,d0
	cmp.l	d0,d7
	blt.b	.nobar
	baselea	Chunky,a6
	move.l	#$3f3f3f3f,(SCREENWIDTH-8)*2(a6)
.nobar:
	endc

;	move.w	#$000,$dff180
	PROFILE	C2P
	move.l	d7,-(a7)
	move.l	b_EffectFrame(a4),a3
	lsl.l	#4,d7
	add.l	d7,a3
	move.l	#$ff00ff00,a1
	bsr.w	C2P
	move.l	#$00ff00ff,a1
	bsr.w	C2P
	move.l	(a7)+,d7
;	move.w	#$f00,$dff180

	addq.l	#1,d7
	cmp.w	#SCREENHEIGHT,d7
	blt.w	.lineloop

	rts


;Parabola:
;
;	add.l	d1,d0
;	add.l	d2,d1
;	move.l	d0,d3
;	bpl.b	.inside1
;	clr.l	d3
;.inside1:	swap.w	d3
;	muls.w	d3,d3
;	lsr.l	d6,d3
;	move.w	(a1,d3.l*2),d4
;
;	swap.w	d4
;
;	add.l	d1,d0
;	add.l	d2,d1
;	move.l	d0,d3
;	bpl.b	.inside2
;	clr.l	d3
;.inside2:	swap.w	d3
;	muls.w	d3,d3
;	lsr.l	d6,d3
;	move.w	(a1,d3.l*2),d4
;
;	add.l	(a0),d4
;	move.l	#$80808080,d3
;	and.l	d4,d3
;	lsr.l	#1,d3
;	sub.l	d3,d4
;	move.l	d4,(a0)+
;
;.outside:
;
;
;Gauss:
;	move.w	(a1,d0.l*2),d7
;	lsl.l	d5,d7
;
;	add.l	d3,d1
;	addx.l	d2,d0
;
;	move.w	(a1,d0.l*2),d7
;	
;	add.l	d3,d1
;	addx.l	d2,d0
;
;	add.l	(a0),d7
;	move.l	#$80808080,d6
;	and.l	d7,d6
;	lsr.l	#1,d6
;	sub.l	d6,d7
;	move.l	d7,(a0)+
;
;Gauss2:
;	move.l	(a1)+,d6
;	mulu.l	d5,d6
;	and.l	#$ff00ff00,d6
;
;	move.l	(a1)+,d7
;	mulu.l	d5,d7
;	and.l	#$ff00ff00,d7
;	
;	lsr.l	#8,d7
;	or.l	d6,d7
;
;	add.l	(a0),d7
;	move.l	#$80808080,d4
;	and.l	d7,d4
;	lsr.l	#1,d4
;	sub.l	d4,d7
;	move.l	d7,(a0)+
;
;Gauss2_pipelined:
;
;.loopl1:
;	add.l	(a0),d7
;	and.l	#$ff00ff00,d6
;
;	move.l	d7,d4
;	and.l	#$80808080,d7
;
;	lsr.l	#1,d7
;	lsr.l	#8,d6
;
;	sub.l	d7,d4
;	move.l	d5,d7
;
;	muls.l	(a1)+,d7
;	bpl.b	.loopl2
;
;	; Loop exit 2
;
;	bra.b	.continue
;
;.loopl2:
;	move.l	d4,(a0)+
;	and.l	#$ff00ff00,d7
;
;	or.l	d6,d7
;	move.l	d5,d6
;
;	muls.l	(a1)+,d6
;	bpl.b	.loopl1
;
;	; Loop exit 1
;
;.continue:


;RadialTable:
;	move.l	d0,d3
;	lsr.l	d6,d3
;	move.l	(a2,d3.l*4),d7
;	add.l	d1,d0
;	add.l	d2,d1
;
;	move.l	d0,d4
;	lsr.l	d6,d4
;	move.w	(a1,d4.l*2),d7
;	add.l	d1,d0
;	add.l	d2,d1
;
;	add.l	(a0),d7
;	move.l	d7,d5
;	and.l	#$80808080,d7
;	lsr.l	#1,d7
;	sub.l	d7,d5
;	move.l	d5,(a0)+
;
;RadialTable_pipelined:
;
;	add.l	d2,d1
;	move.l	d0,d3
;
;	lsr.l	d6,d3
;	move.w	(a1,d4.l*2),d7
;
;	add.l	(a0),d7
;	add.l	d1,d0
;
;	move.l	d7,d5
;	move.l	d0,d4
;
;	and.l	#$80808080,d7
;	add.l	d2,d1
;
;	lsr.l	d6,d4
;	lsr.l	#1,d7
;
;	sub.l	d7,d5
;	move.l	(a2,d3.l*4),d7
;
;	move.l	d5,(a0)+
;	add.l	d1,d0


	endc
