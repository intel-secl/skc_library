#define G_LOG_DOMAIN "keyagent-cli"

#include <stdlib.h>
#include <stdio.h>
#include <glib.h>
#include "key-agent/key_agent.h"
#include <syslog.h>
#include "k_errors.h"


const gchar g_log_domain[] = "keyagent-cli";
static gboolean verbose = FALSE;
static gboolean listnpms = FALSE;
static gboolean liststms = FALSE;
static gboolean debug = FALSE;
static gchar *configfile = NULL;
static gchar *keyurl = NULL;

static GOptionEntry entries[] =
{
  { "verbose", 'v', 0, G_OPTION_ARG_NONE, &verbose, "Be verbose", NULL },
  { "config", 0, 0, G_OPTION_ARG_FILENAME, &configfile, "required! config file to use", NULL },
  { "list-npms", 0, 0, G_OPTION_ARG_NONE, &listnpms, "List the npms", NULL },
  { "list-stms", 0, 0, G_OPTION_ARG_NONE, &liststms, "List the stms", NULL },
  { "load-key", 0, 0, G_OPTION_ARG_FILENAME, &keyurl, "url of key to transfer", NULL },
  { "debug", 0, 0, G_OPTION_ARG_NONE, &debug, "enable debug output", NULL },
  { NULL }
};

int
main (int argc, char *argv[])
{
	GError *error = NULL;
	GOptionContext *context;

	context = g_option_context_new ("- key-agent cli");
	g_option_context_add_main_entries (context, entries, NULL);
	if (!g_option_context_parse (context, &argc, &argv, &error))
	{
		g_print ("option parsing failed: %s\n", error->message);
		exit (1);
	}

	if (debug) { 
		setenv("G_MESSAGES_DEBUG", "all", 1);
	}

	//g_log_set_writer_func (log_writer, NULL, NULL);

	k_debug_msg("TESTING");
	if (!configfile)
	{
		g_print("%s\n", g_option_context_get_help (context, TRUE, NULL));
		exit(1);
	}
	if (!keyagent_init(configfile, &error))
	{
		k_fatal_error(error);
		exit(1);
	}
	if (listnpms)
		keyagent_npm_showlist();

	if (liststms)
		keyagent_stm_showlist();


	if (keyurl)
		keyagent_loadkey(keyurl, &error);

	exit(0);
}
