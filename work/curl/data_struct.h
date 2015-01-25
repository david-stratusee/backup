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
    CURL *curl;
    unsigned int data_len;
    unsigned int idx;
} work_info_t;   /* -- end of work_info_t -- */

typedef enum _HTTP_TYPE_EN {
    HTTP_TYPE,
    HTTPS_TYPE,
    HTTP_TYPE_MAX
} HTTP_TYPE_EN;   /* -- end of HTTP_TYPE_EN -- */

typedef enum _DO_EXIT_EN {
    G_RUNNING,
    G_EXIT,
    G_FORCE_EXIT
} DO_EXIT_EN;   /* -- end of DO_EXIT_EN -- */

#define MAX_URL_LEN 256
/* Description: global info */
typedef struct _global_info_t {
    char url[HTTP_TYPE_MAX][MAX_URL_LEN];
    int read_work_idx;
    int work_num;
    int agent_num;
    int during_time;
    int agent_num_per_thread;
    uint8_t cpu_num;
    uint8_t thread_num;
    uint16_t rampup;
    uint8_t do_exit;
    bool is_https;
    uint16_t agent_num_per_sec_thread;
    char sample_error[128];
    char desc[128];
    char output_filename[128];
} global_info_t;   /* -- end of global_info_t -- */
#define HAVE_WORK_AVAILABLE(global_info) \
    (global_info->do_exit == G_RUNNING && ((global_info)->work_num == 0 || (global_info)->read_work_idx < (global_info)->work_num))

typedef enum _THREAD_STATUS_EN {
    TSE_INIT,
    TSE_DONE,
    TSE_VERIFY,
} THREAD_STATUS_EN;   /* -- end of THREAD_STATUS_EN -- */

/* Description: thread info */
typedef struct _thread_info_t {
    pthread_t tid;
    CURLM *multi_handle;
    work_info_t *work_list;

    global_info_t *global_info;
    unsigned int work_num;
    unsigned int idx             : 8,
                 work_done       : 4,
                 alloc_agent_num : 20;
    unsigned int error_num;
    int still_running;
    time_t last_alloc_time;

    unsigned int total_latency;      /* total time for this work, unit ms */
    unsigned int min_latency;  /* total time for this work, unit ms */
    unsigned int max_latency;  /* total time for this work, unit ms */
    unsigned int succ_num;
    unsigned int total_data_len;

    char sample_error[124];
} thread_info_t;   /* -- end of thread_info_t -- */

#define CONN_TIMEOUT 30     /* second */
#define THREADNUM_PER_CPU 4

#endif   /* -- #ifndef _DATA_STRUCT_H -- */
