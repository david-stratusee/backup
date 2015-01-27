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
    printf("USAGE: \n\t-q for request num"
                  "\n\t-a for agent num"
                  "\n\t-s for https test"
                  "\n\t-f for config file"
                  "\n\t-d for desc"
                  "\n\t-r for rampup, unit second"
                  "\n\t-t for testing time, unit second"
                  "\n\t-o output file\n");
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
    PRINT_MEM_STR(global_info, desc);
    PRINT_MEM_INT(global_info, work_num);
    PRINT_MEM_INT(global_info, cpu_num);
    PRINT_MEM_INT(global_info, thread_num);
    PRINT_MEM_INT(global_info, agent_num);
    PRINT_MEM_INT(global_info, agent_num_per_thread);
    PRINT_MEM_INT(global_info, agent_num_per_sec_thread);
    PRINT_MEM_INT(global_info, rampup);
    PRINT_MEM_STR(global_info, url[HTTP_TYPE]);
    PRINT_MEM_STR(global_info, url[HTTPS_TYPE]);
    PRINT_MEM_INT(global_info, is_https);
    printf("----------------------\n");
}

int32_t parse_cmd(int argc, char **argv, global_info_t *global_info)
{
    int opt;
    bool is_daemon = true;
    while ((opt = getopt(argc, argv, "o:d:r:q:a:t:f:hsN")) != -1) {
        switch (opt) {
            case 'N':
                is_daemon = false;
                break;

            case 'o':
                fix_strcpy_s(global_info->output_filename, optarg);
                break;

            case 'd':
                fix_strcpy_s(global_info->desc, optarg);
                break;

            case 'r':
                global_info->rampup = atoi(optarg);
                break;

            case 'q':
                global_info->work_num = atoi(optarg);
                break;

            case 'a':
                global_info->agent_num = atoi(optarg);
                break;

            case 't':
                global_info->during_time = atoi(optarg);
                break;

            case 's':
                global_info->is_https = true;
                break;

            case 'f':
                {
                    cfg_item_t cfg_list[] = {
                        {FIX_CFGNAME("http"), FIX_CFG_STRDATA(global_info->url[HTTP_TYPE]), dft_cfg_set_string, "http url"},
                        {FIX_CFGNAME("https"), FIX_CFG_STRDATA(global_info->url[HTTPS_TYPE]), dft_cfg_set_string, "https url"},
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

    if ((global_info->work_num == 0 && global_info->during_time == 0) || global_info->agent_num == 0) {
        show_help();
        return -1;
    }

    if (global_info->url[global_info->is_https][0] == '\0') {
        printf("%s url is not defined in config file\n", global_info->is_https ? "https" : "http");
        return -1;
    }

    if (is_daemon) {
        daemon(1, 0);
        FILE *fout = fopen("daemon_out.log", "w");
        stdout = fout;
    }

    if (global_info->agent_num < global_info->thread_num) {
        global_info->thread_num = global_info->agent_num;
    }

    global_info->agent_num_per_thread = (global_info->agent_num / global_info->thread_num);
    if ((global_info->agent_num % global_info->thread_num) != 0) {
        global_info->agent_num_per_thread++;
    }

    if (global_info->rampup > 0) {
        global_info->agent_num_per_sec_thread = global_info->agent_num_per_thread / global_info->rampup;
        if ((global_info->agent_num_per_thread % global_info->rampup) != 0) {
            global_info->agent_num_per_sec_thread++;
        }
    } else {
        global_info->agent_num_per_sec_thread = global_info->agent_num_per_thread;
    }

    print_global_info(global_info);

    return 0;
}
