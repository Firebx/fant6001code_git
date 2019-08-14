include BA45F5542.inc

ds  .section    'data'

        ; ������������
        rec_cmd         db		?           ; ����
        rec_addr        db  	?           ; ��ַ
        rec_dt          db  	?           ; ����
        ; ��������������ʱ��־
        rec_ct_bit      db  	?
        rec_ct_byte     db  	?
        rec_ct_pluse    db  	?
        
        ; ��ʱ��ʱ�ü�����
        count1          db  	?
        count2          db  	?
        
        ;ADC����
        adc_h			db  	?
        adc_l			db  	?
        
        ;OPAУ׼
		sdano_befor		db		?
		sdaof_1			db  	?
		sdaof_2			db  	?


cs      .section   at  000h   'code'
        org   00h
        JMP   SYS_INIT
             	
             	
;;*************************************************************************************
;; ������ʼ��
;;*************************************************************************************
SYS_INIT:
		CALL	INITIAL_CLOCK
		CALL	INITIAL_IO
		CALL	INITIAL_AFE
		CALL	INITIAL_ADC
		CALL	INITIAL_UART
		CALL	CLBT_OPA

        ; ����LED��2�Σ����200ms
        SET	  PA4
        MOV   A, 100
        CALL  DLY_MS
        CLR   PA4
        MOV   A, 250
        CALL  DLY_MS
        SET   PA4
        MOV   A, 100
        CALL  DLY_MS
        CLR   PA4

        JMP   MAIN
        
;;*************************************************************************************
;; ������
;;*************************************************************************************
MAIN:
		SET   PA4
        MOV   A, 200
        CALL  DLY_MS
        CLR   PA4
        MOV   A, 200
        CALL  DLY_MS
 
        ;SET   PA4
        MOV   A, 15
        CALL  DLY_US
        
        ; ι��
        CLR   WDT
        
        ;���̼��
		SET		SDA0EN
		SET		SDA1EN			;ʹ�ܺ�����չܵ�2���˷�
		SET		ADCEN
        MOV		A,50
        CALL	DLY_US
        SET		ISGS0			;ISINK0����ʹ�ܹ����
        CALL	Smoke_D
        CLR		ISGS0
        
		SET		UTXEN
        MOV		A,UUSR
		MOV		A,11111111B
		CALL	UART_TX
        MOV		A,UUSR
		MOV		A,adc_h
		CALL	UART_TX
		MOV		A,UUSR
		MOV		A,adc_l
		CALL	UART_TX
		CLR		UTXEN
		
		
		MOV		A,222
		CALL	DLY_MS	
		
		
		SET		SDA0EN
        SET		SDA1EN			;ʹ�ܺ�����չܵ�2���˷�
        SET		ADCEN
        MOV		A,50
        CALL	DLY_US
        SET		ISGS1			;ISINK0����ʹ�ܹ����
        CALL	Smoke_D
        CLR		ISGS1
        
		SET		UTXEN
        MOV		A,UUSR
		MOV		A,00000000B
		CALL	UART_TX		
        MOV		A,UUSR
		MOV		A,adc_h
		CALL	UART_TX
		MOV		A,UUSR
		MOV		A,adc_l
		CALL	UART_TX
		CLR		UTXEN
		
		MOV		A,222
		CALL	DLY_MS
       
        
        JMP   MAIN


Smoke_D:
        ;SET		ADCEN
        ;MOV		A,10
        ;CALL	DLY_US
        CLR		START			; high pulse on start bit to initiate conversion
		SET		START			; reset A/D
		CLR		START			; start A/D
AD_Converting:
		SZ		ADBZ
		JMP		AD_Converting
		MOV		A,SADOL
		MOV		adc_l,A
		MOV		A,SADOH
		MOV		adc_h,A
		CLR		ADCEN
		CLR		SDA0EN
        CLR		SDA1EN			;���ܺ�����չܵ�2���˷�
		RET
		
;;*************************************************************************************
;; UART���ⷢ������
;;*************************************************************************************	
UART_TX:
		MOV		UTXR_RXR,A
SHIFT_OK:		
		SNZ		UTXIF
		JMP		SHIFT_OK
		SET		UTXEN
UART_transing:		
		SNZ		UTIDLE
		JMP		UART_transing
		CLR		UTXEN
		NOP
		RET
			
       
        
        
;;*************************************************************************************
;; ��ʱ�йصĺ�����ͳһ������count1, count2
;;*************************************************************************************
DLY_US:
        MOV   count1, A
        SDZ   count1
        JMP   $-1
        RET
        
DLY_MS:
        MOV   count2, A
        MOV   A, 163
        MOV   count1, A
        SDZ   count1
        JMP   $-1
        SDZ   count2
        JMP   $-5
        RET
		
		
		

;;*************************************************************************************
;; �ϵ��ʼ��
;;*************************************************************************************  

INITIAL_CLOCK:  
				;---SCC Register--- : ININ_System_Clock 
				;bit7,6,5  	+------------- CKS2~CKS0:System clock selection
				; 			|	          > 000 : fH
				;			|	            001 : fH/2
				; 			|	         	010 : fH/4
				;			|	            011 : fH/8
				;			|	            100 : fH/16
				;			|	            101 : fH/32
				;			|	            110 : fH/64
				;			|	            111 : fSUB
				;Bit4,3,2 	|+------------- Unuse
				;Bit1		||+------------ FHIDEN ; HFREQ OSC WHEN CPU IS SWITCH OFF
				;			|||			  >	0	: Disable
				;			|||				1	: Enable
				;Bit0		|||+----------- FSIDEN ; LFREQ OSC WHEN CPU IS SWITCH OFF
				;			||||		  >	0	: Disable
				;			||||			1	: Enable
				MOV		A,00000000B
				MOV		SCC,A					;ѡ��ϵͳʱ��ΪHIRC
				;---HIRCC Register--- : ININ_System_Clock 
				;bit7,6,5,4 +--------------	Unuse
				;Bit3,2	 	|+------------- HIRC1~HIRC10 :
				;			||			  > 00 : 2MHz
				;			||			  	01 : 4MHz				
				;			||			  	10 : Reserved
				;			||			  	11 : 2MHz												
				;Bit1		||+------------ HIRCF ; HIRC OSC Stable Flag (Only Read)
				;			|||				0	: Unstable
				;			|||				1	: Stable
				;Bit0		|||+---------- HIRCEN: ; LFREQ OSC WHEN CPU IS SWITCH OFF
				;			||||			0	: Disable
				;			||||		  >	1	: Enable
				MOV		A,00001001B
				MOV		HIRCC,A					;ѡ��HIRCƵ��Ϊ8MHz��ʹ��HIRC
				;---WDTC Register--- : ININ_WDT
				;Bit7~3		+--------------	WE4~WE0 : WDT Control
				;			|				10101 : Disable
				;			|			  >	01010 : Enable
				;			|				Other : Reset MCU
				;Bit2~0	 	|+------------- WS2~WS0 : WDT time-out period selection
				;			||			    000 : 2^8/fLIRC
				;			||			  	001 : 2^10/fLIRC			
				;			||			  	010 : 2^12/fLIRC
				;			||			  	011 : 2^14/fLIRC												
				;			||			  	100 : 2^15/fLIRC
				;			||			  	101 : 2^16/fLIRC							
				;			||			  	110 : 2^17/fLIRC
				;			||			  >	111 : 2^18/fLIRC			
				MOV		A,01010111B
				MOV		WDTC,A					;ʹ�ܿ��Ź���ѡ���������Ϊ2^18/FLIRC(�ڲ�����ʱ��Ƶ��32KHz)=8.192s
				RET	
INITIAL_IO:		
				;------INIT PA I/O-----
				; 	   0 : Low
				;	   1 : High	
				MOV		A,01001001B		
				MOV		PA,A
				;------INIT PAC : Pin Type Selection-----
				; 	   0 : Output
				;	   1 : Inpur
				MOV		A,01000000B
				MOV		PAC,A
				;------INIT PAPU : Pin Pull-high -----
				; 	   0 : Disable
				;	   1 : Enable
				MOV		A,11111111B
				MOV		PAPU,A
				;------INIT PAWU : Pin Wake-up -----
				; 	   0 : Disable
				;	   1 : Enable
				CLR		PAWU
				MOV		A,01001100B			;�������Ź���UART��TX,RX
				MOV		PAS0,A
				MOV		A,00100000B
				MOV		PAS1,A
				;�����������
				MOV		A,10000000B
				MOV		ISGENC,A			;�����������ʹ�ܣ�ISINK1��ISINK0���ܣ��ȼ��ʱ����
				MOV		A,00000011B
				MOV		ISGDATA0,A			;ISINK0�Ĺ������mA��=50+10*3=100
				MOV		A,00000110B
				MOV		ISGDATA1,A			;ISINK0�Ĺ������mA��=50+5*6=100
				RET
				
;;��ʼ�������˷�
INITIAL_AFE:
				MOV		A,00100110B
				MOV		SDSW,A				;bit6~5:01 AC��ϣ�s6,s8�պϡ�bit4~0:SDS1,SDS2�պ�,
				MOV		A,00111111B
				MOV		SDPGAC0,A			;R1=63*100K��		R1��������ѹת����Ӱ�촫���������ȣ�R1Խ��������Խ��
				MOV		A,11011110B
				MOV		SDPGAC1,A			;R3=10K�� R2=30*100K��		OP1�Ŵ�������R2+R3��/R3    (3000+40)/40=76
				MOV		A,00000011B
				MOV		SDA0C,A				;�����˷�OPA0,bit1~0ѡ��OPA0�Ĵ��� 00:5KHz 01:40KHz 10:600KHz 11:2MHz
				MOV		A,00000011B
				MOV		SDA1C,A				;�����˷�OPA1,bit1~0ѡ��OPA1�Ĵ��� 00:5KHz 01:40KHz 10:600KHz 11:2MHz
				MOV		A,00000000B
				MOV		SDA0VOS,A
				MOV		A,00000000B
				MOV		SDA0VOS,A
				RET
;;��ʼ��ADC
INITIAL_ADC:
				MOV		A,00011111B
				MOV		SADC0,A
				MOV		A,01101101B
				MOV		SADC1,A				;bit7~5   010:OPA0O��Ϊ����		011:OPA1O��Ϊ����	
				SET		ADRFS				;����ADCת�����ݴ洢��ʽ
				;SET		VBGREN
				RET
								
;��ʼ��uart��
INITIAL_UART:
				MOV		A,00010000B
				MOV		SIMC0,A				;ѡ��UARTģʽ
				MOV		A,10000000B
				MOV		UUCR1,A				;UARTʹ�ܣ�TX��RX��ΪUART��������
				MOV		A,00000000B
				MOV		UUCR2,A				;UART���ͽ��ճ��ܣ����ͼĴ���Ϊ���ж�ʹ�ܣ�������ѡ�����ģʽ
				MOV		A,00001100B
				MOV		UBRG,A				;���ò�����8MHz/��64*��12+1����=9614.38  �����0.16%��
				RET

;У׼AFE�˷�			
CLBT_OPA:
;У׼�˷�0
				CLR		sdano_befor
				MOV		A,00100000B
				MOV		SDSW,A
				MOV		A,01000011B
				MOV		SDA0C,A
				MOV		A,11000000B
				MOV		SDA0VOS,A
				MOV		A,SDA0C
				AND		A,00100000B			;��ȡSDA0O
				;MOV		A,SDA0O
				MOV		sdano_befor,A
				;LSZ		SDA0O
				;SET		sdano_befor
CLBT_OPA0_0:				
				INC		SDA0VOS
				MOV		A,SDA0C
				AND		A,00100000B
				SUB		A,sdano_befor
				SZ		Z
				JMP		CLBT_OPA0_0
				MOV		A,SDA0VOS
				AND		A,00111111B
				MOV		sdaof_1,A
				
				MOV		A,11111111B
				MOV		SDA0VOS,A
				MOV		A,SDA0C
				AND		A,00100000B
				MOV		sdano_befor,A
CLBT_OPA0_1:				
				DEC		SDA0VOS
				MOV		A,SDA0C
				AND		A,00100000B
				SUB		A,sdano_befor
				SZ		Z
				JMP		CLBT_OPA0_1
				MOV		A,SDA0VOS
				AND		A,00111111B
				ADDM	A,sdaof_1
				RRA		sdaof_1
				MOV		SDA0VOS,A

;У׼�˷�1				
				MOV		A,00100000B
				MOV		SDSW,A
				MOV		A,01000011B
				MOV		SDA1C,A
				MOV		A,11000000B
				MOV		SDA1VOS,A
				MOV		A,SDA1C
				AND		A,00100000B
				MOV		sdano_befor,A
CLBT_OPA1_0:				
				INC		SDA1VOS
				MOV		A,SDA1C
				AND		A,00100000B
				SUB		A,sdano_befor
				SZ		Z
				JMP		CLBT_OPA1_0
				MOV		A,SDA1VOS
				AND		A,00111111B
				MOV		sdaof_1,A
				
				MOV		A,11111111B
				MOV		SDA1VOS,A
				MOV		A,SDA1C
				AND		A,00100000B
				MOV		sdano_befor,A
CLBT_OPA1_1:				
				DEC		SDA1VOS
				MOV		A,SDA1C
				AND		A,00100000B
				SUB		A,sdano_befor
				SZ		Z
				JMP		CLBT_OPA1_1
				MOV		A,SDA1VOS
				AND		A,00111111B
				ADDM	A,sdaof_1
				RRA		sdaof_1
				MOV		SDA1VOS,A
				RET
				