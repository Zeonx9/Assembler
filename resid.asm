resident segment 
	assume cs:resident, ds:resident, ss:resident
	org 100h
main: ; resident part
jmp boot
; variables of resident part
number2fh 	db 0D7h
previous2fh dd ?
previous09h dd ?
previous1ch dd ?

tics		db 0

left 	equ 1
right 	equ 20
top 	equ 1
bottom 	equ 20

field		db 0c9h, 20 dup(0cdh), 0bbh, 56 dup(' '), 13, 10 ; field is 20 x 20, however its actual size is 24 x 22 
			db 20 dup(0bah, 20 dup(0b0h), 0bah, 56 dup(' '), 13, 10)
			db 0c8h, 20 dup(0cdh), 0bch, 56 dup(' '), 13, 10, '$'

cor_x		dw 1 	; [1; 20]
cor_y		dw 1 	; [1; 20]
old_x		dw 1 	; [1; 20]
old_y		dw 1 	; [1; 20]

play_flag 	db 0
cursor 		dw ?

handler2fh proc far ; multiplex interrupt handler to interact with tsr
	cmp ah, cs:number2fh
	jne pass_2fh
	cmp al, 00h 		; installation request 
	je install_request
	cmp al, 01h			; uninstallation request
	je uninstall_request
	pass_2fh: 
	jmp dword ptr cs:previous2fh ; previous handler

	install_request:
		mov al, 0ffh 	; return code = alredy installed
		iret

	uninstall_request:
		push bx 
		push es
		push dx
		push cx

			mov ax, 352fh
			int 21h			; get top vector into es:bx
			mov cx, cs 
			mov dx, es 
			cmp dx, cx
			jne cannot_uninstall
			cmp bx, offset cs:handler2fh
			jne cannot_uninstall ; top vector should match our handler

			mov ax, 3509h
			int 21h			; get top vector into es:bx
			mov dx, es 
			cmp dx, cx
			jne cannot_uninstall
			cmp bx, offset cs:handler09h
			jne cannot_uninstall ; top vector should match our handler

			mov ax, 351ch
			int 21h			; get top vector into es:bx
			mov dx, es 
			cmp dx, cx
			jne cannot_uninstall
			cmp bx, offset cs:handler1ch
			jne cannot_uninstall ; top vector should match our handler
			jmp can_uninstall

			cannot_uninstall:
			mov al, 0f0h 	; return code = cannot uninstall
			jmp i_ret

			can_uninstall:
			push ds
				mov ax, 252fh
				lds dx, cs:previous2fh
				int 21h		; put back previous handler
				mov ax, 2509h
				lds dx, cs:previous09h
				int 21h		; put back previous handler
				mov ax, 251ch
				lds dx, cs:previous1ch
				int 21h		; put back previous handler
			pop ds
				mov ah, 49h
				mov es, cs:2ch
				int 21h 	; free memory used for environment
				push cs 
				pop es 
				int 21h		; free resident memory 

			mov al, 00fh 	; return code = uninstall successfully 

		i_ret:
		pop cx
		pop dx
		pop es 
		pop bx
		iret
handler2fh endp

handler09h proc far ; keyboard interrupt handler
	push ds 
		push cs 
		pop ds 
	push ax
		in 	al, 60h ; get scancode from 60h port
		cmp al, 19h ; p pressed
		jne chkfp
			xor play_flag, 1
			jmp not_send_code

		chkfp:
		cmp play_flag, 0
		je pass_09h

		l9w:
		cmp al, 11h ; w pressed
		jne l9a
			cmp cor_y, top
			jle not_send_code
				dec cor_y
				jmp not_send_code
		l9a:
		cmp al, 1eh ; a pressed
		jne l9s
			cmp cor_x, left
			jle not_send_code
				dec cor_x
				jmp not_send_code
		l9s:
		cmp al, 1fh ; s pressed
		jne l9d
			cmp cor_y, bottom
			jge not_send_code
				inc cor_y
				jmp not_send_code
		l9d:
		cmp al, 20h ; d pressed
		jne chkfp2
			cmp cor_x, right
			jge not_send_code
				inc cor_x
				jmp not_send_code

	chkfp2:
	cmp play_flag, 1
	je not_send_code

	pass_09h:	
		pop ax
		pop ds
		jmp dword ptr cs:previous09h

	not_send_code:
		mov al, 20h ; send end of interrupt code to 20h code
		out 20h, al
		pop ax
		pop ds
		iret ; return 
handler09h endp

handler1ch proc far ; timer interrupt handler
	inc tics
	cmp tics, 2
	jne pass_1ch

	push ds 
		push cs 
		pop ds
	push ax
	push dx
	push bx

		mov ax, old_y
		mov dl, 80
		mul dl 
		add ax, old_x
		mov bx, ax 
		mov field[bx], 0b0h

		mov ax, cor_y
		mov dl, 80
		mul dl 
		add ax, cor_x
		mov bx, ax 

		push cor_x
		pop  old_x
		push cor_y
		pop  old_y ; save previous cords

		cmp play_flag, 1 ; put x to active position if game paused
		je lt1
			mov field[bx], 'X'
			jmp lt2
		lt1:
			mov field[bx], 0b2h ;and fill it if resumed
		lt2:

		mov ah, 3 
		mov bh, 0 
		int 10h 
		mov cursor, dx ; save cursor position 

		mov ah, 2 
		mov bh, 0
		xor dx, dx 
		int 10h ; set cursor to the top left corner

		lea dx, field
		mov ah, 9 
		int 21h ; print out field

		mov ah, 2 
		mov bh, 0 
		mov dx, cursor 
		int 10h ; put cursor back

	pop bx
	pop dx
	pop ax
	pop ds

	mov tics, 0

	pass_1ch:
	jmp dword ptr cs:previous1ch
handler1ch endp

end_of_resident:

; boot macro
print_str macro str
	local var, sk_l
	jmp sk_l
		var db str, '$'
	sk_l:
	push dx
		lea dx, var
		call print
	pop dx
endm 

boot: ; used to install, uninstall, and moderate tsr
	xor cx, cx
	mov cl, es:80h
	cmp cx, 0
	je try_to_install ; check cmd args if none try to install 
	mov di, 81h
	cld
	mov al, ' '
	repe scasb		; skip spaces if any 
	dec di 
	lea si, off_key
	mov cx, 4
	repe cmpsb		; compare cmd arg to "/off"
	jne try_to_install
		inc flag_off ; set flag if "/off" passed

try_to_install:
	mov ah, number2fh
	mov al, 00h 
	int 2fh 		; ask status of our tsr
	cmp al, 0ffh 	; return code already installed
	jne continue1
		jmp already_installed
	continue1:
	cmp flag_off, 0 ; check that no "/off"
	je install

		mov ax, 0700h  		
		mov bh, 07h 	
		xor cx, cx
		mov dx, 184fh
		int 10h 		; clear the screen

		print_str "not installed!"
		int 20h

	install: ; (actual installation and saving resident)

		mov ax, 352fh
		int 21h				; get 2fh vector into es:bx
		mov word ptr previous2fh, bx
		mov word ptr previous2fh + 2, es
		mov ah, 25h
		lea dx, handler2fh
		int 21h				; put out handler on top 

		mov ax, 3509h
		int 21h				; get 09h vector into es:bx
		mov word ptr previous09h, bx
		mov word ptr previous09h + 2, es
		mov ah, 25h
		lea dx, handler09h
		int 21h 			; put out handler on top 

		mov ax, 351ch
		int 21h				; get 1ch vector into es:bx
		mov word ptr previous1ch, bx
		mov word ptr previous1ch + 2, es
		mov ah, 25h
		lea dx, handler1ch
		int 21h

		print_str "Installed."
		mov cursor, 1800h
		lea dx, end_of_resident
		int 27h

already_installed:
	cmp flag_off, 1
	je uninstall ; if "/off" passed than try to uninstall (it is done within 2fh interrupt)

		print_str "Program installed already!"
		int 20h

	uninstall:

		mov ah, number2fh 
		mov al, 01h
		int 2fh ; send uninstal request
		cmp al, 00fh ; return code of sucessfull uninstallation
		je success

		print_str "Unable to uninstall the program."
		int 20h 

		success:
		print_str "Uninstalled."
		; mov ax, 0700h  		
		; mov bh, 07h 	
		; xor cx, cx
		; mov dx, 164fh
		; int 10h 		; clear the screen 
		int 20h ; exit

; variables of boot part
off_key 	db "/off"
flag_off	db 0

; procedures
print proc near ; dx = offset of '$'-terminated string  
	push ax
		mov ah, 9
		int 21h
	pop ax
	ret
print endp

newline proc near 
	push dx
		lea dx, new_line
		call print
	pop dx 
	ret 
		new_line db 13, 10, '$'
newline endp 

resident ends
end main