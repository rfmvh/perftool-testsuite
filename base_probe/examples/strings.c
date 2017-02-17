#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define BUF_SIZE 4096

int str_search(const char *s)
{
	FILE *f = fopen("/proc/cmdline", "r");
	char *buf = malloc((BUF_SIZE + 1) * sizeof(char));
	int i, j, found;

	// read data
	fgets(buf, BUF_SIZE, f);

	// sequential search for the (sub-)string
	for(i = 0; i <= strlen(buf) - strlen(s); i++)
	{
		found = -1;
		for(j = 0; j < strlen(s); j++)
			if(s[j] != buf[i + j])
				break;
		if(j == strlen(s))
		{
			found = i;
			break;
		}
	}

	// clean-up
	free(buf);
	fclose(f);

	return found;
}

int main(int argc, char *argv[])
{
	int res;
	if(argc > 1)
		res = str_search(argv[1]);
	else
		res = str_search("root");

	printf("The searched string was %sfound.\n", (res >= 0)? "" : "NOT ");
	return 0;
}
