#!/bin/bash
# Helper script for pentest.psauxit.com

sleep 3

lavg=$(< /proc/loadavg awk '{print $1}')
lavgi=$(echo "100 * $lavg" | bc | cut -f1 -d".")
mf=$(free -m | sed -n '2p' | awk '{print $7}')
np=$(nproc); mcl=$(echo "100 * $np" | bc );

echo ""

if [[ "${lavgi}" -gt "${mcl}" || "${mf}" -lt 756 ]]; then
  echo "System is busy now. Your request hasn't been queued. Please try again later!" | cowsay | lolcat -f -t
  exit 1
fi

banner () {
  figlet -t -k PSAUXIT | lolcat -f -t
}

not_scan_me () {
  if [[ $1 == *"psauxit.com"* || $1 == *"dedeoglupeynir.com"* || $1 == *"ilhamireis.com"* || $1 == *"zuzutasarim.com"* || $1 == *"159.69.247."* || $1 == *"127.0."* || $1 == *"localhost"* || $1 == *"local.psauxit.com"* ]]; then
    echo "Permission denied, you attempted to scan me or my neighbours. Angry cow following you!" | cowsay | lolcat -f -t
    exit 1
  fi
}

turkey_ip () {
 if geoiplookup $1 | grep "TR" >/dev/null 2>&1; then
   echo "Port scanning for TURKEY IP ranges disabled! Ne Mutlu Türküm Diyene!" | cowsay | lolcat -f -t
   echo ""
   exit 1
 fi
}

cidr_disable () {
  if [[ $1 == *","* ]]; then
    echo "IP range scans not enabled for free plan!" | cowsay | lolcat -f -t
    exit 1
  fi

  if echo $1 | egrep '[0-9]{1,3}(\.[0-9]{1,3}){0,3}/[0-9]+' >/dev/null 2>&1; then
    echo "CIDR IP range scans not enabled for free plan!" | cowsay | lolcat -f -t
    exit 1
  fi
}

only_domains () {
  if ! echo $1 | grep -P '(?=^.{4,253}$)(^(?:[a-zA-Z0-9](?:(?:[a-zA-Z0-9\-]){0,61}[a-zA-Z0-9])?\.)+([a-zA-Z]{2,}|xn--[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])$)'; then
    echo "Bad target. This tool only accepts hostanme or FQDN e.g. example.com!" | cowsay | lolcat -f -t
    exit 1
  fi
}

only_ip () {
  if ! [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Bad target. This tool only accepts IP address e.g. 1.1.1.1" | cowsay | lolcat -f -t
    exit 1
  fi
}

remove_prefix () {
  cln="$(echo $1 | sed -e 's|^[^/]*//||' -e 's|/.*$||')"
}

ip_validate () {
  if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    if ipcalc $1 | grep "INVALID" >/dev/null 2>&1; then
      echo "Bad IP, check IP address!" | cowsay | lolcat -f -t
      exit 1
    elif ipcalc $1 | grep "Private Internet" >/dev/null 2>&1; then
      echo "Forbidden! You cannot scan private LAN." | cowsay | lolcat -f -t
      exit 1
    fi
  fi
}

cidr_check () {
  if ! [[ $1 == *"/"* ]]; then
    echo "Missing Subnet Mask. Specify an IP address with subnet e.g. 127.0.0.1/24" | cowsay | lolcat -f -t
    exit 1
  else
   deserialized=${1%/*}
   ip_validate $deserialized
  fi
}

add_prefix () {
  if [[ ! $1 == http* ]]; then
    furl=$(echo $1 | awk '{print "https://" $1}')
  fi
}

my_wait () {
  local my_pid=$!
  local result
  trap "kill -9 $my_pid 2>/dev/null" EXIT
  wait $my_pid
  [[ $? -eq 0 ]] && result=ok
  trap - EXIT
  [[ "${result}" ]] && return 0
  return 1
}

my_wait_err () {
  my_wait >/dev/null 2>&1 || echo "Aborted, something goes wrong and process is zombie now. Try again!" | cowsay | lolcat -f -t
}

if [[ $1 == dig ]]; then
  if [[ $# -eq 2 ]]; then
    not_scan_me $2
    ip_validate $2
    banner
    timeout 1m dig $2 any
  elif [[ $3 == DMARC ]]; then
    not_scan_me $4
    ip_validate $4
    banner
    timeout 1m dig TXT _dmarc.$4
  elif [[ $3 == SPF ]]; then
    not_scan_me $4
    ip_validate $4
    banner
    timeout 1m dig TXT $4
  elif [[ $3 == MX ]]; then
    not_scan_me $4
    ip_validate $4
    banner
    timeout 1m dig MX $4
  elif [[ $3 == NS ]]; then
    not_scan_me $4
    ip_validate $4
    banner
    timeout 1m dig NS $4
  elif [[ $3 == A ]]; then
    not_scan_me$4
    ip_validate $4
    banner
    timeout 1m dig A $4
  elif [[ $3 == REVERSE ]]; then
    not_scan_me $4
    ip_validate $4
    banner
    timeout 1m dig -x $(dig A $4 | grep -v -e "^$\|^;" | awk '{print $NF}') | grep -v -e "^$\|^;" | awk '{print $5}' | sed 's/.$//'
  fi
elif [[ $1 == dnsrecon ]]; then
  if [[ $# -eq 2 ]]; then
    not_scan_me $2
    only_domains $2
    banner
    timeout -s 9 10m python dnsrecon.py -d $2 --threads 1 &
    my_wait_err
  elif [[ $3 == AXFR ]]; then
    not_scan_me $4
    only_domains $4
    banner
    timeout -s 9 10m python dnsrecon.py -d $4 -t zonewalk --threads 1 &
    my_wait_err
  elif [[ $3 == ZONEWALK ]]; then
    not_scan_me $4
    only_domains $4
    banner
    timeout -s 9 10m python dnsrecon.py -d $4 -t axfr --threads 1 &
    my_wait_err
  elif [[ $3 == BRUTE ]]; then
    not_scan_me $4
    only_domains $4
    banner
    timeout -s 9 30m python dnsrecon.py -d $4 -D /dnsrecon/subdomains-top1mil-20000.txt -t brt --threads 1 &
    my_wait_err
  fi
elif [[ $1 == wpscan ]]; then
  if [[ $# -eq 2 ]]; then
    not_scan_me $2
    timeout -s 9 30m wpscan --url $2 -e vp,vt,u --random-user-agent --ignore-main-redirect -t 1 &
    my_wait_err
  else
    args=("$@")
    for n in "${!args[@]}"; do
      [[ ${args[n]} == timeout ]] && opt_1="--connect-timeout ${args[n+1]}"
      [[ ${args[n]} == request ]] && opt_2="--request-timeout ${args[n+1]}"
      [[ ${args[n]} == DISABLE ]] && opt_3="--disable-tls-checks"
    done

    for i in $@; do
      if [[ $i == MIXED ]]; then
        not_scan_me "${@: -1}"
        timeout -s 9 30m wpscan --url ${@: -1} --detection-mode mixed -e vp,vt,u --random-user-agent --ignore-main-redirect -t 1 $opt_1 $opt_2 $opt_3 &
        my_wait_err
      elif [[ $i == PASSIVE ]]; then
        not_scan_me "${@: -1}"
        timeout -s 9 30m wpscan --url ${@: -1} --detection-mode passive -e vp,vt,u --random-user-agent --ignore-main-redirect -t 1 $opt_1 $opt_2 $opt_3 &
        my_wait_err
      elif [[ $i == AGGRESSIVE ]]; then
        not_scan_me "${@: -1}"
        timeout -s 9 30m wpscan --url ${@: -1} --detection-mode aggressive -e vp,vt,u --random-user-agent --ignore-main-redirect -t 1 $opt_1 $opt_2 $opt_3 &
        my_wait_err
      fi
    done
  fi
elif [[ $1 == amass ]]; then
  if [[ $# -eq 2 ]]; then
    not_scan_me $2
    only_domains $2
    banner
    timeout -s 9 15m amass enum -d $2 -brute -src -ip -min-for-recursive 2 &
    my_wait_err
  elif [[ $3 == ACTIVE ]]; then
    not_scan_me $4
    only_domains $4
    banner
    timeout -s 9 15m amass enum -active -d $4 -brute -src -ip -min-for-recursive 2 &
    my_wait_err
  elif [[ $3 == PASSIVE ]]; then
    not_scan_me $4
    only_domains $4
    banner
    timeout -s 9 15m amass enum -d $4 -brute -src -ip -min-for-recursive 2 &
    my_wait_err
  fi
elif [[ $1 == ddec ]]; then
  not_scan_me "${@: -1}"
  only_domains "${@: -1}"
  banner
  timeout 1m python ddec.py $2 $3 $4 $5 $6
elif [[ $1 == rustscan ]]; then
  if [[ $# -eq 2 ]]; then
    not_scan_me $2
    ip_validate $2
    cidr_disable $2
    turkey_ip $2
    remove_prefix $2
    timeout -s 9 10m rustscan -b 600 -a $cln &
    my_wait_err
  elif [[ $3 == ENABLE ]]; then
    not_scan_me $4
    ip_validate $4
    cidr_disable $4
    turkey_ip $4
    remove_prefix $4
    timeout -s 9 20m rustscan -b 600 -a $cln -- -A -sC -sV -T4 &
    my_wait_err
  fi
elif [[ $1 == traceroute ]]; then
  not_scan_me $2
  ip_validate $2
  banner
  timeout 5m traceroute $2
elif [[ $1 == hostlinux ]]; then
  not_scan_me $2
  only_domains $2
  banner
  timeout 1m host $2
elif [[ $1 == whois ]]; then
  not_scan_me $2
  ip_validate $2
  banner
  timeout 1m whois $2
elif [[ $1 == cidr ]]; then
  not_scan_me $2
  cidr_check $2
  banner
  timeout 1m sipcalc -a $2
elif [[ $1 == wapiti ]]; then
  not_scan_me $2
  timeout -s 9 1h wapiti -u $2 &
  my_wait_err
elif [[ $1 == asnn ]]; then
  args=("$@")

  for arg in "${args[@]}"; do
    [[ "${arg}" == "-s" ]] && { shodan=1; break; }
  done

  for arg in "${args[@]}"; do
    [[ -n "${cidr}" ]] && break
    while read -r code; do
      if [[ "${arg}" == "${code}" ]]; then
        cidr="${code}" && break
      fi
    done < "$HOME/helper-scripts/cidr.file"
  done

  if [[ -n "${shodan}" && -n "${cidr}" ]]; then
    echo "Error, you cannot use Shodan Scan and CIDR Mapping at the same time!" | cowsay | lolcat -f -t
  elif [[ -n "${shodan}" ]]; then
    not_scan_me "${@: -1}"
    ip_validate "${@: -1}"
    cidr_disable "${@: -1}"
    banner
    timeout -s 9 5m asn -s "${@: -1}" &
    my_wait_err
  elif [[ -n "${cidr}" ]]; then
    banner
    timeout -s 9 5m asn -c ."${cidr,,}" &
    my_wait_err
  else
    not_scan_me "${@: -1}"
    ip_validate "${@: -1}"
    cidr_disable "${@: -1}"
    banner
    timeout -s 9 5m asn -n "${@: -1}" &
    my_wait_err
  fi
elif [[ $1 == xsstrike ]]; then
    not_scan_me $2
    banner
    add_prefix $2
    timeout -s 9 20m python xsstrike.py -u $furl -t 1 --crawl --blind -l 3 --skip --proxy
fi
