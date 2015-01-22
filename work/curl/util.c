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
#include "common/cfg_parse.h"

static void show_help(void)
{
    printf("USAGE: \n\t-w for request num\n\t-t for agent num\n\t-s for https test\n\t-f for config file\n");
}

#define PRINT_MEM_INT(__stru, __memb)    printf("  %s: %u\n", #__memb, (__stru)->__memb)
#define PRINT_MEM_STR(__stru, __memb)    \
do {    \
    if (strlen((__stru)->__memb) > 0) {  \
        printf("  %s: %s\n", #__memb, (__stru)->__memb);    \
    }   \
} while (0)
void print_global_info(global_info_t *global_info)
{
    printf("----------------------\n");
    printf("GLOBAL INFO:\n");
    PRINT_MEM_INT(global_info, work_num);
    PRINT_MEM_INT(global_info, cpu_num);
    PRINT_MEM_INT(global_info, thread_num);
    PRINT_MEM_INT(global_info, curl_handle_num);
    PRINT_MEM_INT(global_info, handle_num_per_thread);
    PRINT_MEM_INT(global_info, rampup);
    PRINT_MEM_STR(global_info, http_url);
    PRINT_MEM_STR(global_info, https_url);
    PRINT_MEM_INT(global_info, is_https);
    printf("----------------------\n");
}

int32_t parse_cmd(int argc, char **argv, global_info_t *global_info)
{
    int opt;
    while ((opt = getopt(argc, argv, "r:w:t:f:hs")) != -1) {
        switch (opt) {
            case 'w':
                global_info->work_num = atoi(optarg);
                break;

            case 't':
                global_info->curl_handle_num = atoi(optarg);
                break;

            case 'r':
                global_info->rampup = atoi(optarg);
                break;

            case 's':
                global_info->is_https = true;
                break;

            case 'f':
                {
                    cfg_item_t cfg_list[] = {
                        {FIX_CFGNAME("http"), FIX_CFG_STRDATA(global_info->http_url), dft_cfg_set_string, "http url"},
                        {FIX_CFGNAME("https"), FIX_CFG_STRDATA(global_info->https_url), dft_cfg_set_string, "https url"},
                    };

                    int32_t ret_val = parse_cfglist_linux_fmt(optarg, cfg_list);
                    if (ret_val < 0) {
                        printf("error when parse config file: %s\n", optarg);
                        return -1;
                    }

                    break;
                }

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

    if (global_info->is_https && global_info->https_url[0] == '\0') {
        printf("https url is not defined in config file\n");
        return -1;
    } else if (!(global_info->is_https) && global_info->http_url[0] == '\0') {
        printf("http url is not defined in config file\n");
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
        global_info->work_list[idx].url = (global_info->is_https ? global_info->https_url : global_info->http_url);
        global_info->work_list[idx].idx = idx;
    }

    return 0;
}
