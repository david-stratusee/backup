/************************************************
 *       Filename: app_service.h
 *    Description: 
 *        Created: 2015-05-01 04:08
 *         Author: dengwei
 ************************************************/
#ifndef _APP_SERVICE_H
#define _APP_SERVICE_H

#include "common/types.h"
#include "opts.h"

int32_t load_service_module(opts_t *opts, char *so_path);
void unload_service_module(opts_t *opts);

#endif   /* -- #ifndef _APP_SERVICE_H -- */

