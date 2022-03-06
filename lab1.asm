prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h
main:  
jmp begin

; struc
File struc
	handle 	dw ?
	len		dw 0
	pos		dw 0 
	fbuf 	db 1000h dup (?)
File ends

; variables 
inp_file File <>
vow_file File <>
con_file File <>
inp_fname   db 80, ?, 80 dup (?)
vow_fname 	db "vowel.txt", 0
con_fname 	db "cons.txt", 0
vowels		db "aeouiyAEOIUY"
num_of_vows dw $ - vowels
newline		db 0dh, 0ah, '$'

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
	log msg
	print newline
endm

copy_word macro file_
	pop cx
	add file_.len, cx
	mov si, inp_file.pos
	mov di, file_.pos
	rep movsb
	mov byte ptr [di], ' ' 
	inc di
	inc file_.len
	mov file_.pos, di 
endm 

begin:   
    xor cx, cx
	mov cl, es:80h
	cmp cl, 0 		; if length of args is zero the get file names from keyboard
	jne cmd_args
		jmp no_args

	cmd_args:
		logn "from args"
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
		lea di, inp_fname + 2 	; pointer to file name buffer
		mov inp_fname[1], cl 	; mov length of arg in 2nd byte
		rep movsb 				; copy to file name buffer
		jmp open_files

	no_args: 
		log "Enter file name > "; print prompt to enter name of file
		mov ah, 0ah
		lea dx, inp_fname
		int 21h 				; get file name from keyboard
		print newline

	open_files:
		xor bx, bx
		mov bl, inp_fname[1]
		mov inp_fname[bx + 2], 0; make asciz (put 0 after)
		push offset inp_file
		push offset inp_fname + 2
		push 0
		call fopen 				; open input file
		push offset vow_file
		push offset vow_fname
		push 1
		call fopen 				; open file with vowel-started words
		push offset con_file
		push offset con_fname
		push 1
		call fopen 				; open file with consanant-started words
		logn "files opened successfuly!"
		push offset inp_file
		call fread 				; read everything from file to buffer
		logn "file has been read."

	lea di, inp_file.fbuf
	mov cx, inp_file.len
	replace_non_letters:		; all non-letter characters are replaced with spaces
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
	logn "non-space characters replaced."

	mov cx, inp_file.len
	process_file:
		mov al, ' '
		mov di, inp_file.pos
		repe scasb 				; skip spaces
		cmp cx, 0 				; if eof go to write
		je write			
			dec di 				; move to previous byte
			inc cx
			push cx 			; save remain file len in stack
			mov inp_file.pos, di
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
			mov si, inp_file.pos 		; pointer to first letter
			check_first_letter:
				mov dl, vowels[bx]
				cmp byte ptr [si], dl 	; go to section by type of current symbol 
				je vowel
				inc bx
			loop check_first_letter
			jmp consonant
			vowel:
				copy_word vow_file; copy word in buff, put space after it
				jmp contine_process
			consonant:
				copy_word con_file
			contine_process:
				mov inp_file.pos, si ; save current possiton
				pop cx 
				cmp cx, 0     		 ; if eof go to write
				je write
					jmp process_file
	write:
		logn "everything has been processed." ; print prc msg
		mov ah, 0ah
		push offset vow_file
		call fwrite
		push offset con_file
		call fwrite
	exit:
	logn "exit"	; print exit msg
	mov ax, 4c00h
	int 21h		; int 21h

; open file args: file pointer, pointer to ascxiz string, mode of opening
fopen proc
	push bp
	mov bp, sp
		mov bx, [bp + 8] ; File pointer
		mov ah, 3dh
		mov al, [bp + 4] ; mode of opening
		mov dx, [bp + 6] ; file name offset
		int 21h ; open file
		jnc save_handle
			logn "cannot open file!"
			jmp exit
		save_handle:
		mov [bx].handle, ax
		lea dx, [bx].fbuf
		mov [bx].pos, dx
	pop bp
	ret 6
fopen endp

; read from file args: file pointer
fread proc
	push bp
	mov bp, sp
		mov si, [bp + 4] ; File pointer
		mov ah, 3fh
		mov bx, [si].handle
		mov cx, 1000h
		lea dx, [si].fbuf
		int 21h ; read everything to buffer
		mov [si].len, ax
	pop bp
	ret 2 
fread endp

; write to file args: file pointer
fwrite proc 
	push bp
	mov bp, sp
		mov si, [bp + 4] ; File pointer
		mov ah, 40h
		mov bx, [si].handle
		mov cx, [si].len
		lea dx, [si].fbuf
		int 21h ; write to file
		mov [si].len, ax
	pop bp
	ret 2 
fwrite endp

prog ends
end main