;**********************************************************************
;		rotary encoder routines
;**********************************************************************

Encoder_CheckNext_L
	btfsc Encoder_R
		goto Encoder_RightAction
	return
	
Encoder_CheckNext_R
	btfsc Encoder_L
		goto Encoder_LeftAction
	return


Encoder_RightAction
;	right action comes here
	
	incf	shutterDelay,	f			;	increment delay

	goto Encoder_RotationEnds


Encoder_LeftAction
;	left action comes here

	decf	shutterDelay,	f			;	decrement mode


Encoder_RotationEnds
	btfss Encoder_L
		goto Encoder_RotationEnds
	btfss Encoder_R
		goto Encoder_RotationEnds

	return

;**********************************************************************
;		rotary encoder end
;**********************************************************************