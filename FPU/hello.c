#include<stdio.h>
int main(){
/*        asm volatile("li      t0, 8192\t\n"
                   "csrrw   zero, mstatus, t0\t\n"
        );*/
	printf("Hello World\n");
	float a=1.431,b=6.432;
	float c=a+b;
	printf("The value of a=%f, b=%f and c=%f\n",a,b,c);
	return 0;
}
