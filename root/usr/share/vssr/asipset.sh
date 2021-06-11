#!/bin/sh

ipset -N blacklist hash:net 2>/dev/null
ipset -N china hash:net 2>/dev/null

function addAStoIPSet(){
    as=$(echo $1|sed 's/,/%2C/g')
    body="theinput=${as}&thetest=asnlookup&name_of_nonce_field=0d63634a5a&_wp_http_referer=%2Fas-ip-lookup%2F"

    res=$(curl 'https://hackertarget.com/as-ip-lookup/' -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)' -H 'referer: https://hackertarget.com/as-ip-lookup/' --data-raw $body)
    for i in $(echo $res|grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+');do ipset add $2 $i;done
}

[ -f /etc/vssr/block_as.list ] && blackAS=$(cat /etc/vssr/block_as.list |grep -Eo "^[^#].*([0-9]+).*$"|grep -Eo "[0-9]+"|tr  "\n" ",") && addAStoIPSet $blackAS blacklist
[ -f /etc/vssr/esc_as.list ] && escAS=$(cat /etc/vssr/esc_as.list |grep -Eo "^[^#].*([0-9]+).*$"|grep -Eo "[0-9]+"|tr  "\n" ",") && addAStoIPSet $escAS china

