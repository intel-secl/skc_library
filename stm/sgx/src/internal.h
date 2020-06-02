#ifndef STM_SGX_INTERNAL_H
#define STM_SGX_INTERNAL_H

#include <key-agent/stm/stm.h>

#ifdef  __cplusplus
extern "C" {
#endif

const char *stm_init(const char *config_directory, stm_mode mode, GError **err);
gboolean stm_set_session(keyagent_stm_session_details *details, GError **error);
gboolean stm_load_key(keyagent_stm_loadkey_details *details, GError **error);
gboolean stm_create_challenge(keyagent_stm_create_challenge_details *details, GError **err);

#ifdef  __cplusplus
};
#endif

#endif //STM_SGX_INTERNAL_H
