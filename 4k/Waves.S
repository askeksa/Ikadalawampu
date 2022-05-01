;              T         T               T

	include	4k:System.S

	ONCE	Waves

	INCFILE

	include	4k:Constants.S

WAVELENGTH	=	65536

	FastField	SquareWave,WAVELENGTH*4
	FastField	SawWave,WAVELENGTH*4
	FastField	SineWave,WAVELENGTH*4
	FastField	NoiseWave,WAVELENGTH*4

	PRECALC

MakeWaves:
	baselea	SquareWave,a0
	baselea	SawWave,a1
	baselea	SineWave,a2
	baselea	NoiseWave,a3
	datalea	Constants,a6
	fmove.s	c_Dummy3(a6),fp3
	fmove.s	c_2_wave(a6),fp4
	fmove.s	c_2_pi_wave(a6),fp5
	fmove.s	c_pi(a6),fp6
	fmove.s	c_FloatOne(a6),fp7
	move.l	#WAVELENGTH-1,d7
.loop:	fmove.l	d7,fp1
	fmove.l	d7,fp2
	fadd	fp4,fp3
	fmul	fp4,fp1
	fmul	fp5,fp2
	fmul	fp6,fp3
	fsin	fp2
	fsin	fp3
	fmove	fp7,fp0
	fsub	fp7,fp1
	tst.w	d7
	bmi.w	.half
	fneg	fp0
.half:
	fmove.s	fp0,(a0,d7.l*4)
	fmove.s	fp1,(a1,d7.l*4)
	fmove.s	fp2,(a2,d7.l*4)
	fmove.s	fp3,(a3,d7.l*4)

	dbf	d7,.loop

	endc
