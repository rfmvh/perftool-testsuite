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
#define MAX_DIR 32

/* globals */
int verbose = 0;
//int do_cleanup = 1;
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

	char* clean = getenv("TESTLOG_CLEAN");
	if (clean == NULL)				// variable doesn't exist, it was't set
		try_shell("cleanup.sh");
	
	if((clean != NULL) && (strcmp(clean, "y") == 0))	// variable exists and is set to true
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
	int select_run = 0;

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
			setenv("TESTLOG_CLEAN", "n", 1);
			//do_cleanup = 0;
			continue;
		}

		/* run only selected directories */
		/* to run tests only from certain directories use -r or --run followed
			by the list of the names of directories (e.g. stat, trace, top...) to run,
			if the list is empty, all directories are run*/
		if((strcmp(argv[i], "-r") == 0) || (strcmp(argv[i], "--run") == 0))
		{
			if((i+1) < argc){
				select_run = i+1;
				continue;
			}
			fprintf(stderr, "Empty list of selected directories was provided. Running all tests.\n");
		}
	}

	dp = opendir(TESTSUITE_ROOT);
	if(dp != NULL)
	{
		if(select_run){
			for(i = select_run; i < argc; i++)
			{
				char s_dir[MAX_DIR] = "";
				struct stat sb;

				/* check whether the argument is not different option */
				if((strlen(argv[i])) && (argv[i][0] == '-'))
				{
					break;
				}

				strcat(s_dir, "base_");
				if(strlen(argv[i]) > MAX_DIR-5){		// too long string for a directory name
					fprintf(stderr, "Trying to run a nonexistent directory, name too long: %s\n", argv[i]);
					continue;
				}
				strcat(s_dir, argv[i]);

				/* check the existence of the selected directory*/
				if(stat(s_dir, &sb) == 0 && (S_ISDIR(sb.st_mode)))
				{
					failures += run_group(s_dir);
				}
				else
				{
					fprintf(stderr, "Trying to run a nonexistent directory: %s\n", argv[i]);
				}
			}
		}
		else
		{
			while(ep = readdir(dp))
			{
				if(strncmp(ep->d_name, "base_", 5))
					continue;
				failures += run_group(ep->d_name);
			}
			closedir(dp);
		}
	}
	else
		perror("Cannot open outer dir.");

	if(failures || fatal_occured)
		return 1;
	else
		return 0;
}
