/************************************************
 *       Filename: multi_test.c
 *    Description:
 *        Created: 2015-01-20 16:28
 *         Author: dengwei david@stratusee.com
 ************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include "common/types.h"
#include "common/timestamp.h"
#include "common/setsignal.h"
#include "common/atomic_def.h"
#include "common/ssl_lock.h"
#include "common/optimize.h"
#include "common/misc.h"
#include "common/string_s.h"
#include "data_struct.h"
#include "util.h"

global_info_t global_info;
#ifdef DEBUG
#define DUMP(fmt, args...) printf("[%s-%u-%lu]"fmt, __func__, __LINE__, time(NULL), ##args)
#else
#define DUMP(...)
#endif

static void _sig_int(int signum, siginfo_t *info, void *ptr)
{
    global_info.do_exit = true;
    return;
}

size_t write_data(void *buffer, size_t size, size_t nmemb, void *userp)
{
    work_info_t *work_info = (work_info_t *)userp;
    size_t real_size = size * nmemb;
    work_info->data_len += real_size;
    return real_size;
}

static void set_share_handle(CURL *curl_handle)
{
    static CURLSH *share_handle = NULL;

    if (!share_handle) {
        share_handle = curl_share_init();
        curl_share_setopt(share_handle, CURLSHOPT_SHARE, CURL_LOCK_DATA_DNS);
    }

    curl_easy_setopt(curl_handle, CURLOPT_SHARE, share_handle);
    curl_easy_setopt(curl_handle, CURLOPT_DNS_CACHE_TIMEOUT, 60 * 5);
}

static CURL *curl_handle_init(global_info_t *global_info)
{
    CURL *curl = curl_easy_init();
    if (curl == NULL) {
        return NULL;
    }

    //curl_easy_setopt(curl, CURLOPT_FORBID_REUSE, 1L);
    curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
    curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, (long)CONN_TIMEOUT);

    if (global_info->is_https) {
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
    }

    set_share_handle(curl);
    return curl;
}

static inline thread_info_t *thread_init(global_info_t *global_info)
{
    thread_info_t *thread_list = calloc(global_info->thread_num, sizeof(thread_info_t));

    if (thread_list == NULL) {
        printf("alloc threads error\n");
        return NULL;
    }

    int32_t idx = 0, jdx = 0;
    work_info_t *work_info = NULL;

    for (idx = 0; idx < global_info->thread_num; ++idx) {
        thread_list[idx].global_info = global_info;

        thread_list[idx].multi_handle = curl_multi_init();
        curl_multi_setopt(thread_list[idx].multi_handle, CURLMOPT_PIPELINING, 1L);
        curl_multi_setopt(thread_list[idx].multi_handle, CURLMOPT_MAXCONNECTS, MEM_ALIGN_SIZE(global_info->handle_num_per_thread, 4));

        thread_list[idx].curl = calloc(global_info->handle_num_per_thread, sizeof(CURL *));
        if (thread_list[idx].curl == NULL || thread_list[idx].multi_handle == NULL) {
            printf("error when curl init\n");
            return NULL;
        }

        for (jdx = 0; jdx < global_info->handle_num_per_thread; ++jdx) {
            thread_list[idx].curl[jdx] = curl_handle_init(global_info);
            if (thread_list[idx].curl[jdx] == NULL) {
                return NULL;
            }

            if (global_info->read_work_idx < global_info->work_num) {
                work_info = global_info->work_list + (global_info->read_work_idx++);
                curl_easy_setopt(thread_list[idx].curl[jdx], CURLOPT_WRITEDATA, work_info);
                curl_easy_setopt(thread_list[idx].curl[jdx], CURLOPT_URL, work_info->url);
                curl_easy_setopt(thread_list[idx].curl[jdx], CURLOPT_PRIVATE, work_info);
                curl_multi_add_handle(thread_list[idx].multi_handle, thread_list[idx].curl[jdx]);
                DUMP("[%u]add handle %p to multi_handle %p\n", idx, thread_list[idx].curl[jdx], thread_list[idx].multi_handle);
            }
        }

        thread_list[idx].idx = idx;
    }

    return thread_list;
}

static void thread_destroy(global_info_t *global_info, thread_info_t *thread_list)
{
    int idx = 0, jdx = 0;

    DUMP("clear thread info\n");

    for (idx = 0; idx < global_info->thread_num; idx++) {
        for (jdx = 0; jdx < global_info->handle_num_per_thread; ++jdx) {
            curl_easy_cleanup(thread_list[idx].curl[jdx]);
        }
        curl_multi_cleanup(thread_list[idx].multi_handle);
    }

    free(thread_list);
}

static inline void global_init(void)
{
    curl_global_init(CURL_GLOBAL_ALL);
    init_locks();
    TS_INIT();
}

static inline void global_destroy(void)
{
    kill_locks();
    curl_global_cleanup();
}

static inline int32_t global_info_init(global_info_t *global_info)
{
    int cpu_num = get_cpu_num();
    if (cpu_num == 0) {
        printf("error when get cpu num\n");
        return -1;
    }

    memset(global_info, 0, sizeof(global_info_t));
    global_info->cpu_num = cpu_num;
    global_info->thread_num = cpu_num * THREADNUM_PER_CPU;
    return 0;
}

static inline work_info_t *get_one_work(global_info_t *global_info, thread_info_t *thread_info)
{
    if (global_info->read_work_idx < global_info->work_num) {
        work_info_t *work_info = global_info->work_list + atomic_inc(global_info->read_work_idx);
        DUMP("[%u]work %u, read_work_idx: %u\n", thread_info->idx, work_info->idx, global_info->read_work_idx);
        return work_info;
    } else {
        return NULL;
    }
}

int32_t check_available(CURLM *multi_handle, global_info_t *global_info, thread_info_t *thread_info)
{
    int msgs_left;
    CURLMsg *msg;
    work_info_t *work_info = NULL;
    CURL *easy_handle = NULL;

    int num = 0;
    while ((msg = curl_multi_info_read(multi_handle, &msgs_left))) {
        if (CURLMSG_DONE == msg->msg) {
            easy_handle = msg->easy_handle;
            DUMP("easy_handle %p is done, code: %u-%s\n", easy_handle, msg->data.result, curl_easy_strerror(msg->data.result));

            if (unlikely(msg->data.result != CURLE_OK)) {
                global_info->error_num++;
                if (unlikely(global_info->sample_error[0] == '\0')) {
                    fix_strcpy_s(global_info->sample_error, curl_easy_strerror(msg->data.result));
                }
            } else if (easy_handle) {
                /*  TODO: curl_easy_getinfo */
                work_info = NULL;
                if (curl_easy_getinfo(easy_handle, CURLINFO_PRIVATE, &work_info) == CURLE_OK && work_info != NULL) {
                    double total_time = 0.0f;
                    curl_easy_getinfo(easy_handle, CURLINFO_TOTAL_TIME, &(total_time));
                    work_info->total_time = (unsigned long)(total_time * 1000);
                }
            } else {
                continue;
            }

            curl_multi_remove_handle(multi_handle, easy_handle);
            work_info = get_one_work(global_info, thread_info);
            if (work_info) {
                curl_easy_setopt(easy_handle, CURLOPT_WRITEDATA, work_info);
                curl_easy_setopt(easy_handle, CURLOPT_URL, work_info->url);
                curl_easy_setopt(easy_handle, CURLOPT_PRIVATE, work_info);
                curl_multi_add_handle(multi_handle, easy_handle);
                num++;
            }
        } else {
            DUMP("-------------------- [easy_handle-%p] not OK\n", msg->easy_handle);
        }
    }

    return num;
}

static inline CURLMcode curl_multi_perform_cont(CURLM *multi_handle, int *running_handles, global_info_t *global_info)
{
    CURLMcode ret_code;
    while ((ret_code = curl_multi_perform(multi_handle, running_handles)) == CURLM_CALL_MULTI_PERFORM) {
        DUMP("get still_running: %u\n", *running_handles);
        if (global_info->do_exit) {
            return CURLM_BAD_HANDLE;
        }
    }

    return ret_code;
}

static void *pull_one_url(void *arg)
{
    thread_info_t *thread_info = (thread_info_t *)arg;
    global_info_t *global_info = thread_info->global_info;

    int ignore_sig[] = {SIGINT, SIGTERM};
    pthread_set_ignore_sig(ignore_sig, sizeof(ignore_sig) / sizeof(int));

    int still_running;
    CURLMcode mc; /* curl_multi_wait() return code */
    int numfds;
    int calc_num = 0;

    if (curl_multi_perform_cont(thread_info->multi_handle, &still_running, global_info) != CURLM_OK) {
        DUMP("[%u]error when call curl_multi_perform\n", thread_info->idx);
        return NULL;
    }

    DUMP("get still_running: %u, multi_handle: %p\n", still_running, thread_info->multi_handle);
    do {
        /* wait for activity, timeout or "nothing" */
        mc = curl_multi_wait(thread_info->multi_handle, NULL, 0, 1000, &numfds);
        if(mc != CURLM_OK) {
            fprintf(stderr, "[%u]curl_multi_fdset() failed, code %d.\n", thread_info->idx, mc);
            break;
        }

        DUMP("[%u]get still_running: %u, multi_handle: %p, numfds: %u, calc_num: %u\n",
                thread_info->idx, still_running, thread_info->multi_handle, numfds, calc_num);

        if (numfds || check_available(thread_info->multi_handle, global_info, thread_info) > 0 || calc_num >= CONN_TIMEOUT) {
            calc_num = 0;

            if (curl_multi_perform_cont(thread_info->multi_handle, &still_running, global_info) != CURLM_OK) {
                DUMP("[%u]error when call curl_multi_perform\n", thread_info->idx);
                break;
            }

#if 1
            if (check_available(thread_info->multi_handle, global_info, thread_info) > 0) {
                if (curl_multi_perform_cont(thread_info->multi_handle, &still_running, global_info) != CURLM_OK) {
                    DUMP("[%u]error when call curl_multi_perform\n", thread_info->idx);
                    break;
                }
            }
#endif
        } else {
            calc_num++;
        }
    } while ((still_running > 0 || global_info->read_work_idx < global_info->work_num) && !(global_info->do_exit));

    check_available(thread_info->multi_handle, global_info, thread_info);
    return NULL;
}

static int32_t start_thread_list(thread_info_t *thread_list, global_info_t *global_info)
{
    int error;
    int idx = 0;
    int msleep_during = 0;

    if (global_info->rampup > 0) {
        msleep_during = (global_info->rampup * 1000) / global_info->thread_num;
    }

    for (idx = 0; idx < global_info->thread_num; ++idx) {
        if (msleep_during > 0 && idx > 0) {
            ms_sleep(msleep_during);
        }

        error = pthread_create(&(thread_list[idx].tid),
                               NULL, /* default attributes please */
                               pull_one_url,
                               (void *) & (thread_list[idx]));
        if (0 != error) {
            fprintf(stderr, "Couldn't run thread number %d, errno %d\n", idx, error);
            return error;
        }

        printf("[%lu]Thread %u start\n", time(NULL), idx);
    }

    return 0;
}

static void calc_stat(global_info_t *global_info, unsigned long msdiff)
{
    unsigned long total_length = 0;
    unsigned long total_time = 0, max_latency = 0;
    int idx = 0;
    int suc_num = 0;

    for (idx = 0; idx < global_info->work_num; idx++) {
        total_length += global_info->work_list[idx].data_len;
        if (global_info->work_list[idx].total_time > 0) {
            ++suc_num;
            total_time += global_info->work_list[idx].total_time;
            if (global_info->work_list[idx].total_time > max_latency) {
                max_latency = global_info->work_list[idx].total_time;
            }
        }
    }

    free(global_info->work_list);
    printf("----------------------\n");
    printf("RESULT:\n");
    printf("%16s : %u\n", "request num", global_info->work_num);
    printf("%16s : %u\n", "error num", global_info->error_num);
    if (global_info->error_num > 0) {
        printf("%16s : %s\n", "sample error", global_info->sample_error);
    }
    printf("%16s : %lu\n", "total length", total_length);
    printf("%16s : %lu\n", "total time(ms)", msdiff);
    printf("%16s : %luKB/s-%luMB/s\n", "throughput", (total_length) / (msdiff), (total_length) / (msdiff * 1024));
    printf("%16s : %lu/s\n", "request rate", (global_info->work_num * 1000) / msdiff);
    if (suc_num > 0) {
        printf("%16s : %u\n", "succ num", suc_num);
        printf("%16s : %lums[max:%lums]\n", "latency", total_time / suc_num, max_latency);
    }
    printf("----------------------\n");
}

/************************************************
 *         Name: main
 *  Description: main function
 *     Argument:
 *       Return:
 ************************************************/
int main(int argc, char *argv[])
{
    TS_DECLARE(perf);

    global_init();
    if (global_info_init(&global_info) < 0) {
        return EXIT_FAILURE;
    }

    setsignal(SIGINT, _sig_int);
    setsignal(SIGTERM, _sig_int);

    if (parse_cmd(argc, argv, &global_info) != 0) {
        return EXIT_FAILURE;
    }

    thread_info_t *thread_list = thread_init(&global_info);
    if (thread_list == NULL) {
        printf("error when init thread\n");
        return EXIT_FAILURE;
    }

    int idx = 0;
    TS_BEGIN(perf);
    if (start_thread_list(thread_list, &global_info) != 0) {
        printf("error when start thread\n");
        return EXIT_FAILURE;
    }

    /* now wait for all threads to terminate */
    for (idx = 0; idx < global_info.thread_num; idx++) {
        pthread_join(thread_list[idx].tid, NULL);
        printf("[%lu]Thread %d terminated\n", time(NULL), idx);
    }
    TS_END(perf);

    thread_destroy(&global_info, thread_list);
    calc_stat(&global_info, TS_MSDIFF(perf));

    global_destroy();
    return EXIT_SUCCESS;
}       /* -- end of function main -- */
