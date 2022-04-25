.model small
.stack 100h
JUMPS
.data 
; operations
op db 2,2 dup(?)
op1 db 10,13,"1) Print array$"
op2 db 10,13,"2) Inverse$"
op3 db 10,13,"3) Absolute$:"
op4 db 10,13,"4) Square$"
op5 db 10,13,"5) Multiplicative inverse$"
op6 db 10,13,"6) Quit$"
op7 db 10,13,"7) Arithmetic shift (1-r, 2-l)$"
op8 db 10,13,"8) Logic shift (1-r, 2-l)$"
;messages                                 
msg1 db 10,13,"Error: incorrect input $" 
msg2 db 10,13,"Error: overflow $"
msg3 db 10,13,"Error: 0 dose not have multiplicative inverse$"
msg4 db "Enter array of 30 numbers$" 
msg5 db 10,13,"Enter number of operation$"
;other data
nl db 10,13,'$'
buf db 10,10 dup(?) ; -32768 to 32767
out_buf db 6 dup(?),'$'
mul_inv_buf db "00.", 5 dup('0'), '$'
array dw 30 dup(?)

.code

print_str macro out_str
    mov dx,offset out_str 
    mov ah,9h
    int 21h
endm          
                
                
                
                
get_str macro buff 
    mov ah,0Ah
	mov dx,offset buff
	int 21h 
	
	   
endm  


start:           
             
    mov ax,@data
    mov ds,ax 
    
    print_str msg4
    print_str nl
     
    
    call get_array
     
    main:  
        print_str nl
        print_str op1
        print_str op2
        print_str op3
        print_str op4
        print_str op5
        print_str op6 
        print_str op7
        print_str op8
        print_str msg5
        print_str nl
        get_str op
        
        mov bl,op[2]
        cmp bl,'1'
        je call_op1
        cmp bl,'2' 
        je call_op2
        cmp bl,'3'
        je call_op3
        cmp bl,'4' 
        je call_op4
        cmp bl,'5' 
        je call_op5
        cmp bl,'6'
        je exit_main
        cmp bl, '7'
        je call_op7
        cmp bl, '8'
        je call_op8
        
        
        jmp main
        
        call_op1:
            call print_array
            jmp main
        call_op2:
            call inv_all
            jmp main
        call_op3:
            call abs_all
            jmp main
        call_op4:
            call sqr_all
            jmp main
        call_op5:
            call mul_inv_all
            jmp main
        call_op7:
            call arithmetic_shift
            jmp main
        call_op8:
            call logic_shift
            jmp main
        
        
    
    exit_main:

    mov ah,4ch
    int 21h



 ;; Arithmetic shift -------------------------------              
arithmetic_shift proc uses di 
    
    arithmetic_shift_start:
        print_str nl
        mov di,0
        get_str op
        mov bl,op[2]
        cmp bl,'1'
        je arithmetic_shift_main
        cmp bl,'2'
        je arithmetic_shift_main
        jmp arithmetic_shift_start

    arithmetic_shift_main:
        cmp di,60
        je arithmetic_shift_end
        call a_shft
        add di,2
        jmp arithmetic_shift_main
    
    arithmetic_shift_end: 
    ret        
arithmetic_shift endp


a_shft proc uses ax 

    a_start:
        mov ax,array[di]
        cmp bl,'1'
        je a_right
        cmp bl,'2'
        je a_left
    
    ;not ax
    ;add ax,1
    a_shft_main:
        ;jo a_shft_error
        mov array[di],ax
        jmp a_shft_end
    
    a_left:
        sal ax, 1
        jmp a_shft_main

    a_right:
        sar ax, 1
        jmp a_shft_main

    a_shft_error:
        print_str msg2
    
    a_shft_end:
    ret

a_shft endp

;; Logic shift -----------------------------------------

logic_shift proc uses di 
    
    logic_shift_start:
        print_str nl
        mov di,0
        get_str op
        mov bl,op[2]
        cmp bl,'1'
        je logic_shift_main
        cmp bl,'2'
        je logic_shift_main
        jmp logic_shift_start

    logic_shift_main:
        cmp di,60
        je logic_shift_end
        call l_shft
        add di,2
        jmp logic_shift_main
    
    logic_shift_end: 
    ret       

logic_shift endp


l_shft proc uses ax 

    l_start:
        mov ax,array[di]
        cmp bl,'1'
        je l_right
        cmp bl,'2'
        je l_left
    
    ;not ax
    ;add ax,1
    l_shft_main:
        ;jo l_shft_error
        mov array[di],ax
        jmp l_shft_end
    
    l_left:
        shl ax, 1
        jmp l_shft_main

    l_right:
        shr ax, 1
        jmp l_shft_main

    l_shft_error:
        print_str msg2
    
    l_shft_end:
    ret

l_shft endp
;;---------------------------------------------------------------
     
inv proc uses ax
    
    mov ax,array[di]
    cmp ax,32768
    je inv_error
    not ax
    add ax,1
    mov array[di],ax
    jmp inv_end
    
    
    inv_error:
        print_str msg2
    
    inv_end:
            
    ret            
inv endp     
     
     
inv_all proc uses di
    mov di,0
    ia:
        cmp di,60
        je ia_end
        call inv
        add di,2
        jmp ia
    
    ia_end: 
    ret    
inv_all endp

 
 
 
 
 
mul_inv proc uses ax,bx,cx,dx,si      ; multiplicative inverse with 4-5 digits accuracy 
    
    
    mov ax,array[di]
    cmp ax,0
    je mi_zero
    
    xor bx,bx
    mov bx, offset mul_inv_buf
    mov si,0 
    
    fill_zero:
        cmp si,8
        je mi_check_sign
        cmp si,2
        je dot
        mov bx[si],'0'
        inc si
        jmp fill_zero
    dot:
        inc si
        jmp fill_zero
        
    
    mi_check_sign:
        mov bx, offset mul_inv_buf + 8
        mov byte ptr [bx],'$'
        and ax,32768
        cmp ax,32768
        je mi_negative
        jmp mi_positive
        
    mi_negative:
        mov ax,array[di]
        not ax
        add ax,1
        mov bl,'-'
        mov mul_inv_buf,bl
        cmp ax,1
        je mi_one
        cmp ax,10000
        ja more_10000
        jmp mi_main 
        
    mi_positive:
        mov ax,array[di]
        cmp ax,1
        je mi_one
        cmp ax,10000
        ja more_10000
        
        
    mi_main:
        xor dx,dx
        mov bx,ax
        mov ax,10000
        idiv bx
        mov cx,10
        xor bx,bx
        mov bx,offset mul_inv_buf
        mov si,6
        mi_cycle:
            xor dx,dx
            div cx
            cmp si,2
            je mi_main_end
            add dl,'0'
            mov bx[si],dl
            dec si
            jmp mi_cycle
        
    mi_main_end:
        print_str mul_inv_buf
        jmp mi_end     
        
        
    
    
    more_10000:
        xor dx,dx
        mov bx,10
        div bx
        mov bx,ax
        mov ax,10000
        xor dx,dx
        div bx
        add al,'0'
        mov mul_inv_buf[7],al
        print_str mul_inv_buf
        jmp mi_end
        
        
        
       
    
    mi_zero:
        print_str msg3
        jmp mi_end
        
    mi_one:
        mov bl,'1'
        mov mul_inv_buf[1],bl
        
        print_str mul_inv_buf
        
    mi_end:
    ret
mul_inv endp 
 
    
    
    
mul_inv_all proc uses di
    mov di,0
    mia:
        cmp di,60
        je mia_end
        print_str nl
        call mul_inv
        add di,2
        jmp mia
    
    mia_end: 
    ret    
mul_inv_all endp

   

    
   
sqr proc uses ax  
    
    mov ax,array[di]
    and ax,32768
    cmp ax,32768
    mov ax,array[di]
    jne sqr_main
    
    not ax
    add ax,1
    
    sqr_main:
        imul ax
        jo sqr_error
        mov array[di],ax
        jmp sqr_end
    
    sqr_error:
        print_str msg2 
    
    sqr_end:
    
    ret
sqr endp

 
    

sqr_all proc uses di
    mov di,0
    sa:
        cmp di,60
        je sa_end
        call sqr
        add di,2
        jmp sa
    
    sa_end:        
    ret            
sqr_all endp

     
    
    
abs proc uses ax
    
    mov ax,array[di]
    cmp ax,32768
    je abs_error
    and ax,32768
    cmp ax,32768
    jne abs_end  ;if positive
    
    mov ax,array[di]
    not ax
    add ax,1
    mov array[di],ax
    jmp abs_end
    
    abs_error:
        print_str msg2   
    
    abs_end:
     
    ret
abs endp 





abs_all proc uses di
    mov di,0
    aa:
        cmp di,60
        je aa_end
        call abs
        add di,2
        jmp aa
    
    aa_end:        
    ret         
abs_all endp   
   



print_num proc uses ax,bx,cx,dx,si                 
    
    
    xor si,si
    mov si,5 
    
    mov cx, 10
    
    check_sign:
        mov ax, array[di]
        and ax,32768
        cmp ax,32768
        je negative
        jmp positive
        
    negative:
        mov ax,array[di]
        not ax
        add ax,1
        mov bl,'-'
        mov out_buf,bl
        jmp cycle1
        
    
    positive:
        mov ax,array[di]
        mov bl,'0'
        mov out_buf,bl
        jmp cycle1
    
    cycle1: 
        xor bx,bx
        mov bx, offset out_buf
        
        xor dx,dx
        ;mov dl, 10
        div cx
        add dx,'0'
        mov bx[si], dl
        dec si
        cmp si,0
        je end_print_num
        jmp cycle1
    
    end_print_num:
        print_str nl
        print_str out_buf
        
    ret        
print_num endp 




   
   
print_array proc uses di
    mov di,0
    print:
        cmp di,60
        je print_end
        call print_num
        add di,2
        jmp print
    
    print_end:
    
    ret    
print_array endp

 



get_num proc uses ax,bx,cx,dx,si           
    
    xor cx,cx
    mov cl, buf[1]
    cmp cx,0
    je error_input ;no input (pressed enter)
    mov si,2 
    xor bx,bx
    mov bl,buf[si]
    cmp bl,'-'
    jne atoi
    cmp cl,1
    je error_input
    inc si
    dec cx
    
    atoi:
        xor ax, ax ; zero a "result so far"
        top:
            cmp cx,0
            je end_atoi    
            xor bx,bx 
            mov dx, 10 
            mov bl, buf[si] ; get a character
            inc si ; ready for next one
            cmp bl, '0' ; valid?
            jb error_input
            cmp bl, '9'
            ja error_input
            sub bl, '0' ; "convert" character to number 
            imul dx ; multiply "result so far" by ten 
            jc error_overflow
            add ax, bx ; add in current digit
            dec cx
            jmp top ; until done 
            
        end_atoi:     
            xor bx,bx
            mov bl,buf[2]
            cmp bl,'-'
            je _negative
            
            cmp ax,32767
            ja error_overflow
            
            jmp put_in_array   
    
    _negative:  
        cmp ax, 32768
        ja error_overflow
        not ax       ; turn into two's complement
        add ax,1     ;
        
    put_in_array:
        mov array[di],ax
        jmp exit
        
    error_input: 
        sub di,2
        print_str msg1
        jmp exit
    error_overflow:
        sub di,2
        print_str msg2
        ;jmp exit
    
    exit:
    
    ret
get_num endp



 
get_array proc uses di
    xor di,di
    get_array_loop: 
        get_str buf
        call get_num 
        add di,2
        print_str nl
        cmp di, 60
        jne get_array_loop
    ret
get_array endp
     

end start
