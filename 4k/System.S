;              T         T               T

; Memory layout
; ----------------
; System
;  Init code
;  Compressed code
; Base struct
;  Chip
;  Fast
; Data
; PreCalc
; Code
; Fast

;; ********** Once-trick **********

	ifnd	ONCE
ONCE	macro
	ifnd	\1_FLAG
\1_FLAG	set	1
\1\@	set	1
FLAG	set	1
	else
	ifd	\1\@
FLAG	set	1
	else
FLAG	set	0
	endc
	endc
	if	FLAG
	endm
	endc

	ONCE	System

;; ********** Internal constants **********

MEMORY_UNITlog	=	7
MEMORY_UNIT	=	1<<MEMORY_UNITlog

;; ********** System constants **********

SU_Supervisor = -30
SU_OldOpenLibrary = -408
SU_CloseLibrary = -414
SU_CacheClearU = -636
SU_TaggedOpenLibrary = -810
SU_LoadView = -222
SU_WaitTOF = -270
SU_gb_ActiView = $22
SU_gb_copinit = $26
SU_Open = -30
SU_Close = -36
SU_Write = -48
SU_OpenFont = -72
SU_OLTAG_GRAPHICS = 1
SU_MODE_NEWFILE = 1006
SU_tf_CharData = 34

;; ********** Memory macros **********

COUNT_Var	set	0
COUNT_Chip	set	0
COUNT_Fast	set	0
COUNT_Total	set	0
LAST_Chip	set	0
LAST_Fast	set	32*4/MEMORY_UNIT

_inctotal	macro
COUNT_Total	set	COUNT_Total+1
	if	(COUNT_Total>32)
	fail
	endc
	endm

Var	macro	; Name
a_\1	=	COUNT_Var
b_\1	=	a_\1*4
COUNT_Var	set	COUNT_Var+1
	_inctotal
	endm

Field	macro	; Mem,Name,Size
a_\2	=	COUNT_\1
b_\2	set	(a_\2)*4
COUNT_\1	set	COUNT_\1+1
\2:	ds.b	((\3)+MEMORY_UNIT-1)/MEMORY_UNIT*MEMORY_UNIT
	section	Base\1,data_f
	if	(LAST_\1>$ffff)
	printt	"Memory segment too large"
	printv	LAST_\1*MEMORY_UNIT
;	fail
	else
	dc.w	LAST_\1
	endc
LAST_\1	set	((\3)+MEMORY_UNIT-1)/MEMORY_UNIT
	ifd	Before_\1
b_\2	set	(Before_\1+a_\2)*4
	endc
	_inctotal
	endm

ChipField	macro	; Name,Size
	section	Chip,bss_c
	Field	Chip,\1,\2
	endm

FastField	macro	; Name,Size
	section	Fast,bss_f
	Field	Fast,\1,\2
	endm

Space	macro	; Mem,Size
	ds.b	((\2)+MEMORY_UNIT-1)/MEMORY_UNIT*MEMORY_UNIT
LAST_\1	set	LAST_\1+((\2)+MEMORY_UNIT-1)/MEMORY_UNIT
	endm

ChipSpace	macro	; Size
	section	Chip,bss_c
	Space	Chip,\1
	endm

FastSpace	macro	; Size
	section	Fast,bss_f
	Space	Fast,\1
	endm

;; ********** Utility macros **********

INCFILE	macro
	ifnd	MODE
INCFILE\@	set	1
MODE	=	0
SYSTEM	=	0
PERFCOUNT	=	0
ASSERTED	=	1
PROFILING	=	0
b_VBlank	=	0
b_Frame	=	4
b_EffectFrame	=	8
;b_TopazCharData=	8
	endc
	ifd	INCFILE\@
	section	PreCalc,code_f
IncfilePrecalcPrologue:
	; Setup mem pointers
	lea.l	Fast,a4
	lea.l	Chip,a5
	section	System,code_f
System:
Break:
	rts
	section	Fast,bss_f
Fast:
	ds.l	32
End:
	section	Chip,bss_c
Chip:
	endc
	endm

DATA	macro
	section	Data,data_f
	endm

PRECALC	macro
	section	PreCalc,code_f
PRECALC_FLAG	set	1
	endm

CODE	macro
	section	Code,code_f
PRECALC_FLAG	set	0
	endm

baselea	macro
	if	SYSTEM
	move.l	b_\1(a4),\2
	else
	lea.l	\1,\2
	endc
	endm

datalea	macro
	if	(MODE=0)
	lea.l	\1,\2
	else	;(MODE=1)
	ifd	Data_End
	ifd	\1
	if	(Data_End-\1)>512
	printt	"Far data: \1"
	endc
	endc
	endc
	if	PRECALC_FLAG
	lea.l	PreCalc+(\1-Data_End)(pc),\2
	else
	lea.l	Code+(PreCalc-PreCalc_End)+(\1-Data_End)(pc),\2
	endc
	endc
	endm

fastlea	macro
	if	(MODE=0)
	lea.l	\1,\2
	else	;(MODE=1)
	if	PRECALC_FLAG
	lea.l	PreCalc_End+(Code_End-Code)+(\1-Fast)(pc),\2
	else
	lea.l	Code_End+(\1-Fast)(pc),\2
	endc
	endc
	endm

codelea	macro
	if	(MODE=0)
	lea.l	\1,\2
	else	;(MODE=1)
	if	PRECALC_FLAG
	lea.l	PreCalc_End+(\1-Code)(pc),\2
	else
	lea.l	\1(pc),\2
	endc
	endc
	endm

pcall	macro
	if	(MODE=0)
	jsr	\1
	else	;(MODE=1)
	if	PRECALC_FLAG
	bsr.w	PreCalc_End+(\1-Code)
	else
	bsr.w	\1
	endc
	endc
	endm

TIMERINIT	macro
	if	DEBUG
	move.l	b_VBlank(a4),d2
	if	(\2)>0
	addq.l	#(\2),d2
	endc
	move.l	d2,b_EffectVBlank(a4)
	if	(\1)>0
	addq.l	#(\1),b_VBlank(a4)
	endc
	else
	if	(\1)=0
	move.l	b_VBlank(a4),d2
	if	(\2)>0
	addq.l	#(\2),d2
	endc
	move.l	d2,b_EffectVBlank(a4)
	else
.wait:	move.l	b_VBlank(a4),d2
	move.l	b_EffectVBlank(a4),d3
	if	(\1)-(\2)>1
	addq.l	#(\1)-(\2)-1,d3
	endc
	cmp.l	d3,d2
	ble.w	.wait
	if	(\2)>0
	addq.l	#(\2),d2
	endc
	move.l	d2,b_EffectVBlank(a4)
	endc
	endc
	endm

MAINEND	macro
	if	DEBUG
	addq.l	#1,b_VBlank(a4)
	btst.b	#6,$bfe001
	bne.w	MainLoop
	rts
	else
	bra.w	MainLoop
	endc
	endm

COUNTER	macro
	if	PERFCOUNT
	section	perfcount,data_f
a\@:	dc.b	"\1"
b\@:	dcb.b	16-(b\@-a\@),0
counter_\1	=	a\@+12
	endc
	endm

COUNT	macro
	if	PERFCOUNT
	addq.l	#1,counter_\1
	endc
	endm

CLAMP	macro
	if	(MODE=0)|WINUAE
	fcmp.w	#-128,\1
	fbge	.ok1\@
	fmove.w	#-128,\1
.ok1\@:	fcmp.w	#127,\1
	fble	.ok2\@
	fmove.w	#127,\1
.ok2\@:	endc
	endm

CLAMPW	macro
	if	(MODE=0)|WINUAE
	fcmp.w	#-32768,\1
	fbge	.ok1\@
	fmove.w	#-32768,\1
.ok1\@:	fcmp.w	#32767,\1
	fble	.ok2\@
	fmove.w	#32767,\1
.ok2\@:	endc
	endm

ASSERT	macro	; size,val1,comp,val2
	if	ASSERTED
	cmp.\1	\4,\2
	b\3.b	.ok\@
	illegal
.ok\@:
	endc
	endm

PROFDEF	macro	; Name
	if	PROFILING
	; New profile
PROFILE_\1	=	PROFILE_INDEX
PROFILE_INDEX	set	PROFILE_INDEX+1

	section	ProfileText,data_f
text\@:	dc.b	"\1"
text_end\@:	dcb.b	64-(text_end\@-text\@),' '
	section	ProfileCounters,data_f
	dc.l	0,0
	endc
	endm

PROFILE	macro	; Name[,number]
	if	PROFILING

	move.l	#PROFILE_\1,CurrentProfile
	if	"\2">""
	add.l	\2,ProfileCounters+PROFILE_\1*8+0
	else
	addq.l	#1,ProfileCounters+PROFILE_\1*8+0
	endc

	endc
	endm

NOPROFILE	macro
	if	PROFILING
	clr.l	CurrentProfile
	endc
	endm

;; ********** Internal macros **********

CODECALL	macro
	if	(MODE=0)
	jsr	\1
	else	;(MODE=2)
	bsr.w	System+(hs_Code-hs_System)+\1_OFFSET
	endc
	endm

;; ********** Main macro **********

BEGIN4k	macro	; Data files base name,mode
MODE	=	\2
SYSTEM	=	1
	ifnd	PREWAIT
PREWAIT	=	100
	endc
	ifnd	RMBPAUSE
RMBPAUSE	=	(MODE=0)
	endc
	ifnd	DEBUG
DEBUG	=	0
	endc
	ifnd	WINUAE
WINUAE	=	0
	endc
	ifnd	FPUINT
FPUINT	=	1
	endc
	ifnd	PERFCOUNT
PERFCOUNT	=	0
	endc
	ifnd	ASSERTED
ASSERTED	=	(MODE=0)
	endc
	ifnd	PROFILING
PROFILING	=	(MODE=0)
	endc

;; ********** Section setup **********

	section	System,code_f

	if	(MODE=0)|(MODE=1)
	section	BaseChip,data_f
BaseChip:
	section	BaseFast,data_f
BaseFast:
	section	Data,data_f
Data:
	section	PreCalc,code_f
PreCalc:
	section	Code,code_f
Code:
	section	Fast,bss_f
Fast:
	ds.l	32
	section	Chip,bss_c
Chip:
	if	PERFCOUNT
	section	perfcount,data_f
pc:
	endc

	if	PROFILING
	section	ProfileText,data_f
p:
	dc.b	"Name                    "
	dc.b	"    Number      Time  Each1000  Relative"
	dcb.b	64,'-'
presult:	dc.b	"Default"
	dcb.b	64-7,' '
	section	ProfileCounters,data_f
CurrentProfile:
	dc.l	0
ProfileCounters:
	dc.l	0,0
PROFILE_INDEX	set	1
	endc

	else	;(MODE=2)

	include	\1.i
	section	Code,bss_f
Code:
	ds.b	CODE_SIZE
Code_End:
	section	Fast,bss_f
Fast:
	ds.b	FAST_SIZE
Fast_End:
	section	Chip,bss_c
Chip:
	ds.b	CHIP_SIZE
Chip_End:
	endc

	Var	VBlank
	Var	Frame
	Var	EffectFrame

;	Var	TopazCharData

;; ********** Init code **********

	section	System,code_f

System:
	if	(MODE=1)
	; Write data

	; Precalc data
	ifd	DATA_PRECALC
	DATA_PRECALC
	endc

	; Generate WordCode
	lea.l	OrigCode,a2
	lea.l	PreCalc,a0
	move.w	#(PreCalc_End-PreCalc)/2-1,d7
.cloop1:	move.w	(a0)+,(a2)+
	dbf	d7,.cloop1
	lea.l	Code,a0
	move.w	#(Real_Code_End-Code)/2-1,d7
.cloop2:	move.w	(a0)+,(a2)+
	dbf	d7,.cloop2

	lea.l	OrigCode,a1
	lea.l	WordCode,a0
	move.l	a1,a6
	bsr.w	GenerateWordCode
	lea.l	WordCode,a0
	bsr.w	OptimizeWordCode
	move.l	a0,d6
	sub.l	#WordCode,d6

	; Write constants
	lea.l	IncludeFile(pc),a1
	move.l	#VarFields,d0
	bsr.w	WriteNumber
	move.l	#ChipFields,d0
	bsr.w	WriteNumber
	move.l	#FastFields,d0
	bsr.w	WriteNumber
	move.l	d6,d0
	bsr.w	WriteNumber
	move.l	#(BaseChip_End-BaseChip)+(BaseFast_End-BaseFast),d0
	bsr.w	WriteNumber
	move.l	#Data_End-Data,d0
	bsr.w	WriteNumber
	move.l	#(PreCalc_End-PreCalc)+(Code_End-Code),d0
	bsr.w	WriteNumber
	move.l	#Fast_End-Fast,d0
	bsr.w	WriteNumber
	move.l	#Chip_End-Chip,d0
	bsr.w	WriteNumber
	move.l	#0,d0
	bsr.w	WriteNumber
	move.l	#(PreCalc_End-PreCalc)+(Main-Code),d0
	bsr.w	WriteNumber
	move.l	#(PreCalc_End-PreCalc)+(Interrupt-Code),d0
	bsr.w	WriteNumber

	; Open dos
	move.l	$4.w,a6
	lea.l	DosName(pc),a1
	jsr	SU_OldOpenLibrary(a6)
	move.l	d0,a6

	; Write include file
	move.w	#'.i',Ext
	move.l	#FileName,d1
	move.l	#SU_MODE_NEWFILE,d2
	jsr	SU_Open(a6)
	move.l	d0,d7
	beq.b	.error1

	move.l	d7,d1
	move.l	#IncludeFile,d2
	move.l	#IncludeFile_End-IncludeFile,d3
	jsr	SU_Write(a6)

	move.l	d7,d1
	jsr	SU_Close(a6)
.error1:

	; Write bin file
	move.l	#'.bin',Ext
	move.l	#FileName,d1
	move.l	#SU_MODE_NEWFILE,d2
	jsr	SU_Open(a6)
	move.l	d0,d7
	beq.b	.error2
	move.l	d7,d1

	move.l	d7,d1
	move.l	#WordCode,d2
	move.l	d6,d3
	jsr	SU_Write(a6)

	move.l	d7,d1
	move.l	#BaseChip,d2
	move.l	#BaseChip_End-BaseChip,d3
	jsr	SU_Write(a6)

	move.l	d7,d1
	move.l	#BaseFast,d2
	move.l	#BaseFast_End-BaseFast,d3
	jsr	SU_Write(a6)
	
	move.l	d7,d1
	move.l	#ZeroBytes,d2
	move.l	d6,d3
	add.l	#(BaseChip_End-BaseChip)+(BaseFast_End-BaseFast),d3
	neg.l	d3
	and.l	#7,d3
	jsr	SU_Write(a6)

	move.l	d7,d1
	move.l	#Data,d2
	move.l	#Data_End-Data,d3
	jsr	SU_Write(a6)

	move.l	d7,d1
	jsr	SU_Close(a6)
.error2:

	; Close dos
	move.l	a6,a1
	move.l	$4.w,a6
	jsr	SU_CloseLibrary(a6)

	; Validate word code
	lea.l	WordCode,a0
	lea.l	UnpackCode,a1
	lea.l	OrigCode,a3
	bsr.w	CompileWordCode
	rts

WriteNumber:
	; D0 = Number
	; A1 = Dest line

	lea.l	27(a1),a0
	lea.l	28(a1),a1
.loop:
	divul.l	#10,d1:d0
	add.b	#'0',d1
	move.b	d1,-(a0)
	tst.l	d0
	bne.b	.loop
	rts

ZeroBytes:	dcb.b	8,0

IncludeFile:
	dc.b	'VarFields        =         ',10
	dc.b	'ChipFields       =         ',10
	dc.b	'FastFields       =         ',10
	dc.b	'COMP_SIZE        =         ',10
	dc.b	'BASE_SIZE        =         ',10
	dc.b	'DATA_SIZE        =         ',10
	dc.b	'CODE_SIZE        =         ',10
	dc.b	'FAST_SIZE        =         ',10
	dc.b	'CHIP_SIZE        =         ',10
	dc.b	'PreCalc_OFFSET   =         ',10
	dc.b	'Main_OFFSET      =         ',10
	dc.b	'Interrupt_OFFSET =         ',10
IncludeFile_End:

FileName:	dc.b	"\1"
Ext:	dc.b	0,0,0,0,0

DosName:	dc.b	'dos.library',0
	even

	include	4k:GenerateWordCode.S

	section	Buffers,bss_f

OrigCode:	ds.w	50000
WordCode:	ds.w	50000
UnpackCode:	ds.w	50000

	else	;(MODE=0)|(MODE=2)

	ifd	PREINIT
	PREINIT
	endc

	if	(MODE=0)

	; Precalc data
	ifd	DATA_PRECALC
	DATA_PRECALC
	endc

	; Setup mem pointers
	lea.l	Fast,a4
	lea.l	Chip,a5

	; Init base struct
	lea.l	BaseChip,a0
	lea.l	VarFields*4(a4),a1
	moveq.l	#ChipFields,d7
	bra.b	.clend
.cloop:	clr.l	d0
	move.w	(a0)+,d0
	lsl.l	#MEMORY_UNITlog,d0
	add.l	d0,a5
	move.l	a5,(a1)+
.clend:	dbf	d7,.cloop
	move.l	a4,a5
	lea.l	BaseFast,a0
	moveq.l	#FastFields,d7
	bra.b	.flend
.floop:	clr.l	d0
	move.w	(a0)+,d0
	lsl.l	#MEMORY_UNITlog,d0
	add.l	d0,a5
	move.l	a5,(a1)+
.flend:	dbf	d7,.floop

	else	;(MODE=2)

	; Setup mem pointers
	lea.l	System-hs_System+hs_Fast(pc),a4

	; Init base struct
	if	(ChipFields>0)|(FastFields>0)
	lea.l	BaseStruct(pc),a0
	lea.l	VarFields*4(a4),a1
	if	(ChipFields>0)
	move.l	System-4(pc),d5
	lsl.l	#2,d5
	addq.l	#4,d5
	move.l	d5,a5
	moveq.l	#ChipFields-1,d7
.cloop:	clr.l	d0
	move.w	(a0)+,d0
	lsl.l	#MEMORY_UNITlog,d0
	add.l	d0,a5
	move.l	a5,(a1)+
	dbf	d7,.cloop
	endc
	if	(FastFields>0)
	move.l	a4,a5
	moveq.l	#FastFields-1,d7
.floop:	clr.l	d0
	move.w	(a0)+,d0
	lsl.l	#MEMORY_UNITlog,d0
	add.l	d0,a5
	move.l	a5,(a1)+
	dbf	d7,.floop
	endc
	endc

	endc

	; Compile code
	if	(MODE=2)
	lea.l	CompressedCode(pc),a0
	lea.l	System-hs_System+hs_Code(pc),a1
	bsr.w	CompileWordCode
	move.l	$4.w,a6
	jsr	SU_CacheClearU(a6)
	endc

	CODECALL	PreCalc
Break:
	if	(DEBUG=0)
	lea.l	$dff000,a3
	move.l	$4.w,a6
	jsr	SU_CacheClearU(a6)
	lea.l	GetVBR(pc),a5
	jsr	SU_Supervisor(a6)
;	lea.l	SU_GfxName(pc),a1
;	jsr	SU_OldOpenLibrary(a6)
	moveq.l	#SU_OLTAG_GRAPHICS,d0
	jsr	SU_TaggedOpenLibrary(a6)
	move.l	d0,a6
;	; Open topaz
;	lea.l	TextAttr(pc),a0
;	lea.l	TopazName(pc),a1
;	move.l	a1,(a0)
;	jsr	SU_OpenFont(a6)
;	move.l	d0,a0
;	move.l	SU_tf_CharData(a0),b_TopazCharData(a4)
	; Clear display
	move.l	SU_gb_ActiView(a6),d7
	suba.l	a1,a1
	jsr	SU_LoadView(a6)
	move.w	#$0020,$1dc(a3)	; Ensure PAL
	moveq.l	#PREWAIT-1,d2
.wloop:	jsr	SU_WaitTOF(a6)
	dbf	d2,.wloop
	move.w	#$3fdf,$09a(a3)
	move.w	#$00ff,$096(a3)

	; Init interrupt
	move.l	$6c(a2),a5
	movem.l	d7/a2/a3/a5/a6,-(a7)
	lea.l	InterruptHandler(pc),a1
	move.l	a1,$6c(a2)
	move.l	a7,-(a1)	; StackStore
	endc

	CODECALL	Main

; Vbr, Int, GfxBase, OldView

End:
	if	(DEBUG=0)
	move.l	StackStore(pc),a7

	; Restore interrupt
	movem.l	(a7)+,a1/a2/a3/a5/a6
	move.l	a5,$6c(a2)
	move.w	#$a00c,$09a(a3)
	move.w	#$00ff,$096(a3)
	move.w	#$81e0,$096(a3)
	move.l	SU_gb_copinit(a6),$080(a3)
	jsr	SU_LoadView(a6)
	endc
;	move.l	a6,a1
;	move.l	$4.w,a6
;	jmp	SU_CloseLibrary(a6)

	if	PROFILING
	bsr.w	WriteProfile
	endc

	moveq.l	#0,d0
	rts

GetVBR:
	movec	vbr,a2
	rte

;SU_GfxName:
;	dc.b	'graphics.library'
;	even

;TextAttr:
;	dc.l	0
;	dc.w	8
;	dc.b	0,0
;TopazName:
;	dc.b	'topaz.font'
;	even

	if	PROFILING
WriteProfile:
	lea.l	ProfileCounters,a1
	clr.l	d4
	moveq.l	#N_PROFILES-1,d7
.sumloop:
	add.l	4(a1),d4
	addq.l	#8,a1
	dbf	d7,.sumloop

	lea.l	ProfileCounters,a1
	lea.l	presult,a2
	moveq.l	#N_PROFILES-1,d7
.loop:	move.l	(a1)+,d2	; Number
	move.l	(a1)+,d3	; Hits

	move.l	d2,d0
	moveq.l	#0,d1
	lea.l	34(a2),a0
	bsr.w	WriteFracNumber

	move.l	d3,d0
	moveq.l	#0,d1
	lea.l	44(a2),a0
	bsr.w	WriteFracNumber

	tst.l	d2
	beq.b	.none
	move.l	d3,d0
	mulu.l	#1000000,d0
	move.l	d2,d1
	lsr.l	#1,d1
	add.l	d1,d0
	divu.l	d2,d0
	moveq.l	#3,d1
	lea.l	54(a2),a0
	bsr.w	WriteFracNumber
.none:

	tst.l	d4
	beq.b	.nohits
	move.l	d3,d0
	mulu.l	#10000,d0
	move.l	d4,d1
	lsr.l	#1,d1
	add.l	d1,d0
	divu.l	d4,d0
	moveq.l	#2,d1
	lea.l	64(a2),a0
	move.b	#'%',-(a0)
	bsr.w	WriteFracNumber
.nohits:
	lea.l	64(a2),a2
	dbf	d7,.loop
	rts

WriteFracNumber:
	; D0 = Number
	; D1 = Decimals
	; A0 = Pointer (last+1)

.loop:
	divul.l	#10,d5:d0
	add.b	#'0',d5
	move.b	d5,-(a0)
	subq.l	#1,d1
	bgt.b	.loop
	blt.b	.next
	move.b	#'.',-(a0)
	bra.b	.loop
.next:	tst.l	d0
	bne.b	.loop
	rts

	endc

StackStore:
	dc.l	0
InterruptHandler:
	movem.l	d0-a6,-(a7)
	if	FPUINT
	fsave	-(a7)
	fmovem.x	fp0-fp7,-(a7)
	endc

	lea.l	$dff000,a3
	if	(MODE=0)
	lea.l	Fast,a4
	else	;(MODE=2)
	lea.l	System+(hs_Fast-hs_System)(pc),a4
	endc
	addq.l	#1,(a4)

	if	PROFILING
	lea.l	ProfileCounters,a0
	move.l	CurrentProfile,d0
	addq.l	#1,4(a0,d0.l*8)
	endc

	CODECALL	Interrupt
	lea.l	$dff000,a3

	if	RMBPAUSE
	; RMB pause
.rmb:	btst	#10,$016(a3)
	bne.b	.normb
	move.w	#$0020,$09c(a3)
	move.w	#$0020,$09c(a3)

	btst.b	#6,$bfe001
	bne.b	.rmbloop2
.rmbloop:
	moveq.l	#$0020,d0
	and.w	$dff01e,d0
	beq.b	.rmbloop
	CODECALL	Interrupt
	lea.l	$dff000,a3
 	bra.b	.rmb
.rmbloop2:
	moveq.l	#$0020,d0
	and.w	$dff01e,d0
	beq.b	.rmbloop2
	CODECALL	Interrupt
	lea.l	$dff000,a3
	btst.b	#6,$bfe001
	bne.b	.rmb
	move.w	#$0020,$09c(a3)
	move.w	#$0020,$09c(a3)
	if	FPUINT
	fmovem.x	(a7)+,fp0-fp7
	frestore	(a7)+
	endc
	movem.l	(a7)+,d0-a6
	rte
.normb:
	endc

	move.w	#$0020,$09c(a3)
	move.w	#$0020,$09c(a3)

	if	FPUINT
	fmovem.x	(a7)+,fp0-fp7
	frestore	(a7)+
	endc
	movem.l	(a7)+,d0-a6

	btst.b	#6,$bfe001
	bne.b	.end
	if	MODE=0
.lmbwait:	btst.b	#6,$bfe001
	beq.b	.lmbwait
	move.w	#$0020,$dff09c
	move.w	#$0020,$dff09c
	endc
	lea.l	End(pc),a1
	move.l	a1,2(a7)
.end:
	rte

	endc

	if	(MODE=2)
	; WordCode
	include	4k:CompileWordCode.S
System_End:
	dcb.b	((-(System_End-System))&7)+16,0
CompressedCode:
BaseStruct	=	CompressedCode+COMP_SIZE
BaseStruct_End	=	BaseStruct+BASE_SIZE
Data	=	BaseStruct_End+(-(COMP_SIZE+BASE_SIZE)&7)
	incbin	\1.bin
Real_Data_End:
	dcb.b	(-(Real_Data_End-Data))&7,0
Data_End:
	; Consistency chack
	if	Real_Data_End-(Data+DATA_SIZE)
	fail
	endc

	; Hunk struct
	rsreset
hs_System	rs.b	CompressedCode-System
hs_CompCode	rs.b	BaseStruct-CompressedCode
hs_BaseStruct	rs.b	BaseStruct_End-BaseStruct
hs_DataAlign	rs.b	Data-BaseStruct_End
hs_Data	rs.b	Data_End-Data
hs_DataEnd	rs.b	0
hs_Code	rs.b	Code_End-Code
hs_CodeEnd	rs.b	0
hs_Fast	rs.b	Fast_End-Fast
hs_FastEnd	rs.b	0
	else	;(MODE=0)|(MODE=1)
CompressedCode:
BaseStruct:
	endm

END4k	macro
VarFields	=	COUNT_Var
ChipFields	=	COUNT_Chip
FastFields	=	COUNT_Fast
Before_Chip	=	COUNT_Var
Before_Fast	=	COUNT_Var+COUNT_Chip

	section	BaseChip,data_f
BaseChip_End:
	section	BaseFast,data_f
BaseFast_End:
	section	Data,data_f
Real_Data_End:
	dcb.b	(-(Real_Data_End-Data))&7,0
Data_End:
	section	PreCalc,code_f
	rts
PreCalc_End:
	section	Code,code_f
Real_Code_End:
	dcb.b	(-((PreCalc_End-PreCalc)+(Real_Code_End-Code)))&7,0
Code_End:
	section	Fast,bss_f
Fast_End:
	section	Chip,bss_c
Chip_End:
	if	PROFILING
N_PROFILES	=	PROFILE_INDEX
	section	ProfileText,data_f
	dcb.b	64,'-'
	dcb.b	64,' '
	endc
	endm

	endc	;ONCE
