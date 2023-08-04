
	LIST	p=16F886
	include "P16F886.inc"
	ERRORLEVEL	0,	-302

	__CONFIG    _CONFIG1, _DEBUG_OFF & _BOR_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT


;**********************************************************************
;                  DEFINING VARIABLES IN PROGRAM
;**********************************************************************
	
#define _CC			1

;	7 segment display
#define	SSEG_SEG_A		PORTC,	0
#define	SSEG_SEG_B		PORTC,	1
#define	SSEG_SEG_C		PORTC,	2
#define	SSEG_SEG_D		PORTC,	3
#define	SSEG_SEG_E		PORTC,	4
#define	SSEG_SEG_F		PORTC,	5
#define	SSEG_SEG_G		PORTC,	6
#define	SSEG_SEG_DP		PORTC,	7

#define	SSEG_DIG_1		PORTA,	4
#define	SSEG_DIG_2		PORTA,	5
#define	SSEG_DIG_3		PORTA,	7
#define	SSEG_DIG_4		PORTA,	6

;	LEDs
#define Mode			PORTB,	3
#define Calibrate		PORTB,	4
#define Focus			PORTB,	5
#define Trigger			PORTB,	6


;	Rotational encoder
#define Encoder_L		PORTB,	1
#define Encoder_R		PORTB,	2
#define	Encoder_B		PORTB,	0


#define	NeedsDigit		FLAGS,	0


;	User variables
	cblock	0x20			;	Block of variables starts at address 20 h
		W_TEMP				;	Variable for saving W register
		STATUS_TEMP			;	Variable for saving STATUS register
		pclath_temp			;	Variable for saving PCLATH w register

		bin, hundreds		;	used by the BCD-BIN conversion routine
		tens_and_ones

		shutterDelay		;	shutter delay (ms)

		myDigit				;	working register

		R_DEL2, R_DEL1		;	delay

		FLAGS				;	my flags
							;	0 - Needs digit displayed (DisplayData)
							;	1 -
							;	2 -
							;	3 -
							;	4 -
							;	5 -

		shadow

	endc


bank0	macro
		bcf		STATUS,	RP0
		bcf		STATUS,	RP1
	endm

;**********************************************************************
	ORG         0x0000          ; Reset vector
	nop
	goto        mainProgram            ; Go to beginning of program
;**********************************************************************
	ORG         0x0004          ; Interrupt vector address

;	save W and STATUS (from Microchip)
	MOVWF W_TEMP
	SWAPF STATUS,W
	BCF STATUS,RP0
	MOVWF STATUS_TEMP
;**********************************************************************
; This part of the program is executed in interrupt routine
;**********************************************************************

;	Which interrupt occured?
	btfsc	INTCON,	T0IF
		call	Timer0_InterruptHandler

;**********************************************************************
; Interrupt clean-up
;**********************************************************************
endInterrupts
;	restore W and STATUS (from Microchip)
	SWAPF STATUS_TEMP,W
	MOVWF STATUS
	SWAPF W_TEMP,F
	SWAPF W_TEMP,W

	retfie                      ; Return from interrupt routine
;**********************************************************************
;**********************************************************************
; Main program
#include	"init.inc"
#include	"delay.inc"
#include	"displayCC.inc"
#include	"math.inc"
#include	"rotaryencoder.inc"


mainProgram
	call	Init

;	init variables
	clrf	shutterDelay

Calibrate_start
	movlw	0xff
	call	delay

	banksel	CM2CON0
	bsf		CM2CON0,	C2ON		;	start comparator

	bank0
	bcf		Calibrate
	bcf		Focus


Calibrate_loop

;*****************************************
;	check button
;*****************************************

	btfss	Encoder_B
		goto	SetDelay_start

;*****************************************
;*****************************************


;*****************************************
;	check comparator
;*****************************************
	banksel	CM2CON0
	movf	CM2CON0,	w
	bank0
	movwf	shadow

	btfss	shadow,	C2OUT
		goto	bang

no_bang
	bank0
	bcf		Calibrate
	goto	cont1
bang
	bank0
	bsf		Calibrate
	goto	cont1
;*****************************************

cont1
	goto	Calibrate_loop			;	start again


;************************************************************
;************************************************************

SetDelay_start
	movlw	0xff
	call	delay

	banksel	CM2CON0
	bcf		CM2CON0,	C2ON		;	stop comparator

	bank0
	bcf		Calibrate
	bcf		Focus
	bsf		Mode

	clrf	TMR0					;	reset timer0
	bsf		INTCON,	T0IE			;	enable TMR0 interrupt

SetDelay_loop

;*****************************************
;	check button
;*****************************************


	;check rotary encoder - left
	btfss	Encoder_L
		call	Encoder_CheckNext_L

	;check rotary encoder - right
	btfss	Encoder_R
		call	Encoder_CheckNext_R

	;check rotary encoder button
	btfss	Encoder_B
		goto	Action_start

;*****************************************

	goto	SetDelay_loop

;************************************************************
;************************************************************

Action_start
	bcf		INTCON,	T0IE			;	disable TMR0 interrupt

	movlw	0xff
	call	delay

	bank0
	bcf		Calibrate
	bsf		Focus
	bcf		Mode

	banksel	CM2CON0
	bsf		CM2CON0,	C2ON		;	start comparator

Action_loop

;*****************************************
;	check button
;*****************************************

	btfss	Encoder_B
		goto	Calibrate_start


;*****************************************
;	check comparator
;*****************************************
	banksel	CM2CON0
	movf	CM2CON0,	w
	bank0
	movwf	shadow

	btfss	shadow,	C2OUT
		goto	Shoot


;*****************************************


	goto	Action_loop

;************************************************************
;************************************************************


Shoot
	movf	shutterDelay,	w
	andlw	0xff
	btfsc	STATUS,	Z				;	if shutterDelay == 0
		goto	DoShoot				;	shoot immediately

	movf	shutterDelay,	w		;	else
	call	delay					;	wait shutterDelay [ms]

DoShoot
	bsf		Trigger					;	take picture

	banksel	CM2CON0
	clrf	CM2CON0

	banksel	PIR2
	bcf		PIR2,	C2IF

	bank0
	bcf		Calibrate
	bcf		Focus
	bcf		Mode

	movlw	0x50
	call	delay					;	after a few ms delay
	bcf		Trigger					;	release trigger on camera


;***************************************************************
;	Play a bit of lightshow
;***************************************************************
	
;CA

;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_4				;
;	bsf		SSEG_DIG_1				;
;
;	movlw	0x60
;	call	delay
;
;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_1				;
;	bsf		SSEG_DIG_2				;
;
;	movlw	0x60
;	call	delay
;
;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_2				;
;	bsf		SSEG_DIG_3				;
;
;	movlw	0x60
;	call	delay
;
;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_3				;
;	bsf		SSEG_DIG_4				;
;
;	movlw	0x60
;	call	delay
;
;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_4				;
;	bsf		SSEG_DIG_1				;
;
;	movlw	0x60
;	call	delay
;
;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_1				;
;	bsf		SSEG_DIG_2				;
;
;	movlw	0x60
;	call	delay
;
;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_2				;
;	bsf		SSEG_DIG_3				;
;
;	movlw	0x60
;	call	delay
;
;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_3				;
;	bsf		SSEG_DIG_4				;
;
;	movlw	0x60
;	call	delay
;
;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_4				;
;	bsf		SSEG_DIG_1				;
;
;	movlw	0x60
;	call	delay
;
;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_1				;
;	bsf		SSEG_DIG_2				;
;
;	movlw	0x60
;	call	delay
;
;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_2				;
;	bsf		SSEG_DIG_3				;
;
;	movlw	0x60
;	call	delay
;
;	movlw	b'11111110'
;	call	Set7segbits				;	display character
;	bcf		SSEG_DIG_3				;
;	bsf		SSEG_DIG_4				;
;
;	movlw	0x60
;	call	delay
;
;	bcf		SSEG_DIG_4				;
;	

;CC
	bsf		SSEG_DIG_1
	bsf		SSEG_DIG_2
	bsf		SSEG_DIG_3
	bsf		SSEG_DIG_4


	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_4				;
	bcf		SSEG_DIG_1				;

	movlw	0x60
	call	delay

	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_1				;
	bcf		SSEG_DIG_2				;

	movlw	0x60
	call	delay

	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_2				;
	bcf		SSEG_DIG_3				;

	movlw	0x60
	call	delay

	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_3				;
	bcf		SSEG_DIG_4				;

	movlw	0x60
	call	delay

	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_4				;
	bcf		SSEG_DIG_1				;

	movlw	0x60
	call	delay

	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_1				;
	bcf		SSEG_DIG_2				;

	movlw	0x60
	call	delay

	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_2				;
	bcf		SSEG_DIG_3				;

	movlw	0x60
	call	delay

	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_3				;
	bcf		SSEG_DIG_4				;

	movlw	0x60
	call	delay

	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_4				;
	bcf		SSEG_DIG_1				;

	movlw	0x60
	call	delay

	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_1				;
	bcf		SSEG_DIG_2				;

	movlw	0x60
	call	delay

	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_2				;
	bcf		SSEG_DIG_3				;

	movlw	0x60
	call	delay

	movlw	b'11111110'
	call	Set7segbits				;	display character
	bsf		SSEG_DIG_3				;
	bcf		SSEG_DIG_4				;

	movlw	0x60
	call	delay

	
	bsf		SSEG_DIG_1
	bsf		SSEG_DIG_2
	bsf		SSEG_DIG_3
	bsf		SSEG_DIG_4
	


;***************************************************************
;	End of lightshow
;***************************************************************

	movlw	0xff
	call	delay

	bank0
	bsf		Calibrate

	goto	Action_start			;	arm the shutter again

;************************************************************
;************************************************************


Timer0_InterruptHandler
	movf	shutterDelay,	w
	call	DisplayData

	clrf	TMR0
	bsf		INTCON,	T0IE			;	disable TMR0 interrupt
	bcf		INTCON,	T0IF			;	clear TIMER0 IF
	return

;************************************************************
;************************************************************


	end                         	; End of program


