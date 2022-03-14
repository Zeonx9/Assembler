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
mov cx, 5000                 
mov dx, offset buffer          
int 21h
mov buffer_size, ax       

; code
lea si, buffer
lea di, outbuf
lea bp, key
mov cx, buffer_size
lea bx, lookup
xor ah, ah
encode_letter:
	mov al, byte ptr [si]
	cmp al, 'A'
	jl no_replace
	cmp al, 'z'
	jg no_replace
	cmp al, 'Z'
	jle replace
	cmp al, 'a'
	jge replace
	replace:
		sub al, 'a'
		mov dl, byte ptr [bp]
		sub dl, 'a'
		add al, dl 
		xlatb
		inc bp
	no_replace:
	mov byte ptr [di], al
	inc si 
	inc di
loop encode_letter

mov byte ptr [di], '$'
mov ah, 09h
lea dx, outbuf
int 21h
new_line

print_mes "Enter output file name: "
mov dx, offset file_name          
mov ah, 0ah                    
int 21h                 
new_line
xor bx, bx              
mov bl, file_name[1]       
mov file_name[bx+2], 0     
mov ax, 3d01h                           
mov dx, offset file_name + 2       
int 21h                         
jnc ok3
    print_mes "Open error"
    int 20h
ok3:
mov handle2, ax

mov ah, 40h
mov bx, handle2
mov cx, buffer_size
lea dx, outbuf
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

handle1 dw ?
handle2 dw ?
file_name db 27,?, 27 dup(' ')    
buffer db 5000 dup (?)
outbuf db 5000 dup (?) 
key	   db 1250 dup ('c', 'o', 'd', 'e') ; key word = "code"    
lookup db "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabc"       
buffer_size dw ?        

code_seg ends
end main