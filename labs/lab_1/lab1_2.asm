.MODEL tiny
.CODE
ORG 100h
begin:
LEA DX, helloWorldMessage
MOV AH, 9H
INT 21H
ret
helloWorldMessage db "Hello, world!",0Dh,0Ah,'$'
END begin