prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h
main:  
jmp begin

; variables
newline	db 0dh, 0ah, '$'
handle 	dw ?
w		db ?
h		db ?
colour	db ?
next	db ?
inp		db 3, ?, 3 dup (?)
buffer	db 5000h dup (?)
buflen  dw 0

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

logn macro msg
	local m, c
	jmp c
		m db msg, 13, 10,'$'
	c:
		print m
endm

in_range macro dest, num, min, max
	xor ah, ah
	mov al, num
	mov bl, max
	sub bl, min ; length of range
	div bl
	add ah, min ; shift range
	mov dest, ah
endm

mcopy_str macro s
	local m, c
	jmp c
		m db s, 0 
	c:
		lea si, m
		call pcopy_str
endm

copy_newline macro
	mov byte ptr [di], 13
	inc di
	mov byte ptr [di], 10
	inc di
endm

push_byte macro b
	xor bh, bh
	mov bl, b
	push bx
endm

begin:   
    xor cx, cx
	mov cl, es:80h
	cmp cl, 0 		; if length of args is zero the get file names from keyboard
	jne cmd_args
		logn "file name should be in command line arguments!"
		jmp exit

	cmd_args:
		mov di, 81h 
		mov al, ' '
		repe scasb 	; skip spases
		dec di
		inc cx
		push di		; save start of file name to stack
		repne scasb ; fing end of arg (til end or space)
		cmp cx, 0 	; if no spaces after arg then do not increment
		je count_arg_len
			dec di
		count_arg_len:
		mov byte ptr [di], 0
		mov ax, 3d01h
		pop dx
		int 21h 		; open file to write
		jnc open_ok
			logn "cannot open file!"
			jmp exit
		open_ok:
		mov handle, ax 	; save file handle
		logn "file opened successfuly!"

		logn "enter blank line (only ENTER character) to save current rectangle and continue"
		logn "or enter any character to exit."
		mov ah, 0ah
		lea dx, inp
		int 21h ; wait for input

		call rand_seed 	; initialize random
		lea di, buffer

		draw_rect:
			call rand_next
			in_range w, next, 1, 78
			call rand_next
			in_range h, next, 1, 24 
			call rand_next
			in_range colour, next, 1, 16

			mov ax, 0700h  		
			mov bh, 07h 	
			xor cx, cx
			mov dx, 184fh
			int 10h 		; clear the sreen

			xor ch, ch
			mov cl, h
			copy_line:
				push cx
				mov ah, 09h ; write character
				mov al, 178
				xor bh, bh  ; 0 page 
				mov bl, colour
				xor ch, ch
				mov cl, w 	
				int 10h 	; print line of colored chars
				print newline
				pop cx
			loop copy_line

			mov ah, 0ah
			lea dx, inp
			int 21h ; wait for input
			cmp inp[2], 13
			je write_to_buff
				jmp write_to_file

			write_to_buff:
			mcopy_str "Rectangle: "
			copy_newline 
			mcopy_str "width:  "
			push_byte w
			call num_to_str_dec
			copy_newline
			mcopy_str "height: "
			push_byte h
			call num_to_str_dec
			copy_newline
			mcopy_str "colour: "
			push_byte colour
			call num_to_str_dec
			copy_newline
			copy_newline

			mov buflen, di
			sub buflen, offset buffer
		jmp draw_rect

		write_to_file:
			mov ah, 40h 
			mov bx, handle
			mov cx, buflen
			lea dx, buffer
			int 21h ; write whats in buffer to file

	exit:
	print newline
	logn "exit"	
	mov ax, 4c00h
	int 21h	; exit

rand_next proc
	xor ah, ah
	mov al, next
	mov bl, a_
	mul bl
	add al, c_
	mov bl, m_
	div bl
	mov next, ah
	ret
		a_ db 17
		c_ db 31
		m_ db 251
rand_next endp

rand_seed proc
	mov ah, 0h
	int 1ah ; get system time (int cx:dx)
	mov next, dl
	ret
rand_seed endp

; di - destination offset; si - source offset; si points to asciz string
pcopy_str proc 
	start_:
	cmp byte ptr [si], 0
	je end_
		mov dl, byte ptr [si]
		mov byte ptr [di], dl
		inc si
		inc di
	jmp start_
	end_:
	ret
pcopy_str endp

; di - destination str offset, number in stack
num_to_str_dec proc 
	push bp
	mov bp, sp
		xor dh, dh
		mov dl, byte ptr [bp + 4]
		mov bl, 10
		xor cx, cx
		put_dig_in_stack:
			mov ax, dx
			div bl
			mov dl, ah 
			push dx
			inc cx
			mov dl, al
			cmp dl, 0
			je move_dig_to_str
			jmp put_dig_in_stack

		move_dig_to_str:
		pop dx
		add dl, '0'
		mov byte ptr [di], dl
		inc di
		loop move_dig_to_str
	pop bp
	ret 2
num_to_str_dec endp

prog ends
end main