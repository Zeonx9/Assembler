prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h
main: 
	jmp begin

; variables
input_file_name db 20, ?, 20 dup(?)  
handle dw ?
file_name_offset dw ?
symbols dw 100
buffer db 100 dup(?)
msg db "was modified! "
msg_len dw $ - offset msg
nl db 13, 10 ; '\n'

;macro
puts macro str
    local s, body
    jmp body
    	s db str, '$'
    body:  
    push ax
    push dx 
        mov ah, 09h
        mov dx, offset s
        int 21h        
    pop dx
    pop ax
endm  

new_line macro 
    push ax
    push dx 
        mov ah, 02h
        mov dl, 13
        int 21h   
        mov dl, 10
        int 21h     
    pop dx
    pop ax
endm 

fw_new_line macro
	; bx should contain file handle
	push cx
	push ax
	push dx
		mov cx, 2
	    mov dx, offset nl
	    mov ah, 40h
	    int 21h
	pop dx
	pop ax
	pop cx
endm

; main
begin:
	xor bh, bh		
	mov bl, es:80h ; get length of arguments into bx
	cmp bl, 0
	je no_args      	
		mov byte ptr [bx + 81h], 0 ; make asciiz (put 0 after string)
		mov file_name_offset, 82h
		jmp open
	
	no_args: ; if no args get file name from keyboard  
    	puts "enter file name >"
    	new_line
    	
    	mov ah, 0ah ; get file name from keyboard
    	mov dx, offset input_file_name
    	int 21h  

    	xor ax, ax ; make asciiz (put 0 after string)
        mov al, input_file_name[1]
        mov di, ax
        mov input_file_name[di + 2], 0  
        mov file_name_offset, offset input_file_name + 2  
        
    open:
    	mov ax, 3d02h ; try to open file
    	mov dx, file_name_offset
    	int 21h 
    	jc error
    	jmp work

    error:
		puts "open Error!"
		jmp exit

	; do something with open file
    work:
    	mov handle, ax
    	puts "file opened"
    	new_line
    	puts "read from file: "
    	new_line

    	mov bx, handle ; read from file
    	mov ah, 3fh
    	mov dx, offset buffer
    	mov cx, symbols
    	int 21h

    	mov symbols, ax ; print to console
    	mov bx, symbols
    	mov buffer[bx], '$'
    	mov ah, 09h
    	mov dx, offset buffer
    	int 21h

    	mov bx, handle ; write to file
    	fw_new_line
    	mov cx, msg_len
    	mov dx, offset msg
    	mov ah, 40h
    	int 21h

    	mov bx, handle ; close file
    	mov ah, 3eh
    	int 21h
    
    exit:
		int 20h
	
prog ends
end main