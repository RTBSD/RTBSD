#include "bsd_osal.h"

#include <unistd.h>
#include <sys/types.h>
#include <sys/lock.h>
#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <pthread.h>
#include <signal.h>

void *bsd_osal_malloc(size_t size)
{
    return malloc(size);
}

void bsd_osal_free(void *ptr)
{
    free(ptr);
}

int bsd_osal_mtx_init(bsd_osal_mutex_t *mtx, const char *name, int opts)
{
    pthread_mutexattr_t attr;
    int ret = 0;

    if (opts & BSD_OSAL_MTX_SPIN) {
        mtx->handle = bsd_osal_malloc(sizeof(pthread_spinlock_t));
        assert(mtx->handle);

        ret = pthread_spin_init(mtx->handle, 0);
    } else {
        mtx->handle = bsd_osal_malloc(sizeof(pthread_mutex_t));
        assert(mtx->handle);

        pthread_mutexattr_init(&attr);

        if (opts & BSD_OSAL_MTX_RECURSE) {
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
        } else {
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);
        }

        ret = pthread_mutex_init(mtx->handle, &attr);
        pthread_mutexattr_destroy(&attr);
    }
    
    mtx->opts = opts;
    mtx->nest_level = 0;
    mtx->name = name;
    mtx->owner = NULL;

    return ret;
}

void bsd_osal_mtx_destory(bsd_osal_mutex_t *mtx)
{
    assert(mtx && mtx->handle);

    if (mtx->opts & BSD_OSAL_MTX_SPIN) {
        (void)pthread_spin_destroy(mtx->handle);
    } else {
        (void)pthread_mutex_destroy(mtx->handle);
    }

    bsd_osal_free(mtx->handle);
    mtx->handle = NULL;
}