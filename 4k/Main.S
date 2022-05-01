;                 T         T                         T

PERFCOUNT	=	0
PREWAIT	=	10
DEBUG	=	0
FPUINT	=	0
;RMBPAUSE	=	1
ASSERTED	=	0
;PROFILING	=	0
;SHOWQUEUE

MUSIC	=	1

DEMOSTART	=	0*64*5
DEMOLENGTH	=	11776

	include	4k:System.S

; Main 4k system control macro
;
; First argument is the base name for temporary files.
; Second argument is the build mode:
;  0: Test. Use when testing the intro inside AsmPro. Assemble and run.
;  1: Build. Converts the code to an internal instruction format (wordcode) and
;     writes temporary files containing the converted code. Assemble and run.
;  2: Deploy. Ignores the source code and just includes the converted wordcode
;     to produce an executable. Assemble and write object.
;     Sometimes fails with an "Illegal path" error message. Just assemble again.
;
; The resulting executable must have its three fast memory sections merged to
; work properly. This can be done with the --hunkmerge option to Shrinkler.
	BEGIN4k	ram:wordcode,0

	DATA
	include	4k:Music.S

	include	4k:Interpreter.S
	include	4k:C2P1x1x8Half.S

	include	4k:Screen8bit.S
	if	MUSIC
	include	4k:LnsFMsynth2.S
	else
MUSIC_OFFSET	=	50
	endc

	DATA

PalColors:
	dc.w	$000,$000,$000,$000
	dc.w	$fff,$fff,$fff,$fff
	dc.w	$000,$458,$c72,$ccc
	dc.w	$000,$12d,$191,$fff

	PROFDEF	InitFrame
	PROFDEF	Interpret
	PROFDEF	Palette
	PROFDEF	RenderParticles

	CODE

Main:
	ScreenSetup
	if	MUSIC
	StartMusic
	endc
;	if	DEMOSTART>0
	move.l	#DEMOSTART-MUSIC_OFFSET,d0
	move.l	d0,b_VBlank(a4)
;	endc

MainLoop:
	move.l	b_VBlank(a4),d2
	move.l	b_Frame(a4),d3
	addq.l	#1,d3
	move.l	d2,d6
	add.l	d6,d6
	addq.l	#1,d6
	moveq.l	#2,d4
	moveq.l	#SCREEN_BUFFERS,d5
	divu.w	#5,d6
	ext.l	d6	; Currently showing
	cmp.l	d6,d3
	bge.w	.notbehind
	move.l	d6,d3
.notbehind:
	add.l	d5,d6
	cmp.l	d6,d3
	bge.w	MainLoop
	move.l	d3,b_EffectFrame(a4)

	fmove.l	d3,fp0
	fmove.l	d4,fp1
	fdiv	fp1,fp0
	datalea	Constantpool,a1
	fmove.s	fp0,0*4(a1)

	cmp.w	#DEMOLENGTH,d2
	bge.w	DemoDone

	PROFILE	InitFrame
	bsr.w	InitFrame
	PROFILE	Interpret
	bsr.w	Interpret

	PROFILE	Palette
	datalea	Constantpool,a1
	datalea	Constants,a6
	fmove.s	4*4(a1),fp0
	fmove.s	5*4(a1),fp1
	fmove.s	6*4(a1),fp2
	fmove.s	c_ToFixFac(a6),fp7
	fmul	fp7,fp2
	fmove.l	fp0,d0
	fmove.l	fp1,d1
	fmove.l	fp2,d2
	baselea	Palettes,a5
	move.l	b_EffectFrame(a4),d3
	move.l	#SCREEN_BUFFERS-1,d5
	and.l	d5,d3
	swap.w	d3
	add.l	d3,a5
	MakePalette

	PROFILE	RenderParticles
	baselea	Screen,a5
	move.l	b_EffectFrame(a4),d3
	move.l	#SCREEN_BUFFERS-1,d5
	and.l	d5,d3
	swap.w	d3
	add.l	d3,a5
	bsr.w	RenderParticles
	NOPROFILE

	move.l	b_EffectFrame(a4),d3
	move.l	d3,b_Frame(a4)

	if	DEBUG
	btst.b	#6,$bfe001
	bne.b	MainLoop
	rts
	else
	bra.w	MainLoop
	endc

Interrupt:
	ScreenInterrupt
	if	MUSIC
	MusicInterrupt
	endc
DemoDone:	rts

	END4k


; 750000 clear + c2p
;    500 per particle
;    100 per particle line
;     10 per particle pixel
;     40 per node
;     40 per subexp

; EffectVBlank: frame being rendered
; VBlank: Current vblank
;
; In vblank int:
; FrameVBlank = Round VBlank down to frame
; while FrameVBlank >= EffectVBlank
;    FrameVBlank = previous frame
; show FrameVBlank
;
; In mainloop:
; render EffectVBlank
; EffectVBlank = next frame
; loop while (frame to be rendered) - (frame being displayed) >= frame space in queue
; while (frame to be rendered) < (frame being displayed)
;    EffectVBlank = next frame
