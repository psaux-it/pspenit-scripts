#!/bin/bash
#############################################################################
# Single jar, maven build,deploy jvm control helper script.
# For multiple jar files you need some extra loops but this is the basic idea.
#############################################################################

# app info
prog_name="JVM Tools | PSAUXIT.COM"
script_name="$0"

# prod path | app name
app_name="psauxit.jar"
prod_path="$HOME/psauxitwebtools"
preprod_path="$HOME/webnettools"

# my jar is exist
find_prod_app () {
  prod_app=`find "${prod_path:?}/" -name \*"${app_name}" -print0 | tr -d '\0' 2>/dev/null`
}

# Set color
setup_terminal () {
  green="$(tput setaf 2)"; red="$(tput setaf 1)"; reset="$(tput sgr 0)"
  cyan="$(tput setaf 6)"; magenta="$(tput setaf 5)"
  TPUT_BOLD="$(tput bold)"; TPUT_BGRED="$(tput setab 1)"
  TPUT_WHITE="$(tput setaf 7)";
}
setup_terminal

# wait for process exit code
my_wait () {
  local my_pid=$!
  local result
  # Force kill bg process if script exits
  trap "kill -9 $my_pid 2>/dev/null" EXIT
  # Wait stylish while process is alive
  spin='-\|/'
  mi=0
  while kill -0 $my_pid 2>/dev/null # (ps | grep $my_pid) is alternative
  do
    mi=$(( (mi+1) %4 ))
    printf "\r${m_tab}${green}[ ${spin:$mi:1} ]${magenta} ${1}${reset}"
    sleep .1
  done
  # Get bg process exit code
  wait $my_pid
  [[ $? -eq 0 ]] && result=ok
  # Need for tput cuu1
  echo ""
  # Reset trap to normal exit
  trap - EXIT
  # Return status of function according to bg process status
  [[ "${result}" ]] && return 0
  return 1
}

fatal () {
  printf >&2 "\n${m_tab}%s ABORTED %s %s \n\n" "${TPUT_BGRED}${TPUT_WHITE}${TPUT_BOLD}" "${reset}" "${*}"
  exit 1
}

replace_suc () {
  tput cuu 1
  echo "${m_tab}${TPUT_BOLD}${green}[ ✓ ] ${cyan}${1}${reset}"
}

replace_fail () {
  tput cuu 1
  echo "${m_tab}${TPUT_BOLD}${red}[ x ] ${cyan}${1}${reset}"
}

# deployment process
deploy () {
  local preprod_app=`find "${preprod_path:?}/" -name \*-runner.jar -print0 | tr -d '\0' 2>/dev/null`

  # check this is a clean deploy
  if [[ -d "${prod_path:?}" ]]; then
     find_prod_app
     [[ $prod_app ]] && clean=0 || clean=1
  else
    clean=1
  fi

  # Start deployment
  if [[ -d "${preprod_path:?}" ]]; then
    if [[ $preprod_app ]]; then
      if [[ "${clean}" -eq 0 ]]; then
        if [[ "$(md5sum "${preprod_app}" | awk '{print $1}')" != "$(md5sum "${prod_app}" | awk '{print $1}')" ]]; then
          { rm -rf "${prod_path:?}"; mkdir -p "${prod_path}"/lib; cp "${preprod_app}" "${prod_path}"/"${prod_app##*/}"; cp -r "${preprod_path}"/target/lib/* "${prod_path}"/lib/; } >/dev/null 2>&1
        else
          echo "Application up to date. Deployment skipped!"
          return 1
        fi
      else
        { mkdir -p "${prod_path}"/lib; cp "${preprod_app}" "${prod_path}"/"${app_name}"; cp -r "${preprod_path}"/target/lib/* "${prod_path}"/lib/; find_prod_app; } >/dev/null 2>&1
      fi
    else
      echo "Cannot start deployment process, deployment jar cannot found!"
      return 1
    fi
  else
    echo "Cannot start deployment process, preprod path not found!"
    return 1
  fi
  return 0
}

# Build jar via maven
mvn_build () {
  if [[ -d "${preprod_path:?}" ]]; then
    cd "${preprod_path}"
    echo ""
    mvn clean &>/dev/null &
    my_wait "Removing old.." && replace_suc "Completed successfully!" || { replace_fail "Failed"; fatal "QUIT"; }
    mvn package &>/dev/null &
    my_wait "Building application.." && replace_suc "Completed successfully! Ready to deployment!" || { replace_fail "Failed!"; fatal "QUIT"; }
    echo ""
  else
    fatal "Preprod path not exist!"
  fi
}


# Application global vars
global_vars () {
  PORT=8080
  export PATH=/home/black/.asn:/home/black/Asn:/home/black/testssl.sh:/home/black/helper-scripts:/home/black/.gem/ruby/2.7.0/bin:/home/black/amass_linux_amd64:/home/black/virtualenv/wapiti:/home/black/virtualenv/wapiti/XSStrike:/home/black/RustScan/target/release:$PATH
  export AVAILABLE_TOOLS=testssl,ping,dig,dnsrecon,wpscan,ddec,amass,whois,host,rustscan,cidr,mtr,wapiti,asn,xsstrike
  export RATE_LIMIT=60000
  export CA_DIR=/home/black/certs
  export PORT=8080
  export JAVA_OPTIONS="-Dquarkus.http.host=127.0.0.1 -Djava.util.logging.manager=org.jboss.logmanager.LogManager -Dquarkus.http.port=${PORT}"
  export INTRO_TEXT='<div class="accept"><p class="accept-p"><span style="font-size:14px">By using this free service, I accept the <a href="https://tools.psauxit.com/page/terms-and-conditions" onclick="window.open(this.href, ">Terms And Conditions</a> and <a href="https://tools.psauxit.com/page/privacy-policy" onclick="window.open(this.href, ">Privacy Policy</a> of this website (<a href="https://www.psauxit.com/" onclick="window.open( this.href, "><span style="color:#e74c3c"><em>psauxit.com</em></span></a> ).&nbsp;I declare that <strong>I will only scan my own network and domain names I own</strong> for vulnerability testing purposes.</span></p></div>'
  export http_proxy="http://hsntgm:%23%23Ii0210154%24%24@10.0.0.3:3128"
}

# Test application is working after (re)start in background for 5 sec
# To:do add 'try loop' if not suc after 5 sec
nohup_java () {
  startwait=5
  pid=$!
  for i in $(seq $startwait); do
    if ! kill -0 $pid 2>/dev/null; then
      wait $!
      exitcode=$?
      echo "Application cannot (re)started, EXITCODE:$exitcode" >&2
      break
    fi
    sleep 1
  done
  if kill -0 $pid; then
    echo "Application (re)started successfully!"
  fi
}

# run in background
my_run () {
  nohup java -jar "${prod_app}" >/dev/null 2>&1 &
}

# run in foreground
my_run_f () {
  java -jar "${prod_app}"
}

# stop jvm
stop_jvm () {
  if kill -9 $(ps aux | grep -v grep | grep "${app_name}" | awk '{print $2}') >/dev/null 2>&1; then
    echo "Application stopped!"
  else
    echo "Application already stopped!"
  fi
}

# Activate python virtual env
venv_ () {
  cd "$HOME/virtualenv/wapiti" || echo "Python venv path cannot found. Wapiti is disabled."
  . ./bin/activate || echo "Python venv cannot activate. Wapiti is disabled."
}


# start jvm with python venv
start_jvm () {
  if ! ps aux | grep -v grep | grep "${app_name}" >/dev/null 2>&1; then
    find_prod_app
    [[ $prod_app ]] && { venv_; global_vars; my_run; nohup_java; } || echo "App not found. Cannot start application!"
  else
    echo "Application already running!"
  fi
}

# start {python wapiti virtual env,application} on reboot
boot () {
  start_jvm
}

# restart jvm
restart_jvm () {
  stop_jvm
  start_jvm
}

# carry process to foreground
run_foreground () {
  stop_jvm
  find_prod_app
  [[ $prod_app ]] && { global_vars; my_run_f; } || echo "App not found. Cannot start application!"
}

help () {
  echo -e "\n${m_tab}${cyan}# Script Help"
  echo -e "${m_tab}# --------------------------------------------------------"
  echo -e "${m_tab}#${m_tab}--start              start jvm"
  echo -e "${m_tab}#${m_tab}--stop               stop jvm"
  echo -e "${m_tab}#${m_tab}--restart            restart jvm"
  echo -e "${m_tab}#${m_tab}--foreground         start jvm on foreground"
  echo -e "${m_tab}#${m_tab}--deploy             start deployment"
  echo -e "${m_tab}#${m_tab}--build              build app"
  echo -e "${m_tab}#${m_tab}--build-deploy       build app and start deploy"
  echo -e "${m_tab}#${m_tab}--venv               activate python virtual env"
  echo -e "${m_tab}#${m_tab}--boot               start jvm on boot"
  echo -e "${m_tab}#${m_tab}--help               display help"
  echo -e "${m_tab}# ---------------------------------------------------------${reset}\n"
}

deployment () {
  if deploy; then
    # Restart application
    [[ $clean -eq 0 ]] && echo "New application version found, deployment completed successfully" || echo "Clean deployment completed successfully"
    echo "Trying to (re)start application..."
    restart_jvm
  elif ! ps aux | grep -v grep | grep "${prod_app##*/}" >/dev/null 2>&1; then
    echo "Application is not working currently.."
    echo "Trying to start application..."
    start_jvm
  else
    echo "Application is running."
  fi
}

# Build app and deploy it immediately
build_deploy () {
  mvn_build
  deployment
}

inv_opt () {
  printf "%s\\n" "${red}${prog_name}: Invalid option '$1'${reset}"
  printf "%s\\n" "${cyan}Try '${script_name} --help' for more information.${reset}"
  exit 1
}

# Script management
main () {
  if [[ "$#" -eq 0 || "$#" -gt 1 ]]; then
    printf "%s\\n" "${red}${prog_name}: Argument required or too many argument${reset}"
    printf "%s\\n" "${cyan}Try '${script_name} --help' for more information.${reset}"
    exit 1
  fi

  # set script arguments
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -s  | --start        ) start_jvm      ;;
      -t  | --stop         ) stop_jvm       ;;
      -r  | --restart      ) restart_jvm    ;;
      -f  | --foreground   ) run_foreground ;;
      -d  | --deploy       ) deployment     ;;
      -c  | --build        ) mvn_build      ;;
      -cd | --build-deploy ) build_deploy   ;;
      -v  | --venv         ) venv_           ;;
      -b  | --boot         ) boot           ;;
      -h  | --help         ) help           ;;
      --  | -* | *         ) inv_opt        ;;
    esac
    break
  done
}

# Call main
main "${@}"