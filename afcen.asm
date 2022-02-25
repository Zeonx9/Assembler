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
skip_spaces macro
	local next, ok
	dec si
	next:
		inc si
		cmp byte ptr [si], 20h
		je next
endm

move_ptr_after_str macro str_start
	local next, res
	push di
		mov di, str_start
		dec di
		next:
			inc di
			cmp byte ptr [di], 20h
			je res
			cmp byte ptr [di], 0
			je res
			jmp next
		res:
		inc di
		mov str_start, di
	pop di
endm

put_zero_after_str macro str_start
	local next, res
	push di
		mov di, str_start
		dec di
		next:
			inc di
			cmp byte ptr [di], 20h
			je res
			cmp byte ptr [di], 0dh
			je res
			jmp next     
		res:
			mov byte ptr [di], 0
endm

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

; main
begin:
	include tmacro.lib
	mov cl, es:80h
	cmp cl, 0
	jne cmd_args
	jmp no_args

	cmd_args:
		mov si, 81h
		skip_spaces
		put_zero_after_str si 
		open_file si, in_handle
		move_ptr_after_str si
		
		cmp byte ptr [si], 0
		jne second_file
			jmp second_from_keyboard

		second_file:
		skip_spaces
		put_zero_after_str si
		open_file si, out_handle
		jmp work

	no_args:
		puts "enter source file name > "
		newline
		gets_z buffer
		mov si, offset buffer + 2
		open_file si, in_handle
		newline

		second_from_keyboard:
		puts "enter destination file name > "
		newline
		gets_z buffer
		mov si, offset buffer + 2
		open_file si, out_handle
		newline

	work:
		puts "files successfuly opened!"
		jmp exit

	error:
		puts "failed open file!"

	exit:
		mov ax, 4c00h
		int 21h
	
prog ends
end main