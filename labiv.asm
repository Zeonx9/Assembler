code_seg segment
    assume  CS:code_seg, DS:code_seg,ES:code_seg
 	org 100h
main:
jmp start

new_line macro 
    push    AX
    push    DX
        mov DL, 13
        mov AH, 02
        int 21h 
        mov DL, 10
        mov AH, 02
        int 21h 
    pop    DX
    pop    AX
endm 

print_mes macro message
	local msg, nxt
	push AX
	push DX
	    mov DX, offset msg
	    mov AH, 09h
	   int 21h
	pop DX
	pop AX
	jmp nxt
	   msg DB message,'$'
	nxt:
endm   

start:
xor cx, cx     
mov cl, es:80h 
cmp cl, 0 ; длина аргументов командной строки   
je no_arg       
	jmp arg_

no_arg:
    print_mes "Enter input file name: "
    mov dx, offset file_name          
    mov ah, 0ah                    
    int 21h            ; ввести имя с клавиатуры     
    new_line
    xor bx, bx              
    mov bl, file_name[1]       
    mov file_name[bx+2], 0   ; сделать asciz  

    mov ax, 3d00h             
    mov al, 0               
    mov dx, offset file_name + 2       
    int 21h       ; открыть файл                  
    jnc ok1 
        print_mes "Open error"
        int 20h
    ok1:
    mov handle1, ax ; сохранить дескриптор
    print_mes "Open OK"
    new_line
    jmp after_open

arg_:
    mov di, 81h
    mov al, 20h
    repe scasb ; пропустить пробелы
    dec di     
    inc cx
    push di
    repne scasb ; найти конец имени файла
    cmp cx, 0
    je skip1     
        dec di
    skip1:
    mov byte ptr[di], 0 ; сделать asciz  
    
    mov ah, 3dh
    mov al, 0
    pop dx
    int 21h     ; открыть файл   
    jnc ok2 
        print_mes "Open error"
        int 20h
    ok2:
    mov handle1, ax
    print_mes "Open OK"
    new_line
    jmp after_open

after_open:                         
mov ah, 3fh                   
mov bx, handle1                
mov cx, 5000                 
mov dx, offset buffer      ; прочитать все из файла в буфер    
int 21h
mov buffer_size, ax       

print_mes "Enter substring for search: "
new_line
mov dx, offset subst         
mov ah, 0ah                    
int 21h       ; ввести подстроку с клавиатуры          
new_line

xor bh, bh
mov bl, subst[1]
mov subst_len, bl ; сохранить длину подстроки в переменую

cmp bx, buffer_size ; если подстрока длинее считаного из файла, то найдено 0
jle find_
	print_mes "found: 0"
	new_line
	jmp exit

find_:
lea di, buffer ; указатель на буфер
mov cx, buffer_size 
sub cl, subst_len
inc cx ; посчитать количество потенциальных совпадений для внешнего цикла
try_byte:
	push cx
	lea si, subst + 2
	mov cl, subst_len ; длина строки для поиска
	push di ; сохранить текущий адрес
	cmp_byte:
		mov dl, byte ptr [si] ; если текущий байт совпал проверить следующий, несовппел - строки разные
		cmp byte ptr [di], dl 
		jne next_byte 
		inc si ; сдвинуть указатели на следующий байт
		inc di 
	loop cmp_byte
		inc count ; сюда, если нашлось совпадение
	next_byte:
	pop di ; вернуть указатель из стека
	inc di ; сдвинуть на байт вперед, чтобы проверять новую подстроку
	pop cx
loop try_byte

print_mes "found: " ; вывести на экран ответ
push count
call num_to_str_dec

exit:
new_line
print_mes "exit"
mov ax, 4c00h
int 21h

; переменные
handle1 dw ?
file_name db 27,?, 27 dup(' ')    
buffer db 5000 dup (?)
subst  db 80, ?, 80 dup (' ')      
buffer_size dw ? 
subst_len	db 0       
count dw 0

; функция преобразует число в строку и выводит в консоль
num_to_str_dec proc 
	push bp 
	mov bp, sp
		mov ax, [bp + 4]
		mov q, ax
		mov bx, 10 ; делим на 10 пока делится 
		xor cx, cx
		put_dig_in_stack:
			mov ax, q
			xor dx, dx
			div bx
			mov r, dx ; остаток от деления 
			mov q, ax ; неполное частное
			push r    ; сохранить остаток в стек
			inc cx    ; cx считает количество цифр
			cmp q, 0
			je move_dig_to_str
			jmp put_dig_in_stack

		move_dig_to_str:
		pop dx
		add dl, '0' ; достать цифру из стека и вывести на экран
		mov ah, 2
		int 21h 
		loop move_dig_to_str
	pop bp
	ret 2
		r dw 0
		q dw 0
num_to_str_dec endp

code_seg ends
end main