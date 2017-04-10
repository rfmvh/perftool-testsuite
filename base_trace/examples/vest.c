#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>

#define MAX_LEN 128

int main(void)
{
	char *s = malloc(sizeof(char) * (MAX_LEN + 1));
	FILE *f;
	int i;

	sleep(2);

	if(s == NULL)
	{
		printf("FATAL, no mem.\n");
		return 1;
	}

	fgets(s, MAX_LEN, stdin);

	for(i = 0; i < strlen(s); i++)
	{
		s[i] = (char) toupper((int) s[i]);
	}

	sleep(1);

	f = fopen("/tmp/something.txt", "w");

	if(f == NULL)
	{
		printf("%s", s);
	}
	else
	{
		fprintf(f, "%s", s);
		fclose(f);
	}

	free(s);
	return 0;
}
