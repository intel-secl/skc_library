AM_CPPFLAGS = -I$(top_srcdir) $(COMMON_FLAGS) $(LIBCURL_CPPFLAGS) \
	-std=c++11 -DPKGDATA="\"$(prefix)\""

lib_LTLIBRARIES = \
    libskc_utils.la

libskc_utils_la_SOURCES = \
    curl.cpp

libskc_utils_la_LDFLAGS = -version-info @VERSION_INFO@ \
	$(LIBCURL) \
	$(COMMON_LDFLAGS) 
