#include <stdio.h>
#include <stdlib.h>

#define DEFAULT_FROM 18L

long func_ref(long from)
{
	long i, j;
	for (i = 1L; j; ++i)
	{
		for (j = from; j > 0L; --j)
			if (i % j)
				break;
	}
	return --i;
}

long func_test(long from)
{
	long i, j;
	for (i = 1L; j; ++i)
	{
		for (j = from; j > 0L; --j)
			if (i % j)
				break;
	}
	return --i;
}

int main (int argc, char *argv[])
{
	long from, i, j = DEFAULT_FROM;

	if (argc > 1)
		from = atol (argv[1]);
	else
		from = DEFAULT_FROM;

	printf ("%ld\n", func_ref(DEFAULT_FROM));
	printf ("%ld\n", func_test(from));

	return 0;
}
