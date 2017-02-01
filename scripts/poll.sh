set -f
IFS='
'
set -- $( cat ../playbooks/hosts | awk 'BEGIN{FS="ansible_ssh_host_ironic"}{print $2}' | cut -d "=" -f2 | head -n -1 )
for i in `cat ../playbooks/hosts | awk /ansible_ssh_host/ | cut -d'=' -f2 | cut -d ' ' -f1`
do
  if ping -c 1 $1 &> /dev/null
  then
      echo "Available"
  else
      echo "Still Rebooting..."
  fi
  printf "%s %s\n" "$i" "$1"
  shift
done
