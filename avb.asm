code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
;
CR		EQU		13
LF		EQU		10
Space		EQU		20h
;+++++++++++++++++++++++++++++++++++++++++++++++++++++
print_letter	macro	letter
	push	AX
	push	DX
	mov	DL, letter
	mov	AH,	02
	int	21h
	pop	DX
	pop	AX
endm
;=====================================================
start:
	mov		SI,	offset	_str
	mov 	AH,	02	
	mov 	CX,16
_cycle1:		;	Вывод содержимого буфера до выполнения ф-ии 0Ah
		mov 	BL,	byte ptr [SI]
		mov 	DL,	BL
		rcr		DL,	4
		call 	print_hex
		mov		DL,	BL
		call	print_hex
print_letter	Space
		inc SI
    loop    _cycle1
print_letter	CR
print_letter	LF
;=====================================================
	mov		AH,	0Ah
	mov		DX,	offset	_str
	int		21h
	;
print_letter	CR
print_letter	LF
;=====================================================
	mov		SI,	offset	_str
	mov 	AH,	02
	mov 	CX,16
_cycle:
		mov 	BL,	byte ptr [SI]
		mov 	DL,	BL
		rcr		DL,	4
		call 	print_hex
		mov		DL,	BL
		call	print_hex
print_letter	Space
		inc SI
    loop    _cycle
;=====================================================
int 20h
;
print_hex	proc	near
	and	DL,0Fh
	add	DL,30h
	cmp	DL,3Ah
	jl	$print
	add	DL,07h
$print:	
	int	21H
   ret	
print_hex	endp	
;
_str	DB		14,?,14 dup (Space)
	code_seg ends
         end start
