# Firejail profile for nc to restrict access to some sensitive locations

blacklist /var/www
blacklist /usr/lib/cgi-bin
blacklist /root
blacklist /tmp
blacklist /etc/passwd
blacklist /etc/group
blacklist /var/log
