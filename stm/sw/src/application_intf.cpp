#define G_LOG_DOMAIN "stm-sw"
#include "key-agent/stm/stm.h"
#include "config-file/key_configfile.h"
#include "k_errors.h"
#include <glib.h>
#include <unistd.h>
#include "internal.h"

using namespace std;

namespace application_sw_stm {
    GString *configfile;
    gboolean debug;
}

extern "C" void
application_stm_init(const char *config_directory, GError **err)
{
    gint  init_delay = 0;

    application_sw_stm::configfile = g_string_new(g_build_filename(config_directory, "sw_stm.ini", NULL));
    void *config = key_config_openfile(application_sw_stm::configfile->str, err);
    if (config) {
        init_delay = key_config_get_integer_optional(config, "testing", "initdelay", 0);
    }
    if (init_delay)
        sleep(init_delay);
}

__attribute__ ((visibility("default")))
gboolean
stm_create_challenge(keyagent_stm_create_challenge_details *details, GError **err)
{
	gboolean ret = FALSE;

	if (!details->apimodule_get_challenge_cb) {
		k_set_error (err, STM_ERROR_API_MODULE_LOADKEY, "invalid apimodule");
		return FALSE;
	}

	ret = (*details->apimodule_get_challenge_cb)(&details->apimodule_details, NULL, err);
	
	if (!details->apimodule_details.challenge && !*err) {
		k_set_error (err, STM_ERROR_API_MODULE_LOADKEY, 
			"no challenge returned from api-module");
		ret = FALSE;
	}
    k_debug_msg("%s: returning %d", __func__, ret);
    return ret;
}

__attribute__ ((visibility("default")))
gboolean
stm_set_session(keyagent_stm_session_details *details, GError **err)
{
    gboolean ret = FALSE;
	if (!details->set_wrapping_key_cb) {
		k_set_error (err, STM_ERROR_API_MODULE_LOADKEY, "invalid apimodule");
		return FALSE;
	}
	ret = (*details->set_wrapping_key_cb)(&details->apimodule_details, NULL, err);
    k_debug_msg("%s: returning %d", __func__, ret);
    return ret;
}

__attribute__ ((visibility("default")))
gboolean
stm_load_key(keyagent_stm_loadkey_details *details, GError **error)
{
    gboolean ret = FALSE;
	if (!details->apimodule_load_key_cb) {
		k_set_error (error, STM_ERROR_API_MODULE_LOADKEY, "invalid apimodule");
		return FALSE;
	}
	ret = (*details->apimodule_load_key_cb)(&details->apimodule_details, NULL, error);
out:
    k_debug_msg("%s: returning %d", __func__, ret);
    return ret;
}

extern "C" gboolean
stm_seal_key(keyagent_keytype type, k_attributes_ptr attrs, k_buffer_ptr *sealed_data, GError **error)
{
    return FALSE;
}

extern "C" gboolean
stm_unseal_key(keyagent_keytype type, k_buffer_ptr sealed_data, k_attributes_ptr *wrapped_attrs, GError **error)
{
    return FALSE;
}
