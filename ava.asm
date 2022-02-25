;+--------------------------------------------------------------------------
code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
;
CR		EQU		13
LF		EQU		10
Space	EQU		20h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_letter	macro	letter
	push	AX
	push	DX
	mov	DL, letter
	mov	AH,	02
	int	21h
	pop	DX
	pop	AX
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_mes	macro	message
	local	msg, nxt
	push	AX
	push	DX
	mov	DX, offset msg
	mov	AH,	09h
	int	21h
	pop	DX
	pop	AX
	jmp nxt
	msg	DB message,'$'
	nxt:
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;========================================================================
start:
	mov		SI,	offset	FileName
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
;===========================================================================
print_mes	'Input File Name > '	
mov		AH,	0Ah
	mov		DX,	offset	FileName
	int		21h
	;
print_letter	CR
print_letter	LF
;===========================================================================
	mov		SI,	offset	FileName
	mov 	AH,	02
	mov 	CX,16
_cycle:				;	Вывод содержимого буфера после выполнения ф-ии 0Ah
		mov 	BL,	byte ptr [SI]
		mov 	DL,	BL
		rcr		DL,	4
		call 	print_hex
		mov		DL,	BL
		call	print_hex
print_letter	Space
		inc SI
    loop    _cycle
;===========================================================================
;	
	xor	BH,	BH
	mov	BL,  FileName[1]
	mov	FileName[BX+2],	0
;
print_letter	CR
print_letter	LF
;===========================================================================
	mov		SI,	offset	FileName
	mov 	AH,	02
	mov 	CX,16
_cycl:				;	Вывод содержимого буфера после выполнения ф-ии 0Ah
		mov 	BL,	byte ptr [SI]
		mov 	DL,	BL
		rcr		DL,	4
		call 	print_hex
		mov		DL,	BL
		call	print_hex
print_letter	Space
		inc SI
    loop    _cycl
;===========================================================================
;
	mov	AX,	3D02h		; Open file for read/write
	mov	DX, offset FileName+2
	int	21h
	jnc	openOK
print_letter	CR
print_letter	LF
print_mes	'openERR'
	int	20h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
openOK:
print_letter	CR
print_letter	LF
print_mes	'openOK'
	mov		AX,	4C00h
	int 	21h
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
FileName	DB		14,0,14 dup (0)
	code_seg ends
         end start
	
	