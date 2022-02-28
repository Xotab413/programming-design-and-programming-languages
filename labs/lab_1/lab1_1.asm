.MODEL small
.STACK 100h
.DATA
helloWorldMessage db 'Hello World!',0Dh,0Ah,'$'
.CODE
begin:
MOV AX, @data
MOV DS, AX
LEA DX, helloWorldMessage
MOV AH, 9H
INT 21H
MOV AH, 4CH
INT 21H
END begin