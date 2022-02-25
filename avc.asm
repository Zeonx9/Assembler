;+---------------------------------------------------------------------
;	В ответ на приглашение программа просит ввести имя файла
;	Пользователь вводит имя файла без пробела
;+---------------------------------------------------------------------
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
print_letter	CR
print_letter	LF
print_mes	'Input File Name > '	
	mov		AH,	0Ah
	mov		DX,	offset	FileName
	int		21h
print_letter	CR
print_letter	LF
;===========================================================================
	xor	BH,	BH
	mov	BL,  FileName[1]
	mov	FileName[BX+2],	0
;===========================================================================
	mov	AX,	3D02h		; Open file for read/write
	mov	DX, offset FileName+2
	int	21h
	jnc	openOK
print_letter	CR
print_letter	LF
print_mes	'openERR'
	int	20h
;===========================================================================
openOK:
print_letter	CR
print_letter	LF
print_mes	'openOK'
	mov		AX,	4C00h
	int 	21h
;
FileName	DB		14,0,14 dup (0)
	code_seg ends
         end start
	
	