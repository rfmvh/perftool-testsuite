/*
	run_all.c
	Author: Michael Petlan <mpetlan@redhat.com>

	Description:
		The driver that runs all the tests.
*/

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <string.h>

#define TESTSUITE_ROOT "./"


/* globals */
int verbose = 0;
int do_cleanup = 1;
int fatal_occured = 0;


/* runs a shell script */
int _run_shell(char *script)
{
	int ret;
	char *cmd = malloc(strlen(script) + 3 * sizeof(char));
	strcpy(cmd, "./");
	strcpy(cmd + 2, script);
	ret = system(cmd);
	if(ret == -1)
	{
		fprintf(stderr, "FATAL: Could not run %s", cmd);
		fatal_occured++;
		return 1;
	}
	return ret;
}


/* checks for existence of a file and runs it */
int run_shell(char *script)
{
	struct stat sb;
	int ret;

	if(stat(script, &sb) == -1)
	{
		fatal_occured++;
		return 1;
	}

	if(!(sb.st_mode & (S_IXUSR | S_IFREG)))
	{
		fatal_occured++;
		return 1;
	}

	return _run_shell(script);
}


/* if a script is available, run it, otherwise ignore it */
int try_shell(char *script)
{
	struct stat sb;
	int ret;

	if(stat(script, &sb) == -1)
		return 0;

	if(!(sb.st_mode & (S_IXUSR | S_IFREG)))
		return 0;

	return _run_shell(script);
}


/* runs a group of tests ("base_something", ...) */
int run_group(char *path)
{
	DIR *dp;
	struct dirent *ep;

	int failures = 0;
	chdir(path);

	if(verbose)
		printf("======== %s ========\n", path);

	/* try to run setup */
	failures += try_shell("setup.sh");

	/* scan the dir and run tests */
	dp = opendir("./");
	if(dp != NULL)
	{
		while(ep = readdir(dp))
		{
			if(strncmp(ep->d_name, "test_", 5))
				continue;
			failures += run_shell(ep->d_name);
		}
		closedir(dp);
	}
	else
		perror("Cannot open inner dir.");

	/* try to do clean-up */
	if(do_cleanup)
		try_shell("cleanup.sh");

	chdir("..");
	if (verbose)
		printf("\n");
	return failures;
}


/* main */
int main(int argc, char *argv[])
{
	DIR *dp;
	struct dirent *ep;
	int failures = 0;
	int i;
	char verbosity_str[2];

	for(i = 1; i < argc; i++)
	{
		/* verbosity */
		if(strncmp(argv[i], "-v", 2) == 0)
		{
			char *p;
			for(p = argv[1]; *p != '\0'; p++)
				if(*p == 'v') verbose++;
			if(verbose > 9)
				verbose = 9;
			snprintf(verbosity_str, 2, "%i", verbose);
			setenv("TESTLOG_VERBOSITY", verbosity_str, 1);
			continue;
		}

		/* skip the clean-up */
		if((strcmp(argv[i], "--no-cleanup") == 0) || (strcmp(argv[i], "-n") == 0))
		{
			do_cleanup = 0;
			continue;
		}
	}

	dp = opendir(TESTSUITE_ROOT);
	if(dp != NULL)
	{
		while(ep = readdir(dp))
		{
			if(strncmp(ep->d_name, "base_", 5))
				continue;
			failures += run_group(ep->d_name);
		}
		closedir(dp);
	}
	else
		perror("Cannot open outer dir.");

	if(failures || fatal_occured)
		return 1;
	else
		return 0;
}
