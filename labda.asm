code_seg segment
    assume  CS:code_seg, DS:code_seg,ES:code_seg
    org 100h
main:
jmp start

new_line macro    
    push AX
    push DX
        mov DL, 13
        mov AH, 02
        int 21h 
        mov DL, 10
        mov AH, 02
        int 21h 
    pop DX
    pop AX
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

put_num_in_buf macro
    local one_digit, two_digit, nxt_
    push ax
    push bx
        xor bh, bh
        mov bl, num_start
        cmp buffer[bx + 1], '0'
        jl one_digit
        cmp buffer[bx + 1], '9'
        jg one_digit
        jmp two_digit
        one_digit:
            mov num_str_buf[0], '0'
            mov al, buffer[bx]
            mov num_str_buf[1], al
            add bx, 6
        jmp nxt_

        two_digit:
            mov al, buffer[bx]
            mov num_str_buf[0], al 
            mov al, buffer[bx + 1]
            mov num_str_buf[1], al
            add bx, 7
        nxt_:
        mov num_start, bl
    pop bx
    pop ax
endm 

str_to_num macro var
    push ax
    push bx
        mov al, 0
        mov bl, 10 

        add al, num_str_buf[0]
        sub al, '0'
        mul bl
        add al, num_str_buf[1]
        sub al, '0'
        mov var, al
    pop bx
    pop ax
endm

div_vars macro v1, v2, v3
    push ax
    push bx
        xor ax, ax
        mov v1, al 
        mov bl, v2
        div bl
        mov v3, al
    pop ax
    pop bx
endm

; в point лежит координаты точки, малая половина столбец, старшая строка
mark_point macro
    push dx
    push bx
    push ax
    push cx
        mov dx, point
        mov bh, 0
        mov ah, 2
        int 10h ; переместить курсор

        mov al, 0b2h
        mov bh, 0
        mov bl, 07h
        mov cx, 1
        mov ah, 9h
        int 10h ; записать символ
    pop cx
    pop ax 
    pop bx 
    pop dx    
endm


start:
xor cx, cx     
mov cl, es:80h 
cmp cl, 0      
je no_arg       
    jmp arg_

no_arg:
    print_mes "Enter input file name: "
    mov dx, offset file_name          
    mov ah, 0ah                    
    int 21h                 
    new_line
    xor bx, bx              
    mov bl, file_name[1]       
    mov file_name[bx+2], 0     

    mov ax, 3d00h             
    mov al, 0               
    mov dx, offset file_name + 2       
    int 21h                         
    jnc ok1 
        print_mes "Open error"
        int 20h
    ok1:
    mov handle1, ax
    print_mes "Open OK"
    new_line
    jmp after_open

arg_:
    mov di, 81h
    mov al, 20h
    repe scasb 
    dec di     
    inc cx
    push di
    repne scasb 
    cmp cx, 0
    je skip1     
        dec di
    skip1:
    mov byte ptr[di], 0
    
    mov ah, 3dh
    mov al, 0
    pop dx
    int 21h 
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
    mov cx, 6000                 
    mov dx, offset buffer          
    int 21h
    mov buffer_size, ax       

process:
    put_num_in_buf  ; переместить в буфер число 
    str_to_num x1   ; перевести строку из буфера в число и записать в переменную
    put_num_in_buf 
    str_to_num y1   ; так же как для первого числа для остальных 3ех
    put_num_in_buf  
    str_to_num x2
    put_num_in_buf 
    str_to_num y2

    mov ax, 0700h    
    mov bh, 07h     ; базовые атрибуты для bh   
    xor cx, cx
    mov dx, 184fh
    int 10h         ; очистить экран

    ; определить самую левую точку и записать в ax
    mov al, x1
    mov ah, y1
    mov dl, x2
    mov dh, y2
    cmp al, dl 
    jle now_ax_is_left
        xchg ax, dx
    now_ax_is_left:

    mov point, ax ; закрасить левую точку
    mark_point

    mov point, dx ; закрасить правую 
    mark_point

    push ax
    push dx
    call draw_line_func

    mov dx, 1600h
    mov bh, 0
    mov ah, 2
    int 10h ; переместить курсор
    
exit:
    new_line
    print_mes "exit"
    mov ax, 4c00h
    int 21h

handle1 dw ?
handle2 dw ?
file_name db 24,?, 24 dup(' ')    
buffer db 6000 dup (?) 
buffer_size dw 0    
num_str_buf db 0, 0 
x1 db ?
y1 db ?
x2 db ?
y2 db ?
num_start db 3
point dw ? ; малая половина столбец, старшая строка

; первый аргумент левая точка, второй правая
draw_line_func proc 
    push bp
        mov bp, sp 
    push ax
    push dx
    push cx
        mov ax, [bp + 6] ; координаты 1ой точки
        mov dx, [bp + 4] ; координаты 2ой точки
        mov cx, ax 
        add cx, dx
        shr cl, 1 ; координаты середины отрезка
        shr ch, 1 

        cmp cx, ax 
        je exit_func ; точки близко и мы больше не вызываемся снова
        cmp cx, dx
        je exit_func

        again:
            mov point, cx
            mark_point ; закрасить середину

            push ax
            push cx
            call draw_line_func ; вызвать для левого полуотрезка

            push cx 
            push dx 
            call draw_line_func ; вызвать для правого полуотрезка
        
    exit_func:
    pop cx
    pop dx 
    pop ax 
    pop bp
    ret 4
draw_line_func endp

code_seg ends
end main