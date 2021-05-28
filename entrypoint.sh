#!/bin/ash
c=0
res="b71ca9c0b2ca1390bfd3a4515c69a38230962ff4  -"
while true; do
  if [ "$(iptables -L | sha1sum)" != "$res" ]; then
    /firewall.sh
    sleep 2
    c=0
  else
    let c+=1
    echo "Wait 10 sec..."
    sleep 10
    echo "Timeout done ($c of 6)."
    [ $c -ge 6 ] && exit 0
  fi
done
