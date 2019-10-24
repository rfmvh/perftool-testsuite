#include <stdio.h>
#include <stdlib.h>


int main (int argc, char *argv[])
{
	long from, i, j = 20L;

	if (argc > 1)
		from = atol (argv[1]);
	else
		from = 20L;

	for (i = 1L; j; ++i)
	{
		for (j = from; j > 0L; --j)
			if (i % j)
				break;
	}

	printf ("%ld\n", --i);

	return 0;
}
