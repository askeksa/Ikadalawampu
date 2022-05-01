;              T         T               T

	include	4k:System.S

	ONCE	Interpreter

	INCFILE

	ifeq	SYSTEM
	DATA
	include	4k:Music.S
	endc

	DATA

Bytecode:
	incbin	4k:tree.dat
;	dc.b	-3,0,-5,1,2,-10,-2,3,4,-4,5,5,-2,4,3,0
Bytecode_End:
	align	0,4
Constantpool:
	incbin	4k:constantpool.dat
;	dc.s	0.0,200.0,100.2,0.7,0.3,1.0
Constantpool_End:
;	dcb.s	256-(Constantpool_End-Constantpool)/4

	include	4k:Particles.S
	include	4k:Waves.S

MAX_MATRIX_STACK_HEIGHT = 1024
MAX_EXPRESSION_STACK_HEIGHT = 20

	FastField	MatrixStack,MAX_MATRIX_STACK_HEIGHT*6*4
	FastField	TreeLabels,256*4
	FastField	ExpressionStack,MAX_EXPRESSION_STACK_HEIGHT*4
	FastField	NotePosUnfold,MUSICLENGTH*NUMTRACKS*4

;	FastSpace	1024*1024
;	FastField	Stack,0

	Var	NumParticles

	PRECALC

UnfoldNotePositions:
	datalea	NotePositions,a2
	baselea	NotePosUnfold,a6
	move.l	#MUSICLENGTH,d1
	move.l	#NUMTRACKS-1,d7
.trackloop:	clr.l	d0
	fmove.l	d0,fp0
.loop:	bftst	(a2){d0:1}
	beq.b	.nonote
	fmove.l	d0,fp0
.nonote:	fmove.s	fp0,0(a6)
	lea.l	4(a6),a6
	addq.l	#1,d0
	cmp.l	d1,d0
	blt.w	.loop
	lea.l	MUSICLENGTH/8(a2),a2
	dbf	d7,.trackloop
	
;TestInterpreter:
;	pcall	InitFrame
;;	baselea	Stack,a7
;	pcall	Interpret


T_OFFSET	macro
	dc.w	(\1-.traverse_base)/2
	endm
O_OFFSET	macro
	dc.w	(\1-.op_base)/2
	endm

	PROFDEF	Traverse
	PROFDEF	GlobalDef
	PROFDEF	LocalDef
	PROFDEF	Conditional
	PROFDEF	Scale
	PROFDEF	Move
	PROFDEF	Rotate
	PROFDEF	Eval
	PROFDEF	EvalSubexp
	PROFDEF	EvalSinus
	PROFDEF	EvalRandom

	CODE

Interpret:
;	move.w	#$00f,$dff180
	baselea	MatrixStack,a5
	baselea	TreeLabels,a6

	datalea	Bytecode,a0
	move.l	#Bytecode_End-Bytecode-1,d7
.labelloop:	move.b	(a0)+,d0
	extb.l	d0
	addq.l	#1,d0
	bne.w	.notlabel
	move.l	a0,(a6)+
.notlabel:	dbf	d7,.labelloop

	move.l	#0,d0
	move.l	#1,d1
	move.l	#SCREENWIDTH/2,d2
	move.l	#SCREENHEIGHT/2,d3
	fmove.l	d0,fp0
	fmove.l	d1,fp1
	fmove.l	d2,fp2
	fmove.l	d3,fp3
	fmove.s	fp1,0(a5)
	fmove.s	fp0,4(a5)
	fmove.s	fp0,8(a5)
	fmove.s	fp1,12(a5)
	fmove.s	fp2,16(a5)
	fmove.s	fp3,20(a5)

	datalea	Bytecode,a0
	datalea	Constantpool,a1
Traverse:
	PROFILE	Traverse
	ASSERT	l,a1,eq,#Constantpool
	baselea	ExpressionStack,a2
	ASSERT	l,a0,hs,#Bytecode
	ASSERT	l,a0,lo,#Bytecode_End
	move.b	(a0)+,d0
	ASSERT	b,d0,hs,#$f4
	extb.l	d0
	bra.w	.traverse_lookup

;.localdef:
;	PROFILE	Eval
;	bsr.w	Eval
;	PROFILE	LocalDef
;	clr.l	d0
;	move.b	(a0)+,d0
;	move.l	(a1,d0.l*4),-(a7)
;	fmove.s	fp0,(a1,d0.l*4)
;	move.l	d0,-(a7)
;	bsr.w	Traverse
;	move.l	(a7)+,d0
;	move.l	(a7)+,(a1,d0.l*4)
;	rts

.fanout:
	bsr.w	Traverse
	tst.b	(a0)
	bne.b	.fanout
	move.b	(a0)+,d0
.nopleaf:	rts

.savetrans:
	ASSERT	l,a5,lo,#MatrixStack+(MAX_MATRIX_STACK_HEIGHT-1)*6*4
	rept	6
	move.l	(a5)+,(6-1)*4(a5)
	endr
	bsr.w	Traverse
	lea.l	-6*4(a5),a5
	rts

.repeat:
	clr.l	d0
	move.b	(a0)+,d0
	subq.b	#1,(a0)
	beq.b	.repeat_end
	move.l	a0,-(a7)
	baselea	TreeLabels,a6
	move.l	(a6,d0.l*4),a0
	bsr.w	Traverse
	move.l	(a7)+,a0
.repeat_end:
	addq.b	#1,(a0)+
	rts

.globaldef:
	PROFILE	Eval
	bsr.w	Eval
	PROFILE	GlobalDef
	clr.l	d0
	move.b	(a0)+,d0
	fmove.s	fp0,(a1,d0.l*4)
	bra.w	Traverse

;.call:
;	clr.l	d0
;	move.b	(a0)+,d0
;	fmove.s	(a1,d0.l*4),fp0
;	fmove.l	fp0,d0
;	move.l	a0,-(a7)
;	baselea	TreeLabels,a6
;	move.l	(a6,d0.l*4),a0
;	bsr.w	Traverse
;	move.l	(a7)+,a0
;	bra.w	Traverse

.conditional:
	PROFILE	Eval
	bsr.w	Eval
	PROFILE	Conditional
	clr.l	d0
	move.b	(a0)+,d0
	fmove.s	fp0,d1
	tst.l	d1
	bge.w	.cond_pos
	addq.l	#1,a0
	bra.b	.cond_chosen
.cond_pos:
	move.b	(a0)+,d0
.cond_chosen:
	move.l	a0,-(a7)
	baselea	TreeLabels,a6
	move.l	(a6,d0.l*4),a0
	bsr.w	Traverse
	move.l	(a7)+,a0
	rts

.scale:
	PROFILE	Eval
	bsr.w	Eval	; y
	PROFILE	Scale
	lea.l	2*4(a5),a6
	fmove.s	0(a6),fp2
	fmove.s	4(a6),fp3
	fmul	fp0,fp2
	fmul	fp0,fp3
	fmove.s	fp2,0(a6)
	fmove.s	fp3,4(a6)

	PROFILE	Eval
	bsr.w	Eval	; x
	PROFILE	Scale,#0
	lea.l	0*4(a5),a6
	fmove.s	0(a6),fp2
	fmove.s	4(a6),fp3
	fmul	fp0,fp2
	fmul	fp0,fp3
	fmove.s	fp2,0(a6)
	fmove.s	fp3,4(a6)

	bra.w	Traverse

.move:
	PROFILE	Eval
	bsr.w	Eval
	fmove	fp0,fp1
	PROFILE	Eval
	bsr.w	Eval

	PROFILE	Move
	lea.l	0*4(a5),a6
	fmove.s	0(a6),fp2
	fmove.s	8(a6),fp3
	fmove.s	16(a6),fp4
	fmul	fp0,fp2
	fmul	fp1,fp3
	fadd	fp3,fp2
	fadd	fp4,fp2
	fmove.s	fp2,16(a6)

	lea.l	1*4(a5),a6
	fmove.s	0(a6),fp2
	fmove.s	8(a6),fp3
	fmove.s	16(a6),fp4
	fmul	fp0,fp2
	fmul	fp1,fp3
	fadd	fp3,fp2
	fadd	fp4,fp2
	fmove.s	fp2,16(a6)
	bra.w	Traverse

.rotate:
	PROFILE	Eval
	bsr.w	Eval
	PROFILE	Rotate
	datalea	Constants,a6
	fmove.s	c_Wavelength(a6),fp1
	fmul	fp1,fp0
	fmove.l	fp0,d0
	baselea	SineWave,a6
	clr.l	d1
	move.w	d0,d1
	fmove.s	(a6,d1.l*4),fp0 ; sin
	add.w	#$4000,d1
	fmove.s	(a6,d1.l*4),fp1 ; cos

	lea.l	0*4(a5),a6
	fmove.s	0(a6),fp2
	fmove.s	8(a6),fp3
	fmove	fp2,fp4
	fmove	fp3,fp5
	fmul	fp1,fp2
	fmul	fp0,fp3
	fmul	fp0,fp4
	fmul	fp1,fp5
	fadd	fp3,fp2
	fsub	fp4,fp5
	fmove.s	fp2,0(a6)
	fmove.s	fp5,8(a6)

	lea.l	1*4(a5),a6
	fmove.s	0(a6),fp2
	fmove.s	8(a6),fp3
	fmove	fp2,fp4
	fmove	fp3,fp5
	fmul	fp1,fp2
	fmul	fp0,fp3
	fmul	fp0,fp4
	fmul	fp1,fp5
	fadd	fp3,fp2
	fsub	fp4,fp5
	fmove.s	fp2,0(a6)
	fmove.s	fp5,8(a6)
.label:	bra.w	Traverse

.draw:
	PROFILE	Eval
	bsr.w	Eval
	fmove	fp0,fp1
	PROFILE	Eval
	bsr.w	Eval
;	move.w	#$0f0,$dff180
	bsr.w	PutParticle
;	move.w	#$00f,$dff180
	addq.l	#1,b_NumParticles(a4)
	rts


;	T_OFFSET	.localdef
	T_OFFSET	.fanout
	T_OFFSET	.nopleaf
	T_OFFSET	.savetrans
	T_OFFSET	.repeat
	T_OFFSET	.conditional
	T_OFFSET	.globaldef
	T_OFFSET	.scale
	T_OFFSET	.move
	T_OFFSET	.rotate
	T_OFFSET	.draw
	T_OFFSET	.label
.traverse_lookup:
	move.w	.traverse_offsets(pc,d0.l*2),d0
	jmp	.traverse_base(pc,d0.l*2)
.traverse_offsets = .traverse_lookup
.traverse_base = .traverse_offsets+4

Eval:
	PROFILE	EvalSubexp
	ASSERT	l,a2,hs,#ExpressionStack
	ASSERT	l,a2,lo,#ExpressionStack+MAX_EXPRESSION_STACK_HEIGHT*4
	ASSERT	l,a0,lo,#Bytecode_End
	move.b	(a0)+,d0
	ASSERT	b,d0,ge,#$f6
	extb.l	d0
	bmi.w	.op
.load:
	fmove.s	fp0,0(a2)
	lea	4(a2),a2
	fmove.s	(a1,d0.l*4),fp0
	rts
.random:
	PROFILE	EvalRandom
	fmove.s	fp0,0(a2)
	lea	4(a2),a2
	move.l	4(a1),d0
	addq.l	#7,d0
	move.l	#16307,d1
	muls.l	d1,d0
	move.l	d0,4(a1)
	swap.w	d0
	fmove.w	d0,fp0
	datalea	Constants,a6
	fmove.s	c_2_wave(a6),fp2
	fmul	fp2,fp0
	PROFILE	Eval,#0
	rts
.noteat:
	bsr.w	Eval
	bsr.w	Eval
	fmove.s	-(a2),fp2
	; FP0 = Position
	; FP2 = Channel
;	move.l	#SPEED,d4
;	fmove.l	d4,fp4
;	fmul	fp4,fp0
	fintrz	fp0,fp3
	fmove.l	fp2,d2
	fmove.l	fp3,d3
	baselea	NotePosUnfold,a6
	move.l	#MUSICLENGTH,d1
	mulu.w	d1,d2
	add.l	d2,d3
	fmove.s	(a6,d3.l*4),fp2
	fsub	fp2,fp0
;	fdiv	fp4,fp0
	rts
.add:
	bsr.w	Eval
	bsr.w	Eval
	fmove.s	-(a2),fp2
	fadd	fp0,fp2
	fmove	fp2,fp0
	rts
.sub:
	bsr.w	Eval
	bsr.w	Eval
	fmove.s	-(a2),fp2
	fsub	fp0,fp2
	fmove	fp2,fp0
	rts
.mul:
	bsr.w	Eval
	bsr.w	Eval
	fmove.s	-(a2),fp2
	fmul	fp0,fp2
	fmove	fp2,fp0
	rts
;.div:
;	bsr.w	Eval
;	bsr.w	Eval
;	fmove.s	-(a2),fp2
;	fdiv	fp0,fp2
;	fmove	fp2,fp0
;	rts
;.mod:
;	bsr.w	Eval
;	bsr.w	Eval
;	fmove.s	-(a2),fp2
;	fdiv	fp0,fp2
;	fintrz	fp2
;	fmul	fp0,fp2
;	fmove.s	0(a2),fp0
;	fsub	fp2,fp0
;	rts
.round:
	bsr.w	Eval
	fint	fp0
	rts
.clamp:
	bsr.w	Eval
	fmove.s	fp0,d1
	tst.l	d1
	bge.w	.clamp_pos
	fsub	fp0,fp0
.clamp_pos:	rts
.sin:
	bsr.w	Eval
	PROFILE	EvalSinus
	datalea	Constants,a6
	fmove.s	c_Wavelength(a6),fp2
	fmul	fp2,fp0
	fmove.l	fp0,d0
	baselea	SineWave,a6
	clr.l	d1
	move.w	d0,d1
	fmove.s	(a6,d1.l*4),fp0
	PROFILE	Eval,#0
	rts

	O_OFFSET	.random
	O_OFFSET	.noteat
	O_OFFSET	.add
	O_OFFSET	.sub
	O_OFFSET	.mul
;	O_OFFSET	.div
;	O_OFFSET	.mod
	O_OFFSET	.round
	O_OFFSET	.clamp
	O_OFFSET	.sin
	dcb.w	1
.op:
	move.w	.op_offsets(pc,d0.l*2),d0
	jmp	.op_base(pc,d0.l*2)
.op_offsets = .op
.op_base = .op_offsets+4

	endc
