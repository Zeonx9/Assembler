prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h
main: 
	jmp begin

; variables
in_handle dw ?
out_handle dw ?
buffer db 80, ?, 80 dup (?)

;macro
open_file macro file_name_offset, handle_
	local ok 
	push ax
	push dx
		mov ax, 3d02h
		mov dx, file_name_offset
		int 21h
		jnc ok
			jmp error
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
			open_file si, handle_
			mov si, di
			inc si
	pop di
endm

open_file_from_keyboard macro msg, buff, handle_
	push si
		puts msg
		gets_z buff
		mov si, offset buff + 2
		open_file si, handle_
		newline
	pop si
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
		jmp second_from_keyboard

		second_from_arg:
		open_file_from_arg_line out_handle
		jmp work

	no_args:
		open_file_from_keyboard "enter source file name > ", buffer, in_handle
		second_from_keyboard:
		open_file_from_keyboard "enter destination file name > ", buffer, out_handle

	work:
		puts "files successfuly opened!"
		jmp exit

	error:
		newline
		puts "failed open file!"

	exit:
		mov ax, 4c00h
		int 21h
	
prog ends
end main