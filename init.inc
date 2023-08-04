Init
;	set up ports

	clrf	PORTA
	clrf	PORTB
	clrf	PORTC

	banksel	 TRISA

	movlw	b'00000101'					;	A[2,0] input (comp2)
	movwf	TRISA						;	the rest is output

	movlw	b'00000111'					;	B[2-0] input
	movwf	TRISB						;	the rest is output

	clrf	TRISC						;	PORTC all output (segments)

	banksel	ANSEL
	movlw	b'00000101'
	movwf	ANSEL
	clrf	ANSELH


;	pull-up resistors
	banksel	OPTION_REG
	bcf		OPTION_REG, NOT_RBPU

	banksel	WPUB
	bsf		WPUB,	WPUB1


;	set up comparator

	banksel	CM2CON0
	movlw	b'10000000'
	movwf	CM2CON0

;	set up Timer0
	banksel	OPTION_REG

	bcf		OPTION_REG,	T0CS	;	select timer mode for Timer0
	bsf		OPTION_REG,	T0SE	;	select rising edge

	bcf		OPTION_REG,	PSA		;	assign prescaler to TMR0

	bcf		OPTION_REG,	PS2		;	set prescaler to 1:8
	bsf		OPTION_REG,	PS1
	bsf		OPTION_REG,	PS0

	bcf		INTCON,	T0IF		;	clear TIMER0 IF

;	interrupts
	banksel	PIE2
	bcf		PIE2,	C2IE		;	no need for comp interrupts

	banksel	INTCON
	bcf		INTCON,	INTE		;	disable external interrupt
	bcf		INTCON,	PEIE		;	enable peripherals
	bcf		INTCON,	T0IE		;	disable TMR0 interrupt
	bsf		INTCON,	GIE			;	enable interrupts



	bank0



	retlw	0x00