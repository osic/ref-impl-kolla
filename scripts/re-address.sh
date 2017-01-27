set -f
IFS='
'
set -- $( cat hosts | awk 'BEGIN{FS="ansible_ssh_host_ironic"}{print $2}' | cut -d "=" -f2 | head -n -1 )
for i in `cat hosts | awk /ansible_ssh_host/ | cut -d'=' -f2 | cut -d ' ' -f1`
do
  /usr/bin/ssh-keyscan $1 >> ~/.ssh/known_hosts
  sshpass -p cobbler ssh root@$1 ip addr add $i/22 dev bond0
  printf "%s %s\n" "$i" "$1"
  shift
done
