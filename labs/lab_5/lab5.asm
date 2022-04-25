.model small
.stack 256h
.data    
    end_str db 3,"$"
    success db "File was inversed by strings!$"
    opened db "File has been opened$"
    temp db 0,"$" 
    start_str db 4,"$"
    file_handle dw 0
    endl db 10,13,"$"
    buffer_0 db 2
    len_0 db 0                                    
    symbol db 1 dup("$")
    not_found_file db "File not found!$"    
    buffer_1 db 129
    len_1 db 0
    filename_1 db 128 dup("$")
    filename_2 db "Temp.txt",0,"$"
.code
;-------------------
clear proc near
    mov ah,0
    mov al,3
    int 10h                                     ;clear screen
    mov ah,02                                   ;set cursor to left corner of screen
    mov dh,0
    mov dl,0
    int 10h
    ret
clear endp
;-------------------
cout macro str
    mov ah,09h
    lea dx,str
    int 21h       
endm
;-------------------
cin macro str
    mov ah,0ah
    lea dx,str
    int 21h
    xor si,si
    loop_end:               
        mov al,str[si]
        cmp al,13
        je cn
        inc si
        jmp loop_end
    cn:
    mov str[si],0    
endm 
;-------------------
skip proc
    mov ah,42h                                  ;set pointer of file
    mov al,1                                    ;current position                                                                        
    mov cx,-1
    mov dx,-2
    int 21h                                     
    skip_procedure_cycle:                       
        mov cx,1
        mov ah,3fh
        lea dx,buffer_0
        int 21h                         
        mov ah,42h
        mov al,1                                    
        mov cx,-1
        mov dx,-2
        int 21h
        mov al,buffer_0[0]
        cmp al,10
        je skip_proc_exit
        jmp skip_procedure_cycle
    skip_proc_exit:    
    ret
skip endp
;-------------------
search proc 
    search_procedure_cycle:
        mov cx,1                                ;num of byte
        mov ah,3fh                              ;read from file
        lea dx,buffer_0
        int 21h           
        mov al,buffer_0[0]
        cmp al,10
        je search_proc_exit1
        cmp al,4
        je search_proc_exit2               
        mov ah,42h
        mov al,1                                    
        mov cx,-1
        mov dx,-2
        int 21h 
        jmp search_procedure_cycle
    search_proc_exit2:
    mov ah,42h
    mov al,1                                    
    mov cx,-1
    mov dx,-1
    int 21h
    search_proc_exit1:
    ret
search endp
;-------------------
main:   
    mov ax,@data
    mov ds,ax
    call clear    
    cout opened
    cout endl
    xor cx,cx
    xor di,di
    mov si,80h
    command_line_input:
        mov al,es:[si]
        inc si
        cmp al,0                 
        je command_line_end        
        mov buffer_1[di],al
        inc di
        jmp command_line_input
    command_line_end:
    xor si,si
    xor di,di
    xor si,si
    loop_end_e:               
        mov al,buffer_1[si]
        cmp al,13
        je cn1
        inc si
        jmp loop_end_e
    cn1:    
    mov buffer_1[si],0 
    mov dx,offset filename_1
    mov ah,3dh                                  ;open existing file
    mov al,00000010b                            ;writing parameter
    int 21h
    jc er1
    jmp er2
    er1:
    jmp err_exit
    er2:

    mov bx,ax
    mov file_handle,bx   
    
    mov cx,1
    mov ah,3fh
    lea dx,temp
    int 21h
    mov temp[1],'$'
    mov ah,42h
    mov al,0                                    
    mov cx,0
    mov dx,0
    int 21h
    mov ah,40h                                  ;write in file 
    mov cx,1                                    ;num of bytes
    mov dx,offset start_str                     ;data buf
    int 21h 
    
    mov ah,5bh                                  ;create and open new file
    xor cx,cx
    lea dx,filename_2
    int 21h
    mov bx,ax                                   ;mov file descriptor
        
    push bx  ;>>
    mov ah,42h                           
    mov al,2
    mov bx,file_handle                                    
    mov cx,0
    mov dx,0
    int 21h                                     ;understand the size of file
    mov ah,40h
    mov cx,1
    mov dx,offset end_str
    int 21h     
             
    xor si,si
    mov ah,42h
    mov al,2                                   
    mov cx,-1
    mov dx,-2
    int 21h
    pop bx  ;<<
    reading_cycle:
        push bx  ;>>
        mov bx,file_handle
        call search
        mov cx,1
        mov ah,3fh
        lea dx,buffer_0
        int 21h           
        mov al,buffer_0[0]       
        cmp al,4
        je end_reading_cycle        
        mov ah,42h
        mov al,1                                    
        mov cx,-1
        mov dx,-1
        int 21h
        pop bx ;<<  
        cout_file:                                      ;read f-st file and write to buffer string in vice versa order
            push bx
            mov bx,file_handle
            mov cx,1
            mov ah,3fh
            lea dx,buffer_0
            int 21h 
            pop bx  ;<<        
            mov al,buffer_0[0]
            cmp al,10
            je end_cout_cycle
            cmp al,3
            je end_cout_cycle
            mov buffer_0[1],36
            ;cout buffer_0 ;!!!
            mov ah,40h
            mov cx,1
            lea dx,buffer_0
            int 21h
            jmp cout_file
        end_cout_cycle:
        ;cout endl;!!!
        mov ah,40h
        mov cx,1
        lea dx,endl
        int 21h
        push bx   ;>>
        mov bx,file_handle
        call skip
        pop bx  ;<<
        jmp reading_cycle
    end_reading_cycle:
    pop bx ;<<
    ;cout temp ;!!!
    mov ah,40h
    mov cx,1
    lea dx,temp
    int 21h 
    cout_last_string:
        push bx
        mov bx,file_handle
        mov cx,1
        mov ah,3fh
        lea dx,buffer_0
        int 21h
        mov al,buffer_0[0]
        pop bx ;<<
        cmp al,10
        je end_cout_last_string
        cmp al,3
        je end_cout_last_string
        mov buffer_0[1],36
        ;cout buffer_0 ;!!!
        mov ah,40h
        mov cx,1
        lea dx,buffer_0
        int 21h
        jmp cout_last_string
    end_cout_last_string:
    mov ah,40h
    mov cx,1
    lea dx,end_str
    int 21h
    
    mov ah,42h
    mov al,0                                    
    mov cx,0
    mov dx,0
    int 21h
    push bx ;>>
    mov ah,42h
    mov bx,file_handle
    mov al,0                                    
    mov cx,0
    mov dx,0
    int 21h
    pop bx  ;<<
    
    copy_f:
        mov cx,1
        mov ah,3fh
        lea dx,buffer_0
        int 21h
        mov buffer_0[1],36
        mov al,buffer_0[0]
        cmp al,3
        je end_copy_f
        push bx ;>>
        mov bx,file_handle
        mov ah,40h
        mov cx,1
        lea dx,buffer_0
        int 21h
        pop bx ;<<
        jmp copy_f
    end_copy_f:     

    push bx 
    mov bx,file_handle
    mov ah,42h
    mov al,2                                    
    mov cx,-1
    mov dx,-1
    int 21h
    xor ax,ax
    mov ah,40h
    xor cx,cx
    int 21h
    pop bx
        
    mov ah,3Eh
    int 21h                                                 ;close file   
    mov ah,41h
    lea dx,filename_2
    int 21h                                                 ;delete file
    mov bx,file_handle
    mov ah,3Eh 
    int 21h    
    cout success
    cout endl 
    jmp exit
    err_exit:
    call clear
    cout endl
    cout not_found_file 
       
    exit:

    mov ax,4c00h
    int 21h

end main