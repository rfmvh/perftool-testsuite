#include <pthread.h>
#include <assert.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

#define N 256

static volatile int var;

static void *start(void *arg)
{
	printf("A thread here!\n");
	sleep(1);
	return arg;
}

int main(int argc, char *argv[])
{
	pthread_t threads[N];
	int nthreads;
	int i, r;

	if(argc > 1)
		nthreads = atoi(argv[1]);
	else
		nthreads = N;

	if(nthreads > N)
		nthreads = N;

	/* create */
	for(i = 0; i < nthreads; i++)
    {
		r = pthread_create (&threads[i], NULL, start, NULL);
		assert (r == 0);
    }

	/* join */
	for(i = 0; i < nthreads; i++)
    {
		r = pthread_join (threads[i], NULL);
		assert (r == 0);
    }

	return 0;
}
