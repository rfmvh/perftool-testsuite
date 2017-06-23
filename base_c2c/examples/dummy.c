#include <stdio.h>
#include <stdlib.h>

#define LIMIT 300

double function_a(long a)
{
	double r = 0;
	for(long i = 1; i <=a; i++)
		r += ((i % 2)? 1 : -1) / (double) i;
	return r;
}

double function_b(long a)
{
	double r = 0;
	for(long i = 1; i <=a; i++)
		r += ((i % 2)? -1 : 1) / (double) (i * i);
	return r;
}

double function_F(long a)
{
	double r = 0;
	for(long i = 0; i < a; i++)
		r += function_a(i) + function_b(i);
	return r;
}


int main (int argc, char *argv[])
{
	long i, to;

	if (argc > 1)
		to = atol (argv[1]);
	else
		to = LIMIT;

	for (i = 0; i < to; i++)
		printf("F(%ld) = %f\n", i, function_F(i));

	printf ("\n");

	return 0;
}
