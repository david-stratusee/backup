/************************************************
 *       Filename: app_service.c
 *    Description:
 *        Created: 2015-05-01 03:30
 *         Author: dengwei
 ************************************************/
#include "common/types.h"
#include "common/umemory.h"
#include "common/misc.h"
#include "opts.h"
#include <dlfcn.h>

#define APP_SERVICE_NAME "ssl_service"
int32_t load_service_module(opts_t *opts, char *so_path)
{
    void *so_handle = dlopen(so_path, RTLD_NOW | RTLD_GLOBAL);

    if (PTR_NULL(so_handle)) {
        char *error_str = dlerror();
        fprintf(stderr, "error when open service file %s: %s\n", so_path, error_str);
        return -1;
    }

    void *srv_handle = dlsym(so_handle, APP_SERVICE_NAME);

    if (PTR_NULL(srv_handle)) {
        fprintf(stderr, "Not found symbol \"" APP_SERVICE_NAME "\" in library, unload it\n");
        dlclose(so_handle);
        return -2;
    }

    opts->srv_so_handle = so_handle;
    opts->srv_handle = srv_handle;
    return 0;
}

void unload_service_module(opts_t *opts)
{
    if (likely(opts)) {
        if (opts->srv_handle && opts->srv_handle->mod_uninit_service) {
            opts->srv_handle->mod_uninit_service();
        }

        if (opts->srv_so_handle) {
            dlclose(opts->srv_so_handle);
            opts->srv_so_handle = NULL;
        }
    }
}
