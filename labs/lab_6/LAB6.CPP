#include <conio.h>
#include <dos.h>
#include <io.h>
#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#pragma inline

#define SIZE 10

float array[SIZE];
float power;

void inputArray();
void outputArray();
void asmAlgorithm();

int main() {
    inputArray();
    printf("Input array: \n");
    outputArray();

    asmAlgorithm();

    printf("\nResult array: \n");
    outputArray();

    return 0;
}

void inputArray() {
    int res;
    printf("Input 10 elements: \n");

    for (int i = 0; i < SIZE; ++i) {
        do {
            res = scanf("%f", &array[i]);
            while (getchar() != '\n')
            if (res != 1) printf("Invalid input\n");
        } while (res != 1);
    }
	printf("Input a power num: \n");
	do {
		res = scanf("%f", &power);
		while (getchar() != '\n')
		if (res != 1) printf("Invalid input\n");
	} while (res != 1);	
}

void outputArray() {
    for (int i = 0; i < SIZE; ++i) {
        printf("%.3f ", array[i]);
    }
}

void asmAlgorithm() {

    asm {
		finit
		xor cx, cx
		mov cx, SIZE
		lea bx, array
	}
	calculate:				// Dos inline asm can only jump to labels inside  blocks
	asm {					
		fld dword ptr power /* st(0) = z -> grade of num */
    	fld dword ptr [bx]	/* st(1) = z, st(0) = arr[i] */
    	fyl2x       		/* st(0) = z*log2(arr[i]) -> p */
    	fld st(0)   		/* Make copy of st(0) */
    	frndint     		/* Round ST(0)=trunc(p)				 	| ST(1)= p */
    	fxch st(1)			/* ST(0)=p                              | ST(1)=trunc(p) */
    	fsub st(0),st(1)	/* ST(0)=p-trunc(p)        				| ST(1)=trunc(p) */
    	f2xm1           	/* ST(0)=2**(z-trunc(p))-1            	| ST(1)=trunc(p) */
    	fld1            	/* ST(0)=1 ST(1)=2**(p-trunc(p))-1  	| ST(2)=trunc(p) */
    	faddp st(1),st  	/* ST(0)=2**(p-trunc(p))      			| ST(1)=trunc(p) */
    	fscale 				/* ST(0)=(2**(p-trunc(p)))*(2**trunc(p))=2**(p) */
		fstp dword ptr [bx]
		add bx, 4
		loop calculate
    }
	end: 
	asm fwait
}
