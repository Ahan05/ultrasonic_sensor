/*
 * Ultrasonic.asm
 */
.include "m32def.inc"
   .EQU  SENSELED=0    ;  SENSELED pin (Output on AVR)
   .EQU  RANGELED1=1   ;  RANGELED pin (Output on AVR)
   .EQU  RANGELED2=2
   .EQU  RANGELED3=3
   .EQU  TRIG=6			   ;  Sensor TRIG pin (Output on AVR, input on sensor)
   .EQU  ECHO=7            ;  Sensor ECHO pin (Input on AVR, output on sensor)

   .EQU  BDV10usCNT=55
   .EQU  WDV50msCNT=166000  ; WDELAY count for 50ms delay
   .EQU  BDV1cmCNT=255      ; Number of iterations for BDELAY loop to get 1cm
                            ; resolution.
   .EQU  BDV2mmCNT=6        ; Number of iterations for BDELAY loop to get 2mm
                            ; resolution.


   .DEF A = R16            ;  GENERAL PURPOSE ACCUMULATOR
   .DEF BDV = R17          ;  Counter used in BDELAY routine.
   .DEF CNT = R18

   .DEF DTEST=R19          ;  DTEST is used to test for particular distances.
                           ;  Will be 1 if distance test passes or 0 if failed

   .DEF DRNG1=R20          ;  Distance in increments of CNT for DNEARER

;===================

.ORG 0000
      RJMP  ON_RESET       ;  GO HERE WHEN CHIP IS TURNED ON OR RESET

ON_RESET:

	LDI R16, 0b11111111;
	OUT DDRB, R16;

	LDI R16, 0b01111111;
	OUT DDRD, R16;

	LDI R16, 0b11111111;
	OUT DDRC, R16;

	LDI R16, 0b11111111;
	OUT DDRA, R16;
;===================
	LDI R16, 0b00000000;
	OUT PortB, R16;

	LDI R16, 0b00000000;
	OUT PortD, R16;

	LDI R16, 0b00000000;
	OUT PortA, R16;

	LDI R16, 0b00000000;
	OUT PortC, R16;

	ldi	A, $02	;    Set Stack Pointer to end of RAM
	out SPH, A
	ldi A, $5f
   	out	SPL,A
;===================

MAIN_LOOP:
      rcall ONTRIG            ; Start 10mcs trigger pulse by setting TRIG high.
      ldi   BDV, BDV10usCNT   ; Set DELAY count for delay of approx. 10mcs.
      rcall BDELAY            ; Run the delay.
      rcall OFFTRIG           ; Turn off the trigger.
      rcall WAIT4ONECHO       ; Wait for start of ECHO pulse

      rcall GETECHOPULSE   ; Get length of echo pulse in CNT.

      tst   CNT            ; Check CNT for zero, indicating object not detected.
      breq  NOOBJECT
      rcall ONSENSELED

	; FIRST LED
      ldi   DRNG1,25
      rcall DBETWEEN       ; Test for object within certain distance.

      tst   DTEST          ; DTEST will be 1 if test passed (object is near).
      breq  NOTNEARER1
      rcall ONRANGELED1

	; SECOND LED
	  ldi   DRNG1,20
      rcall DBETWEEN       ; Test for object within certain distance.

      tst   DTEST
      breq  NOTNEARER2
      rcall ONRANGELED2

	; THIRD LED
	  ldi   DRNG1,15
      rcall DBETWEEN       ; Test for object within certain distance.

      tst   DTEST
      breq  NOTNEARER3
      rcall ONRANGELED3
;----------------------

      rjmp  MAINWAIT
NOTNEARER1:
      rcall OFFRANGELED1
NOTNEARER2:
	  rcall OFFRANGELED2
NOTNEARER3:
	  rcall OFFRANGELED3
      rjmp  MAINWAIT


   NOOBJECT:
      rcall OFFSENSELED
      rcall OFFRANGELED1
	  rcall OFFRANGELED2
	  rcall OFFRANGELED3

   MAINWAIT:
      ldi YH, HIGH(WDV50msCNT)
      ldi YL, LOW(WDV50msCNT)    ; ultrasonic pulses in the room to completely fade
      rcall WDELAY

  END:
 	   RJMP  MAIN_LOOP

;---------------------------
;  WAIT4ONECHO
;  Waits for echo to start from ultrasonic sensor.

WAIT4ONECHO:
   sbis     PIND, ECHO         ; Check ECHO line of sensor and skip if high
   rjmp     WAIT4ONECHO
   ret

; -------------------------------------
;  GETECHOPULSE
;  Loop timing is set up to generate one iteration/count per a fixed length (ex. 1cm.)

GETECHOPULSE:
   clr      CNT
GEP1:
   inc      CNT            ;
   tst      CNT            ;    Increment CNT
   breq     GEPret         ;    If CNT overflows to zero, exit routine.

   ldi      BDV,BDV1cmCNT  ;    Load delay count here
   rcall    BDELAY

   sbic     PINd, ECHO     ;    Check ECHO pin. If no ECHO, skip over next instruction.

   rjmp     GEP1

GEPret:
   ret
; -------------------------------------
; BDELAY
; A simple 1-byte loop delay
; BDV must be loaded.

BDELAY:                    ;    # of clks to call here
   dec      BDV            ;    Decrement counter
   brne     BDELAY         ;    Loop back up if not zero

   ret                     ;    Else return

; -------------------------------------
;  DBETWEEN
;  The distance will be determined by the delay in GETECHOPULSE.
;  DRNG1 must be loaded with range values before this routine is called.

DBETWEEN:
   ldi   DTEST,1
   cp    CNT,DRNG1      ; Check lower distance
   brlo  DBret          ; If CNT lower (closer) then exit with 1.
   ldi   DTEST,0        ; Otherwise, farther out, so exit with 0
DBret:
   ret

; -------------------------------------
; WDELAY
; A simple 2-byte (Word) loop delay
; YH and YL must be pre-loaded:

WDELAY:
   sbiw     YH:YL,1
   brne     WDELAY         ;    Loop back up if not zero
   ret                     ;    Else return


ONSENSELED:
   SBI   PORTB,SENSELED ; turns on senseled LED
   ret
ONRANGELED1:
   SBI   PORTB,RANGELED1 ; turns on 1-st LED
   ret
ONRANGELED2:
   SBI   PORTB,RANGELED2 ; turns on 2-nd LED
   ret
ONRANGELED3:
   SBI   PORTB,RANGELED3 ; turns on 3-rd LED
   ret
OFFSENSELED:
   CBI   PORTB,SENSELED ; turns off senseled LED
   ret
OFFRANGELED1:
   CBI   PORTB,RANGELED1; turns off 1-st LED
   ret
OFFRANGELED2:
   CBI   PORTB,RANGELED2; turns off 2-nd LED
   ret
OFFRANGELED3:
   CBI   PORTB,RANGELED3; turns off 3-rd LED
   ret

ONTRIG:
   SBI   PORTD,TRIG ; turns on trigger
   ret
OFFTRIG:
   CBI   PORTD,TRIG;  turns off trigger
   ret
