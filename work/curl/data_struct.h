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
    char *url;
    int idx;
    int data_len;
} work_info_t;   /* -- end of work_info_t -- */

/* Description: global info */
typedef struct _global_info_t {
    pthread_mutex_t rmtx;
    work_info_t *work_list;
    char *url;
    int read_work_idx;
    int write_work_idx;
    int work_num;
    int thread_num;
    int curl_handle_num;
    int handle_num_per_thread;
    int cpu_num;
    unsigned int error_num;
    bool do_exit;
} global_info_t;   /* -- end of global_info_t -- */

/* Description: thread info */
typedef struct _thread_info_t {
    pthread_t tid;
    CURLM *multi_handle;
    CURL **curl;
    global_info_t *global_info;
    int idx;
} thread_info_t;   /* -- end of thread_info_t -- */

//#define HTTP_URL "http://192.168.101.102:8080/static/code.py"
#define HTTP_URL "http://192.168.101.102:8080/images/sample1.jpg"
//#define HTTP_URL "http://192.168.10.31/assets/jquery.flot.js"
#define HTTPS_URL "https://192.168.10.31:3000/assets/jquery.flot.js"

#define CONN_TIMEOUT 10     /* second */

#endif   /* -- #ifndef _DATA_STRUCT_H -- */
