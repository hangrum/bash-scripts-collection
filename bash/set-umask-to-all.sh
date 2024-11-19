#!/bin/bash
UMASK_NUMBER=022
# fine all user's home directory and apply umask on bashrc
find /home -name '.bashrc' -print0|while IFS= read -r -d '' i; do
  grep umask "$i" 1>/dev/null || echo "umask $UMASK_NUMBER" >> "$i"
done
grep "^umask 022" /etc/profile
if [ $? != 0 ];then
  echo "umask 022" >> /etc/profile
fi
grep "^export umask" /etc/profile
if [ $? != 0 ];then
  echo "export umask" >> /etc/profile
fi

# apply umask 022 globally on profile script 
>/etc/profile.d/set-umask.sh cat << EOF
umask $UMASK_NUMBER
export umask
EOF
