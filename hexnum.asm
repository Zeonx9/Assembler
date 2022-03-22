prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h
main:  
jmp begin

; variables
newline db 13, 10, '$'
number dw 0

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
	log "enter bin number > "
	push offset number 
	call scan_hex_number  
	print newline
	log "entered number is: "
	push number 
	call print_hex_number
int 20h

; print out hex number 
print_hex_number proc 
	push bp
		mov bp, sp
	push ax
	push bx
	push cx
	push dx
		mov cx, 4
		mov bx, [bp + 4]
		mov ah, 2
		print_digit_bin:
			rol bx, 4
			mov al, bl
			and al, 0Fh
			push bx
				lea bx, digits
				xlatb
			pop bx
			mov dl, al
			int 21h

		loop print_digit_bin
	pop dx 
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
		digits db "0123456789ABCDEF"
print_hex_number endp

; scan hex number from keyboard and assign it to a variable passed trough offset in stack
scan_hex_number proc 
	push bp
		mov bp, sp
	push ax
	push cx
	push dx
	push si 
	push di 
		mov ah, 0Ah
		lea dx, input
		int 21h 		; get input from keyboard
		xor ax, ax
		xor dx, dx
		xor cx, cx 
		mov cl, input[1]
		lea si, input + 2

		process_digit_hex:
		    shl dx, 4
			mov al, byte ptr [si]
			cmp al, '0'				; check if entered symbol can be a hex digit
			jl incorrect_input_hex	
			cmp al, 'F'
			jg incorrect_input_hex
			cmp al, 'A'
			jge ok
			cmp al, '9'
			jg incorrect_input_hex
			
			ok:
			cmp al, 'A'
			jl zero_nine
				sub al, 37h	; 37h = 'A' (41h) - 10 (0Ah)
				jmp nxt_
			zero_nine:
				sub al, '0'
			nxt_:
				add dx, ax
			inc si
		loop process_digit_hex

		mov di, [bp + 4] ; save result in given variable
		mov [di], dx
	pop di 
	pop si 
	pop dx
	pop cx 
	pop ax 
	pop bp
	ret 2
		input db 5, ?, 5 dup(0)
	incorrect_input_hex:
		log "your input is incorrect, only 0-9 and A-F symbols can be a hex digit."
		int 20h
scan_hex_number endp

prog ends
end main