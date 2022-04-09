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

; field is 10(20) x 20, however its actual size is 80 x 22, to get cell under current add 80 
field		db        0c9h, flen dup(0cdh),  0bbh, 10 dup(empty), "score:", 40 dup(empty), 13, 10 
			db 20 dup(0bah, flen dup(empty), 0bah, 56 dup(empty), 13, 10)
			db 		  0c8h, flen dup(0cdh),  0bch, 56 dup(empty), 13, 10, '$'

cor_x		dw 9 	; current coordinats
cor_y		dw 1 	; both coordinates shoudl be odd numbers
old_x		dw 10 	; previous coordinats
old_y		dw 7 	

play_flag 	db 0 	; set if game is on, toggled by <P> if down then pause
go_flag 	db 0 	; set if reached game over

paused 		db 1 	; used to change current element to show that game is paused
cursor 		dw ?	; save coordinates of cursor

colours		db 0b0h, 0b1h, 0b2h, 0dbh ; possible colours of elements
color 		db 0b0h ; current color
next_color 	db ?
next 		db ? 	; used in random, present the result of call rand_nextf

score 		dw 0 	; score of the curren game
score_y 	dw 1 	; line where score is printed
gameover 	db " game is over!" ; msg of gaming over
go_len 		dw $-gameover 

rot_r 		db 0; flag if rotation to right pressed
rot_l  		db 0; flag if totation to left pressed

cur_fig 	dw 6    ; index of current figure in figures array 
next_fig    dw 0
place_flag 	dw 0    ; flag shows whether figure should be placed

; structure of each figure: 
; 4 words = offset related prev block, 4 words = flags for cheking, 4 words = left check, 4 words = right check
; 2 words = indices of rotated figure, 1 word = numbers of rows taken by figure, 3 words = rotation borders ((22 words) 44 byte per figure) 
;			  +0              +8           +16          +24          +32+34+36 +38
figures		dw 0,  2, 78,  2,  0, 0, 1, 1,  1, 0, 1, 0,  0, 1, 0, 1,  0, 0, 2,  1, 20, 20 ; "O" figure  0
			dw 0, 80, 80, 80,  0, 0, 0, 1,  1, 1, 1, 1,  1, 1, 1, 1,  2, 2, 4,  1, 13, 20 ; "I" figure  1
			dw 0,  2,  2,  2,  1, 1, 1, 1,  1, 0, 0, 0,  0, 0, 0, 1,  1, 1, 1,  1, 20, 17 ; rot "I"     2
			dw 0,  2, 76,  2,  0, 1, 1, 1,  0, 0, 1, 0,  0, 1, 0, 1,  4, 4, 2,  1, 20, 18 ; "S" figure  3
			dw 0, 80,  2, 80,  0, 1, 0, 1,  1, 1, 0, 1,  0, 0, 1, 1,  3, 3, 3,  2, 20, 20 ; rot "S"     4
			dw 0,  2, 80,  2,  1, 0, 1, 1,  1, 0, 1, 0,  0, 0, 0, 1,  6, 6, 2,  2, 20, 18 ; "Z" figure  5
			dw 0, 78,  2, 78,  0, 0, 1, 1,  0, 1, 0, 1,  1, 0, 1, 1,  5, 5, 3,  1, 15, 20 ; rot "Z"     6

; -------------------------------------------------- prodedures and macroses for resident part ---------------------------------------------------------

; bx = index of field cell with given coordinates
get_index macro x_, y_ 
	mov ax, y_
	mov dl, 80
	mul dl 
	add ax, x_
	mov bx, ax 
endm

; dest = num % (max - min) + min
in_range macro dest, num, min, max
	xor ah, ah
	mov al, num
	mov bl, max
	sub bl, min ; length of range
	div bl
	add ah, min ; shift range
	mov dest, ah
endm

; si = figure with given index in figures array
get_figure macro ind 
	mov ax, ind 
	mov dl, 44
	mul dl 
	lea si, figures
	add si, ax 
endm

; set all cells taken by figure with center at field[bx], to empty ones
erase_figure proc 
	; bx should be configured to the center point of a figure
	get_figure cur_fig
	mov cx, 4 
	clr_fig:
		add bx, word ptr [si]
		mov field[bx], empty
		mov field[bx + 1], empty
		add si, 2
	loop clr_fig
	ret 
erase_figure endp

; draws a figure with center at field[bx]
draw_figure proc
	; bx should be configured to the center pivot from where center of figure goes
	get_figure cur_fig
	mov cx, 4 
	mov al, color
	drw_fig:
		add bx, word ptr [si]
		mov field[bx], al
		mov field[bx + 1], al 
		add si, 2
	loop drw_fig
	ret 
draw_figure endp

; place_flag = 1 if figure on the bottom or on top of another, else place_flag = 0
check_bottom proc
	; get_figure cur_fig
	get_figure cur_fig
	mov cx, 4
	chk_fig:
		add bx, word ptr [si]
		cmp word ptr [si + 8], 0 
		je skip_chk

		cmp field[bx + 80], empty
		jne set_flag_place

		skip_chk:
			add si, 2
	loop chk_fig

	mov place_flag, 0
	jmp return_
	set_flag_place:
	mov place_flag, 1

	return_:
	ret 
check_bottom endp

; place_flag = 0 if figure can be moved to the left, else place_flag = 1
check_left proc
	get_figure cur_fig
	mov cx, 4
	chk_fig2:
		add bx, word ptr [si]
		cmp word ptr [si + 16], 0 
		je skip_chk2

		cmp field[bx - 1], empty
		jne set_flag_place2

		skip_chk2:
			add si, 2
	loop chk_fig2

	mov place_flag, 0 ; can move left
	jmp return_2
	set_flag_place2:
	mov place_flag, 1 ; cannot move left

	return_2:
	ret 
check_left endp 

; place_flag = 0 if figure can be moved to the rightt, else place_flag = 1
check_right proc
	get_figure cur_fig
	mov cx, 4
	chk_fig3:
		add bx, word ptr [si]
		cmp word ptr [si + 24], 0 
		je skip_chk3

		cmp field[bx + 2], empty
		jne set_flag_place3

		skip_chk3:
			add si, 2
	loop chk_fig3

	mov place_flag, 0 ; can move left
	jmp return_3
	set_flag_place3:
	mov place_flag, 1 ; cannot move left

	return_3:
	ret 
check_right endp

; fills all play-field with empty cells
clear_field proc 
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
	ret
clear_field endp

; moves down by 1 cell every thing when collected full row (condition isn'nt checked)
row_done proc
	get_index 1, cor_y
	mov cx, flen
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
	ret 
row_done endp

; handle game over situation
game_over proc 
	inc go_flag ; set game over flag
	dec play_flag ; switching to normal input mode
	get_index 4, 11 ; position to print game over
	lea di, field[bx]
	lea si, gameover 
	mov cx, go_len
	cpy_go:				; print gameover msg in the middle of field
		mov al, [si]
		mov [di], al 
		inc si 
		inc di 
	loop cpy_go
	ret
game_over endp

; color = random color 
set_color proc
	call rand_next
	in_range next_color, next, 0, 4
	mov al, next_color
	lea bx, colours
	xlatb
	mov next_color, al
	ret
set_color endp 

rotate proc
	get_figure cur_fig
	mov dx, cor_x
	cmp dx, word ptr [si + 38]
	jl rett
	cmp dx, word ptr [si + 40]
	jg rett 
	mov dx, cor_y
	cmp dx, word ptr [si + 42]
	jg rett 
	cmp rot_r, 0
	je rl
		mov ax, word ptr [si + 34]
		mov cur_fig, ax
	rl: 
	cmp rot_l, 0
	je rett
		mov ax,  word ptr [si + 32]
		mov cur_fig, ax
	rett:
		mov rot_l, 0
		mov rot_r, 0
	ret
rotate endp

; next = random number (db), (n+1) = ((n) * a + c ) % m
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

; initialize randomizer with system time
rand_seed proc
	mov ah, 0h
	int 1ah ; get system time (int cx:dx)
	mov next, dl
	ret
rand_seed endp 

; print current score into the field
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

; -------------------------------------------------------------- interrunt handlers --------------------------------------------------------------

; multiplex interrupt handler to interact with tsr
handler2fh proc far 
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

; keyboard interrupt handler
handler09h proc far 
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
	push si
		in 	al, 60h ; get scancode from 60h port
		cmp al, 19h ; p pressed
		jne chkfp
			cmp go_flag, 0
			je normal_p
				; here if game over and <P> pressed the game will start over
				mov go_flag, 0 ; down go flag
				mov score, 0   ; set initial values
				mov cor_y, 1
				mov cor_x, 10
				inc score_y
				inc play_flag
				call clear_field

			normal_p:
			xor play_flag, 1 ; toggle play flag
			jmp not_send_code

		chkfp: cmp play_flag, 0 ; if game is not active then keys are handled usually
		jne l9j 
		jmp pass_09h

		l9j: cmp al, 24h ; j pressed (rotate left)
		jne l9k
			inc rot_l
		outl9j: jmp not_send_code

		l9k: cmp al, 25h ; k pressed (rotate right)
		jne l9d
			inc rot_r
		outl9k: jmp not_send_code

		l9d: cmp al, 20h ; d pressed (move left)
		jne l9f
			get_index cor_x, cor_y
			call check_left
			cmp place_flag, 0
			jne out9d
				sub cor_x, 2 	
		out9d: jmp not_send_code

		l9f: cmp al, 21h ; f pressed (move right)
		jne l9v
			get_index cor_x, cor_y
			call check_right
			cmp place_flag, 0
			jne out9f
				add cor_x, 2
		out9f: jmp not_send_code

		l9v: cmp al, 2fh ; v pressed (move down)
		jne chkfp2
			try_pos_down:
				get_index cor_x, cor_y
				call check_bottom
				cmp place_flag, 0
				jne out9v
					inc cor_y
			jmp try_pos_down
		out9v: jmp not_send_code

	chkfp2:
	cmp play_flag, 0
	jne not_send_code

	pass_09h:
		pop si
		pop dx 
		pop cx
		pop bx	
		pop ax
		pop ds
		jmp dword ptr cs:previous09h

	not_send_code:
		mov al, 20h ; send end of interrupt code to 20h code
		out 20h, al
		pop si
		pop dx 
		pop cx
		pop bx
		pop ax
		pop ds
		iret ; return
handler09h endp 

; timer interrupt handler
handler1ch proc far 
	; used to update the screen also provides all logic and physics of the game
	; if go_flag set just pass control to old handler

	cmp cs:go_flag, 0 ; check if game is over then do not draw field
	je cont_inter2
		jmp pass_1ch
	cont_inter2:

	inc cs:tics

	cmp cs:tics, 6    ; check for tics, and update with given frequency
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
	push si
	push di 

		cmp play_flag, 0
		jne cont_play 
		cmp paused, 0
		je pause_game ; skip if paused else pause
			jmp pass_draw
		pause_game:

			get_index old_x, old_y 
			call erase_figure

			mov field[bx],     '>'  ; put signal of paused '><'
			mov field[bx  + 1],  '<'
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
			call erase_figure

			call rotate

			get_index cor_x, cor_y
			call draw_figure

		get_index cor_x, cor_y 
		call check_bottom
		cmp place_flag, 0
		jne save_and_next
		jmp continue_fall

		save_and_next:
			cmp cor_y, 1
			je game_ov 

			add score, 5
			push cor_y 
			get_figure cur_fig
			mov cx, word ptr [si + 36] ; check all rows taken by a figure
			chk_row:
				push cx
				get_index 1, cor_y
				mov cx, flen
				chk_cell:
					cmp field[bx], empty
					je skip_row
					inc bx
				loop chk_cell 	; check if row is done
				call row_done
				add score, 100
			skip_row:
			pop cx
			inc cor_y
			loop chk_row
			pop cor_y 

			cont_1csave:
			mov cor_y, 1 ; put new up
			mov old_y, 1
			mov al, next_color
			mov color, al
			call set_color
			call print_score
			jmp draw_field

		continue_fall:
			push cor_x
			pop  old_x
			push cor_y
			pop  old_y ; save cords

			inc cor_y

		jmp draw_field
			game_ov: call game_over
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

	pop di
	pop si
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

; ------------------------------------------------ non-resident part to install and uninstall program -------------------------------------------------

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
		call set_color
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
instruction db " - - - - - - - - -  Wanna play Tetris ?) - - - - - - - - - - ", 13, 10 
			db " -> press <P> to start the game and pause/resume it later", 13, 10
			db " -> press <D> to move left   and <F> to move right", 13, 10
			db " -> press <J> to rotate left and <K> to rotate right", 13, 10
			db " -> press <V> to move down immediatly", 13, 10
			db " -> press <P> again to restart the game after game is over", 13, 10
			db " - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ", 13, 10, '$'

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