#!/bin/bash
crontab -l | grep -v 'credential_agent.ini' | crontab -
rm -rf /var/log/credential-agent.log 2> /dev/null
rm -rf /opt/skc 2> /dev/null
echo "SKC_Library Uninstalled"
