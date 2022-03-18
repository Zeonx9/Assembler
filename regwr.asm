prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h
main:  
jmp begin

; variable
input db 5, ?, 5 dup (?)
newline db 13, 10, '$'

; macro
print macro msg
	mov ah, 09h
	lea dx, msg
	int 21h ; print msg
endm

log macro msg
	local m, c
	jmp c
		m db msg, '$'
	c:
		print m
endm

; task is to write number in register (bx), and then print it back
begin:
	log "enter 4 hex digits > "
	mov ah, 0Ah
	lea dx, input ; get input from the keyboard 
	int 21h
	print newline

	xor bx, bx ; write 4-digit hex-number in bx register
	xor ax, ax
	lea si, input + 2
	mov cx, 4
	put_in_number_in_reg:
		shl bx, 4
		mov al, byte ptr [si]

		cmp al, '0'
		jl incorrect_input	; check if entered symbol can be a hex digit
		cmp al, 'F'
		jg incorrect_input
		cmp al, 'A'
		jge ok
		cmp al, '9'
		jg incorrect_input

		ok:
		cmp al, 'A'
		jl zero_nine
			sub al, 37h	; 37h = 'A' (41h) - 10 (0Ah)
			jmp nxt_
		zero_nine:
			sub al, '0'
		nxt_:
			add bx, ax
		inc si
	loop put_in_number_in_reg

	log "value in bx: "
	mov dl, bh
	call print_byte_from_dl
	mov dl, bl
	call print_byte_from_dl
int 20h
	
incorrect_input:
	log "your input is incorrect, only 0-9 and A-F symbols can be a hex digit."
int 20h

print_byte_from_dl proc 
	push ax
	push bx
	push dx
		mov ah, 2
		lea bx, digits
		mov al, dl 
		shr al, 4
		xlatb
		push dx
		mov dl, al
		int 21h
		pop dx
		mov al, dl 
		and al, 0fh
		xlatb 
		mov dl, al 
		int 21h
	pop dx
	pop bx
	pop ax
	ret
		digits db "0123456789ABCDEF"
print_byte_from_dl endp

prog ends
end main