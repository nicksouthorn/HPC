for i in {0..15}; do ping -c 1 r1i0n$i | grep icmp | awk '{print $4 " , " $5 }'| sed -e 's/\://g' | sed -e 's/[()]//g'   ; done > hosts.txt
for i in {0..15}; do ping -c 1 r1i1n$i | grep icmp | awk '{print $4 " , " $5 }'| sed -e 's/\://g' | sed -e 's/[()]//g'   ; done >> hosts.txt
for i in {0..15}; do ping -c 1 r1i3n$i | grep icmp | awk '{print $4 " , " $5 }'| sed -e 's/\://g' | sed -e 's/[()]//g'   ; done >> hosts.txt
