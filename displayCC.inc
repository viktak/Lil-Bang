;**********************************************************************
;	RefreshDisplay
;	Takes number to display in W
;**********************************************************************
DisplayData
	bsf		SSEG_DIG_1
	bsf		SSEG_DIG_2
	bsf		SSEG_DIG_3
	bsf		SSEG_DIG_4
	
	movwf	bin

	call	binary_to_bcd		;	Convert BIN -> BCD

;hundreds
	bcf		NeedsDigit
	movfw	hundreds
	andlw	b'00001111'

	btfsc	STATUS,	Z			;	hide leading zeros
		goto nohundreds

	bsf		NeedsDigit
	call	GetDigit			;	get character to be displayed

	call	Set7segbits			;	display character


	bcf		SSEG_DIG_2			;	Display hundreds

	movlw	0x01				;	wait a few ms
	call	delay

	bsf		SSEG_DIG_2			;	Hide hundreds

nohundreds

;ones
	movfw	tens_and_ones
	andlw	b'00001111'

	call	GetDigit			;	get character to be displayed
	call	Set7segbits			;	display character


	bcf		SSEG_DIG_4			;	Display ones

	movlw	0x01				;	wait a few ms
	call	delay

	bsf		SSEG_DIG_4			;	Hide ones

;tens
	rrf		tens_and_ones, f
	rrf		tens_and_ones, f
	rrf		tens_and_ones, f
	rrf		tens_and_ones, f
	movfw	tens_and_ones
	andlw	b'00001111'

	btfsc	NeedsDigit			;	if there are hundreds to display,
		goto needtens			;	the tens must be displayed as well

	btfsc	STATUS,	Z			;	hide leading zeros
		goto notens

needtens

	call	GetDigit			;	get character to be displayed
	call	Set7segbits			;	display character

	bcf		SSEG_DIG_3			;	Display ones

	movlw	0x01				;	wait a few ms
	call	delay

	bsf		SSEG_DIG_3			;	Hide ones

notens

	retlw	0x00


;**********************************************************************


;**********************************************************************
;	Set 7seg data bits here
;**********************************************************************
Set7segbits

	movwf	myDigit

;	First clear all bits
	bcf		SSEG_SEG_A
	bcf		SSEG_SEG_B
	bcf		SSEG_SEG_C
	bcf		SSEG_SEG_D
	bcf		SSEG_SEG_E
	bcf		SSEG_SEG_F
	bcf		SSEG_SEG_G
	bcf		SSEG_SEG_DP

	btfss	myDigit,	7
		bsf		SSEG_SEG_A
	btfss	myDigit,	6
		bsf		SSEG_SEG_B
	btfss	myDigit,	5
		bsf		SSEG_SEG_C
	btfss	myDigit,	4
		bsf		SSEG_SEG_D
	btfss	myDigit,	3
		bsf		SSEG_SEG_E
	btfss	myDigit,	2
		bsf		SSEG_SEG_F
	btfss	myDigit,	1
		bsf		SSEG_SEG_G
	btfss	myDigit,	0
		bsf		SSEG_SEG_DP

	retlw	0x00
;**********************************************************************


;**********************************************************************
;	Character decoder
;**********************************************************************
GetDigit
	addwf	PCL,	f

	retlw	b'00000011'			;0
	retlw	b'10011111'			;1
	retlw	b'00100101'			;2
	retlw	b'00001101'			;3
	retlw	b'10011001'			;4
	retlw	b'01001001'			;5
	retlw	b'01000001'			;6
	retlw	b'00011111'			;7
	retlw	b'00000001'			;8
	retlw	b'00001001'			;9
;**********************************************************************


;**********************************************************************
;	7 segment character decoder
;**********************************************************************
;GetDigit
;	addwf	PCL,	f

;	retlw	b'11111100'			;0
;	retlw	b'01100000'			;1
;	retlw	b'11011010'			;2
;	retlw	b'11110010'			;3
;	retlw	b'01100110'			;4
;	retlw	b'10110110'			;5
;	retlw	b'10111110'			;6
;	retlw	b'11100000'			;7
;	retlw	b'11111110'			;8
;	retlw	b'11110110'			;9

;**********************************************************************

;GetDigit
;	addwf	PCL,	f

;	retlw	b'00000011'			;0
;	retlw	b'10011111'			;1
;	retlw	b'00100101'			;2
;	retlw	b'00001101'			;3
;	retlw	b'10011001'			;4
;	retlw	b'01001001'			;5
;	retlw	b'01000001'			;6
;	retlw	b'00011111'			;7
;	retlw	b'00000001'			;8
;	retlw	b'00001001'			;9

;**********************************************************************
