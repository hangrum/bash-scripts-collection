#!/bin/bash
#/etc/update-motd.d chmod -x : system motd disable
if [ -d /etc/update-motd.d ];then
  chmod -x /etc/update-motd.d/*
  for i in $(ls /etc/update-motd.d);do
    stat /etc/update-motd.d/$i|grep ".* Uid.*"|grep "x" 1>/dev/null
    if [ "$?" == 1 ];then
      echo "Disable System motd [OK]: /etc/update-motd.d/$i"
    else
      echo "Disable System motd [failed]: please check remain excutable file on /etc/update-motd.d"
    fi
    done
else
  echo "/etc/update-motd.d doesn't exsist. [skip]"
fi

#/etc/default/motd-news: disable motd-news
if [ -f /etc/default/motd-news ];then
  sed -i 's/^ENABLE.*/ENABLE=0/g' /etc/default/motd-news
  grep "ENABLE=1" /etc/default/motd-news
  if [ "$?" == 0 ];then
    echo "Disable motd-news [OK]"
  else
    echo "Disable motd-news [failed]"
  fi
else
  echo "/etc/default/motd-news doesn't exsist. [skip]"
fi

#/etc/motd: remove "Last ansible run: 2022-09-28 ..."
if [ -f /etc/motd ];then
  sed -i '/^Last ansible.*/d' /etc/motd
  grep "Last ansible" /etc/motd
  if [ "$?" == 1 ];then
    echo "remove Last ansible run on motd [OK]"
  else
    echo "remove Last ansible run on motd [failed]: please check /etc/motd"
  fi
fi
#remove os info on /etc/issue & issue.net
cat /dev/null > /etc/issue
cat /dev/null > /etc/issue.net
if [ ! -s /etc/issue ] && [ ! -s /etc/issue.net ];then
    echo "/etc/issue and /etc/issue.net is empty [OK]"
else
    echo "/etc/issue and /etc/issue.net is not empty [failed]"
fi

#/etc/ssh/sshd_config: disable Last login & motd by os
if [ -f /etc/ssh/sshd_config ];then
  sed -i 's/^#*PrintLastLog.*/PrintLastLog no/g' /etc/ssh/sshd_config
  sed -i 's/^#*PrintMotd.*/PrintMotd yes/g' /etc/ssh/sshd_config
  if [ -f /etc/os-release ];then
    grep CentOS /etc/os-release 1>/dev/null
  else
    grep CentOS /etc/system-release 1>/dev/null
  fi
  if [ "$?" == 0 ];then
    sed -i 's/^#*PrintMotd.*/PrintMotd yes/g' /etc/ssh/sshd_config
  else
    sed -i 's/^#*PrintMotd.*/PrintMotd no/g' /etc/ssh/sshd_config
  fi
fi

grep "^Print.*" /etc/ssh/sshd_config
echo "Config Complete: restart sshd"
  if [ -f /etc/os-release ];then
    grep CentOS /etc/os-release 1>/dev/null
  else
    grep CentOS /etc/system-release 1>/dev/null
  fi

if which systemctl 1> /dev/null;then
  systemctl restart sshd
fi
if [ -f /etc/init.d/ssh ];then
    /etc/init.d/ssh restart
fi
if [ -f /etc/init.d/sshd ];then
    /etc/init.d/sshd restart
fi
