prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h
main:  
jmp begin

; variables
newline	db 0dh, 0ah, '$'
handle 	dw ?
w		db 0
h		db 0
colour	db 0
next	db 0
shape	db 2000 dup (' ')
fill	db 80 dup (178)
inp		db 3, ?, 3 dup (?)

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

newline_buff macro
	mov byte ptr [di], 13
	inc di 
	mov byte ptr [di], 10
	inc di
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

		call rand_seed 	; initialize random

		draw_rect:
		call rand_next
		in_range w, next, 1, 78
		call rand_next
		in_range h, next, 1, 24 
		call rand_next
		in_range colour, next, 17, 255

		mov ax, 0700h 	; scroll up iterrupt
		mov bh, colour 	; set text colour
		xor cx, cx
		mov dx, 184fh
		int 10h 		; clear the sreen

		xor ch, ch
		lea di, shape

		mov cl, h
		copy_line:
			push cx
			mov cl, w
			lea si, fill
			rep movsb
			newline_buff
			pop cx
		loop copy_line
		mov byte ptr [di], '$'
		print shape

		mov ah, 0ah
		lea dx, inp
		int 21h ; wait for input
		cmp inp[2], 13
		je write
			jmp exit
		write:

		xor ah, ah
		mov al, w
		add al, 2
		mov bl, h
		mul bl
		mov cx, ax ; count symbols to write
		mov ah, 40h 
		mov bx, handle
		lea dx, shape
		int 21h ; write to file

		jmp draw_rect

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

prog ends
end main