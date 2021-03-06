/***************************************************************************
 *                                  _   _ ____  _
 *  Project                     ___| | | |  _ \| |
 *                             / __| | | | |_) | |
 *                            | (__| |_| |  _ <| |___
 *                             \___|\___/|_| \_\_____|
 *
 * Copyright (C) 1998 - 2014, Daniel Stenberg, <daniel@haxx.se>, et al.
 *
 * This software is licensed as described in the file COPYING, which
 * you should have received as part of this distribution. The terms
 * are also available at http://curl.haxx.se/docs/copyright.html.
 *
 * You may opt to use, copy, modify, merge, publish, distribute and/or sell
 * copies of the Software, and permit persons to whom the Software is
 * furnished to do so, under the terms of the COPYING file.
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied.
 *
 ***************************************************************************/
/* This is a very simple example using the multi interface. */

#include <stdio.h>
#include <string.h>

/* somewhat unix-specific */
#include <sys/time.h>
#include <unistd.h>
#include <pthread.h>

/* curl stuff */
#include <curl/curl.h>

#ifdef _WIN32
#define WAITMS(x) Sleep(x)
#else
/* Portable sleep for platforms other than Windows. */
#define WAITMS(x)                               \
    struct timeval wait = { 0, (x) * 1000 };      \
    (void)select(0, NULL, NULL, NULL, &wait);
#endif

//char *http_url = "http://192.168.10.31/assets/jquery.flot.js";
//char *http_url = "http://192.168.101.102:8080/static/code.py";
char *http_url = "http://192.168.101.102:8080/images/sample1.jpg";
unsigned long total_length = 0;

int32_t check_available(CURLM *multi_handle)
{
    int         msgs_left;
    CURLMsg    *msg;

    int num = 0;
    while ((msg = curl_multi_info_read(multi_handle, &msgs_left))) {
        printf("msgs_left: %u\n", msgs_left);

        if (CURLMSG_DONE == msg->msg) {
            num++;
            CURL *easy_handle = msg->easy_handle;
            printf("easy_handle %p is done\n", easy_handle);
            fflush(stdout);
            curl_multi_remove_handle(multi_handle, easy_handle);
            //curl_multi_add_handle(multi_handle, easy_handle);
        } else {
            printf("-------------------- [easy_handle-%p] not OK\n", msg->easy_handle);
        }
    }

    return num;
}

size_t write_data(void *buffer, size_t size, size_t nmemb, void *userp)
{
    size_t real_size = size * nmemb;
    *((unsigned long *)userp) += real_size;
    return real_size;
}

static void *pull_one_url(void *arg)
{
    CURLM *multi_handle = arg;
    int still_running; /* keep number of running handles */

    /* we start some action by calling perform right away */
    curl_multi_perform(multi_handle, &still_running);
    printf("%u, still_running:%d\n", __LINE__, still_running);
    fflush(stdout);

    do {
        CURLMcode mc; /* curl_multi_wait() return code */
        int numfds;
        /* wait for activity, timeout or "nothing" */
        mc = curl_multi_wait(multi_handle, NULL, 0, 1000, &numfds);
        if (mc != CURLM_OK) {
            printf("curl_multi_fdset() failed, code %d.\n", mc);
            fflush(stdout);
            break;
        }

        /* 'numfds' being zero means either a timeout or no file descriptors to
           wait for. Try timeout on first occurance, then assume no file
           descriptors and no file descriptors to wait for means wait for 100
           milliseconds. */
#if 0
        if (!numfds) {
            repeats++; /* count number of repeated zero numfds */

            if (repeats > 1) {
                WAITMS(100); /* sleep 100 milliseconds */
            }

            printf("%u, still_running:%d\n", __LINE__, still_running);
            fflush(stdout);
        } else {
            repeats = 0;
        }
#endif

        printf("%u, still_running:%d, numfds: %u\n", __LINE__, still_running, numfds);
        fflush(stdout);
        curl_multi_perform(multi_handle, &still_running);
        printf("%u, still_running:%d\n", __LINE__, still_running);
        fflush(stdout);
        if (check_available(multi_handle) > 0) {
            //WAITMS(100);
            curl_multi_perform(multi_handle, &still_running);
            printf("%u, still_running:%d\n", __LINE__, still_running);
            fflush(stdout);
        }
    } while (still_running);

    printf("-----------------------\n");
    check_available(multi_handle);
    printf("-----------------------%lu\n", total_length);

    return NULL;
}

/*
 * Simply download a HTTP file.
 */
int main(void)
{
    CURL *http_handle;
    CURLM *multi_handle;
    //int repeats = 0;
    curl_global_init(CURL_GLOBAL_DEFAULT);
    http_handle = curl_easy_init();
    /* init a multi stack */
    multi_handle = curl_multi_init();
    /* set the options (I left out a few, you'll get the point anyway) */
    curl_easy_setopt(http_handle, CURLOPT_URL, http_url);
    curl_easy_setopt(http_handle, CURLOPT_WRITEFUNCTION, write_data);
    curl_easy_setopt(http_handle, CURLOPT_WRITEDATA, &total_length);
    printf("%u\n", __LINE__);
    fflush(stdout);
    /* add the individual transfers */
    curl_multi_add_handle(multi_handle, http_handle);
    printf("add handle: %p\n", http_handle);

    CURL *new_http_handle = curl_easy_duphandle(http_handle);
    printf("add handle: %p\n", new_http_handle);
    curl_multi_add_handle(multi_handle, new_http_handle);

    new_http_handle = curl_easy_duphandle(http_handle);
    printf("add handle: %p\n", new_http_handle);
    curl_multi_add_handle(multi_handle, new_http_handle);

    new_http_handle = curl_easy_duphandle(http_handle);
    printf("add handle: %p\n", new_http_handle);
    curl_multi_add_handle(multi_handle, new_http_handle);

    new_http_handle = curl_easy_duphandle(http_handle);
    printf("add handle: %p\n", new_http_handle);
    curl_multi_add_handle(multi_handle, new_http_handle);
    printf("%u\n", __LINE__);
    fflush(stdout);

    pthread_t tid;
    int error = pthread_create(&tid,
            NULL, /* default attributes please */
            pull_one_url,
            multi_handle);
    printf("error: %d\n", error);

    pthread_join(tid, NULL);

    //curl_multi_remove_handle(multi_handle, http_handle);
    //curl_easy_cleanup(http_handle);
    curl_multi_cleanup(multi_handle);
    curl_global_cleanup();
    return 0;
}
