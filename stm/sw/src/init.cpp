#define G_LOG_DOMAIN "stm-sw"
#include "key-agent/key_agent.h"
#include "key-agent/stm/stm.h"
#include "config-file/key_configfile.h"
#include "k_errors.h"
#include <glib.h>
#include <errno.h>
#include <iostream>
#include <memory>

#include <openssl/evp.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/bio.h>
#include <openssl/bn.h>
#include <openssl/buffer.h>

#include "internal.h"

using namespace std;

using BIO_MEM_ptr = std::unique_ptr<BIO, decltype(&::BIO_free)>;


extern "C" const char *
stm_init(const char *config_directory, stm_mode mode, GError **err)
{
    if (mode == APPLICATION_STM_MODE)
        application_stm_init(config_directory, err);
    else
        server_stm_init(config_directory, err);

    if (*err) {
		k_critical_error(*err);
		return NULL;
	}
	return "SGX";
}
