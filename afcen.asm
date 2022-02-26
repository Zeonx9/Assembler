prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h
main: 
	jmp begin

; constants
len equ 80
lf equ 0ah

; variables
in_handle dw ?
out_handle dw ?
buffer db len, ?, len dup (?)
spaces db len dup(' ')

;macro
open_file macro file_name_offset, handle_, error_lablel
	local ok 
	push ax
	push dx
		mov ax, 3d02h
		mov dx, file_name_offset
		int 21h
		jnc ok
			jmp error_lablel
		ok:
			mov handle_, ax
	pop dx
	pop ax
endm

open_file_from_arg_line macro handle_
	local c1, c2, ok, res
	push di
		dec si
		c1:
			inc si
			cmp byte ptr [si], 20h
		je c1

		mov di, si
		dec di
		c2:
			inc di
			cmp byte ptr [di], 20h
			je res
			cmp byte ptr [di], 0dh
			je res
		jmp c2

		res:
		mov byte ptr [di], 0
		open_file si, handle_, error
		mov si, di
		inc si
	pop di
endm

open_file_from_keyboard macro msg, buff, handle_
	push si
		puts msg
		gets_z buff
		mov si, offset buff + 2
		open_file si, handle_, error
		newline
	pop si
endm

read_file_line macro buff
	local rchar, endr
	push ax
	push bx
	push dx
	push si
	push di
		mov di, offset buff + 1
		mov byte ptr [di], 0
		mov dx, di
		mov si, dx
		mov cx, 1
		rchar:
			inc dx
			mov ah, 3fh
			int 21h
			cmp al, 0 
			je endr
			inc byte ptr [di]
			inc si
		cmp byte ptr [si], lf
		je endr
		jmp rchar
	endr:
	pop di
	pop si
	pop dx
	pop bx
	pop ax
endm

; main
begin:
	include tmacro.lib
	mov cl, es:80h
	cmp cl, 0
	jne cmd_args
	jmp no_args

	cmd_args:
		mov si, 81h
		open_file_from_arg_line in_handle
		
		cmp byte ptr [si], 0
		jne second_from_arg
		jmp no_second

		second_from_arg:
		open_file_from_arg_line out_handle
		jmp work

		no_second:
			mov ax, in_handle
			mov out_handle, ax
			jmp work

	no_args:
		open_file_from_keyboard "enter source file name > ", buffer, in_handle
		open_file_from_keyboard "enter destination file name > ", buffer, out_handle

	work:
		puts "files successfuly opened!"
		newline

		next_line:
			mov bx, in_handle
			
			read_file_line buffer

			cmp buffer[1], 0
			je end_of_line_process

			puts "line: "
			xor bh, bh
			mov bl, buffer[1]
			mov buffer[bx + 2], '$'
			mov ah, 09h
			mov dx, offset buffer + 2
			int 21h
			
			xor ah, ah
			xor ch, ch
			mov al, len  
			sub al, buffer[1]
			mov bl, 2
			div bl

			mov bx, out_handle
			mov cl, al
			mov ah, 40h
			mov dx, offset spaces
			int 21h
			
			mov cl, buffer[1]
			mov ah, 40h
			mov dx, offset buffer + 2
			int 21h

		jmp next_line	
		end_of_line_process:
		jmp exit

	error:
		newline
		puts "failed open file!"

	exit:
		newline
		puts "exit"
		mov ax, 4c00h
		int 21h
prog ends
end main