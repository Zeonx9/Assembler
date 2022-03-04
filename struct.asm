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

; data
newline db 0dh, 0ah, '$'
inp_file File <>
vow_file File <>
con_file File <>
fn_str 	db 80, ?, 80 dup (?)

; code
begin:
	log "enter name > "
	mov ah, 0ah
	lea dx, fn_str
	int 21h ; get from keyboard
	print newline

	xor bx, bx
	mov bl, fn_str[1]
	mov fn_str[bx + 2], 0 ; terminate by 0

	push offset inp_file
	push offset fn_str + 2
	push 0
	call fopen
	logn "successfuly opened"

	push offset inp_file
	call fread

	logn "read from file:"
	mov bx, inp_file.len
	mov inp_file.fbuf[bx], '$'
	print inp_file.fbuf
	print newline

exit:
	log "exit"
	mov ax, 4c00h
	int 21h	

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

prog ends
end main