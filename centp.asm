prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h

main: 
	xor ch, ch
	mov cl, es:80h
	cmp cl, 0 ; if length of args is zero the get file names from keyboard
	jne cmd_args
		jmp no_args

	cmd_args:

	    mov di, 81h 
		mov al, ' '
		repe scasb ; strip lead spases
		dec di 	   ; di now is right after first byte of arg
		inc cl     ; put cl & di on prev byte
		mov dx, di ; save in dx
		call make_next_arg_asciz

		push dx
		push 0
		push offset handle_in
		call fopen ; open first file to read

		cmp cl, 0
		je open_second      
        	mov dx, di
			call make_next_arg_asciz
		open_second:
		push dx 
		push 1
		push offset handle_out
		call fopen ; open second to write
		jmp files_open

	no_args: 
		mov ah, 09h
		mov dx, offset s_srcf
		int 21h
		push offset fnbuf
		push 0
		call gets ; get file name from keyboard 
		call newline
		push offset fnbuf + 2
		push 0
		push offset handle_in
		call fopen ; open to read

		mov ah, 09h
		mov dx, offset s_dstf
		int 21h
		push offset fnbuf
		push 0
		call gets ; get second file from keyboard
		call newline
		add sp, 4 ; clear 2 words from stack
		push offset fnbuf + 2
		push 1
		push offset handle_out
		call fopen ; open to write

	files_open:
		mov ah, 09h
		lea dx, s_ok
		int 21h ; print ok msg 

		mov ah, 3fh
		mov bx, handle_in
		mov cx, 400h
		lea dx, inbuf
		int 21h ; read all from file
		mov inbuf_size, ax
		push inbuf_size

		mov ah, 09h
		lea dx, s_lr
		int 21h ; print lr msg
		call newline

		mov bx, inbuf_size
		mov inbuf[bx], '$'
		mov ah, 09h
		lea dx, inbuf
		int 21h ; print in buffer
		call newline

		mov cur_in_p, offset inbuf
		mov cur_out_p, offset outbuf

		process_line:
			mov di, cur_in_p
			mov cx, str_len
			mov al, 0ah
			repne scasb ; find end of line
			push cx

			mov bl, 2
			mov ax, cx
			div bl ;  count how much spaces needed
			mov cl, al
			add outbuf_size, cx
			lea si, space_s
			mov di, cur_out_p
			rep movsb ; put spases into out buffer

			mov si, cur_in_p
			mov cx, str_len
			pop ax
			sub cx, ax ; count length of line
			sub inbuf_size, cx
			rep movsb ; put line into out buffer
			mov cur_out_p, di
			mov cur_in_p, si ; save indexes
			cmp inbuf_size, 0 ; if no more lines then write else repeat cycle
			je write
				jmp process_line

		write:
			pop cx
			add outbuf_size, cx
			mov inbuf_size, cx 
			
			mov ah, 09h
    		lea dx, s_prc
    		int 21h ; print prc msg
    		call newline
    
    		mov bx, outbuf_size
    		mov outbuf[bx], '$'
    		mov ah, 09h
    		lea dx, outbuf
    		int 21h ; print out buffer
    		call newline

		    mov ah, 40h 
			mov bx, handle_out
			mov cx, outbuf_size
			mov dx, offset outbuf
			int 21h ; write to file
		jmp exit

	error:
		mov ah, 09h
		lea dx, s_err
		int 21h ; print error msg

	exit:
	mov ah, 09h
	lea dx, s_exit
	int 21h
	mov ax, 4c00h
	int 21h

; messages
s_exit  db "exit", 13, 10, '$'
s_ok    db "files opened", 13, 10, '$'
s_err   db "error", 13, 10, '$' 
s_srcf  db "enter source file name > ", '$'
s_dstf  db "enter destination file name > ", '$'
s_lr    db "input file has been read: ", 13, 10, '$'  
s_prc   db "file has been processed: ", 13, 10, '$'

; consts
str_len equ 80
buf_len equ 1000h

; variables
handle_in  	dw ?
handle_out 	dw ?
inbuf_size 	dw 0
outbuf_size dw 0
fnbuf      	db str_len, ?, str_len dup(?)
space_s    	db str_len dup (' ')
outbuf     	db buf_len dup (?)
inbuf      	db buf_len dup (?)
cur_in_p   	dw ?
cur_out_p  	dw ?


;procedures
fopen proc near 
	; [bp + 8] offset of asciz string - file name
	; [bp + 6] mode of opening
	; [bp + 4] offset of variable to save handle  
	push  bp
	mov bp, sp
	push di
	push dx
	push ax
		mov ah, 3dh
		mov al, byte ptr [bp + 6] ; choose mode of opening
		mov dx, [bp + 8]
		int 21h ; open file in given mode with given name
		jnc ok
			jmp error
		ok: 
			mov di, [bp + 4]
			mov [di], ax ; save handle to given var
	pop ax
	pop dx
	pop di
	pop bp
	ret 6 ; clear 3 words in stack and return
fopen endp

gets proc near
	; [bp + 6] offset of buffer to scan 
	; [bp + 4] terminal symbol
	push bp
	mov bp, sp
	push di
	push ax
	push dx
	push bx
		mov ah, 0ah
		mov di, [bp + 6] 
		mov dx, di
		int 21h ; input from keyboard
		xor bh, bh
		mov bl, byte ptr[di + 1]
		mov dl, byte ptr[bp + 4]
		mov byte ptr [di + bx + 2], dl ; put terminal char
	pop bx
	pop dx
	pop ax
	pop di
	pop bp
	ret 4
gets endp

make_next_arg_asciz proc near
	; di should contain offset of end of prev arg or 81h for first
	; cl should contain number of ramaining bytes
	; puts di right after arg when return
	mov al, ' '
	repne scasb ; find end of string  
	cmp cl, 0 ; if end of args do not increment
	je put_terminal
		dec di 
		inc cl
	put_terminal:
	mov byte ptr [di], 0 ; put 0 after arg
	cmp cl, 0 ; if end of args do not increment
	je end_of_p3
		inc di  
		dec cl
	repe scasb ; skip spases after arg
	cmp cl, 0 ; if end of args do not increment
	je end_of_p3
		dec di
		inc cl 	   
	end_of_p3:     
	ret
make_next_arg_asciz endp

newline proc near
	mov ah, 09h
	mov dx, offset nl
	int 21h ; print new line chars
	ret
	nl db 13, 10, '$'
newline endp


prog ends
end main