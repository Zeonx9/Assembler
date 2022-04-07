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
empty 	equ ' ' ; filler of the field
flen 	equ 20  ; length of field

field		db        0c9h, flen dup(0cdh),  0bbh, 10 dup(empty), "score:", 40 dup(empty), 13, 10 ; field is 20 x 20, however its actual size is 24 x 22 
;			db 	      0bah, flen dup(empty), 0bah, 10 dup(empty), "000000", 40 dup(empty), 13, 10
			db 20 dup(0bah, flen dup(empty), 0bah, 56 dup(empty), 13, 10)
			db 		  0c8h, flen dup(0cdh),  0bch, 56 dup(empty), 13, 10, '$'

cor_x		dw 1 	; current coordinats
cor_y		dw 1 	
old_x		dw 1 	; previous coordinats
old_y		dw 1 	

play_flag 	db 0 	; set if game is on, toggled by <P> if down then pause
go_flag 	db 0 	; set if reached game over
; again_flag 	db 0
paused 		db 1 	; used to change current element to show that game is paused
cursor 		dw ?	; save coordinates of cursor

colours		db 0b0h, 0b1h, 0b2h, 0dbh ; possible colours of elements
color 		db 0b0h ; current color
next 		db ? 	; used in random, present the result of call rand_nextf

score 		dw 0 	; score of the curren game
score_y 	dw 1 	; line where score is printed
gameover 	db "game is over!" ; msg of gaming over
go_len 		dw $-gameover 
; --------- prodedures and macroses for resident part ---------

; uses ax, bx, dx, doesn't save
get_index macro x_, y_ 
	mov ax, y_
	mov dl, 80
	mul dl 
	add ax, x_
	mov bx, ax 
endm

; uses ax, bx, dest - db
in_range macro dest, num, min, max
	xor ah, ah
	mov al, num
	mov bl, max
	sub bl, min ; length of range
	div bl
	add ah, min ; shift range
	mov dest, ah
endm

; uses ax, bx, [color, colours, next] variables 
set_color proc
	call rand_next
	in_range color, next, 0, 4
	mov al, color
	lea bx, colours
	xlatb
	mov color, al
	ret
set_color endp 

; uses ax, bx, doesn't save, next variable
rand_next proc
	xor ah, ah ; formula n + 1 = (n * a + c) % m
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

; uses ax, cx, dx, doesn't save next variable
rand_seed proc
	mov ah, 0h
	int 1ah ; get system time (int cx:dx)
	mov next, dl
	ret
rand_seed endp 

print_score proc
	get_index 37, score_y
	mov dl, 10
	mov ax, score 
	digit_dec:
		div dl 
		add ah, '0'
		mov field[bx], ah
		dec bx
		xor ah, ah 
	or al, al 
	jnz digit_dec
	ret 
print_score endp

; --------- interrunt handlers ---------

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
	; if game is active then handle controling keys pressing, none of keys are inputed, noncontroling are skipped
	; <P> toggles play_flag anyway
	; if game is paused all keys but <P> behave normally 
	push ds 
		push cs 
		pop ds 
	push ax
	push bx
	push cx
	push dx 
		in 	al, 60h ; get scancode from 60h port
		cmp al, 19h ; p pressed
		jne l9a
			cmp go_flag, 0
			je normal_p
				; here if game over and <P> pressed the game will start over
				mov go_flag, 0 ; down go flag
				mov score, 0   ; set initial values
				mov cor_y, 1
				inc score_y
				inc play_flag

				mov cx, flen
				get_index 1, 1
				clr_row_screen: ; clear field
					push cx 
					mov cx, flen
					clr_cell_screen:
						mov field[bx], empty
						inc bx
					loop clr_cell_screen
					sub bx, flen
					add bx, 80 
					pop cx
				loop clr_row_screen

			normal_p:
			xor play_flag, 1
			jmp not_send_code

		l9a:
		cmp play_flag, 0
		jne l9j 
			jmp pass_09h

		l9j:
		cmp al, 24h ; j pressed (rotate left)
		jne l9d
			; todo
			jmp not_send_code

		l9d:
		cmp al, 20h ; d pressed (move left)
		jne l9k
			cmp cor_x, left
			jle out9d
			get_index cor_x, cor_y
			sub bx, 1
			cmp field[bx], empty
			jne out9d
				
				dec cor_x
				
			out9d: jmp not_send_code

		l9k:
		cmp al, 25h ; k pressed (rotate right)
		jne l9v
			; todo
			jmp not_send_code

		l9v:
		cmp al, 2fh ; v pressed (move down)
		jne l9f
			cmp cor_y, bottom
			je out9v

			mov cx, bottom 
			sub cx, cor_y
			get_index cor_x, cor_y

			check_stop:
				cmp field[bx + 80], empty
				jne set_point
				add bx, 80
			loop check_stop
			set_point:

			mov cor_y, bottom
			sub cor_y, cx

			out9v: jmp not_send_code

		l9f:
		cmp al, 21h ; f pressed (move right)
		jne chkfp2
			cmp cor_x, right
			jge out9f
			get_index cor_x, cor_y
			cmp field[bx + 1], empty
			jne out9f

				inc cor_x
				
			out9f: jmp not_send_code

	chkfp2:
	cmp play_flag, 0
	jne not_send_code

	pass_09h:
		pop dx 
		pop cx
		pop bx	
		pop ax
		pop ds
		jmp dword ptr cs:previous09h

	not_send_code:
		mov al, 20h ; send end of interrupt code to 20h code
		out 20h, al
		pop dx 
		pop cx
		pop bx
		pop ax
		pop ds
		iret ; return
handler09h endp 

handler1ch proc far ; timer interrupt handler
	; used to update the screen also provides all logic and physics of the game
	; if go_flag set just pass control to old handler

	cmp cs:go_flag, 0
	je cont_inter2
		jmp pass_1ch
	cont_inter2:

	inc cs:tics

	cmp cs:tics, 2
	je cont_inter
		jmp pass_1ch
	cont_inter:

	push ds 
		push cs 
		pop ds
	push ax
	push dx
	push bx
	push cx

		cmp play_flag, 0
		jne cont_play 
		cmp paused, 0
		je pause_game ; skip if paused else pause
			jmp pass_draw
		pause_game:
				get_index old_x, old_y
				mov field[bx], 'X' ; put signal of paused
				inc paused
				jmp draw_field
		cont_play:

		cmp play_flag, 0
		je cont_play2
		cmp paused, 0
		je cont_play2 ; resume 
			dec paused
		cont_play2:

			get_index old_x, old_y
			mov field[bx], empty ; erase previous

			get_index cor_x, cor_y
			mov al, color
			mov field[bx], al ; set current position

		cmp cor_y, bottom ; check if figure is at the bottom 
		je save_and_next

		get_index cor_x, cor_y 
		cmp field[bx + 80], empty ;check for figure bellow
		jne save_and_next
		jmp continue_fall

		save_and_next:
			cmp cor_y, 1
			jne cont_1csave1
				inc go_flag ; set game over flag
				dec play_flag ; switching to normal input mode
				get_index 5, 11
				lea di, field[bx]
				lea si, gameover 
				mov cx, go_len
				cpy_go:				; print gameover msg in the middle of field
					mov al, [si]
					mov [di], al 
					inc si 
					inc di 
				loop cpy_go
				jmp draw_field
			cont_1csave1:

			add score, 5
			mov cx, flen
			get_index 1, cor_y
			chk_row:				; check if row is done
				cmp field[bx], empty
				je cont_1csave
				inc bx
			loop chk_row 

			add score, 50
			mov cx, flen
			sub bx, flen
			clr_row: 		; clear the row and move everything down
				push bx 
				move_clmn:
					cmp field[bx], empty
					je next_clmn
					sub bx, 80
					mov al, field[bx]
					mov field[bx + 80], al
				jmp move_clmn

				next_clmn:
				pop bx
				inc bx
			loop clr_row

			cont_1csave:
			mov cor_y, 1 ; put new up
			call set_color
			call print_score
			jmp draw_field

		continue_fall:
			push cor_x
			pop  old_x
			push cor_y
			pop  old_y ; save cords

			inc cor_y

		draw_field:

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

		pass_draw:

	pop cx
	pop bx
	pop dx
	pop ax
	pop ds

	mov cs:tics, 0

	pass_1ch:
	jmp dword ptr cs:previous1ch
handler1ch endp

end_of_resident:

; --------- non-resident part to install and uninstall program ---------

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

		mov ah, 2 
		mov bh, 0
		mov dx, 1800h 
		int 10h ; set cursor to the bottom left corner

		mov ax, 351ch
		int 21h				; get 1ch vector into es:bx
		mov word ptr previous1ch, bx
		mov word ptr previous1ch + 2, es
		mov ah, 25h
		lea dx, handler1ch
		int 21h

		call rand_seed ; initialaze random
		print_str "Installed."
		lea dx, instruction
		call print
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
		int 20h ; exit

; variables of boot part
off_key 	db "/off"
flag_off	db 0
instruction db " ------- Wanna play Tetris ?) ------- ", 13, 10 
			db " -> press <P> to start the game and pause/resume it later", 13, 10
			db " -> press <D> to move left   and <F> to move right", 13, 10
			db " -> press <J> to rotate left and <K> to rotate right", 13, 10
			db " -> press <V> to move down immediatly", 13, 10
			db " - - - - - - - - - - - - - - - - - - - - - ", 13, 10, '$'

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