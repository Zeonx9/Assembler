prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h
main:  
jmp begin

; consts
buf_len equ 1000h

; messages
s_exit  db "exit", 13, 10, '$'
s_ok    db "files opened", 13, 10, '$'
s_err   db "error", 13, 10, '$' 
s_srcf  db "enter source file name > ", '$'
s_rdok  db "input file has been read :", 13, 10, '$' 
s_prc   db "file has been processed :", 13, 10, '$'
s_fprmt db "enter file name > ", '$'
nl 		db 0dh, 0ah, '$'

; variables 
file_name   db 80, ?, 80 dup (?)
inbuf       db buf_len dup (?)
out1buf     db buf_len dup (?)
out2buf		db buf_len dup (?)
out1_name 	db "vowel.txt", 0
out2_name 	db "cons.txt", 0
vowels		db "aeouiyAEOIUY"
num_of_vows dw $ - vowels
handle_in  	dw ?
handle_out1 dw ?
handle_out2 dw ?
in_pos		dw ?
out1_pos	dw ?
out2_pos	dw ?
inbuf_size  dw 0
out1b_size  dw 0
out2b_size  dw 0

;macro
fout_open macro fname, handle
	local ok
	mov ax, 3d01h
	lea dx, fname
	int 21h ; open file to write
	jnc ok 
		jmp error
	ok:
		mov handle, ax ; save handle
endm fout_open

msg_print macro msg
	mov ah, 09h
	lea dx, msg
	int 21h ; print msg
endm msg_print   

put_word_in_buff macro bsize, pos
	pop cx
	add bsize, cx
	mov si, in_pos
	mov di, pos
	rep movsb
	mov byte ptr [di], ' ' 
	inc di
	inc bsize
	mov pos, di 
endm put_word_in_buff

fout_write macro handle, bsize, buf
	mov ah, 40h 
	mov bx, handle
	mov cx, bsize
	lea dx, buf
	int 21h ; write to file
endm fout_write

print_buffer macro bsize, buf
	mov bx, bsize
	mov buf[bx], '$'
	msg_print buf
	msg_print nl
endm print_buffer   

begin:   
    xor cx, cx
	mov cl, es:80h
	cmp cl, 0 		; if length of args is zero the get file names from keyboard
	jne cmd_args
		jmp no_args

	cmd_args:
		mov di, 81h 
		mov al, ' '
		repe scasb 	; skip spases
		dec di 	   	; put pointer back on first non-spase byte
		inc cx
		push di 	; save values into stack
		push cx
		repne scasb ; fing end of arg (til end or space)
		cmp cx, 0 	; if no spaces after arg then do not increment
		je count_arg_len
			inc cx 
		count_arg_len:
		mov ax, cx
		pop cx
		sub cx, ax 				; count real length of arg
		pop si 					; pointer to start of arg 
		lea di, file_name + 2 	; pointer to file name buffer
		mov file_name[1], cl 	; mov length of arg in 2nd byte
		rep movsb 				; copy to file name buffer
		jmp open_files

	no_args: 
		msg_print s_fprmt ; print prompt to enter name of file
		mov ah, 0ah
		lea dx, file_name
		int 21h 				; get file name from keyboard
		msg_print nl

	open_files:
		xor bx, bx
		mov bl, file_name[1]
		mov file_name[2 + bx], 0 			; make asciz (put 0 after)
		mov ax, 3d00h
		lea dx, file_name + 2 
		int 21h 							; open file to read
		jnc next_files
			jmp error
		next_files:
		mov handle_in, ax 					; save handle
		fout_open out1_name, handle_out1 	; open file for vowels
		fout_open out2_name, handle_out2 	; open file for consonants
		msg_print s_ok 						; print ok msg 

		mov ah, 3fh
		mov bx, handle_in
		mov cx, buf_len
		lea dx, inbuf
		int 21h 			; read everything from file to buffer
		mov inbuf_size, ax 	; save len of buffer
		msg_print s_rdok 	; print read ok msg
		msg_print nl 
		print_buffer inbuf_size, inbuf 		; print input buffer

		lea di, inbuf - 1
		mov cx, inbuf_size
		replace_non_letters:	; all non-letter characters are replaced to spaces
			inc di 
			cmp byte ptr [di], 'A'
			jl replace
			cmp byte ptr [di], 'z'
			jg replace
			cmp byte ptr [di], 'Z'
			jle no_replace
			cmp byte ptr [di], 'a'
			jge no_replace
			replace:
				mov byte ptr [di], ' '
			no_replace:
		loop replace_non_letters

		mov in_pos, offset inbuf
		mov out1_pos, offset out1buf
		mov out2_pos, offset out2buf
		mov cx, inbuf_size
		process_file:
			mov al, ' '
			mov di, in_pos
			repe scasb 				; skip spaces
			cmp cx, 0 				; if eof go to write
			je write			
				dec di 				; move to previous byte
				inc cx
				push cx 			; save remain file len in stack
				mov in_pos, di
				repne scasb 		; find end of word
				cmp cx, 0 			; if eof go increment cx
				je count_word_len
					inc cx
					dec di
				count_word_len:
				mov ax, cx
				pop cx 				; get ramain file len and push it back
				push ax
				sub cx, ax 			; count length of word
				push cx 			; save len of word in stack
				mov cx, num_of_vows
				xor bx, bx
				mov si, in_pos 		; pointer to first letter
				check_first_letter:
					mov dl, vowels[bx]
					cmp byte ptr [si], dl 					; go to section by type of current symbol 
					je vowel
					inc bx
				loop check_first_letter
				jmp consonant
				vowel:
					put_word_in_buff out1b_size, out1_pos	; copy word in buff, put space after it
					jmp contine_process
				consonant:
					put_word_in_buff out2b_size, out2_pos 
				contine_process:
					mov in_pos, si ; save current possiton
					pop cx 
					cmp cx, 0      ; if eof go to write
					je write
					jmp process_file
		write:
		msg_print s_prc 							; print prc msg
		print_buffer out1b_size, out1buf			; print vowels buffer
		print_buffer out2b_size, out2buf			; print consonants buffer
		fout_write handle_out1, out1b_size, out1buf ; write to file with vowels
		fout_write handle_out2, out2b_size, out2buf ; write to file with consonants	
		jmp exit
	error:
		msg_print s_err ; print error msg
	exit:
	msg_print s_exit 	; print exit msg
	mov ax, 4c00h
	int 21h				; int 21h
prog ends
end main