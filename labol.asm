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
    print_mes "Enter output file name: "
    mov dx, offset file_name          
    mov ah, 0ah                    
    int 21h                 
    new_line
    xor bx, bx              
    mov bl, file_name[1]       
    mov file_name[bx+2], 0     

    mov ax, 3d00h             
    mov al, 1               
    mov dx, offset file_name + 2       
    int 21h                         
    jnc ok3 
        print_mes "Open error"
        int 20h
    ok3:
    mov handle2, ax
    print_mes "Open OK"
    new_line

    mov ah, 3fh                   
    mov bx, handle1                
    mov cx, 2000h                 
    mov dx, offset buffer          
    int 21h
    mov buffer_size, ax       

process:
    lea si, buffer
    lea di, outbuf

    mov cx, buffer_size
    mov ah, 02h
    put_sym_in_buf:
        mov dl, byte ptr [si]
        mov byte ptr [di], dl 
        int 21h
        inc si 
        inc di 

        cmp dl, '.'
        je newl
        cmp dl, '!'
        je newl 
        cmp dl, '?'
        je newl
            jmp next_

        newl:
            new_line
            mov byte ptr [di], 13
            inc di
            mov byte ptr [di], 10
            inc di

            skip_sen:
                mov dl, byte ptr [si]
                cmp dl, 'A'
                jl incr_
                cmp dl, 'z'
                jg incr_
                cmp dl, 'Z'
                jle next_
                cmp dl, 'a'
                jge next_
                incr_:
                    inc si
                    dec cx 
                cmp cx, 0
                je write_
            jmp skip_sen

        next_:
    loop put_sym_in_buf

    write_:
    mov cx, di
    sub cx, offset outbuf
    mov ah, 40h 
    mov bx, handle2
    lea dx, outbuf
    int 21h
    
exit:
    new_line
    print_mes "exit"
    mov ax, 4c00h
    int 21h

handle1 dw ?
handle2 dw ?
file_name db 24,?, 24 dup(' ')    
buffer db 2000h dup (?) 
outbuf db 2000h dup (?)
buffer_size dw 0    

code_seg ends
end main