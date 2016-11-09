COUNT=58
for i in $(cat ilo.csv)
do
    NAME=`echo $i | cut -d',' -f1`
    IP=`echo $i | cut -d',' -f2`
    TYPE=`echo $i | cut -d',' -f3`

    case "$TYPE" in
      cinder)
            SEED='ubuntu-14.04.3-server-unattended-osic-cinder'
            ;;
        swift)
            SEED='ubuntu-14.04.3-server-unattended-osic-swift'
            ;;
        *)
        SEED='ubuntu-14.04.3-server-unattended-osic-generic'
            ;;
    esac
    MAC=`sshpass -p cobbler ssh -o StrictHostKeyChecking=no root@$IP ifconfig -a bon0 | awk 'BEGIN{ FS="HWaddr "}{print$2}' | tr -d " \t\n\r"`
    #hostname,mac-address,host-ip,host-netmask,host-gateway,dns,pxe-interface,cobbler-profile,ironic-ipv4
    echo "$NAME,${MAC//[$'\t\r\n ']},172.22.0.$COUNT,255.255.252.0,172.22.0.1,8.8.8.8,p2p1,$SEED,$IP" | tee -a input.csv
    (( COUNT++ ))
done
