#ifndef __K_TYPES_H__
#define __K_TYPES_H__
#include <glib.h>

#if(( __GNUC__ >= 4 ) && (!SKC_KEYAGENT_DLL_API_VISIBLITY))
	#define DLL_PUBLIC __attribute__ ((visibility ("default")))
	#define DLL_LOCAL  __attribute__ ((visibility ("hidden")))
#else
	#define DLL_PUBLIC
	#define DLL_LOCAL
#endif

#define FORMAT_PEM "PEM"
#define FORMAT_ENG "ENG"

typedef struct {
	const char *certfile;
	const char *ca_certfile;
	const char *certtype;
	const char *keyname;
	const char *keytype;
	const char *key_password;
	gboolean ssl_verify;
	gint ssl_version;
}keyagent_ssl_opts;

typedef struct {
	GByteArray *bytes;
	gint ref_count;
}k_buffer;

typedef struct {
	GHashTable *hash;
	gint ref_count;
}k_attributes;

typedef k_buffer * k_buffer_ptr;
typedef k_attributes * k_attributes_ptr;

#define k_buffer_data(PTR) (PTR)->bytes->data
#define k_buffer_length(PTR) (PTR)->bytes->len

static inline void
k_buffer_append(k_buffer_ptr buf, void *data, int size)
{
	g_byte_array_append(buf->bytes, (guint8*) data, size);
}

static inline k_buffer_ptr
k_buffer_alloc(void *data, int size)
{
	k_buffer_ptr buf = g_new0(k_buffer, 1);
	buf->ref_count = 1;
	buf->bytes = g_byte_array_sized_new(size);

	if(!data) {
		g_byte_array_set_size(buf->bytes, size);
	} else {
		k_buffer_append(buf, data, size);
	}
	return buf;
}

static inline k_buffer_ptr
k_buffer_ref(k_buffer_ptr buf)
{
	g_byte_array_ref(buf->bytes);
	g_atomic_int_inc(&buf->ref_count);
	return buf;
}

static inline void
k_buffer_unref(k_buffer_ptr buf)
{
	if(buf != NULL)
	{
		g_byte_array_unref(buf->bytes);
		if (g_atomic_int_dec_and_test(&buf->ref_count))
			g_free(buf);
	}
}

static inline gboolean
k_buffer_equal(k_buffer_ptr buf1, k_buffer_ptr buf2)
{
    if (k_buffer_length(buf1) != k_buffer_length(buf2)) return FALSE;

    return (memcmp(k_buffer_data(buf1),k_buffer_data(buf2), k_buffer_length(buf1)) ? FALSE: TRUE);
}

static inline void
k_attribute_free(gpointer _data)
{
	k_buffer_ptr data = (k_buffer_ptr)_data;
	k_buffer_unref(data);
}

static inline  k_attributes_ptr
k_attributes_alloc() {
	k_attributes_ptr ptr = g_new0(k_attributes, 1);
	ptr->ref_count = 1;
	ptr->hash = g_hash_table_new_full(g_str_hash, g_str_equal, NULL, k_attribute_free);
	return ptr;
}

static inline k_attributes_ptr
k_attributes_ref(k_attributes_ptr attrs)
{
	g_hash_table_ref(attrs->hash);
	g_atomic_int_inc(&attrs->ref_count);
	return attrs;
}

static inline void
k_attributes_unref(k_attributes_ptr attrs)
{
	g_hash_table_unref(attrs->hash);
	if(g_atomic_int_dec_and_test(&attrs->ref_count))
		g_free(attrs);
}
#endif
