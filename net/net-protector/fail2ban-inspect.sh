#!/bin/bash

fail2ban-client status | grep "Jail list:" | sed "s/\`- Jail list://" | sed "s/\s//g" | sed "s/,/\n/g" | xargs -L1 fail2ban-client status | less
