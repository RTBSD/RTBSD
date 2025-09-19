/*
 * Copyright (C) 2025, RTBSD
 *
 * SPDX-License-Identifier: BSD 3-Clause
 */
#ifndef LIBBSD_OSAL_H
#define LIBBSD_OSAL_H

#include <stdint.h>
#include <string.h>
#include <stdbool.h>

void *bsd_osal_malloc(size_t size);
void bsd_osal_free(void *ptr);

typedef struct {

} bsd_osal_thread_t;

typedef struct {
    void               *handle;
    bsd_osal_thread_t  *owner;
    const char *name;
    int nest_level;
#define BSD_OSAL_MTX_DEF     0x0
#define BSD_OSAL_MTX_SPIN    (1 << 0)
#define BSD_OSAL_MTX_RECURSE (1 << 1)
    int opts;
} bsd_osal_mutex_t;

int bsd_osal_mtx_init(bsd_osal_mutex_t *m, const char *name, int opts);
void bsd_osal_mtx_destory(bsd_osal_mutex_t *m);

#endif /* LIBBSD_OSAL_H */