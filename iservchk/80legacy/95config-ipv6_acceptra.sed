s/disable IPv6 accept_ra on all network interfaces/enable IPv6 accept_ra on all network interfaces/g
s/! find \/proc\/sys\/net\/ipv6 -name accept_ra -exec cat {} + | grep -q '\^1\$'/! find \/proc\/sys\/net\/ipv6 -name accept_ra -exec cat {} + | grep -q '\^0\$'/g
s/for i in \/proc\/sys\/net\/ipv6\/conf\/\*\/accept_ra; do echo 0 > "$i"; done/for i in \/proc\/sys\/net\/ipv6\/conf\/*\/accept_ra; do echo 2 > "$i"; done/g
