code_seg segment
	assume cs:code_seg,ds:code_seg,ss:code_seg
	org 100h
start:
org 100h

Begin:
       mov ax,3
       int 10h        ;������ �����

       mov ax,cs:[2Ch]
       mov ds,ax      ;DS ���������  �� ������� ��������� DOS
       xor si,si      ;SI - ��������

       mov ah,2       ;������� ������ ������ ������� �� �����

Next_char:
       lodsb          ;�������� ������ ������
       or al,al       ;��� ����?
       jz End_param   ;�� - ����� ������ �������� ���������� 

Next_param:
       mov dl,al      ;���, �� ����. ����� ������� ���������� ������...
       int 21h        ;...�� ����� � ������� ������� �������
       jmp short Next_char ; ���������� � ���������� �������... 

End_param:
       mov dl,0Ah     ;��������� ����� ������� ���������
       int 21h        ;������� ������� ������� / ������� ������,
       mov dl,0Dh     ;����� ��������� �� ���� � ����, � ������ ���������
       int 21h        ;�� ��������� ������.

       lodsb          ;������� ��������� ������ �� ������ ��������� DOS
       or al,al       ;���� ��� 0, �� ��� ��������� ��������.
       jnz Next_param ;���� �������� � DOS.
                      ;����� - ������� ��������� ��������... 

       ;int 20h
	   inc	SI			; skip two bytes
	   inc	SI
Next_char_:
       lodsb          ;�������� ������ ������
       or al,al       ;Is it zero?
       jz End_   ;Yes - string of program run is ended 

Next_param_:
       mov dl,al      ;No, print received character...
       int 21h        ;
       jmp short Next_char_ ; goto next character... 
End_ :
	int	20h	   

code_seg ends
         end start
