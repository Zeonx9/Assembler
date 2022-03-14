prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h
main: 
	jmp begin
; macro
save_state macro 
    push ax
    push bx  
    push cx 
    push dx
    push si
    push di 
    push bp        
endm  

recover_state macro
    pop bp
    pop di
    pop si  
    pop dx
    pop cx
    pop bx
    pop ax 
endm

prints macro str
    local skip, s
    save_state
    mov ah, 09h
    mov dx, offset s
    int 21h 
    jmp skip
        s db str, '$'
    skip:       
    recover_state
endm 

pope macro
    add sp, 2
endm

; procedures
puts proc  
    save_state
    mov si, sp
    mov dx, [si + saved_state]   
    mov ah, 09h
    int 21h  
    recover_state
    ret    
puts endp  
             
newline proc   
    save_state
    mov ah, 02h  
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    recover_state
    ret    
newline endp

gets proc
    save_state  
    mov si, sp
    mov dx, [si + saved_state]   
    mov ah, 0ah
    int 21h 
    mov di, dx
    xor bh, bh
    mov bl, [di + 1]           
    mov byte ptr [di + bx + 2], '$' 
    recover_state
    ret    
gets endp   

scanint proc 
    save_state
    jmp body
        buff db 10, 0, 10 dup(0)
    body:  
    push offset buff
    call gets
    add sp, 2
    
    mov si, sp
    mov di, [si + saved_state]
    xor ax, ax 
    xor ch, ch
    mov cl, buff[1]
    mov bx, 2  
    xor dh, dh    
    cycle: 
        push cx
        mov cx, 10
        mul cx
        mov dl, buff[bx]
        sub dl, '0'
        add ax, dx  
        inc bx  
        pop cx
    loop cycle  
    mov [di], ax
    recover_state
    ret    
scanint endp

printint proc
    save_state
    mov si, sp
    mov di, [si + saved_state]
    mov dx, [di]
    mov bl, 10  
    xor cx, cx
    put_dig_to_stack:
        mov ax, dx
        div bl
        xor dh, dh  
        mov dl, ah
        push dx
        inc cx
        mov dl, al 
    cmp dl, 0   
    jne put_dig_to_stack 
    
    mov ah, 02h    
    print_dig:  
        pop dx
        add dx, '0'
        int 21h
    loop print_dig
    recover_state
    ret
printint endp

; variables   
len equ 40
saved_state equ 16
msg db len, 0, len dup(0)  
a dw 0
b dw 0
c dw 0

; main
begin:  
    push offset a
    call scanint
    pope
    call newline
    push offset b
    call scanint
    pope
    call newline

    mov ax, a
    add ax, b
    mov c, ax

    call newline
    push offset a
    call printint
    pope
    prints " + "
    push offset b
    call printint
    pope
    prints " = "
    push offset c
    call printint
    pope
    call newline

    int 20h
prog ends
end main