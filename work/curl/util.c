/************************************************
 *       Filename: util.c
 *    Description:
 *        Created: 2015-01-20 16:45
 *         Author: dengwei david@stratusee.com
 ************************************************/
#include <stdlib.h>
#include <stdio.h>

#include "types.h"
#include "data_struct.h"

static void show_help(void)
{
    printf("USAGE: \n\t-w for work_num\n\t-t for thread num\n\t-s for https test\n");
}

#define PRINT_MEM_INT(__stru, __memb)    printf("  %s: %u\n", #__memb, (__stru)->__memb)
#define PRINT_MEM_STR(__stru, __memb)    printf("  %s: %s\n", #__memb, (__stru)->__memb)
static void print_global_info(global_info_t *global_info)
{
    printf("----------------------\n");
    printf("GLOBAL INFO:\n");
    PRINT_MEM_INT(global_info, work_num);
    PRINT_MEM_INT(global_info, cpu_num);
    PRINT_MEM_INT(global_info, thread_num);
    PRINT_MEM_INT(global_info, curl_handle_num);
    PRINT_MEM_INT(global_info, handle_num_per_thread);
    PRINT_MEM_STR(global_info, url);
    printf("----------------------\n");
}

int32_t parse_cmd(int argc, char **argv, global_info_t *global_info)
{
    int opt;
    while ((opt = getopt(argc, argv, "w:t:hs")) != -1) {
        switch (opt) {
            case 'w':
                global_info->work_num = atoi(optarg);
                break;

            case 't':
                global_info->curl_handle_num = atoi(optarg);
                break;

            case 's':
                global_info->url = HTTPS_URL;
                break;

            case 'h':
            default:
                show_help();
                return 1;
        }
    }

    if (global_info->work_num == 0 || global_info->curl_handle_num == 0) {
        show_help();
        return -1;
    }

    if (global_info->curl_handle_num < global_info->thread_num) {
        global_info->thread_num = global_info->curl_handle_num;
    }

    global_info->handle_num_per_thread = (global_info->curl_handle_num / global_info->thread_num);
    if ((global_info->curl_handle_num % global_info->thread_num) != 0) {
        global_info->handle_num_per_thread++;
    }

    print_global_info(global_info);

    global_info->work_list = calloc(global_info->work_num, sizeof(work_info_t));
    if (global_info->work_list == NULL) {
        printf("alloc work_list error\n");
        return -1;
    }

    int idx = 0;
    for (idx = 0; idx < global_info->work_num; ++idx) {
        global_info->work_list[idx].url = global_info->url;
        global_info->work_list[idx].idx = idx;
    }

    return 0;
}
