#!/bin/bash

fail2ban-client status | grep "Jail list:" | sed "s/\`- Jail list://" | sed "s/\s//g" | sed "s/,/\n/g" | xargs -L1 fail2ban-client status | grep "IP list:" | sed 's/`- Banned IP list://g' | tr " " "\n" | sed -r "s/\s//g" | sed '/^$/d' | sort | uniq  > tmp.txt

