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
    jmp nxt
       msg DB message,'$'
    nxt:
    push AX
    push DX
        mov DX, offset msg
        mov AH, 09h
        int 21h
    pop DX
    pop AX
endm 

copy_to_buf macro c 
    mov byte ptr [di], c 
    inc di
endm  

start:
xor cx, cx     
mov cl, es:80h 
cmp cl, 0      
je no_arg       
    jmp arg_

no_arg:
    print_mes "Error! no params"
    jmp exit

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
    mov al, 1
    pop dx
    int 21h 
    jnc ok2 
        print_mes "Open error"
        int 20h
    ok2:
    mov handle, ax
    print_mes "Open OK"
    new_line
    jmp after_open

after_open:  
print_mes "Enter symbol to start: "                         
mov ah, 0ah
lea dx, inp
int 21h
new_line

lea di, buffer ; for copy_to_buff

xor dh, dh
mov dl, inp[2] ; symbol
mov cx, 256
sub cx, dx ; count cycle

mov ah, 02h ; for interupt
lea bx, digits ; for xlatb
print_info:
    copy_to_buf dl
    int 21h

    copy_to_buf ' '
    copy_to_buf '-'
    copy_to_buf ' '
    print_mes " - "

    push dx
        mov al, dl
        shr al, 4
        xlatb
        mov dl, al
        copy_to_buf al
        int 21h
    pop dx
    push dx
        mov al, dl
        and al, 0fh
        xlatb
        mov dl, al
        copy_to_buf dl
        int 21h
    pop dx
    
    copy_to_buf 13
    copy_to_buf 10
    new_line
    inc dl
loop print_info

mov buffer_size, di
sub buffer_size, offset buffer

mov ah, 40h
mov bx, handle
mov cx, buffer_size
lea dx, buffer
int 21h
jnc ok4
    print_mes "cannot write"
    jmp exit
ok4:

exit:
new_line
print_mes "exit"
mov ax, 4c00h
int 21h 

handle dw ?
inp db 3, ?, 3 dup(?)    
buffer db 1000h dup(?)            
buffer_size dw ? 
digits db "0123456789ABCDEF"

code_seg ends
end main