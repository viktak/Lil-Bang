; Calls the delay_1ms routine the number of times specified by
; the W register.
delay
	movwf	R_DEL2
delay_loop
	call	delay_1ms
	decfsz	R_DEL2, F
		goto	delay_loop
	return
	
; When called gives a delay of about 1000 cycles, or 1ms at 4Mhz
; before the next instruction is executed.
delay_1ms
	movlw	d'248'
	movwf	R_DEL1
delay_1ms_loop
	nop
	decfsz	R_DEL1, F
		goto	delay_1ms_loop
	return
