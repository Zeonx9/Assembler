code_seg segment
	assume cs:code_seg,ds:code_seg,ss:code_seg
	org 100h

print_mes macro	message
	local msg, nxt
	push AX
	push DX
		mov	DX, offset msg
		mov	AH,	09h
		int	21h
	pop	DX
	pop	AX
	jmp nxt
		msg	DB message,'$'
	nxt:
endm

start:
    xor AX,AX
    mov ES,AX
    mov BX,65h
    shl BX,2

    lea dx, new_65h ; offset of interuption processer
    mov ax, 2565h ; 25h for set vector, 65 is number of set vector
    int 21h ; set new interruption vector to 65h

    int 65h ; call interruption 
	int	20h ; exit

new_65h proc far
	print_mes "hello world!"
    iret
new_65h endp

code_seg ends
end start
