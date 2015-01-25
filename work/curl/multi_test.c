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
#include "common/file_op.h"
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

static void add_no_cache_header(CURL *curl_handle)
{
    struct curl_slist *no_cache = NULL;
    no_cache = curl_slist_append(no_cache, "Cache-control: no-cache");
    curl_easy_setopt(curl_handle, CURLOPT_HTTPHEADER, no_cache);
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

static inline bool _get_one_work(global_info_t *global_info, thread_info_t *thread_info, const char *func, const int line)
{
    if (HAVE_WORK_AVAILABLE(global_info)) {
        atomic_inc(global_info->read_work_idx);
        thread_info->work_num++;
        DUMP("[%s-%u]thread %u add one work, work_num is %u\n", func, line, thread_info->idx, thread_info->work_num);
        return true;
    } else {
        return false;
    }
}
#define get_one_work(global_info, thread_info)  \
    _get_one_work(global_info, thread_info, __func__, __LINE__)

static CURL *curl_handle_init(global_info_t *global_info, work_info_t *work_info)
{
    CURL *curl = curl_easy_init();
    if (curl == NULL) {
        return NULL;
    }

    //curl_easy_setopt(curl, CURLOPT_FORBID_REUSE, 1L);
    curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
    curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, (long)CONN_TIMEOUT);
    curl_easy_setopt(curl, CURLOPT_URL, global_info->url[global_info->is_https]);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, work_info);
    curl_easy_setopt(curl, CURLOPT_PRIVATE, work_info);

    if (global_info->is_https) {
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
    }

    set_share_handle(curl);
    add_no_cache_header(curl);
    return curl;
}

static inline thread_info_t *thread_init(global_info_t *global_info)
{
    thread_info_t *thread_list = calloc(global_info->thread_num, sizeof(thread_info_t));
    if (thread_list == NULL) {
        printf("alloc threads error\n");
        return NULL;
    }

    int32_t idx = 0, jdx = 0, agent_num_per_sec_thread = 0;
    work_info_t *work_info = NULL;
    thread_info_t *thread_info;

    for (idx = 0; idx < global_info->thread_num; ++idx) {
        thread_info = thread_list + idx;
        thread_info->global_info = global_info;
        thread_info->min_latency = (unsigned int)(-1);

        thread_info->multi_handle = curl_multi_init();
        thread_info->work_list = calloc(global_info->agent_num_per_thread, sizeof(work_info_t));
        if (thread_info->multi_handle == NULL || thread_info->work_list == NULL) {
            printf("error when curl init\n");
            return NULL;
        }

        curl_multi_setopt(thread_info->multi_handle, CURLMOPT_PIPELINING, 1L);
        curl_multi_setopt(thread_info->multi_handle, CURLMOPT_MAXCONNECTS, MEM_ALIGN_SIZE(global_info->agent_num_per_thread, 4));

        agent_num_per_sec_thread = MIN(global_info->agent_num_per_sec_thread, global_info->agent_num_per_thread);

        for (jdx = 0; jdx < global_info->agent_num_per_thread; ++jdx) {
            work_info = thread_info->work_list + jdx;

            work_info->curl = curl_handle_init(global_info, work_info);
            if (work_info->curl == NULL) {
                return NULL;
            }

            if (jdx < agent_num_per_sec_thread && get_one_work(global_info, thread_info)) {
                work_info->data_len = 0;
                curl_multi_add_handle(thread_info->multi_handle, work_info->curl);
                DUMP("[%u]add handle %p to multi_handle %p\n", idx, work_info->curl, thread_info->multi_handle);

                thread_info->alloc_agent_num = jdx;
                thread_info->last_alloc_time = time(NULL);
            }
        }

        thread_info->idx = idx;
    }

    return thread_list;
}

static void thread_destroy(global_info_t *global_info, thread_info_t *thread_list)
{
    int idx = 0, jdx = 0;

    DUMP("clear thread info\n");

    for (idx = 0; idx < global_info->thread_num; idx++) {
        for (jdx = 0; jdx < global_info->agent_num_per_thread; ++jdx) {
            curl_easy_cleanup(thread_list[idx].work_list[jdx].curl);
        }
        curl_multi_cleanup(thread_list[idx].multi_handle);
    }

    free(thread_list);
}

static inline void global_init(void)
{
    curl_global_init(CURL_GLOBAL_DEFAULT);
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

static int32_t check_rampup_agent(CURLM *multi_handle, global_info_t *global_info, thread_info_t *thread_info)
{
    time_t ts;
    time(&ts);

    if (ts != thread_info->last_alloc_time) {
        work_info_t *work_info = NULL;
        int num = 0;
        int32_t idx = 0;

        int32_t agent_num_per_sec_thread = MIN(global_info->agent_num_per_sec_thread, global_info->agent_num_per_thread - thread_info->alloc_agent_num);
        for (idx = 0; idx < agent_num_per_sec_thread; ++idx) {
            work_info = thread_info->work_list + thread_info->alloc_agent_num;

            if (get_one_work(global_info, thread_info)) {
                work_info->data_len = 0;
                curl_multi_add_handle(multi_handle, work_info->curl);
                thread_info->alloc_agent_num++;
                DUMP("[%u]add handle %p to multi_handle %p\n", thread_info->idx, work_info->curl, multi_handle);
            } else {
                thread_info->last_alloc_time = time(NULL);
            }

            num++;
        }

        if (idx == agent_num_per_sec_thread) {
            thread_info->last_alloc_time = time(NULL);
        }

        return num;
    } else {
        return 0;
    }
}

#define fill_thread_error(thread_info, fmt, args...) \
    do {    \
        (thread_info)->error_num++;   \
        if (unlikely((thread_info)->sample_error[0] == '\0')) {   \
            fix_snprintf((thread_info)->sample_error, fmt, ##args); \
        }   \
    } while (0)

#define fill_thread_fixerr(thread_info, desc) \
    do {    \
        (thread_info)->error_num++;   \
        if (unlikely((thread_info)->sample_error[0] == '\0')) {   \
            fix_strcpy_s((thread_info)->sample_error, desc);   \
        }   \
    } while (0)


static int32_t check_available(CURLM *multi_handle, global_info_t *global_info, thread_info_t *thread_info)
{
    int msgs_left;
    CURLMsg *msg;
    work_info_t *work_info = NULL;
    CURL *easy_handle = NULL;
    int num = 0;

    if (unlikely(thread_info->alloc_agent_num < global_info->agent_num_per_thread)) {
        num += check_rampup_agent(multi_handle, global_info, thread_info);
    }

    long response_code = 200;
    double total_time = 0.0f;
    unsigned int latency = 0;
    while ((msg = curl_multi_info_read(multi_handle, &msgs_left))) {
        if (CURLMSG_DONE == msg->msg) {
            easy_handle = msg->easy_handle;
            DUMP("easy_handle %p is done, code: %u-%s, msg_left: %d\n",
                    easy_handle, msg->data.result, curl_easy_strerror(msg->data.result),
                    msgs_left);
            DUMP("  %u:S[%u]-R[%u]-D[%u-%u], [%s]\n",
                    thread_info->idx, thread_info->work_done, thread_info->still_running,
                    thread_info->work_num, thread_info->succ_num, BOOL_DESC(thread_info->work_num - thread_info->succ_num == 1));

            if (likely(msg->data.result == CURLE_OK && easy_handle)) {
                /*  TODO: curl_easy_getinfo */
                if (likely(curl_easy_getinfo(easy_handle, CURLINFO_RESPONSE_CODE, &response_code) == CURLE_OK
                        && (response_code >= 200 && response_code < 400))) {
                    work_info = NULL;
                    if (curl_easy_getinfo(easy_handle, CURLINFO_PRIVATE, &work_info) == CURLE_OK && work_info != NULL) {
                        curl_easy_getinfo(easy_handle, CURLINFO_TOTAL_TIME, &(total_time));
                        latency = (unsigned int)(unsigned long)(total_time * 1000);
                        thread_info->total_latency += latency;
                        if (latency > thread_info->max_latency) {
                            thread_info->max_latency = latency;
                        }
                        if (latency < thread_info->min_latency) {
                            thread_info->min_latency = latency;
                        }

                        thread_info->total_data_len += work_info->data_len;
                        thread_info->succ_num++;
                    } else {
                        fill_thread_fixerr(thread_info, "get NULL private data");
                    }
                } else {
                    fill_thread_error(thread_info, "get response_code %ld", response_code);
                }

                curl_multi_remove_handle(multi_handle, easy_handle);
                if (get_one_work(global_info, thread_info)) {
                    work_info->data_len = 0;
                    curl_multi_add_handle(multi_handle, easy_handle);
                    num++;
                }
            } else {
                fill_thread_fixerr(thread_info, curl_easy_strerror(msg->data.result));
                if (easy_handle) {
                    curl_multi_remove_handle(multi_handle, easy_handle);
                }
            }
        } else {
            printf("-------------------- [easy_handle-%p] not OK\n", msg->easy_handle);
        }
    }

    return num;
}

static void print_thread_info(thread_info_t *thread_list, global_info_t *global_info)
{
    int idx = 0;
    printf("------------------\n");
    printf("[%lu]threads info:\n", time(NULL));
    for (idx = 0; idx < global_info->thread_num; idx++) {
        if (thread_list[idx].error_num == 0) {
            printf("  %u:S[%u]-R[%u]-D[%u-%u]\n",
                    idx, thread_list[idx].work_done, thread_list[idx].still_running, thread_list[idx].work_num, thread_list[idx].succ_num);
        } else {
            printf("  %u:S[%u]-R[%u]-D[%u-%u]-E[%u]-ES[%s]\n",
                    idx, thread_list[idx].work_done, thread_list[idx].still_running, thread_list[idx].work_num, thread_list[idx].succ_num,
                    thread_list[idx].error_num, thread_list[idx].sample_error);
            if (global_info->sample_error[0] == '\0') {
                fix_strcpy_s(global_info->sample_error, thread_list[idx].sample_error);
            }
        }
    }
    printf("------------------\n");
    fflush(stdout);
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

    CURLMcode mc; /* curl_multi_wait() return code */
    int numfds;
    int calc_num = 0;

    if (curl_multi_perform_cont(thread_info->multi_handle, &(thread_info->still_running), global_info) != CURLM_OK) {
        fprintf(stderr, "[%u-%lu-%u]error when call curl_multi_perform\n", thread_info->idx, time(NULL), __LINE__);
        return NULL;
    }

    DUMP("get still_running: %u, multi_handle: %p\n", thread_info->still_running, thread_info->multi_handle);
    do {
        /* wait for activity, timeout or "nothing" */
        mc = curl_multi_wait(thread_info->multi_handle, NULL, 0, 1000, &numfds);
        if (mc != CURLM_OK) {
            fprintf(stderr, "[%u]curl_multi_fdset() failed, code %d.\n", thread_info->idx, mc);
            break;
        }

        DUMP("[%u]get still_running: %u, multi_handle: %p, numfds: %u, calc_num: %u, alloc_agent_num: %u\n",
                thread_info->idx, thread_info->still_running, thread_info->multi_handle, numfds, calc_num, thread_info->alloc_agent_num);

        if (numfds || check_available(thread_info->multi_handle, global_info, thread_info) > 0 || calc_num >= CONN_TIMEOUT) {
            calc_num = 0;

            if (curl_multi_perform_cont(thread_info->multi_handle, &(thread_info->still_running), global_info) != CURLM_OK) {
                fprintf(stderr, "[%u-%lu-%u]error when call curl_multi_perform\n", thread_info->idx, time(NULL), __LINE__);
                break;
            }

#if 1
            if (check_available(thread_info->multi_handle, global_info, thread_info) > 0) {
                if (curl_multi_perform_cont(thread_info->multi_handle, &(thread_info->still_running), global_info) != CURLM_OK) {
                    fprintf(stderr, "[%u-%lu-%u]error when call curl_multi_perform\n", thread_info->idx, time(NULL), __LINE__);
                    break;
                }
            }
#endif
        } else {
            calc_num++;
        }
    } while ((thread_info->still_running > 0 || HAVE_WORK_AVAILABLE(global_info)) && !(global_info->do_exit));

    DUMP("[%u]last check avail\n", thread_info->idx);

#ifdef DEBUG
    if (thread_info->error_num == 0) {
        printf("  %u:S[%u]-R[%u]-D[%u-%u]\n",
                thread_info->idx, thread_info->work_done, thread_info->still_running, thread_info->work_num, thread_info->succ_num);
    } else {
        printf("  %u:S[%u]-R[%u]-D[%u-%u]-E[%u]-ES[%s]\n",
                thread_info->idx, thread_info->work_done, thread_info->still_running, thread_info->work_num, thread_info->succ_num,
                thread_info->error_num, thread_info->sample_error);
    }
#endif

    check_available(thread_info->multi_handle, global_info, thread_info);
    thread_info->work_done = TSE_DONE;
    return NULL;
}

static int32_t start_thread_list(thread_info_t *thread_list, global_info_t *global_info)
{
    int error;
    int idx = 0;

    for (idx = 0; idx < global_info->thread_num; ++idx) {
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

#define PRINT_ROUND 5
static int32_t check_thread_end(thread_info_t *thread_list, global_info_t *global_info)
{
    int idx = 0;
    time_t end_time = 0;

    if (global_info->during_time > 0) {
        end_time = time(NULL) + global_info->during_time;
    }

#if 0
    /* now wait for all threads to terminate */
    for (idx = 0; idx < global_info->thread_num; idx++) {
        pthread_join(thread_list[idx].tid, NULL);
        printf("[%lu]Thread %d terminated\n", time(NULL), idx);
    }
#endif

    int finish_num;
    int check_num = 0;
    bool get_exit = global_info->do_exit;
    do {
        finish_num = 0;
        for (idx = 0; idx < global_info->thread_num; idx++) {
            if (thread_list[idx].work_done >= TSE_DONE) {
                if (thread_list[idx].work_done == TSE_DONE) {
                    pthread_join(thread_list[idx].tid, NULL);
                    printf("[%lu]Thread %d terminated\n", time(NULL), idx);

                    thread_list[idx].work_done = TSE_VERIFY;
                }

                finish_num++;
            }
        }

        if (finish_num < global_info->thread_num) {
            sec_sleep(1);

            if (++check_num >= PRINT_ROUND) {
                print_thread_info(thread_list, global_info);
                if (get_exit) {
                    return -1;
                }

                check_num = 0;
                get_exit = global_info->do_exit;
            }
        } else {
            print_thread_info(thread_list, global_info);
        }

        if (global_info->during_time > 0 && time(NULL) >= end_time) {
            global_info->do_exit = true;
        }
    } while (finish_num < global_info->thread_num);

    return 0;
}

static void calc_stat(global_info_t *global_info, thread_info_t *thread_list, unsigned long msdiff)
{
    unsigned long total_length = 0;
    unsigned long total_time = 0;
    unsigned int max_latency = 0, min_latency = (unsigned int)(-1);
    int idx = 0;
    int suc_num = 0, error_num = 0;

    for (idx = 0; idx < global_info->thread_num; idx++) {
        total_length += thread_list[idx].total_data_len;
        suc_num += thread_list[idx].succ_num;
        error_num += thread_list[idx].error_num;

        total_time += thread_list[idx].total_latency;
        if (thread_list[idx].max_latency > max_latency) {
            max_latency = thread_list[idx].max_latency;
        }
        if (thread_list[idx].min_latency < min_latency) {
            min_latency = thread_list[idx].min_latency;
        }
    }

    printf("----------------------\n");
    printf("RESULT: \"%s\"\n", global_info->desc);
    printf("%16s : %u\n", "request num", global_info->read_work_idx);
    printf("%16s : %u\n", "error num", error_num);
    printf("%16s : %u\n", "succ num", suc_num);
    printf("%16s : %lu\n", "total length", total_length);
    printf("%16s : %lu\n", "total time(ms)", msdiff);
    printf("%16s : %luKB/s-%luMB/s\n", "throughput", (total_length) / (msdiff), (total_length) / (msdiff * 1024));
    printf("%16s : %lu/s\n", "request rate", (global_info->read_work_idx * 1000) / msdiff);
    if (suc_num > 0) {
        printf("%16s : %lums[max:%ums, min:%ums]\n", "latency", total_time / suc_num, max_latency, min_latency);
    }
    printf("----------------------\n");

    if (global_info->output_filename[0]) {
        bool file_exist = isfile(global_info->output_filename);
        FILE *fp = fopen(global_info->output_filename, "a");
        if (fp) {
            char *last_url = strrchr(global_info->url[global_info->is_https], '/');
            if (last_url) {
                last_url++;
            } else {
                last_url = global_info->url[global_info->is_https];
            }

            if (!file_exist) {
                fprintf(fp,
                        "\"%s\"," "\"%s\"," "\"%s\"," "\"%s\"," "\"%s\"," "\"%s\"," "\"%s\"," "\"%s\","
                        "\"%s\"," "\"%s\"," "\"%s\"," "\"%s\"," "\"%s\"," "\"%s\"," "\"%s\"\n",
                        "desc", "req url", "agent num", "req num", "err num", "suc num", "total len", "total ms", "perf KB", "perf MB",
                        "req rate", "latency avg", "latency max", "latency min", "err str"
                );
            }

            fprintf(fp,
                    "\"%s\"," "\"%s\"," "\"%u\"," "\"%u\"," "\"%u\"," "\"%u\"," "\"%lu\"," "\"%lu\","
                    "\"%lu\"," "\"%lu\"," "\"%lu\"," "\"%lu\"," "\"%u\"," "\"%u\"," "\"%s\"\n" ,
                    global_info->desc, last_url, global_info->agent_num, global_info->read_work_idx, error_num, suc_num,
                    total_length, msdiff, (total_length) / (msdiff), (total_length) / (msdiff * 1024),
                    (global_info->read_work_idx * 1000) / msdiff, (suc_num > 0 ? total_time / suc_num : 0),
                    max_latency, min_latency, global_info->sample_error
                   );
            fclose(fp);
        }
    }
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

    TS_BEGIN(perf);
    if (start_thread_list(thread_list, &global_info) != 0) {
        printf("error when start thread\n");
        return EXIT_FAILURE;
    }
    check_thread_end(thread_list, &global_info);
    TS_END(perf);

    calc_stat(&global_info, thread_list, TS_MSDIFF(perf));

    thread_destroy(&global_info, thread_list);
    global_destroy();
    return EXIT_SUCCESS;
}       /* -- end of function main -- */
