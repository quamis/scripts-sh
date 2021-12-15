# About
A very restrictive `fail2ban` filter that works with `fail2ban` version `0.10`

```bash
$ fail2ban-client -V
Fail2Ban v0.10.2
```

----------
# General fail2ban configuration
You should configure `fail2ban` to ignore a small list of trusted IP's.
The default values for internal variables can be found in `/etc/fail2ban/jail.conf`.
```properties
ignoreip = 127.0.0.1/8 ::1 ONE.PRIVILEGED.LOCAL.IP MY.WORK.IP.HERE MY.OTHER.GENERAL.IP mydomain.go.ro
```
Replace the above texts with some real IP's, but be careful about not letting this list empty, as you might end up banning yourself.


## Step 1
Create `/etc/fail2ban/filter.d/apache-qmonitor2.conf`
Paste into it the following rules:
```properties
[INCLUDES]

[Definition]

_qm_valid_paths_regex = *** EDIT THIS HERE ***|

failregex = ^<HOST> - - \[.*?\] \"(GET|POST|HEAD) .*? HTTP/1\.[0-1]\" 40(0|4|8) [0-9]+ "

ignoreregex = ^<HOST> - - \[.*\] \"(GET|POST|HEAD) (%(_qm_valid_paths_regex)s/favicon.ico|/robots.txt|sitemap.xml|/.well-known/security.txt|/) HTTP/1\.[0-1]\"

```

You should edit `_qm_valid_paths_regex` to a value that suits you. In my case that would be:
```properties
_qm_valid_paths_regex = /dev-folder/.+|/health-notes/.+|/MyOwnC10ud/index.php/.+|
```
Please note the final `|`. **IT NEEDS TO BE THERE**

## Step 2
In `/etc/fail2ban/jail.d/apache.conf` add this at the end of the file:

```properties
[apache-qmonitor2]
enabled   = true
banaction = iptables-allports
port      = http,https
logpath   = /var/log/apache2/access.log
bantime   = 2mo
findtime  = 1mo
maxretry  = 3
```


## Debugging/developping
You might test a filter by running:
```bash
fail2ban-regex --print-all-matched /var/log/apache2/access.log /etc/fail2ban/filter.d/apache-qmonitor2.conf /etc/fail2ban/filter.d/apache-qmonitor2.conf
```

Unban an IP by running this:
```bash
fail2ban-client set apache-qmonitor2 unbanip 192.168.1.1
```