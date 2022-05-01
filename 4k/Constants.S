;               T         T               T

	include	4k:System.S

	ONCE	Constants

	INCFILE

	rsreset
c_Detune1Fac	rs.l	1
c_Detune2Fac	rs.l	1
c_IndexSprFac	rs.l	1
c_PitchDecayFac	rs.l	1
c_Dummy1	rs.l	1
c_OneTwelfth	rs.l	1
c_Dummy2	rs.l	1
c_Dummy3	rs.l	1
;c_2_pi_degrees	rs.l	1
c_2_wave	rs.l	1
c_2_pi_wave	rs.l	1
c_pi	rs.l	1
c_FloatOne	rs.l	1
c_SustainFac	rs.l	1
c_BaseNote	rs.l	1
c_IndexFac	rs.l	1
c_ToFixFac	rs.l	1
c_CurvFac	rs.l	1
;c_PulsePeakRec	rs.l	1
;c_PulseFreq	rs.l	1
c_Wavelength	rs.l	1
c_ColorFac	rs.l	1
c_ColorFalloff	rs.l	1

	DATA
Constants:
	dc.s	1.0/4.0/32768.0
	dc.s	1.0/4.0/32768.0
	dc.s	65536.0/12.0/32768.0
	dc.s	(1.0/512.0/512.0)
	dc.s	(1.0/512.0/512.0)
	dc.s	1.0/12.0
	dc.s	1.0/12.0
	dc.s	1.0/12.0
;	dc.s	2*3.14159265358979/4096
	dc.s	2.0/65536.0
	dc.s	2*3.14159265358979/65536.0
	dc.s	3.14159265358979
	dc.s	1.0
	dc.s	1.0/32.0
	dc.s	4.68299152 ; C0
	dc.s	65536.0/12.0
	dc.s	128.0
	dc.s	64.0*32768.0
;	dc.s	1.0/8.0/2
;	dc.s	2*3.14159265358979/10/2
	dc.s	65536.0
	dc.s	60.0
	dc.s	0.94921875

	endc
