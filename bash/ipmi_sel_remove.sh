#!/bin/sh

# Clear the system event log on the BMC when it is more than 80% full.
# https://gist.github.com/ixs/8c74e171242625fc043d
THRESH=80
IPMITOOL_CMD=`which ipmitool`
IPMISEL_CMD=`which ipmi-sel`
SEL_STATE=$($IPMITOOL_CMD sel info 2> /dev/null)


if [ $? -ne 0 ]; then
  yum install -y freeipmi
  $IPMISEL_CMD --clear
  $IPMISEL_CMD
  exit 0
fi

SEL_GAUGE=$(echo "$SEL_STATE" | awk '/Percent Used/ { printf "%d\n", $4 }')

# ipmi sel 80% 이상일 시 sel clear
echo "Check IPMI PCT Used..."
if [ $SEL_GAUGE -ge $THRESH ]; then
  /usr/bin/ipmitool sel clear > /dev/null
  echo "IPMI System Event Log at ${SEL_GAUGE}% capacity. Cleared..."
  else
    echo "IPMI SEL Pct Used: ${SEL_GAUGE}% ...OK"
fi

# Set the date of the local SEL clock once per 24h
SEL_TIME=$(date -d "$(ipmitool sel time get)" +%s)
SYS_TIME=$(date +%s)

# system 시간조정: UTC 기준 1초보다 차이 클 시 ntp_sync.sh 실행
echo "Check IPMI Time..."
if [ $SEL_TIME -gt $SYS_TIME ]; then
  	DIFF=$((SEL_TIME - SYS_TIME));
  else
  	DIFF=$((SYS_TIME - SEL_TIME));
fi
if [ $DIFF -gt 32000 ]; then
DIFF=$((DIFF - 32400))
fi
if [ $DIFF -gt 1 ]; then
    	/usr/bin/ipmitool sel time set "$(date +"%m/%d/%Y %H:%M:%S")" > /dev/null;
    	echo "IPMI TIME DIFF ${DIFF}s ...Corrected";
  else
    	echo "IPMI TIME DIFF ${DIFF}s ...OK";
fi
