all: main

main: 
	gcc -o mnist-3lnn -Iutil main.c 3lnn.c util/screen.c util/mnist-utils.c util/mnist-stats.c -lm


