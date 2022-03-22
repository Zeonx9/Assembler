code_seg segment
	assume cs:code_seg,ds:code_seg,ss:code_seg
	org 100h
start:
org 100h

Begin:
       mov ax,3
       int 10h        ;Чистим экран

       mov ax,cs:[2Ch]
       mov ds,ax      ;DS указывает  на сегмент окружения DOS
       xor si,si      ;SI - смещение

       mov ah,2       ;Функция вывода одного символа на экран

Next_char:
       lodsb          ;Получаем первый символ
       or al,al       ;Это ноль?
       jz End_param   ;Да - тогда первый параметр закончился 

Next_param:
       mov dl,al      ;Нет, не ноль. Тогда выводим полученный символ...
       int 21h        ;...на экран в текущую позицию курсора
       jmp short Next_char ; Приступаем к следующему символу... 

End_param:
       mov dl,0Ah     ;Достигнут конец первого параметра
       int 21h        ;Выведем возврат каретки / перевод строки,
       mov dl,0Dh     ;чтобы параметры не были в куче, а каждый начинался
       int 21h        ;со следующей строки.

       lodsb          ;Получим очередной символ из строки окружения DOS
       or al,al       ;Если это 0, то все параметры выведены.
       jnz Next_param ;Пора выходить в DOS.
                      ;Иначе - выводим очередной параметр... 

       ;int 20h
	   inc	SI			; skip two bytes
	   inc	SI
Next_char_:
       lodsb          ;Получаем первый символ
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
