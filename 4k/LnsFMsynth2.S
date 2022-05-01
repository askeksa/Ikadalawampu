;              T         T               T

;	auto	j\wb data:instr2\InstrumentRender\InstrumentRender+d0*4\
;	auto	j\wb data:instr3\InstrumentRender\InstrumentRender+d0*2\
;	auto	j\wb data:instr4\SampleSpace\a5\

	include	4k:System.S

	ONCE	LnsFMsynth

	INCFILE

	include	4k:Constants.S
	include	4k:Waves.S

	ifeq	SYSTEM
	DATA
	include	4k:Music.S
	endc

MUSIC_OFFSET	=	50
CLIPPING	=	1

MAX_SAMPLES	=	100
FILTER_SIZE	=	24
FILTER_SHIFT	=	14
PERIOD	=	124
SAMPLES_PER_VBLANK =	573
COPY_PER_VBLANK =	572

MAX_INSTR_LENGTH =	LONGEST_INSTRUMENT*SPEED*SAMPLES_PER_VBLANK*4
SAMPLE_SPACE	=	LONGEST_TRACK_INSTRUMENT_BUFFER*SPEED*SAMPLES_PER_VBLANK*2
MUSIC_BUFFER_LENGTH =	MUSICLENGTH*SPEED*SAMPLES_PER_VBLANK
PLAY_BUFFER_LENGTH =	64*COPY_PER_VBLANK

	FastField	InstrumentRender,MAX_INSTR_LENGTH*4
	FastSpace	FILTER_SIZE*4
	FastField	InstrumentDest,MAX_INSTR_LENGTH*4
	FastSpace	FILTER_SIZE*4

	FastField	SampleSpace,SAMPLE_SPACE
	FastField	Samples,MAX_SAMPLES*2*4

	FastSpace	DELAY_LENGTH*2
	FastField	Music,MUSIC_BUFFER_LENGTH*2

	ChipField	PlayBuffer,PLAY_BUFFER_LENGTH

;	Var	Side
;	Var	ToneDelta

	PRECALC

MakeMusic:
	datalea	InstrumentData,a0
	datalea	NotePositions,a2
	datalea	NoteSamples,a3

	move.l	#NUM_EFFECT_TRACKS-1,d7
	pcall	MixTracks

	baselea	Music,a6
	move.l	#MUSIC_BUFFER_LENGTH,d7
.delayloop:
	move.w	-DELAY_LENGTH*2(a6),d1
	muls.w	#DELAY_STRENGTH,d1
	asr.l	#8,d1
	add.w	d1,(a6)+

	if	CLIPPING
	bvc.b	.ok1
	smi.b	d1
	ext.w	d1
	move.w	d1,-(a6)
	eor.w	#$8000,(a6)+
.ok1:
	endc

	subq.l	#1,d7
	bgt.b	.delayloop

	move.l	#NUMTRACKS-NUM_EFFECT_TRACKS-1,d7
	pcall	MixTracks

;	; Test
;	datalea	TestInstr,a0
;	baselea	InstrumentSpace,a5
;	pcall	MakeSample
;
;	baselea	InstrumentRender,a1
;	clr.l	d7
;.fliploop:	move.l	(a1),d1
;	ror.w	#8,d1
;	swap.w	d1
;	ror.w	#8,d1
;	move.l	d1,(a1)+
;	addq.l	#1,d7
;	cmp.l	d0,d7
;	blt.b	.fliploop

;	rts



;	DATA
;
;TestInstr:
;	dc.b	60,24,0,5,0
;	dc.b	42,10,0,0,100,6
;	dc.b	1,1,25,20
;	dc.b	120
;	dc.b	50,30,30,30
;	dc.b	20


	rsreset
;s_return	rs.l	1
s_detune1	rs.l	1
s_detune2	rs.l	1
s_indexspr	rs.l	1

s_pitchd1	rs.l	1
s_pitchd2	rs.l	1
s_pitchs1	rs.l	1
s_pitchs2	rs.l	1
s_note	rs.l	1

; Instrument format:
; (note)
; pitch s 2
; pitch s 1
; pitch d 2
; pitch d 1
; randomseed
; layers
; index spr
; detune 2
; detune 1
; index base
; wave1
; wave2
; release length
; (length)
; volume
; sustain
; attack
; decay
; release
; gain


	CODE

StartMusic macro
	bset.b	#1,$bfe001

	lea.l	$dff0a0,a2
	baselea	PlayBuffer,a5
;	move.l	#PLAY_BUFFER_LENGTH,d3
	rept	4
;	moveq.l	#4-1,d7
;.loop:
	move.l	a5,(a2)+
	move.l	#((PLAY_BUFFER_LENGTH/2)<<16)|PERIOD,(a2)+
	move.w	#64,(a2)+
	addq.l	#6,a2
;	add.l	d3,a5
;	dbf	d7,.loop
	endr
	move.w	#$800f,$096-($0a0+4*$010)(a2)
;	rts
	endm

MusicInterrupt macro
MI:
	baselea	PlayBuffer,a5
	baselea	Music,a6
	move.l	b_VBlank(a4),d0
	move.l	#MUSIC_OFFSET,d2
	move.l	#63,d3
	move.l	#COPY_PER_VBLANK/4,d4
	add.l	d2,d0
	move.l	d0,d1
	add.l	d2,d0
	and.l	d3,d0
	mulu.w	d4,d0
	mulu.w	d4,d1
	lea.l	(a5,d0.l*4),a5
	lea.l	(a6,d1.l*4),a6
	lea.l	(a6,d1.l*4),a6

;	move.l	#4-1,d7
;.channelloop:
;	move.l	#64,d2
;	mulu.w	d7,d2

;	lea.l	0(a6),a0
	move.l	#COPY_PER_VBLANK/4-1,d6
.loop:
	move.w	(a6)+,d0
;	add.w	d2,d0
	asr.w	#8,d0
	move.b	d0,d3

	lsl.l	#8,d3

	move.w	(a6)+,d0
;	add.w	d2,d0
	asr.w	#8,d0
	move.b	d0,d3

	lsl.l	#8,d3

	move.w	(a6)+,d0
;	add.w	d2,d0
	asr.w	#8,d0
	move.b	d0,d3

	lsl.l	#8,d3

	move.w	(a6)+,d0
;	add.w	d2,d0
	asr.w	#8,d0
	move.b	d0,d3

	move.l	d3,(a5)+
	dbf	d6,.loop

;	add.l	#PLAY_BUFFER_LENGTH-COPY_PER_VBLANK,a5
;	dbf	d7,.channelloop
;	rts
	endm

MixTracks:
	; A0 = instrument data
	; A2 = note positions
	; A3 = note samples
	; D7 = num tracks -1

.trackloop:
	clr.l	d0
	clr.l	d1
	move.b	(a0)+,d0	; Number of samples for track -1
	lea.l	20(a0),a1
	baselea	SampleSpace,a5
	baselea	Samples,a6
	clr.b	-(a0)
	move.l	a5,(a6)+
.sampleloop:
	move.b	(a1)+,d1	; Tone delta
	add.b	d1,(a0)
	move.b	(a1)+,14(a0)	; Length
	movem.l	d0-d2/d7/a0-a3/a6,-(a7)
	bsr.w	MakeSample
	movem.l	(a7)+,d0-d2/d7/a0-a3/a6
	move.l	a5,(a6)+
	dbf	d0,.sampleloop

	ext.l	d0	; Position = -1
.noteloop:
	clr.l	d1
	clr.l	d2
	move.b	(a3)+,d1	; Sample
	bmi.w	.trackdone
.nextpos:	addq.l	#1,d0
	bftst	(a2){d0:1}
	beq.b	.nextpos

;	cmp.l	#MUSICLENGTH,d0
;	blt.b	.posok
;	illegal
;.posok:

	move.l	#SPEED*SAMPLES_PER_VBLANK,d3
	mulu.w	d0,d3
	baselea	Samples,a5
	baselea	Music,a6
	move.l	0(a5,d1.l*4),a0
	move.l	4(a5,d1.l*4),d5
	lea.l	(a6,d3.l*2),a6
	sub.l	a0,d5
.mixloop:
	move.w	(a0)+,d1
	add.w	d1,(a6)+

	if	CLIPPING
	bvc.b	.ok1
	smi.b	d1
	ext.w	d1
	move.w	d1,-(a6)
	eor.w	#$8000,(a6)+
.ok1:
	endc

	subq.l	#2,d5
	bgt.b	.mixloop

	bra.b	.noteloop
.trackdone:
	move.l	a1,a0
	lea.l	MUSICLENGTH/8(a2),a2
	dbf	d7,.trackloop
	rts

MakeSample:
	lea.l	-8*4(a7),a7
	datalea	Constants,a6

	move.l	#5-1,d7
.exploop:
	fmove.s	12(a6,d7.l*4),fp1
	move.b	(a0)+,d0
	fmove.b	d0,fp0
	fmul	fp1,fp0
	ftwotox	fp0
	fmove.s	fp0,12(a7,d7.l*4)
	dbf	d7,.exploop

	tst.l	d1
	bne.w	.firsttone

	lea.l	8(a0),a0

	move.l	#SPEED*SAMPLES_PER_VBLANK*4,d1
	clr.l	d6
	clr.l	d7
	move.b	(a0)+,d6
	move.b	(a0)+,d7
	add.l	d7,d6
	mulu.w	d1,d6	; Length including release
	mulu.w	d1,d7	; Length excluding release

	bra.w	.sametone
.firsttone:
	move.b	(a0)+,d0
	extb.l	d0
	move.l	#16307,d5
;	move.l	#31333,d6
	mulu.w	d0,d5
;	add.l	d6,d5	; random

	baselea	InstrumentRender,a1
	move.l	#MAX_INSTR_LENGTH,d7
.clearloop:	clr.l	(a1)+
	subq.l	#1,d7
	bgt.b	.clearloop

	clr.l	d4
	move.b	(a0)+,d4	; Layers-1
.layerloop:
	datalea	Constants,a6
	move.l	#3-1,d7
.sprloop:
	fmove.s	(a6,d7.l*4),fp1
	move.b	(a0)+,d0	; IndexSpr, M Detune, B Detune
	fmove.b	d0,fp0
	fmul	fp1,fp0
	fmove.w	d5,fp1
	ror.l	d5,d5
	subq.l	#1,d5
	fmul	fp1,fp0
	fmove.s	fp0,(a7,d7.l*4)
	dbf	d7,.sprloop

	fmove.s	s_note(a7),fp0
	fmove.s	c_BaseNote(a6),fp1
	fmul	fp0,fp1	; NoteFreq
	fmove.s	s_detune1(a7),fp4
	fmove.s	s_detune2(a7),fp5
	fmove.s	s_indexspr(a7),fp6
	fadd	fp1,fp4	; freq1
	fadd	fp1,fp5	; freq2

	fmove.s	c_IndexFac(a6),fp1
	move.b	(a0)+,d0	; Index
	fmove.b	d0,fp0
	fmul	fp1,fp0	; index base
	fadd	fp0,fp6	; layer index

	fmove.s	fp4,s_detune1(a7)
	fmove.s	fp5,s_detune2(a7)
	fmove.s	fp6,s_indexspr(a7)

	baselea	SquareWave,a1
	clr.l	d0
	move.b	(a0)+,d0
	swap.w	d0
	lea.l	(a1,d0.l*4),a2	; wave1
	clr.l	d0
	move.b	(a0)+,d0
	swap.w	d0
	lea.l	(a1,d0.l*4),a3	; wave2

	baselea	InstrumentRender,a1
	move.l	#SPEED*SAMPLES_PER_VBLANK*4,d1
	clr.l	d6
	clr.l	d7
	move.b	(a0)+,d6
	move.b	(a0)+,d7
	add.l	d7,d6
	mulu.w	d1,d6	; Length including release
	mulu.w	d1,d7	; Length excluding release

	clr.l	d1
	fmove.l	d1,fp2	; phase1
	fmove.l	d1,fp3	; phase2
	fmove.s	s_pitchs1(a7),fp0
	fmove.s	s_pitchs2(a7),fp1
	move.l	#WAVELENGTH-1,d3
	; D1 = sample
.sampleloop:
	fmove.s	s_detune1(a7),fp4	; freq1
	fmove.s	s_detune2(a7),fp5	; freq2
	fmove.s	s_indexspr(a7),fp6	; index
	fmul	fp0,fp4
	fmul	fp1,fp5

	fmove.l	fp3,d2
	and.l	d3,d2
	fadd	fp5,fp3
	fmove.s	(a3,d2.l*4),fp7
	fmul	fp6,fp7
	fadd	fp2,fp7
	fmove.l	fp7,d2
	and.l	d3,d2
	fadd	fp4,fp2
	fmove.s	(a1,d1.l*4),fp6
	fmove.s	(a2,d2.l*4),fp7
	fadd	fp7,fp6
	fmove.s	fp6,(a1,d1.l*4)

	addq.l	#1,d1

	; Test for pitch slide
	tst.w	-12(a0)
	beq.b	.noslide

	; update phases and pitches...
	fmove.s	c_FloatOne(a6),fp7
	fmove.s	s_pitchd1(a7),fp4
	fmove.s	s_pitchd2(a7),fp5
	fsub	fp7,fp0
	fsub	fp7,fp1
	fmul	fp4,fp0
	fmul	fp5,fp1
	fadd	fp7,fp0
	fadd	fp7,fp1
.noslide:
	cmp.l	d6,d1
	blt.w	.sampleloop

	subq.l	#8,a0
.llend:	dbf	d4,.layerloop
	addq.l	#8,a0

.sametone:
	; Factor in fixed-point scaling and number of layers
	move.b	-9(a0),d0	; Layers-1
	addq.b	#1,d0
	move.b	(a0)+,d1	; Volume
	fmove.b	d0,fp0
	fmove.b	d1,fp1
	fmove.s	c_IndexFac(a6),fp6
	fmul	fp1,fp6
	fmove.s	fp6,s_indexspr(a7)	; really for a different purpose, but...
	fdiv	fp6,fp0

	; ADSR envelope

	move.b	(a0)+,d0	; Sustain
	move.b	(a0)+,d1	; Attack
	move.b	(a0)+,d2	; Decay
	move.b	(a0)+,d3	; Release
	move.b	(a0)+,d4	; Gain
	extb.l	d0
	extb.l	d1
	extb.l	d2
	extb.l	d3
	extb.l	d4
	lsl.l	#7,d1
	lsl.l	#7,d2
	lsl.l	#7,d3
	lsl.l	#7,d4
	lsl.l	#4,d2
	lsl.l	#4,d3
	fmove.l	d0,fp3	; sustain
	fmove.l	d1,fp4	; attack
	fmove.l	d2,fp5	; decay
	fmove.l	d3,fp6	; release
	fmove.l	d4,fp7	; distgain
	fmove.s	c_FloatOne(a6),fp1
	fmove.s	c_SustainFac(a6),fp2
	fmul	fp2,fp3
	fmove	fp3,fp2
	fsub	fp1,fp2
	fneg	fp3
	fmul	fp0,fp4
	fmul	fp0,fp5
	fmul	fp0,fp6
	fdiv	fp4,fp1	; attack slope
	fdiv	fp5,fp2	; decay slope
	fdiv	fp6,fp3	; release slope

	fmove.s	fp3,d6
	fsub	fp3,fp3	; sustain slope
	move.l	d3,d4
	move.l	d7,d3
	sub.l	d1,d3
	sub.l	d2,d3	; sustain length
	add.l	d4,d7	; total length
	lsr.l	#2,d7
	addq.l	#FILTER_SIZE/4,d7

	; distgain coefficients
	fmove.s	c_Wavelength(a6),fp5	; 1/(amplitude/(gain factor))²
	fmove.s	s_indexspr(a7),fp6	; volume factor
	fmul	fp6,fp6
	fmul	fp7,fp7
	fmul	fp6,fp5
	fdiv	fp7,fp5
	fadd	fp5,fp6
	fsqrt	fp6

	baselea	InstrumentRender,a1
	baselea	InstrumentDest,a2
	clr.l	d0	; sample
	fmove.l	d0,fp0	; volume
.adsrloop:
	fmove.s	(a1,d0.l*4),fp7
	fmul	fp0,fp7

;	cmp.b	#1,-1(a0)
;	beq.b	.nodistgain
;	bra.b	.nodistgain
	fmove	fp7,fp4
	fmul	fp6,fp7
	fmul	fp4,fp4
	fadd	fp5,fp4
	fsqrt	fp4
	fdiv	fp4,fp7
.nodistgain:
	fmove.l	fp7,(a2)+

	fadd	fp1,fp0
	addq.l	#1,d0

	subq.l	#1,d1
	bgt.w	.adsrloop

	; Next section
	fmove	fp2,fp1
	fmove	fp3,fp2
	fmove.s	d6,fp3
	move.l	d2,d1
	move.l	d3,d2
	move.l	d4,d3
	clr.l	d4
	tst.l	d1
	bne.w	.adsrloop

	rept	FILTER_SIZE
	clr.l	(a2)+
	endr

	baselea	InstrumentDest,a2
	lea.l	-FILTER_SIZE/2*4(a2),a2
.resampleloop:
	move.l	a2,a1
	move.l	a2,a3
	datalea	ResampleFilter,a6
	clr.l	d3
	move.l	#FILTER_SIZE/2-1,d6
.filterloop:
	move.b	(a6)+,d1
	extb.l	d1
	move.l	d1,d2
	muls.l	-(a1),d1
	muls.l	(a3)+,d2
	add.l	d1,d3
	add.l	d2,d3
	dbf	d6,.filterloop

	asr.l	#(FILTER_SHIFT-1)/2,d3
	asr.l	#FILTER_SHIFT/2,d3
	lea.l	4*4(a2),a2

	fmove.l	d3,fp0
	fmove.w	fp0,(a5)+
	subq.l	#1,d7
	bgt.b	.resampleloop

	lea.l	-15(a0),a0

	lea.l	8*4(a7),a7
	rts

	DATA

ResampleFilter:
	dc.b	126,116,98,51,30,14,3,-2,-4,-4,-2,-1
	dc.b	1

	endc
