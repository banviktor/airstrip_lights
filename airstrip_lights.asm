;*************************************************************** 
;* Feladat: Kifut�p�lya vil�g�t�s megval�s�t�sa
;* R�vid le�r�s: 
;	Az INT nyom�gomb, a f�ny�rz�kel� �s a LED0~LED7
;	LED-ek felhaszn�l�s�val k�sz�tsen kifut�p�lya vil�g�t�st!
; 
;* Szerz�k: 
;	B�n Viktor Gergely
;	K�rolyi �ron
;* M�r�csoport: CDE05
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
; v�ltoz�k
	.def temp = r16
	.def mode = r17
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
	jmp ADC_IT		; ADC Conversion Complete Handler 
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

;< t�bbi IT kezel� a f�jl v�g�re! >

DUMMY_IT:	
	ldi r16,   0xFF ; LED pattern:  *-
	out DDRC,  r16  ;               -*
	ldi r16,   0xA5	;               *-
	out PORTC, r16  ;               -*
DUMMY_LOOP:
	rjmp DUMMY_LOOP ; endless loop

;< t�bbi IT kezel� a f�jl v�g�re! >

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

;LED-ek kezd��llapota
	ldi temp, 0b1100_1100
	mov led_initial, temp

;LED-ek v�g�llapota
	ldi temp, 0b1001_1001
	mov led_final, temp

;Kezd��llapot bet�lt�se
	mov led, led_initial
	ldi mode, 0b0000_0001
	ldi pwm_cmp, 0
	ldi pwm_cntr, 0
	ldi int_state, 0
	ldi int_cntr, 0

;Ki- �s bemenetek inicializ�l�sa
	ldi temp, 0xFF
	out DDRC, temp        ;LED-ek kimenetek
	ldi temp, 0b1110_1111        
	out DDRE, temp   ;DEBUG
	;sts DDRE, temp		  ;INT bemenet       ;PROD

;Timer0 inicializ�l�sa
	ldi temp, 0b0000_1011 ;CTC, 32-es Prescale
	out TCCR0, temp
	ldi temp, 172         ;173-as modulus
	out OCR0, temp
	ldi temp, 0b0000_0010 ;IT: Output Compare Match
	out TIMSK, temp

;Opto, ADC inicializ�l�sa
	ldi temp, 0b01000010 ; ADMUX: 5V ref, balra igaz�tott, poti
		      ; 01...... ; REFS = 01 (referenciafesz�lts�g: 5V VCC)
              ; ..0..... ; ADLAR = 0  (jobbra igaz�tott)
              ; ...00010 ; ADMUX = 00010 Fotorezisztor (f�nyellen�ll�s)
	out ADMUX, temp
	ldi temp, 0b11101111 ; ADCSRA: folyamatos fut�s, IT, 128-as el�oszt�
			  ; 1....... ; ADEN = 1 (A/D enged�lyez�se)
              ; .1...... ; ADSC = 1 (start conversion)
              ; ..1..... ; ADFR = 1 (free running / folyamatos konverzi�)
              ; ...0.... ; ADIF (nem t�r�lj�k a megszak�t�sjelz� flaget)
              ; ....1... ; ADIE = 1 (megszak�t�sok enged�lyez�se)
              ; .....111 ; ADPS = 111 (128-as el�oszt�)
	out ADCSRA, temp

	sei ;glob�lis interrupt

;*************************************************************** 
;* MAIN program, Endless loop part
 
M_LOOP: 	
	jmp M_LOOP ; Endless Loop  


;*************************************************************** 
;* Subroutines, Interrupt routines

ROTATE:
	cp led, led_final
	breq else_rotate_led ;ha egyenl�k, ugrik
if_rotate_led:	
	lsr led ;l�pteti a ledeket
	jmp endif_rotate_led
else_rotate_led:
	mov led, led_initial ;bet�lti a kezdeti led-�ll�st
endif_rotate_led:
	ret

ADC_IT:
	;temp, SREG lement�se stackbe
	push temp
	in temp, SREG
	push temp

;ha ki van kapcsolva
	cpi mode, 0
	brne if_on
	ldi pwm_cmp, 0
	jmp endif_level
if_on:
	cpi mode, 1
	brne if_level3

;ha szab�lyozott
	in temp, ADCH
	andi temp, 0b0000_0011  ;a biztons�g kedv��rt kimaszkoljuk ami nem l�nyeges

	cpi temp, 0
	brne if_level1
if_level0:
	ldi pwm_cmp, 10
	jmp endif_level
if_level1:
	cpi temp, 1
	brne if_level2
	ldi pwm_cmp, 20
	jmp endif_level
if_level2:
	cpi temp, 2
	brne if_level3
	ldi pwm_cmp, 30
	jmp endif_level
if_level3:
;ha full f�nyer�
	ldi pwm_cmp, 40
endif_level:

	;temp, SREG visszat�lt�se stackb�l
	pop temp
	out SREG, temp
	pop temp
	reti

INT_HANDLER:
	inc mode
	cpi mode, 3
	brlo end_mode_reset
	ldi mode, 0
end_mode_reset:
	ret

T0_HANDLER:
	;temp, SREG lement�se stackbe
	push temp
	in temp, SREG
	push temp

;PWM megval�s�t�sa
	inc pwm_cntr

	;ha pwm_cntr == 40, null�zzuk
	cpi pwm_cntr, 40
	brne endif_overflow
	ldi pwm_cntr, 0
endif_overflow:

	;PWM m�k�d�s
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

;INT �llapot�nak lek�rdez�se
	inc int_cntr
	cpi int_cntr, 10
	brne endif_intcntr
	;>> Ha int_cntr == 10
	;Balra shiftelj�k int_state-et, majd az utols� bitj�be bet�ltj�k INT �llapot�t
	ldi int_cntr, 0
	lsl int_state
	;lds temp, PINE ;PROD
	in temp, PINE   ;DEBUG
	bst temp, 4
	bld int_state, 0
	
	;Megvizsg�ljuk az utols� 4 bitet
	andi int_state, 0x0F
	cpi int_state, 0b0000_1100	
	brne endif_intcntr
	;>> Ha int_state == 0b0000_1100
	call INT_HANDLER
endif_intcntr:

	;temp, SREG visszat�lt�se stackb�l
	pop temp
	out SREG, temp
	pop temp
	reti




