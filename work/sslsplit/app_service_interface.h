/************************************************
 *       Filename: app_service_interface.h
 *    Description: 
 *        Created: 2015-05-01 04:17
 *         Author: dengwei
 ************************************************/
#ifndef _APP_SERVICE_INTERFACE_H
#define _APP_SERVICE_INTERFACE_H

#include "common/types.h"

#define APP_DECLARE_MOD_DATA   __declspec(dllexport)
#define MAX_PORTS_NUM 8
/* Description: app service interface */
typedef struct _app_service_t {
    int32_t port[MAX_PORTS_NUM];
    const char *name;      

    int (*mod_init_service)(void);
    int (*mod_post_init_service)(void);
    void (*mod_uninit_service)(void);

    void *(*mod_init_transaction)(void);
    void (*mod_release_transaction)(void *trans_handle);

    int (*mod_data_handle)(void *trans_handle, char *buffer, int32_t buffer_size, bool is_ssn_end);
    void (*mod_record_core_info)(int signum, int intr_type, FILE *fp);
} app_service_t;   /* -- end of app_service_t -- */

#endif   /* -- #ifndef _APP_SERVICE_INTERFACE_H -- */

