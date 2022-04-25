;15 Вставить в строке слово «number» перед словами, состоящими только из цифр.

.model small
;.386
JUMPS
.stack 100h
.data
    start_msg db "Enter a string",10,13,'$'
    word_number db "number"
    string  db 201
	        db ?
	        db 801 dup(?)
.code
 get_length proc
    pop ax
    pop bx
    sub ax, bx
    push ax
    ret
 get_length endp

 left_shift_with_insert macro count, str, word
	pop dx
	push di
	push si
	mov si, dx
	xor ax, ax
	;mov al, byte ptr [str + 1]
	mov ax,bx
	mov di, offset str + 2
	add di, ax
	inc di
	shift_loop:
	    dec di
	    mov al, byte ptr ds:[di]            ; косвенная аддрессация
	    mov byte ptr ds:[di+6], al          ; туть со сдвигом , т.к учитываем длину number
	    cmp di, si
	    je  _insert_word
	    jmp shift_loop
	_insert_word:
	    mov di, offset word
	    xor cx, cx
	    mov cx, 6
	    _insert_word_loop:
		mov al, [di]
		mov [si], al
		inc di
		inc si
	    loop _insert_word_loop
	    jmp _exit_shift
	 _exit_shift:
	    pop si
	    pop di
  endm


_start:
    mov ax, @data
    mov ds, ax

_start_msg:
    mov dx, offset start_msg
    mov ah, 9
    int 21h
    ;mov dx, offset string
    ;mov ah, 0Ah
    ;int 21h
    xor cx,cx
    mov si, offset string + 2
enter_line_text:
    mov ah,1
    int 21h
    cmp al,0Dh
    je _replace_enter
    mov byte ptr[si],al
    inc si
    inc cx
    cmp cx,200
    je _replace_enter
    jmp enter_line_text

_replace_enter:
   ; kostul
    ;mov si, offset string + 1
    ;mov [si], cl
   mov bx, cx
   xor cx, cx
   ;--------
    xor si, si
    ;mov si, offset string + 1
    mov si, bx
    xor ch, ch
    mov cx, si
    inc cx
    mov si, offset string + 1
    add si,cx
    mov al, '$'
    mov [si], al

_prepare_for_searching_words:
    mov di, offset string + 2
    xor ax, ax
    mov al, 32
    xor cx, cx
        ;mov cl, byte ptr[string + 1]
    mov cx, bx
    inc cx
    jmp _find_word

_inc_dest_index:
    mov di, si
    inc di
    xor ax, ax
    mov ah, '$'
    mov al, [di]
    inc di
    pop cx
    cmp ah, al
    je _exit
    jmp _find_word

_find_word:
    push di
    jmp _start_searching_word

_start_searching_word:
    mov ah, [di]
    inc di
    cmp al, ah
    je _check_is_number
    loop _start_searching_word
    jmp _check_is_number


_check_is_number_last:
    dec di
    mov si, di
    pop di
    push cx
    xor dx, dx
    mov dx, di
    dec di
    xor ax, ax
    cmp di, si
    je _inc_dest_index
    jmp _start_cheking_last

_start_cheking_last:
    cmp di, si
    je _out_founded_word
    inc di
    mov ah, "0"
    mov al, [di]
    cmp al, ah
    jl _exit                            ; if sf != of (sf - znak)
    mov ah, "9"
    cmp al, ah
    jg _exit
    jmp _start_cheking_last

_check_is_number:
    dec cx
    sub di, 2
    mov si, di
    pop di
    push cx
    xor dx, dx
    mov dx, di
    dec di
    xor ax, ax
    cmp di, si
    je _inc_dest_index
    jmp _start_cheking

_start_cheking:
    cmp di, si
    je _insert_word_number
    inc di
    mov ah, "0"
    mov al, [di]
    cmp al, ah
    jl _inc_dest_index
    mov ah, "9"
    cmp al, ah
    jg _inc_dest_index
    jmp _start_cheking

_insert_word_number:
    push dx
    left_shift_with_insert 6, string, word_number
    add di, 6
    add si, 6
    xor ax, ax
        ;mov al, byte ptr[string+1]
    mov ax,bx
        ;add al, 6
    add ax,6
        ;mov byte ptr[string+1], al
    mov bx,ax
    jmp _inc_dest_index



_out_founded_word:
    mov di, dx
    dec di
    xor dx, dx
    jmp _print_word
_print_word:
    inc di
    mov dl, [di]
    mov ah, 2
    int 21h
    cmp si, di
    jne _print_word
    je _inc_dest_index

_exit_without_output:
    mov ah, 4Ch
    int 21h

_exit:
    mov dl, 10;
    mov ah, 2
    int 21h
    mov dl, 13;
    mov ah, 2
    int 21h
    mov dx, offset string + 2
    mov ah, 9
    int 21h
    mov ah, 4Ch
    int 21h
end _start
