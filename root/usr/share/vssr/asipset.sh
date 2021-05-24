#!/bin/sh

ipset -N blacklist hash:net 2>/dev/null
ipset -N china hash:net 2>/dev/null

[ -f /etc/vssr/block_as.list ] && for as in $(cat /etc/vssr/block_as.list |grep -Eo "^[^#].*([0-9]+).*$"|grep -Eo "[0-9]+"); do echo "dealing with AS${as} ..."; for i in $(wget --no-check-certificate -U 'Mozilla/5.0' https://ipinfo.io/AS${as} -O- | grep -E "f=\"/AS${as}/.*?\"\s*>" | sed -E "s/.*AS${as}\/(.*)\".*>/\1/g" | grep -v :); do ipset add blacklist $i; done; done
[ -f /etc/vssr/esc_as.list ]   && for as in $(cat   /etc/vssr/esc_as.list |grep -Eo "^[^#].*([0-9]+).*$"|grep -Eo "[0-9]+"); do echo "dealing with AS${as} ..."; for i in $(wget --no-check-certificate -U 'Mozilla/5.0' https://ipinfo.io/AS${as} -O- | grep -E "f=\"/AS${as}/.*?\"\s*>" | sed -E "s/.*AS${as}\/(.*)\".*>/\1/g" | grep -v :); do ipset add china     $i; done; done
