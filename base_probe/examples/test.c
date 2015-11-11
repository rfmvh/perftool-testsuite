#include <stdio.h>
#include <stdlib.h>

int some_function_with_a_really_long_name_that_must_be_longer_than_64_bytes(int some_argument_with_a_really_long_name_that_must_be_longer_than_64_bytes)
{
	int some_variable_with_a_really_long_name_that_must_be_longer_than_64_bytes = 0;
	int i;

	for(i = 0; i <= some_argument_with_a_really_long_name_that_must_be_longer_than_64_bytes; i++)
	{
		some_variable_with_a_really_long_name_that_must_be_longer_than_64_bytes += i;
	}

	return some_variable_with_a_really_long_name_that_must_be_longer_than_64_bytes;
}

int some_normal_function(int a)
{
	return a * a * a;
}

int main(int argc, char **argv)
{
	int x = 20, y, z;

	if(argc > 1)
		x = atoi(argv[1]);

	y = some_function_with_a_really_long_name_that_must_be_longer_than_64_bytes(x);
	z = some_normal_function(x);

	printf("f1(%i) = %i\nf2(%i) = %i\n", x, y, x, z);

	return 0;
}
