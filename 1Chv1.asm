CODE_SEG	SEGMENT
		ASSUME	CS:CODE_SEG,DS:CODE_SEG,SS:CODE_SEG
		ORG	100H
START:
jmp BEGIN

; macro
print_letter macro letter
	push AX
	push DX
		mov	DL, letter
		mov	AH,	02
		int	21h
	pop	DX
	pop	AX
endm
	
get_vector macro vector, old_vector    
	push BX
	push ES
		mov AX, 35&vector        			
		int 21h                           	; получить вектор прерывания
		mov word ptr old_vector, BX 		; ES:BX - вектор
		mov word ptr old_vector + 2, ES  	
	pop	ES
	pop	BX
endm

set_vector	macro vector, isr
    mov DX, offset isr      		; получить смещение точки входа в новый  обработчик на DX
    mov AX, 25&vector           	; функция установки прерывания 
    int 21h  						; изменить вектор AL - номер прерыв. DS:DX - ук-ль программы обр. прер.
endm

recovery_vector	macro vector, old_vector
	push DS
	    lds DX, CS:old_vector   
	    mov AX, 25&vector       ; Заполнение вектора старым содержимым
	    int 21h					; DS:DX - указатель программы обработки пр
	pop	DS														
endm

old_1Ch DD ?

BEGIN:
	get_vector 1Ch, old_1Ch
	set_vector 1Ch, new_1Ch
	mov	CX, 30
	c:
		xor	AX,	AX
		go:
			inc	AX
			cmp	AX,	0
			jne	go
	loop c  			; долгий цикл, чтобы несколько раз вызвались прерывания таймера (1Ch)

	recovery_vector	1Ch, old_1Ch
	print_letter 'D'

	mov	AX,	4C00h
	int	21h

new_1Ch	proc far
	print_letter 'A'
	jmp	dword ptr CS:[old_1Ch]
new_1Ch	endp	

CODE_SEG    ENDS
END START