/************************************************
 *       Filename: data_struct.h
 *    Description: 
 *        Created: 2015-01-20 16:42
 *         Author: dengwei david@stratusee.com
 ************************************************/
#ifndef _DATA_STRUCT_H
#define _DATA_STRUCT_H

#include <stdio.h>
#include <pthread.h>
#include <curl/curl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "timestamp.h"

typedef enum _WORK_STATUS_EN {
    STAT_INIT,
    STAT_WORK,
    STAT_DONE
} WORK_STATUS_EN;   /* -- end of WORK_STATUS_EN -- */
/* Description: work info */
typedef struct _work_info_t {
    int idx;
    int data_len;
    unsigned long total_time;  /* total time for this work, unit ms */
} work_info_t;   /* -- end of work_info_t -- */


typedef enum _HTTP_TYPE_EN {
    HTTP_TYPE,
    HTTPS_TYPE,
    HTTP_TYPE_MAX
} HTTP_TYPE_EN;   /* -- end of HTTP_TYPE_EN -- */

#define MAX_URL_LEN 256
/* Description: global info */
typedef struct _global_info_t {
    pthread_mutex_t rmtx;
    work_info_t *work_list;
    char url[HTTP_TYPE_MAX][MAX_URL_LEN];
    int read_work_idx;
    int write_work_idx;
    int work_num;
    int thread_num;
    int curl_handle_num;
    int handle_num_per_thread;
    int cpu_num;
    int rampup;
    unsigned int error_num;
    char desc[128];
    char output_filename[128];
    char sample_error[256];
    bool do_exit;
    bool is_https;
} global_info_t;   /* -- end of global_info_t -- */

typedef enum _THREAD_STATUS_EN {
    TSE_INIT,
    TSE_DONE,
    TSE_VERIFY,
} THREAD_STATUS_EN;   /* -- end of THREAD_STATUS_EN -- */

/* Description: thread info */
typedef struct _thread_info_t {
    pthread_t tid;
    CURLM *multi_handle;
    CURL **curl;
    global_info_t *global_info;
    int idx;
    int work_done:4,
        work_num :28;
} thread_info_t;   /* -- end of thread_info_t -- */

#define CONN_TIMEOUT 30     /* second */
#define THREADNUM_PER_CPU 4

#endif   /* -- #ifndef _DATA_STRUCT_H -- */
