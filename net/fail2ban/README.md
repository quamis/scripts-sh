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

# qmonitor2
**qmonitor2** is a custom filter that will ban all IP's that access invalid url's on the server, most likely trying to hit known buggy backends. It has a small whitelist for items where **404**'s should be ignored, and that list should be edited manually.

## qmonitor2, step 1
Create `/etc/fail2ban/filter.d/apache-qmonitor2.conf` and paste the contents of [apache-qmonitor2.conf](./apache-qmonitor2.conf) file
You should edit `_qm_valid_paths_regex` to a value that suits you. **Please note the final `|`. IT NEEDS TO BE THERE**

## qmonitor2, step 2
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

---------------

# qmonitor2-l0
**qmonitor2** is a very strict, level 0 filter that will ban all IP's that access certain url's on the server, most likely trying to hit known buggy backends. It's designed for attacks that hit only once and are not picked up by the **qmonitor2** basic filter. **It will ban guests after only one access, so care must be taken on the internal blacklist**. Basically this filter implements a big blacklist, after analysing my own server logs.

## qmonitor2-l0, step 1
Create `/etc/fail2ban/filter.d/apache-qmonitor2.conf` and paste the contents of [apache-qmonitor2-l0.conf](./apache-qmonitor2-l0.conf) file

## qmonitor2-l0, step 2
In `/etc/fail2ban/jail.d/apache.conf` add this at the end of the file:

```properties
[apache-qmonitor2-l0]
enabled   = true
banaction = iptables-allports
port      = http,https
logpath   = /var/log/apache2/access.log
bantime   = 2mo
findtime  = 1mo
maxretry  = 1
```

------------

## Debugging/developping
You might scan the access.log file by running
```bash
cat ./access.log | egrep -v "(\/nextcloud\/|\/dev\/pmt\/| \/ |favicon.ico|\/.well-known\/.+|\/sys\/deluge\/)
```

You might test a filter by running:
```bash
fail2ban-regex --print-all-matched /var/log/apache2/access.log /etc/fail2ban/filter.d/apache-qmonitor2.conf /etc/fail2ban/filter.d/apache-qmonitor2.conf
```

Unban an IP by running this:
```bash
fail2ban-client set apache-qmonitor2 unbanip 192.168.1.1
```
