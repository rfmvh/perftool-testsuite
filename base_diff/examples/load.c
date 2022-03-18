#include <stdio.h>
#include <stdlib.h>

int mandelbrot(double real, double imag) {
	int limit = 100;
	double zReal = real;
	double zImag = imag;

	for (int i = 0; i < limit; ++i) {
		double r2 = zReal * zReal;
		double i2 = zImag * zImag;
		
		if (r2 + i2 > 4.0) return i;

		zImag = 2.0 * zReal * zImag + imag;
		zReal = r2 - i2 + real;
	}
	return limit;
}

int calculate_mandelbrot() {
	int width = 379;
	int heigth = 98;
		
	double x_start = -2.0;
	double x_fin = 1.0;
	double y_start = -1.0;
	double y_fin = 1.0;

	double dx = (x_fin - x_start)/(width - 1);
	double dy = (y_fin - y_start)/(heigth - 1);

	for (int i = 0; i < heigth; i++) {
		for (int j = 0; j < width; j++) {
			double x = x_start + j*dx;
			double y = y_fin - i*dy;

			int value = mandelbrot(x, y);
		}
	}
	return 0;
}

int main (int argc, char *argv[])
{
	printf ("%ld\n", func_ref(calculate_mandelbrot()));
	printf ("%ld\n", func_test(calculate_mandelbrot()));

	return 0;
}
