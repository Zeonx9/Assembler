;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CR	EQU	13
LF	EQU	10
SPACE	EQU	20h
;==================================================================================
;=============================macro=================================
Print_Word_dec	macro	src	, mes	;	выводит на экран источник src в десятичном виде
local	l1, l2, ex
;
push	AX
push	BX
push	CX
push	DX
;print_letter	CR
;print_letter	LF
;print_mes	mes
	mov		AX,	src					;	Выводимое число в регисте EAX
	push		-1					;	Сохраним признак конца числа
	mov		cx,	10					;	Делим на 10
l1:	
	xor		dx,	dx					;	Очистим регистр dx 
	div		cx						;	Делим 
	push		DX						;	Сохраним цифру
	or 			AX,	AX				;	Остался 0? (это оптимальнее, чем  cmp	ax,	0 )
	jne		l1						;	нет -> продолжим
	mov		ah,	2h
l2:	
	pop		DX						;	Восстановим цифру
	cmp		dx,	-1					;	Дошли до конца -> выход {оптимальнее: or EDX,dx jl ex}
	je			ex
	add		dl,	'0'					;	Преобразуем число в цифру
	int		21h						;	Выведем цифру на экран
	jmp	l2							;	И продолжим
ex:	
print_mes	mes
pop		DX
pop		CX
pop		BX
pop		AX
;
endm
;=============================================================
LookForbyte	macro	What, StartAddr, MaxLenght, Direction
	local	nxt
	;
	push	ES
	push	DS
	pop		ES
;
ifnb	<Direction>
	std
endif
ifb	<Direction>
	cld
endif
	mov		CX,		MaxLenght
	mov		DI,		StartAddr						; ES:DI-> начало буфера
	mov 	AL,		What        					; Ищем What
repne    scasb   									; AL - (ES:DI) -> флаги процессора
													; повторять пока элементы не равны
													; DI-> на  What
													; if CX =0 - not found!
ifnb	<Direction>
	inc		DI
endif
ifb	<Direction>
	dec 	DI
endif													
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cmp		CX,		0
	jne	nxt						
	stc												; not found
nxt:
	pop		ES
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_byte	macro	src
	local	nxt, prn_hex,prnt
	pushf
	pusha
	;push	AX
	;push	DX
	;
	mov		BL,	src
    mov     DL,		BL
	shr		DL,		4
	call 	prn_hex
    mov 	DL,		BL
	call	prn_hex
;
	jmp short nxt
;
prn_hex	proc	near
	and		DL,		0Fh
	add		DL,		30h
	cmp		DL,		3Ah
	jl		prnt
	add		DL,		07h
prnt:		
	mov 	AH,		02
	int		21h
	ret
prn_hex	endp	
nxt:
	popa
	popf
;pop		DX
;pop		AX
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_word	macro	src
;
	pusha
	;push	AX
	;push	DX
	;
	mov		DX,		src
	print_byte		DH
	mov		DX,		src
	print_byte		DL
;
	popa
;pop		DX
;pop		AX
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_dword	macro	src
;
	pushf
	push	EAX
	push	EDX
	;
	mov		EDX,	src
	shr 	EDX,	16
	print_word		DX
	mov		EDX,	src	
	print_word		DX
;
pop		EDX
pop		EAX
popf
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_all_reg macro
;
print_CRLF
print_mes	' AX = '
print_word		AX	
;
print_mes	'	'
print_mes	' BX = '
print_word		BX	
;
print_mes	'	'
print_mes	' CX = '
print_word		CX	
;
print_mes	'	'
print_mes	' DX = '
print_word		DX	
;

print_CRLF
print_mes	' SI = '
print_word		SI	
;
print_mes	'	'
print_mes	' DI = '
print_word		DI	
;
;
print_CRLF
print_mes	' DS = '
print_word		DS	
;
print_mes	'	'
print_mes	' ES = '
print_word		ES	

;
print_mes	'	'
print_mes	' SS = '
print_word		SS	
;
print_CRLF
;print_mes	'	'
print_mes	' BP = '
print_word		BP	
print_mes	'	'
print_mes	' SP = '
print_word		SP
;
;
endm
;=================================================================
print_field	macro	StartAddr, EndAddr
	local	cycl, m1,m2
	pushf
	pusha
	mov		AX,		EndAddr
	mov		BX,		StartAddr
	sub		AX,		BX
	cmp		AX,	0
	jg		m2
	jmp		m1
m2:
	mov		CX,		AX
	mov 	SI,		StartAddr		; 
cycl:

    mov BL,byte ptr [DS:SI]
print_byte	BL
;
print_letter SPACE
;
   ;inc SI
    ;mov BL,byte ptr [DS:SI]
;print_byte	BL
;

;
    inc SI
;    inc SI
    loop    cycl
print_letter SPACE
print_letter SPACE
print_letter SPACE
PRINT_CRLF

m1:
	popa
	popf
	endm
;===================================================================================
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cond	macro	what, met
		ifidn	<what>,<{>
		jb met
	endif
		ifidn	<what>,<}>
		ja met
	endif
	ifidn	<what>,<=>
		je met
	endif
	ifidn	<what>,<{}>
		jne met
	endif
	endm
if_	macro	reg8, codition,	limit,	metka
;
	cmp	reg8,	limit
	cond	condition, metka
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if_ah	macro	condition,	limit,	metka
;
	cmp	AH,	limit
	cond	condition, metka
	endm	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ret_false	macro
		stc
		ret
	endm
ret_true	macro
		clc
		ret
endm
;
;
;-----------------------------------------------------------------------------;;
;
PRINT_CRLF     macro    
    push    AX
    push    DX
        mov DL,13
        mov AH,02
        int 21h ; print CR
        mov DL,10
        mov AH,02
        int 21h ; print LF
    pop    DX
    pop    AX
      ENDm
;
;-----------------------------------------------------------------------------;
print_mes	macro	message
	local	msg, nxt,m2,m3
	pusha
	lea		DX,		msg
	mov	AH,	09h
	int	21h
	popa
	jmp nxt
	msg	DB message,'$'
	nxt:
	endm
;-----------------------------------------------------------------------------;
Delete_file	macro	file_name
	local	msg, nxt
	push	AX
	push	DX
	mov	DX, offset msg
	mov	AH,	41h
	int	21h
	pop	DX
	pop	AX
	jmp nxt
	msg	DB file_name,0
	nxt:
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OpenFile	macro	field, file_name, handler
	local	nxt, nxt1,m1,mmmm
	CLC
	push	AX
	push	BX
	push	DX
	mov	AX,	3D02h		; Open file for read/write
;
ifnb	<field>
	mov	dx, offset file_name
endif
ifb	<field>
	mov	DX, file_name
endif
;
	int	21h
	jc	nxt
	jmp	nxt1
nxt:	
PRINT_CRLF 
print_word AX
print_mes	'openER!R'
exit
;
nxt1:
PRINT_CRLF 
print_mes	'openOK!'
;
;PRINT_CRLF
;print_mes 'AX='
;print_word	AX
	mov	handler,	AX
;
	pop	DX
	pop	BX
	pop	AX
;
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ReadFile	macro	Handler,	Buffer,	Counter, RealRead
local 		read_error,	nx,m1
;
; RealRead     number of bytes actually read
;
clc
	pusha
		MOV BX,		Handler  	;                             }
		MOV	CX,		Counter		; number reading bytes        } for READ_FILE
		LEA DX,		Buffer     
		MOV	AH,3FH		; function - read file
		INT	21H		; read file
print_CRLF
print_mes	' BX = '
print_word		BX
print_mes	'	'
print_mes	' CX = '
print_word		CX
print_mes	'	'
print_mes	' DX = '
print_word		DX
		JnC	m1
		jmp	read_error
m1:
		mov	RealRead,	AX
		PRINT_CRLF
		print_mes	' RealRead = '
		print_word	AX	
		jmp	nx
read_error:
		PRINT_CRLF
		print_mes	' ** ReadError '
		print_word	AX	
		
nx:			popa
	ENDm
;====================================================================
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WriteFile	macro	Handler,	Buffer,	Counter, RealWrite
local 		Write_error,	m2,m1
;
; RealWrite     number of bytes actually Write
;
clc
	pusha
		MOV BX,		Handler  	;                             }
		MOV	CX,		Counter		; number Writeing bytes        } for Write_FILE
		LEA DX,		Buffer     
		MOV	AH,40H		; function - Write file
		INT	21H		; Write file
		JnC		m1
		jmp	Write_error
m1:
		mov	RealWrite,	AX
		PRINT_CRLF
		print_mes	' RealWrite = '
		print_word	AX	
		jmp	m2
Write_error:
		PRINT_CRLF
		print_mes	' ** WriteError '
		print_word	AX	
		
m2:			popa
	ENDm
;====================================================================
print_letter	macro	letter
	push	AX
	push	DX
	mov	DL, letter
	mov	AH,	02
	int	21h
	pop	DX
	pop	AX
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
exit	macro
	mov		AX,	4C00h
	int		21h
endm

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; macro;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_vector	macro	vector, DD_for_save_vector   
	pusha
	push	ES
		mov AX,35&vector                     	 	;  получить вектор прерывания
		int 21h                           			;  
		mov word ptr DD_for_save_vector,		BX 	;  ES:BX - вектор
		mov word ptr DD_for_save_vector+2,		ES  	;
	pop		ES
	popa
endm
;	
set_vector	macro	vector,	handler
    mov DX,offset handler      ;  получить смещение точки входа в новый
;                              ;  обработчик на DX
    mov AX,25&vector           ;  функция установки прерывания
;                              ;  изменить вектор 
    int 21h  							; 	AL - номер прерыв. 
											;	DS:DX - указатель программы обработки прер.
endm
;
recovery_vector	macro	vector,	DD_for_save_vector
	pusha
	push	ES
	push	DS
    lds    DX, 	CS:DD_for_save_vector   
    mov 		AX,	25&vector        ; Заполнение вектора старым содержимым
    int    21h	
	
	pop		DS						;	DS:DX - указатель программы обработки прер.
	pop		ES
	popa
endm
;
;==================================================================================
start_time	macro	saved_vector_1Ch, count
local	nxt, new_1Ch
get_vector	1Ch,	saved_vector_1Ch
set_vector	1Ch,	new_1Ch
;
jmp nxt
new_1Ch	proc	far
		pushf
		inc		CS:count
		print_mes '*'
		popf
		jmp		dword ptr CS:	[saved_vector_1Ch]
new_1Ch	endp	
nxt:
;
endm
;
finish_time	macro	saved_vector, count
local	nxt, old_1Ch,new_1Ch
;
recovery_vector	1Ch,	saved_vector
			Print_Word_hex	count
;
endm
;
;
Print_Word_hex	macro	src	;	выводит на экран источник src в hex виде
local	next, print_DL, print_hex, print_, msg
;CR	EQU	13
;LF	EQU	10
push	AX
push	BX
push	CX
push	DX
;
			mov DX,offset msg  ; CR+LF
			mov 	AH,	09h
			int	21h
;			
	mov		BX,	src
	mov 		AH,02
   mov     DL,BH
	;rcr		DL,4
	call 		print_DL
   ;mov 		DL,BH
	;call		print_hex
;
	mov 		DL,BL
	;rcr		DL,4
	call 		print_DL
	;mov		DL,BL
	;call		print_hex
;
pop		DX
pop		CX
pop		BX
pop		AX
jmp	next
;
;
print_DL	 proc	near
	push		DX
	rcr		DL,4
	call 		print_hex
   ;mov 		DL,BH
   pop		DX
	call		print_hex
   ret
print_DL	 endp		
;
print_hex	proc	near
	and	DL,	0Fh
	add	DL,	30h
	cmp	DL,	3Ah
	jl		print_
	add	DL,	07h
print_:	
	int	21H
   ret
print_hex	endp	
;
msg	DB	CR,LF,'runtime:','$'
next:
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
old_1Ch       DD  ?
;old_08h       DD  ?
time_count				DW	?
;;;;;;;;;;;;;;;;;;;;;;;;;;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
