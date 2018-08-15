# Report SSL Certificate Expiration info
set -e

DATE_FORMAT="%d/%b/%Y:%H:%M:%S %z"
HOST="${1}"
PORT=${2:-443}
IP="${HOST}"


function ssl_expire_date() {
  expire_date="$(openssl s_client -servername "${1}" -connect "${1}":"${2}" 2>&- | openssl x509 -enddate -noout 2>/dev/null | sed 's/^notAfter=//g')"
  if [ -z "${expire_date}" ]
    then
      echo "[$(date +"${DATE_FORMAT}")] ERROR ${HOST} ${PORT}" >&2
      exit 1
    else
      echo ${expire_date}
  fi
}

function days_until_expire() {
  ssl_expire_date="$@"

  expire_in_seconds=$(date -d "${ssl_expire_date}" +%s)
  now_in_seconds=$(date +%s)

  seconds_to_expire=$((${expire_in_seconds}-${now_in_seconds}))

  echo $(seconds_to_days ${seconds_to_expire})
}

function seconds_to_days() {
  seconds="${1}"
  echo $((${seconds}/60/60/24))
}


if [ -z "${1}" ]
  then
    echo "  
  Hostname is required.

  Basic Usage:

    check_cert.sh www.labcorp.com 443
    "
    exit 1
fi

EXPIRE_DATE="$(ssl_expire_date ${HOST} ${PORT})"
DAYS_TO_EXPIRE="$(days_until_expire ${EXPIRE_DATE})"

echo "[$(date +"${DATE_FORMAT}")] OK ${HOST} ${PORT} [$(date -d "${EXPIRE_DATE}" +"${DATE_FORMAT}")] ${DAYS_TO_EXPIRE}"

exit 0