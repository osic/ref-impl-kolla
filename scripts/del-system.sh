for i in `cobbler system list`; do
    cobbler system remove --name $i
done
