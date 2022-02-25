prog segment
	assume cs:prog, ds:prog, ss:prog
	org 100h
main: 
	jmp begin

msg db 'prepairing for print...', 13, 10, '$'
bsize equ 20
buffer db bsize, ?, bsize dup(' ')

; main code
begin:
	; get input from keyboard
	push offset buffer
	call input

	push offset msg
	call print
	call newline

	push offset buffer + 2
	call print
	call newline


	; exit
	int 20h	

; functions and procedures
print proc 
	mov si, sp					; get addres of top of stack
	mov dx, [si + 2]			; get parameter (adress of messege) from previous value in the stack 
	push ax 					; save ax state

	mov ah, 09h					; chose function 09h for printig string
	int 21h						; call interuption 

	pop ax						; recover ax state
	ret
print endp

input proc
	mov si, sp					; get addres of top of stack
	mov dx, [si + 2]			; get parameter (adress of messege) from previous value in the stack 
	push ax						; save ax and bx state
	push bx

	mov ah, 0ah					; chose function 09h for printig string
	int 21h						; call interuption 
	xor bx, bx					; clear bx register
	mov di, dx					; get adress of input
	mov bl, [di + 1]			; put into low byte of bx the length of input which is definde in second byte of buffer
	mov [di + bx + 2], '$'		; put terminal character '$' right after last got byte which is

	pop bx						; recover ax and bx state
	pop ax						
	ret
input endp

newline proc
	push ax                     ; save state
	push dx

	mov ah, 02h                 ; chose 02h function to print 1 char
	mov dl, 13                  ; print 13, and then 10
	int 21h
	mov dl, 10
	int 21h

	pop dx                      ; recover state
	pop ax
	ret
ewline endp

prog ends
end main