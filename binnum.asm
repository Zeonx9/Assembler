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
	call scan_bin_number  
	print newline
	log "entered number is: "
	push number 
	call print_bin_number
int 20h

; print out bin number 
print_bin_number proc 
	push bp
		mov bp, sp
	push ax
	push bx
	push cx
	push dx
		mov cx, 16
		mov bx, [bp + 4]
		mov ah, 2
		print_digit_bin:
			rol bx, 1
			mov dl, bl
			and dl, 1
			add dl, '0'
			int 21h
		loop print_digit_bin
	pop dx 
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
print_bin_number endp

; scan bin number from keyboard and assign it to a variable passed trough offset in stack
scan_bin_number proc 
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

		process_digit_bin:
		    shl dx, 1
			mov al, byte ptr [si]
			cmp al, '0'				; check if entered symbol can be a hex digit
			jl incorrect_input_bin	
			cmp al, '1'
			jg incorrect_input_bin
			
			sub al, '0'
			add dx, ax
			inc si
		loop process_digit_bin

		mov di, [bp + 4] ; save result in given variable
		mov [di], dx
	pop di 
	pop si 
	pop dx
	pop cx 
	pop ax 
	pop bp
	ret 2
		input db 17, ?, 17 dup(0)
	incorrect_input_bin:
		log "your input is incorrect, only 0-9 and A-F symbols can be a hex digit."
		int 20h
scan_bin_number endp

prog ends
end main