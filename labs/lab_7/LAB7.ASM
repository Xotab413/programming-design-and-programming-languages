.model tiny
.code
org 100h

start:
;========================================
_print      macro str  
        push ax
        push dx
        lea dx, str
        mov ah, 09h
        int 21h
        pop dx
        pop ax 
endm
;========================================
_realloc macro                          ; free memory after end of program and stack
    push ax
    push bx
    mov sp, programLength + 100h + 200h ; move stack pointer to 200h after end of program (100h for psp)
    mov ax, programLength + 100h + 200h ; and stack
    shr ax, 4                           ; because 4Ah funcs use bx register (and that's why we implement our num of bytes to paragraphs)
    inc ax                              ; just because :3
    mov bx, ax                          ; bx contain num of paragraphs (blocks of memory, which size is 16 byte)
    mov ah, 4Ah
    int 21h
    pop bx
    pop ax
endm
;========================================
;########################################
    call CmdParse
    jc incorrectArgsErrorIndicate

    call ArgumentsParse
    jc incorrectArgsErrorIndicate

    _realloc
    jc reallocErrorIndicate

init_EPB:
    mov ax, cs
    mov word ptr EPB + 4, ax            ; seg address of command word
    mov word ptr EPB + 8, ax            ; seg address of  first FCB
    mov word ptr EPB + 0Ch, ax          ; seg address of  second FCB
    
    mov ax, 04B00h
    mov dx, offset execProgName
    mov bx, offset EPB
    int 21h
    jc errorProgExecIndicate
    jmp endOfProgram

incorrectArgsErrorIndicate:
    _print incorrectArgsError
    jmp endOfProgram

reallocErrorIndicate:
    _print reallocError
    jmp endOfProgram
    
errorProgExecIndicate:
    _print programExecError    
        
    
endOfProgram:
    mov ah, 4ch
    int 21h
;########################################
EPB                 dw 0000; текущее окружени
                    dw offset cmdSize, 0; адрес ком строки
                    dw 005Ch, 006Ch; адреса FCB (File Control Block) программы
                    dd ?                   
cmdSize             db 0
cmdText             db 126 dup (?) 

programLength       equ $ - start 

maxPathSize             equ     126
flag                    db      ?
oversizeFlag            db      ?
buffer                  db      ?
execProgName            db      "lab5.exe", 0
textFilePath            db      maxPathSize dup(0), 0
                                                                   
openingFileError            db    0dh, 0ah, "Error opening file.", 0dh, 0ah, '$'
emptyFileError              db    0dh, 0ah, "Error: file is empty.", 0dh, 0ah, '$' 
oversizeError               db    0dh, 0ah, "Error: arguments name are too large.", 0dh, 0ah, '$'
incorrectArgsError          db    0dh, 0ah, "Error: incorrect cmd arguments format.", 0dh, 0ah, '$'
reallocError                db    0dh, 0ah, "Error reallocation memory.", 0dh, 0ah, '$'
programExecError            db    0dh, 0ah, "Program execution error.", 0dh, 0ah, '$'                                                                   
;======================================
;======================================
CmdParse proc; output: text_file_path - program path
    push bx
    push cx
    xor ah, ah
    mov al, byte ptr ds:[80h]; в al длина ком строки 
    cmp al, 0
    je cmdParseError

    xor ch, ch
    mov cl, al; в cl длина ком строки
    mov di, 81h; в di начало ком строки
    call FileNameParse
    jc cmdParseError

    jmp cmdParseEnd
    
    cmdParseError:
    stc      
    
    cmdParseEnd:
    pop cx
    pop bx
    ret
endp
;======================================
;======================================
FileNameParse proc; 
    push ax
    push si
    mov al, ' '; 
    repe scasb; ищем первый байт, отличный от пробела (пропускаем все пробелы в ком строке)
    cmp cx, 0; если в ком строке были одни пробелы
    je fileNameParseEmptyError
    dec di
    inc cx
    push di
    mov si, di
    mov di, offset textFilePath
    rep movsb; копируем байты из si в di
    jmp fileNameParseEnd
    
    fileNameParseEmptyError:; если в ком строке были одни пробелы
    push di    
    
    fileNameParseError:
    stc; устанавливаем флаг CF для ошибки  
    
    fileNameParseEnd:
    pop di
    pop si
    pop ax
    ret
endp
;======================================
;======================================
CharCheck proc; buf - char, di - dest
    push ax
    mov al, buffer
    
    cmp al, 0Dh
    je charCheckEnd
    
    cmp al, 09h
    je charCheckEnd
    
    cmp al, ' '
    jne checkNeededSpace 
    
    mov flag, 1
    jmp charCheckEnd

    checkNeededSpace:
        cmp flag, 0
        je needSpace
        mov al, ' '
        stosb; al -> di++
        inc cmdSize
        mov al, buffer
        mov flag, 0 
        needSpace:; запись символов перед пробелом (имя файла)
                stosb; al -> di++
                mov al, 0Dh
                stosb
                inc cmdSize
                dec di
                cmp di, maxPathSize
                jne charCheckEnd
                stc
                jmp charCheckEnd

    charCheckEnd:
    pop ax
    ret
endp
;======================================
;======================================
LineProcessing proc; обработка новой строки
    push ax
    push dx
    push cx
    push bx
    push si

    mov oversizeFlag, 0
    ;----------------
    mov al, 00h
    mov ah, 3Dh
    mov dx, offset textFilePath
    int 21h
    jc openingFileErrorIndicate
    ;----------------
    mov flag, 1 
    
    mov si, cx; сохраняем номер строки в si
    dec si        
    mov bx, ax; дескриптор файла
    mov cx, 1; число байт для чтения
    mov ah, 3Fh
    mov dx, offset buffer; буфер для чтения
    
    cmp si, 0; если первая по счёту строка
    je processCurrentLine    

    lineApproach:; добираемся до строки, на которой остановились на предыдущей итерации
        mov ah, 3Fh
        int 21h; ЧИТАЕМ БАЙТ ИЗ ФАЙЛА 
        
        cmp ax, 0; если ничего не прочиталось
        je emptyFileErrorIndicate  
        
        cmp buffer, 0Ah; сравнение с \n
        jne lineApproach
        
        dec si
        cmp si, 0
        je processCurrentLine
        jmp lineApproach
    
    processCurrentLine:; обработка строки, на которую указывал cx
        mov ah, 3Fh
        int 21h
        
        cmp ax, 0
        je endOfLineReached 
        
        cmp buffer, 0Dh
        je endOfLineReached 
        
        cmp buffer, 0Ah
        je endOfLineReached 

        call CharCheck
        jc oversizeErrorIndicate
        jmp processCurrentLine

    endOfLineReached:
        jmp parseWithoutErrors

    emptyFileErrorIndicate: 
        jmp closeFileWithErrors
        
    openingFileErrorIndicate:
        _print openingFileError
        jmp catchAnyError
        

    oversizeErrorIndicate:
        mov oversizeFlag, 1
        _print oversizeError
        jmp catchAnyError

    catchAnyError:
        stc
        jmp closeFileWithErrors

    closeFileWithErrors:
        mov ah, 3Eh
        int 21h
        stc
        jmp endAfterCloseFile 
        
    parseWithoutErrors:; ЗАКРЫТИЕ ФАЙЛА
         mov ah, 3Eh
         int 21h   
         
    endAfterCloseFile:
        pop si
        pop bx
        pop cx
        pop dx
        pop ax
        ret
endp
;======================================
;======================================
ArgumentsParse proc; 
    push cx
    push di

    mov cx, 1
    mov di, offset cmdText

    argumentsParseLoop:
        call LineProcessing
        jc argumentsParseError
        inc cx
        jmp argumentsParseLoop

    argumentsParseError:
        cmp oversizeFlag, 1
        je endOfParse
        clc

    endOfParse:
        pop di
        pop cx
        ret
endp

end start
