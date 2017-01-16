#include <cstdlib>
#include <iostream>

void foo(int a, int b, int c, int d, int e)
{
	int i = a - b * c + d * e;
	std::cout << "i=" << i << std::endl;
}

int main(int argc, char **argv)
{
	int A, B, C, D, E;
	if(argc != 6) return 1;
	A = atoi(argv[1]);
	B = atoi(argv[2]);
	C = atoi(argv[3]);
	D = atoi(argv[4]);
	E = atoi(argv[5]);
	foo(A, B, C, D, E);
	return 0;
}
