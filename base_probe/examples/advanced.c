#include <stdlib.h>
#include <stdio.h>

static int counter = 0;

int incr(void)
{
	int a;
	a = counter++ * 2;
	return a;
}

int isprime(int a)
{
	int i;
	if(a <= 1)
		return 0;
	for(i = 2; i <= a / 2; i++)
		if(!(a % i))
			return 0;
	return 1;
}

int main(int argc, char **argv)
{
	int numbers[] = { 2, 3, 4, 5, 6, 7, 13, 17, 19 };
	int i;

	for(i = 0; i < 9; i++)
	{
		printf("%i %s prime\n", numbers[i], (isprime(numbers[i]))? "is" : "is not");
	}

	for(i = 0; i < 9; i++)
	{
		printf("Now the state is %i.\n", incr());
	}

	return 0;
}
