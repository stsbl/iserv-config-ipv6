s#ifconfig|grep -q \^ppp#ifconfig | grep -q '^dsl:'#
s#\$8~/\^ppp/#\$8~/^dsl\$/#
