;*************************************************************** 
;* Feladat: Kifutópálya világítás megvalósítása
;* Rövid leírás: 
;	Az INT nyomógomb, a fényérzékelõ és a LED0~LED7
;	LED-ek felhasználásával készítsen kifutópálya világítást!
; 
;* Szerzõk: 
;	Bán Viktor Gergely
;	Károlyi Áron
;* Mérõcsoport: CDE05
;
;***************************************************************
;* "AVR ExperimentBoard" port assignment information:
;***************************************************************
;*
;* LED0(P):PortC.0          LED4(P):PortC.4
;* LED1(P):PortC.1          LED5(P):PortC.5
;* LED2(S):PortC.2          LED6(S):PortC.6
;* LED3(Z):PortC.3          LED7(Z):PortC.7        INT:PortE.4
;*
;* SW0:PortG.0     SW1:PortG.1     SW2:PortG.4     SW3:PortG.3
;* 
;* BT0:PortE.5     BT1:PortE.6     BT2:PortE.7     BT3:PortB.7
;*
;***************************************************************
;*
;* AIN:PortF.0     NTK:PortF.1    OPTO:PortF.2     POT:PortF.3
;*
;***************************************************************
;*
;* LCD1(VSS) = GND         LCD9(DB2): -
;* LCD2(VDD) = VCC         LCD10(DB3): -
;* LCD3(VO ) = GND         LCD11(DB4): PortA.4
;* LCD4(RS ) = PortA.0     LCD12(DB5): PortA.5
;* LCD5(R/W) = GND         LCD13(DB6): PortA.6
;* LCD6(E  ) = PortA.1     LCD14(DB7): PortA.7
;* LCD7(DB0) = -           LCD15(BLA): VCC
;* LCD8(DB1) = -           LCD16(BLK): PortB.5 (1=Backlight ON)
;*
;***************************************************************

.include "m128def.inc" ; Definition file for ATmega128 
;* Program Constants 
.equ const =$00 ; Generic Constant Structure example  
;* Program Variables Definitions 
; konstansok
	.def led_initial = r1
	.def led_final = r2
; változók
	.def temp = r16
	.def mode = r17
	.def brightness = r18
	.def pwm_cmp = r19
	.def pwm_cntr = r20
	.def led = r21
	.def int_state = r22
	.def int_cntr = r23

;*************************************************************** 
;* Reset & Interrupt Vectors  
.cseg 
.org $0000 ; Define start of Code segment 
	jmp RESET ; Reset Handler, jmp is 2 word instruction 
	jmp DUMMY_IT	; Ext. INT0 Handler
	jmp DUMMY_IT	; Ext. INT1 Handler
	jmp DUMMY_IT	; Ext. INT2 Handler
	jmp DUMMY_IT	; Ext. INT3 Handler
	jmp DUMMY_IT	; Ext. INT4 Handler (INT gomb)
	jmp DUMMY_IT	; Ext. INT5 Handler
	jmp DUMMY_IT	; Ext. INT6 Handler
	jmp DUMMY_IT	; Ext. INT7 Handler
	jmp DUMMY_IT	; Timer2 Compare Match Handler 
	jmp DUMMY_IT	; Timer2 Overflow Handler 
	jmp DUMMY_IT	; Timer1 Capture Event Handler 
	jmp DUMMY_IT	; Timer1 Compare Match A Handler 
	jmp DUMMY_IT	; Timer1 Compare Match B Handler 
	jmp DUMMY_IT	; Timer1 Overflow Handler 
	jmp T0_HANDLER	; Timer0 Compare Match Handler 
	jmp DUMMY_IT	; Timer0 Overflow Handler 
	jmp DUMMY_IT	; SPI Transfer Complete Handler 
	jmp DUMMY_IT	; USART0 RX Complete Handler 
	jmp DUMMY_IT	; USART0 Data Register Empty Hanlder 
	jmp DUMMY_IT	; USART0 TX Complete Handler 
	jmp DUMMY_IT	; ADC Conversion Complete Handler 
	jmp DUMMY_IT	; EEPROM Ready Hanlder 
	jmp DUMMY_IT	; Analog Comparator Handler 
	jmp DUMMY_IT	; Timer1 Compare Match C Handler 
	jmp DUMMY_IT	; Timer3 Capture Event Handler 
	jmp DUMMY_IT	; Timer3 Compare Match A Handler 
	jmp DUMMY_IT	; Timer3 Compare Match B Handler 
	jmp DUMMY_IT	; Timer3 Compare Match C Handler 
	jmp DUMMY_IT	; Timer3 Overflow Handler 
	jmp DUMMY_IT	; USART1 RX Complete Handler 
	jmp DUMMY_IT	; USART1 Data Register Empty Hanlder 
	jmp DUMMY_IT	; USART1 TX Complete Handler 
	jmp DUMMY_IT	; Two-wire Serial Interface Handler 
	jmp DUMMY_IT	; Store Program Memory Ready Handler 

.org $0046

;****************************************************************
;* DUMMY_IT interrupt handler -- CPU hangup with LED pattern
;* (This way unhandled interrupts will be noticed)

;< többi IT kezelõ a fájl végére! >

DUMMY_IT:	
	ldi r16,   0xFF ; LED pattern:  *-
	out DDRC,  r16  ;               -*
	ldi r16,   0xA5	;               *-
	out PORTC, r16  ;               -*
DUMMY_LOOP:
	rjmp DUMMY_LOOP ; endless loop

;< többi IT kezelõ a fájl végére! >

;*************************************************************** 
;* MAIN program, Initialisation part
.org $004B;
RESET: 
;* Stack Pointer init, 
;  Set stack pointer to top of RAM 
	ldi temp, LOW(RAMEND) ; RAMEND = "max address in RAM"
	out SPL, temp 	      ; RAMEND value in "m128def.inc" 
	ldi temp, HIGH(RAMEND) 
	out SPH, temp 

M_INIT:

;LED-ek kezdõállapota
	ldi temp, 0b1100_1100
	mov led_initial, temp

;LED-ek végállapota
	ldi temp, 0b1001_1001
	mov led_final, temp

;Kezdõállapot betöltése
	mov led, led_initial
	ldi mode, 0b0000_0001
	ldi brightness, 0
	ldi pwm_cmp, 0
	ldi pwm_cntr, 0
	ldi int_state, 0
	ldi int_cntr, 0

;Ki- és bemenetek inicializálása
	ldi temp, 0xFF
	out DDRC, temp        ;LED-ek kimenetek
	ldi temp, 0b0001_0000        
	out DDRE, temp   ;DEBUG
	;sts DDRE, temp		  ;INT bemenet       ;PROD
	ldi temp, 0b0000_0100
	sts DDRF, temp   ;DEBUG
	;sts DDRF, temp        ;OPTO bemenet     ;PROD

;Timer0 inicializálása
	ldi temp, 0b0000_1011 ;CTC, 32-es Prescale
	out TCCR0, temp
	ldi temp, 172         ;173-as modulus
	out OCR0, temp
	ldi temp, 0b0000_0010 ;IT: Output Compare Match
	out TIMSK, temp


;*************************************************************** 
;* MAIN program, Endless loop part
 
M_LOOP: 	
	call T0_HANDLER ;DEBUG
	jmp M_LOOP ; Endless Loop  


;*************************************************************** 
;* Subroutines, Interrupt routines

ROTATE:
	cp led, led_final
	breq else_rotate_led ;ha egyenlõk, ugrik
if_rotate_led:	
	lsr led ;lépteti a ledeket
	jmp endif_rotate_led
else_rotate_led:
	mov led, led_initial ;betölti a kezdeti led-állást
endif_rotate_led:
	ret

SET_BRIGHTNESS:

	ret

INT_HANDLER:
	ret

T0_HANDLER:
	;temp, SREG lementése stackbe
	push temp
	in temp, SREG
	push temp

	;PWM megvalósítása
	inc pwm_cntr
	cp pwm_cmp, pwm_cntr
	brsh if_leds_off
	;>> Ha pwm_cntr < pwm_cmp
	out PORTC, led
	jmp endif_leds
if_leds_off:
	;>> Ha pwm_cntr >= pwm_cmp
	ldi temp, 0
	out PORTC, temp
endif_leds:

	;INT állapotának lekérdezése
	inc int_cntr
	cpi int_cntr, 10
	brne endif_intcntr
	;>> Ha int_cntr == 10
	;Balra shifteljük int_state-et, majd az utolsó bitjébe betöltjük INT állapotát
	ldi int_cntr, 0
	lsl int_state
	;lds temp, PINE ;PROD
	in temp, PINE   ;DEBUG
	bst temp, 4
	bld int_state, 0
	
	;Megvizsgáljuk az utolsó 4 bitet
	andi int_state, 0x0F
	cpi int_state, 0b0000_1100	
	brne endif_intcntr
	;>> Ha int_state == 0b0000_1100
	call INT_HANDLER
endif_intcntr:

	;temp, SREG visszatöltése stackbõl
	pop temp
	out SREG, temp
	pop temp
	reti




