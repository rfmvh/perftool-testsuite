#include <stdio.h>
#include <stdlib.h>


int f_1x(void) { return 1; }
int f_2x(void) { return 2; }
int f_3x(void) { return 3; }
int f_103x(void) { return 103; }
int f_997x(void) { return 997; }
int f_65535x(void) {return 65535; }

int main(int argc, char **argv)
{
	int i, a;

	for(i = 0; i < 1; i++)
		a = f_1x();

	for(i = 0; i < 2; i++)
		a = f_2x();

	for(i = 0; i < 3; i++)
		a = f_3x();

	for(i = 0; i < 103; i++)
		a = f_103x();

	for(i = 0; i < 997; i++)
		a = f_997x();

	for(i = 0; i < 65535; i++)
		a = f_65535x();

	return 0;
}
