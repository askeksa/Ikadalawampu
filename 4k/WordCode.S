
	ifnd	WC_INCLUDED
; 1 = Compile
; 2 = Generate
; 4 = Test
; 8 = Validate
WC_INCLUDED	=	15
	endc

UAE_COMP	=	0

	if	WC_INCLUDED&4

Test:
	lea.l	TestCode(pc),a1
	lea.l	TestCode_End(pc),a2
	lea.l	WordCode(pc),a0
	bsr.w	GenerateWordCode

	lea.l	WordCode(pc),a0
	bsr.w	OptimizeWordCode

	lea.l	WordCode(pc),a0
	lea.l	Compiled(pc),a1
	lea.l	TestCode(pc),a3
	bra.w	CompileWordCode	

TestCode:
;	move.l	d0,d1
;	add.l	d3,d6
;	eor.b	d6,d7
;	swap.w	d2
;	addq.w	#2,d5
;	tst.l	d4
;	tst.w	d3
;	tst.b	d2
;	ori.w	#4,d7
;	move.l	d4,d3
;	move.l	#145,d4
;	move.l	#5364,d4
;
;	move.l	0*4(a1),d2
;	move.l	3*4(a4,d5.l*4),d6
;	move.l	7*4(a0),a1
;	move.l	2*4(a3,d4.l*4),a5
;	move.l	d2,0*4(a1)
;	move.l	d6,3*4(a4,d5.l*4)
;	move.l	a1,7*4(a0)
;	move.l	a5,2*4(a3,d4.l*4)
;
;	lea.l	1*4(a2),a3
;	lea.l	2*4(a3,d4.l*4),a5
;.dummy:
;	rts
;	bra.w	.dummy
;	bpl.w	.dummy
;	bmi.w	*+2
;	bmi.w	*+500
;	bsr.w	*+5000
;	rept	20
;	bsr.w	.dummy
;	endr
;	bsr.w	*+2
;	dbf	d4,.dummy

	fmove.s	fp1,(a2,d4.l*4)
	lea.l	-345(pc),a3

;	fmove.s	#9.05,fp0

	fmove.s	1*4(a2),fp0
	fmove.s	2*4(a3),fp1
	fmove.s	3*4(a4),fp2
	fmove.s	fp3,4*4(a5)
	fmove.s	fp4,5*4(a6)
	fmove.s	fp5,6*4(a7)
;	fmove.s	0*4(a1,d2.l*4),fp3
;	fmove.s	fp3,2*4(a1)
;	fmove.s	fp3,2*4(a1,d0.l*4)
;
;	fmove	fp0,fp3
;	fmul	fp3,fp7
;	fdiv	fp2,fp7
;	fsin	fp7,fp1
;
;	fmove.l	fp1,d1
;	fmove.w	fp1,d2
;	fmove.b	fp1,d3
;	fmove.s	fp1,d4
;	fmove.l	d1,fp2
;	fmove.w	d2,fp2
;	fmove.b	d3,fp2
;	fmove.s	d4,fp2

TestCode_End:

WordCode:
	dcb.w	1000
Compiled:
	dcb.w	1000

	endc

	if	WC_INCLUDED&4
a
	endc

	if	WC_INCLUDED&9
CompileWordCode:
	; A0 = WordCode
	; A1 = Compiled Code
	; (A3 = Original code for validation)
	move.l	a1,a2
.mainloop:
	movem.w	.masks(pc),d1-d7
	move.b	(a0),d7
	move.w	(a0)+,d0
	beq.b	.end
	and.w	d0,d1
	and.w	d0,d2
	and.w	d0,d3
	or.b	d3,d4
	lsr.w	#4,d7
	ror.w	#6,d4
	lsl.b	#3,d4
	lsr.w	#1,d3
	lsr.w	#1,d4
	move.w	d2,(a1)
	move.b	.jump_table(pc,d7.w),d6
	if	UAE_COMP
	move.w	d0,d5
	asl.w	#7,d5
	asr.w	#7,d5
	ext.l	d5
	else
	bfexts	d0{23:9},d5
	endc
	if	WC_INCLUDED&8
	move.l	a1,a4
	endc
	jsr	.jump_base(pc,d6.w*2)
	if	WC_INCLUDED&8
	bra.b	.val_in
.val_loop:
	cmpm.w	(a4)+,(a3)+
	beq.b	.val_in
	illegal
.val_in:
	cmp.l	a1,a4
	blo.b	.val_loop
	endc
	bra.b	.mainloop
.masks:
	dc.w	$0e00,$0007,$01f8,$0006

.jump_table:
	dc.b	(.integer-.jump_base)/2
	dc.b	(.loadstore-.jump_base)/2
	dc.b	(.loadstore-.jump_base)/2
	dc.b	(.loadstore-.jump_base)/2
	dc.b	(.loadstore-.jump_base)/2
	dc.b	(.loadstore-.jump_base)/2
	dc.b	(.branch-.jump_base)/2
	dc.b	(.bsr-.jump_base)/2
	dc.b	(.dbf-.jump_base)/2
	dc.b	(.lsf_offset-.jump_base)/2
	dc.b	(.lsf_indexed-.jump_base)/2
	dc.b	(.float-.jump_base)/2
	dc.b	(.immediate_9-.jump_base)/2
	dc.b	(.datalea-.jump_base)/2
	dc.b	(.shift-.jump_base)/2
	dc.b	(.floatdata_or_immediate_23_or_raw_or_multiplicity-.jump_base)/2

.jump_base:

.loadstore:
	bmi.b	.ls_indexed
	move.w	d3,d4
	addq.w	#5,d7
.ls_indexed:
	move.b	.ls_table-1(pc,d7.w),d6
	bfins	d6,d1{23:6}
	lsr.w	#6,d6
	ror.w	#3,d6
	or.w	d1,d6
	or.w	d6,(a1)+
.addr:	move.w	d4,(a1)+
.end:	rts
.ls_table:
	dc.b	%01000110,%01001110,%01110000,%01110001,%10111110
	dc.b	%01000101,%01001101,%01101000,%01101001,%10111101

;.rts:
;	move.w	#$4e75,(a1)+
;	rts

.branch:
;	beq.b	.rts
	move.w	d0,d2
	eor.b	d0,d2
	ext.w	d0
.boff:	add.w	d0,d0
	move.w	d2,(a1)+
.shift:
	move.w	d0,(a1)+
	rts

.lsf_offset:
	moveq.l	#$007c,d4
	and.w	d3,d4
.lsf_indexed:
	lsl.w	#8,d0
	addx.w	d1,d1
	lsl.w	#3,d7
	ror.w	#3,d1
	eor.w	#$f260,d7
	or.w	#$4400,d1
	or.w	d7,(a1)+
	move.w	d1,(a1)+
	bra.b	.addr

.integer:
	move.l	#$89bcd245,d4
	rol.l	d3,d4
	lsr.w	#5,d3
	lsl.w	#2,d3
	move.b	d3,d4
	lsl.w	#4,d4
	or.w	d1,d4
	or.w	d4,(a1)+
	rts

.byteload:
	or.w	#$1018,d1
	or.w	d1,(a1)+
	rts

.float:
	addq.l	#8,d5
	bcs.b	.byteload
	or.w	d3,d1
	lsl.w	#4,d1
	or.w	d2,d1
	ror.w	#6,d1
	move.w	#$f200,(a1)+
	move.w	d1,(a1)+
	rts

.datalea:
	or.w	#$41fa,d1
	move.w	d1,(a1)+
	or.w	#$fe00,d0
	bra.b	.rel

.dbf:
	or.w	#$51c8,d2
	asl.w	#4,d0
	asr.w	#7,d0
	bra.b	.boff

.bsr:
	move.w	#$6100,(a1)+
	lsl.w	#4,d0
	lsr.w	#3,d0
.rel:	add.w	a2,d0
	sub.w	a1,d0
	bra.b	.shift

.floatdata_or_immediate_23_or_raw_or_multiplicity:
	bpl.b	.floatdata_or_immediate_23
.raw_or_multiplicity:
	tst.b	d5
	bmi.b	.raw
.multiplicity:
	lsl.w	#2,d5
	lsr.b	#2,d5
	lsl.w	#3,d5
	lsr.b	#2,d5
	lsl.w	#3,d5
	lsr.b	#2,d5
	lsr.w	#5,d5
	move.w	(a0),d0
.multi_loop:
	sub.w	d5,d0
	move.w	d0,-(a0)
	dbf	d2,.multi_loop
	rts
.raw:
	move.w	(a0)+,(a1)+
	addq.b	#1,d5
	bne.b	.raw
	rts
.floatdata_or_immediate_23:
	tst.b	d5
	bpl.b	.immediate_23
.floatdata:
	lsl.w	#8,d3
	lsr.w	#2,d1
	or.w	d3,d1
	or.w	#$f200,(a1)+
	move.w	d1,(a1)+
	rts

.immediate_23:
	swap.w	d5
	move.w	(a0)+,d5
.immediate_9:
	or.w	#$203c,d1
	move.w	d1,(a1)+
	move.l	d5,(a1)+
	rts
	endc
	if	WC_INCLUDED&4
s
	endc

; Known bugs in the following:
; Branch and dbf to odd addresses
; Longword branch
; FPU-instruction-similar instruction data

	if	WC_INCLUDED&4
d
	endc
	if	WC_INCLUDED&2
GenerateWordCode:
	; A1 = 680x0 Code
	; A2 = End of 680x0 Code
	; A0 = Generated WordCode
	; A6 = Virtual start of 680x0 Code
.convloop:
	move.w	(a1)+,d1
	bfextu	d1{16:4},d5
	move.l	a0,d6
	jsr	([.jump1,pc,d5.w*4])
	subq.l	#2,d0
	bge.b	.convnext
.raw:
	addq.l	#2,a0
	move.l	a0,a4
	move.w	-2(a1),(a0)+
	moveq.l	#0,d7
	bra.b	.rawnext
.rawloop:
	; Check for overflow
	move.l	a5,d4
	sub.l	a4,d4
	cmp.l	#256,d4
	blt.b	.rawcont
	move.w	#$ff80,-(a4)
	bra.b	.convloop
.rawcont:
	move.w	(a1)+,d1
	bfextu	d1{16:4},d5
	move.l	a0,d6
	jsr	([.jump1,pc,d5.w*4])
	subq.l	#2,d0
	bgt.b	.rawend
	beq.b	.valid
	moveq.l	#0,d7
	bra.b	.copy
.valid:
	addq.l	#2,d7
.copy:
	sub.l	d0,a0
	move.w	-2(a1),-2(a0)
.rawnext:
	move.l	a0,a5
	cmp.l	a2,a1
	blo.b	.rawloop
	moveq.l	#0,d0
	addq.l	#2,a1
.rawend:
	sub.l	d7,a5
	sub.l	d7,a1
	subq.l	#2,a1
	move.l	a4,d4
	sub.l	a5,d4
	lsr.l	#1,d4
	move.w	#$ff00,d3
	move.b	d4,d3
	move.w	d3,-(a4)
	move.l	a5,a0
	bra.b	.convlend
.convnext:
	add.l	d0,a1
.convlend:
	cmp.l	a2,a1
	blo.b	.convloop
	clr.w	(a0)+
	rts

.fail:
	moveq.l	#0,d0
	rts

.jump1:
	dc.l	.fail
	dc.l	.move_byte
	dc.l	.immediate_or_move
	dc.l	.fail
	dc.l	.rts_or_lea
	dc.l	.dbf_or_int
	dc.l	.branch
	dc.l	.fail
	dc.l	.int
	dc.l	.int
	dc.l	.fail
	dc.l	.int
	dc.l	.int
	dc.l	.int
	dc.l	.shift
	dc.l	.float

.move_byte:
	; Test for move byte
	move.w	d1,d2
	and.w	#$f1f8,d2
	cmp.w	#$1018,d2
	bne.b	.fail
	; move.b (a0)+,dx
	and.w	#$0e07,d1
	or.w	#$b1f8,d1
	move.w	d1,(a0)+
	moveq.l	#2,d0
	rts

.rts_or_lea:
;	; Test for rts
;	cmp.w	#$4e75,d1
;	bne.b	.move_or_lea
;	move.w	#$6000,(a0)+
;	moveq.l	#2,d0
;	rts
	bra.b	.move_or_lea

.immediate_or_move:
	; Test for immediate
	move.w	d1,d2
	and.w	#$f1ff,d2
	cmp.w	#$203c,d2
	bne.b	.move_or_lea
	move.l	(a1),d3
	cmp.l	#1<<8,d3
	bge.b	.notsmall
	cmp.l	#-1<<8,d3
	blt.w	.fail
	; Small immediate
	eor.w	d2,d1
	or.w	#$c000,d1
	and.w	#$01ff,d3
	or.w	d3,d1
	move.w	d1,(a0)+
	moveq.l	#6,d0
	rts
.notsmall:
	cmp.l	#1<<23,d3
	bge.w	.fail
	; Large immediate
	eor.w	d2,d1
	or.w	#$f000,d1
	swap.w	d3
	and.w	#$007f,d3
	or.w	d3,d1
	move.w	d1,(a0)+
	swap.w	d3
	move.w	d3,(a0)+
	moveq.l	#6,d0
	rts

.move_or_lea:
	; PC rel lea?
	move.w	d1,d2
	and.w	#$f1ff,d2
	cmp.w	#$41fa,d2
	beq.w	.pc_rel_lea
	move.w	d1,d2
	lsl.l	#3,d2
	lsl.w	#4,d2
	lsr.l	#2,d2
	lsr.w	#8,d2
	lea.l	.loads_and_stores(pc),a3
	moveq.l	#2,d3
.iloop:	cmp.w	(a3)+,d2
	bne.b	.inext
	move.w	(a1),d4
	and.w	(a3)+,d4
	cmp.w	(a3)+,d4
	bne.w	.fail
	move.w	-4(a3),d4
	not.w	d4
	and.w	(a1),d4
	lsl.w	#1,d4
	lsr.w	#1,d3
	bcc.b	.ioffset
	lsr.b	#3,d4
	rol.w	#6,d4
	or.w	#$0100,d4
.ioffset:
	ror.w	#4,d3
	and.w	#$0e07,d1
	or.w	d3,d1
	or.w	d4,d1
	move.w	d1,(a0)+
	moveq.l	#4,d0
	rts
.inext:
	addq.l	#4,a3
	addq.w	#1,d3
	cmp.w	#12,d3
	blt.b	.iloop
	bra.w	.int

.loads_and_stores:
	dc.w	%01000101,%1111111110000011,%0000000000000000
	dc.w	%01000110,%1000111111110011,%0000110000000000
	dc.w	%01001101,%1111111110000011,%0000000000000000
	dc.w	%01001110,%1000111111110011,%0000110000000000
	dc.w	%01101000,%1111111110000011,%0000000000000000
	dc.w	%01110000,%1000111111110011,%0000110000000000
	dc.w	%01101001,%1111111110000011,%0000000000000000
	dc.w	%01110001,%1000111111110011,%0000110000000000
	dc.w	%10111101,%1111111110000011,%0000000000000000
	dc.w	%10111110,%1000111111110011,%0000110000000000

.pc_rel_lea:
	move.w	(a1),d3
	add.w	a1,d3
	sub.w	a6,d3
	move.w	d3,d2
	and.w	#$fe00,d2
	cmp.w	#$fe00,d2
	bne.w	.fail
	and.w	#$0e00,d1
	and.w	#$01ff,d3
	or.w	d3,d1
	or.w	#$d000,d1
	move.w	d1,(a0)+
	moveq.l	#4,d0
	rts

.dbf_or_int:
	bfextu	d1{20:9},d2
	cmp.w	#%000111001,d2
	bne.b	.int
	move.w	(a1),d3
	cmp.w	#512,d3
	bge.w	.fail
	cmp.w	#-512,d3
	blt.w	.fail
	asr.w	#1,d3
	and.w	#$0007,d1
	or.w	#$8000,d1
	bfins	d3,d1{20:9}
	move.w	d1,(a0)+
	moveq.l	#4,d0
	rts

.branch:
	tst.b	d1
	bne.w	.fail
	bfextu	d1{20:4},d2
	move.w	(a1),d3
	cmp.w	#1,d2
	beq.b	.bsr
	cmp.w	#256,d3
	bge.w	.fail
	cmp.w	#-256,d3
	blt.w	.fail
	asr.w	#1,d3
	bcs.w	.fail
	beq.w	.fail
	move.b	d3,d1
	move.w	d1,(a0)+
	moveq.l	#4,d0
	rts
.bsr:
	add.w	a1,d3
	sub.w	a6,d3
	cmp.w	#8192,d3
	bge.w	.fail
	lsl.w	#3,d3
	lsr.w	#4,d3
	bcs.w	.fail
	or.w	#$7000,d3
	move.w	d3,(a0)+
	moveq.l	#4,d0
	rts
.int:
	bftst	d1{26:3}
	bne.w	.fail
	and.w	#$0fff,d1
	or.w	.int_codes(pc,d5.w*2),d1
	tst.w	d1
	beq.w	.fail
	move.w	d1,(a0)+
	moveq.l	#2,d0
	rts
.int_codes:
	dc.w	0,0,0<<3,0,1<<3,2<<3,0,0,3<<3,4<<3,0,5<<3,6<<3,7<<3,0,0
.shift:
	move.w	d1,(a0)+
	moveq.l	#2,d0
	rts
.float:
	bfextu	d1{20:6},d2
	cmp.w	#%001000,d2
	bne.w	.fail
	move.w	(a1),d3
	btst.l	#6,d3
	bne.w	.fail
	btst.l	#15,d3
	bne.w	.fail
	bftst	d3{16:3}
	bne.b	.loadstore_or_conv
	bftst	d1{26:6}
	bne.w	.fail
	lsl.w	#1,d3
	lsl.b	#1,d3
	lsl.l	#5,d3
	lsr.w	#4,d3
	lsr.l	#3,d3
	rol.w	#3,d3
	or.w	#$b000,d3
	move.w	d3,(a0)+
	moveq.l	#4,d0
	rts
.loadstore_or_conv:
	bftst	d3{26:6}
	bne.w	.fail
	bftst	d1{26:3}
	bne.b	.loadstore
	lsl.l	#6,d3
	lsr.w	#7,d3
	lsr.l	#6,d3
	ror.w	#7,d3
	and.w	#$0007,d1
	or.w	d1,d3
	or.w	#$f000,d3
	move.w	d3,(a0)+
	moveq.l	#4,d0
	rts
.loadstore:
	move.w	d3,d2
	move.b	d1,d2
	lsr.w	#2,d2
	lsl.b	#4,d2
	lsr.w	#5,d2
	lea.l	.loads_and_stores2(pc),a3
	lsl.w	#2,d3
	move.b	d1,d3
	and.w	#$0e07,d3
	moveq.l	#0,d1
.floop:	cmp.w	(a3)+,d2
	bne.b	.fnext
	move.w	2(a1),d4
	and.w	(a3)+,d4
	cmp.w	(a3)+,d4
	bne.w	.fail
	move.w	-4(a3),d4
	not.w	d4
	and.w	2(a1),d4
	lsl.w	#1,d4
	move.w	#$9000,d5
	lsr.w	#1,d1
	bcc.b	.foffset
	lsr.b	#3,d4
	rol.w	#6,d4
	move.w	#$a000,d5
.foffset:
	lsl.w	#8,d1
	or.w	d3,d1
	or.w	d4,d1
	or.w	d5,d1
	move.w	d1,(a0)+
	moveq.l	#6,d0
	rts
.fnext:
	addq.l	#4,a3
	addq.w	#1,d1
	cmp.w	#4,d1
	blt.b	.floop
	bra.w	.fail

.loads_and_stores2:
	dc.w	%10001101,%1111111110000011,%0000000000000000
	dc.w	%10001110,%1000111111110011,%0000110000000000
	dc.w	%11001101,%1111111110000011,%0000000000000000
	dc.w	%11001110,%1000111111110011,%0000110000000000
	endc
	if	WC_INCLUDED&4
f
	endc

	if	WC_INCLUDED&2
OptimizeWordCode:
	; A0 = WordCode

	move.l	a0,a1
.mainloop:
	move.w	(a1)+,d0
	beq.b	.end

	move.w	(a1),d1
	sub.w	d0,d1
	move.w	#%1111110110110110,d2
	and.w	d1,d2
	bne.b	.not_multi

	moveq.l	#6,d3
.cloop:	move.w	2(a1),d4
	sub.w	(a1)+,d4
	cmp.w	d1,d4
	dbne	d3,.cloop
	bne.b	.not5
	addq.l	#2,a1
.not5:
	moveq.l	#6,d5
	sub.w	d3,d5
	bne.b	.morethan2
	move.w	#%1111110110110110,d2
	and.w	d4,d2
	bne.b	.morethan2
	move.w	2(a1),d3
	sub.w	(a1),d3
	cmp.w	d3,d4
	bne.b	.morethan2
	subq.l	#2,a1
	bra.b	.not_multi
.morethan2:
	lsl.w	#5,d1
	lsl.b	#2,d1
	lsr.w	#3,d1
	lsl.b	#2,d1
	lsr.w	#3,d1
	lsl.b	#2,d1
	lsr.w	#2,d1

	or.w	d5,d1
	or.w	#$ff00,d1
	move.w	d1,(a0)+
	move.w	-2(a1),(a0)+
	bra.b	.mainloop

.not_multi:
	move.w	d0,(a0)+
	move.w	d0,d1
	and.w	#$f180,d1
	cmp.w	#$f000,d1
	bne.b	.not_imm23
	move.w	(a1)+,(a0)+
	bra.b	.mainloop
.not_imm23:
	move.w	#%0000111011111111,d1
	or.w	d0,d1
	addq.w	#1,d1
	bne.b	.mainloop
	; Raw
.rloop:
	move.w	(a1)+,(a0)+
	addq.b	#1,d0
	bne.b	.rloop
	bra.b	.mainloop
.end:	move.w	d0,(a0)+
	rts

	endc

; 0000xxxooooooyyy	(integer ops)
; 0001xxx0zzzzzyyy	lod z,ay,dx	move.l	z*4(ay),dx
; 0001xxx1zziiiyyy	lid z,ay,di,dx	move.l	z*4(ay,di.l*4),dx
; 0010xxx0zzzzzyyy	loa z,ay,ax	move.l	z*4(ay),ax
; 0010xxx1zziiiyyy	lia z,ay,di,ax	move.l	z*4(ay,di.l*4),ax
; 0011xxx0zzzzzyyy	sod dy,z,ax	move.l	dy,z*4(ax)
; 0011xxx1zziiiyyy	sid dy,z,ax,di	move.l	dy,z*4(ax,di.l*4)
; 0100xxx0zzzzzyyy	soa ay,z,ax	move.l	ay,z*4(ax)
; 0100xxx1zziiiyyy	sia ay,z,ax,di	move.l	ay,z*4(ax,di.l*4)
; 0101xxx0zzzzzyyy	aoa z,ay,ax	lea.l	z*4(ay),ax
; 0101xxx1zziiiyyy	aia z,ay,di,ax	lea.l	z*4(ay,di.l*4),ax
; 0110xxx000000000	rts		rts
; 0110ccccszzzzzzz	bcc label	bcc.w	sz*2(pc)
; 0111zzzzzzzzzzzz	bsr label	bsr.w	Code+z*2
; 1000szzzzzzzzyyy	dbf dy,label	dbf	dy,sz*2(pc)
; 1001xxx0zzzzzyyy	lof z,ay,fpx	fmove.s	z*4(ay),fpx
; 1001xxx1zzzzzyyy	sof fpx,z,ay	fmove.s	fpx,z*4(ay)
; 1010xxx0zziiiyyy	lif z,ay,di,fpx	fmove.s	z*4(ay,di.l*4),fpx
; 1010xxx1zziiiyyy	sif fpx,z,ay,di	fmove.s	fpx,z*4(ay,di.l*4)
; 1011xxxooooooyyy	fop fpy,fpx	fop.x	fpy,fpx
; 1011xxx111111yyy	lbd ay,dx	move.b  (ay)+,dx
; 1100xxxszzzzzzzz	imm sz,dx	move.l	#sz,dx
; 1101xxxzzzzzzzzz	datalea z,dx	lea.l	Code-512+z(pc),ax
; 1110oooooooooooo	(shifts and rotates)
; 1111xxx00zzzzzzz 16z	imm zz,dx	move.l	#zz,dx
; 1111xxx010zzzyyy	i2f.z dy,fpx	fmove.z	dy,fpx
; 1111xxx011zzzyyy	f2i.z fpx,dy	fmove.z	fpx,dy
; 111111110xziymmm	(multiplicity)	m+2 delta-repetitions
; 111111111zzzzzzz	raw 128-z	128-z words of raw copying

;+-- load/store/address
;|+- offset/indexed
;||+ to data/address reg
;lod  0010ddr000101abr 000000000xxxxx00
;lid  0010ddr000110abr 0idr11000000xx00
;loa  0010dar001101abr 000000000xxxxx00
;lia  0010dar001110abr 0idr11000000xx00
;sod  0010abr101000sdr 000000000xxxxx00
;sid  0010abr110000sdr 0idr11000000xx00
;soa  0010abr101001sar 000000000xxxxx00
;sia  0010abr110001sar 0idr11000000xx00
;aoa  0100dar111101abr 000000000xxxxx00
;aia  0100dar111110abr 0idr11000000xx00

;lof  1111001000101abr 010001dfr0000000 000000000xxxxx00
;sof  1111001000101abr 011001dfr0000000 000000000xxxxx00
;lif  1111001000110abr 010001dfr0000000 0idr11000000xx00
;sif  1111001000110abr 011001dfr0000000 0idr11000000xx00

;fpu  1111001000000000 000sfrdfr0operat

;i2f  1111001000000sdr 010fmtdfr0000000
;f2i  1111001000000ddr 011fmtsfr0000000

;dbf  0101000111001cdr yyyyyyyyxxxxxxxx

; FPU operations
;move   000000
;int    000001
;sinh   000010
;intrz  000011
;sqrt   000100
;lognp1 000110
;etoxm1 001000
;tanh   001001
;atan   001010
;asin   001100
;atanh  001101
;sin    001110
;tan    001111
;etox   010000
;twotox 010001
;tentox 010010
;logn   010100
;log10  010101
;log2   010110
;abs    011000
;cosh   011001
;neg    011010
;acos   011100
;cos    011101
;getexp 011110-
;getman 011111-
;div    100000
;mod    100001
;add    100010
;mul    100011
;sgldiv 100100-
;rem    100101
;scale  100110-
;sglmul 100111-
;sub    101000
;sincos 110cfr-
;cmp    111000
;tst    111010

;move.b (Ax)+,Dy
;       0001yyy000011xxx

; Integer
;move.l 0010destea000sdr
;negx   01000000sz000ddr
;clr    01000010sz000ddr
;neg    01000100sz000ddr
;not    01000110sz000ddr
;nbcd.b 0100100000000ddr
;swap.w 0100100001000ddr
;ext.w  0100100010000ddr
;ext.l  0100100011000ddr
;extb.l 0100100111000ddr
;tst    01001010sz000ddr
;tas.b  0100101011000ddr
;addq   0101qid0sz000ddr
;subq   0101qid1sz000ddr
;scc.b  0101cccc11000ddr
;or     1000ddr0sz000sdr
;divu.w 1000ddr011000sdr
;sbcd.b 1000ddr100000sdr
;divs.w 1000ddr111000sdr
;sub    1001ddr0sz000sdr
;suba.w 1001dar011000sdr
;subx   1001ddr1sz000sdr
;suba.l 1001dar111000sdr
;cmp    1011ddr0sz000sdr
;cmpa.w 1011dar011000sdr
;eor    1011sdr1sz000ddr
;cmpa.l 1011dar111000sdr
;and    1100ddr0sz000sdr
;mulu.w 1100ddr011000sdr
;abcd.b 1100ddr100000sdr
;exg.l  1100sdr101000ddr
;muls.w 1100ddr111000sdr
;add    1101ddr0sz000sdr
;adda.w 1101dar011000sdr
;addx   1101ddr1sz000sdr
;adda.l 1101dar111000sdr

;asr    1110qid0sz000ddr
;lsr    1110qid0sz001ddr
;roxr   1110qid0sz010ddr
;ror    1110qid0sz011ddr
;asr    1110sdr0sz100ddr
;lsr    1110sdr0sz101ddr
;roxr   1110sdr0sz110ddr
;ror    1110sdr0sz111ddr
;asl    1110qid1sz000ddr
;lsl    1110qid1sz001ddr
;roxl   1110qid1sz010ddr
;rol    1110qid1sz011ddr
;asl    1110sdr1sz100ddr
;lsl    1110sdr1sz101ddr
;roxl   1110sdr1sz110ddr
;rol    1110sdr1sz111ddr
