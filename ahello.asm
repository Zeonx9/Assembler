code_seg segment
	assume cs:code_seg, ds:code_seg, ss:code_seg
	org 100h
main: 
	jmp begin

msg db 'Hello, world, or something', 13, 10, '$'

begin:
	mov ah, 9h
	lea dx, msg
	int 21h
	int 20h

code_seg ends
end main
