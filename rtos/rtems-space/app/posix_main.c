
#include <assert.h>
#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    printf( "POSIX -- Hello World\n" );
    sleep( 1 );
    return 0;
}