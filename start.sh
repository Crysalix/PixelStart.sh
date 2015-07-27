#!/bin/bash

#Colors
ok="[\e[0;32m OK \e[0;39m]"
warn="[\e[1;33mWARN\e[0;39m]"
fail="[\e[0;31mFAIL\e[0;39m]"
info="[\e[0;36mINFO\e[0;39m]"
warning="\e[0;31mWARNING!\e[0;39m"
threedot="[\e[....]"

#Settings
mcscreen='mcserver'
service='spigot.jar'
path=$(pwd)
MMIN='1G'
MMAX='4G'

function mc_start(){
    if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
        then
        echo -e "$warn $service is running !"
    else
        echo -e "$info Starting $service..."
        bash -c "screen -dmS $mcscreen java -Xms$MMIN -Xmx$MMAX -jar $path/$service nogui"
        sleep 15
        if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
        then
            echo -e "$ok $service started !"
        else
            echo -e "$fail Can't start $service !"
        fi
    fi
}

function mc_stop(){
    if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
    then
        echo -e "$info Shutting down $service"
        bash -c "screen -p 0 -S $mcscreen -X eval 'stuff \"save-all\"\015'"
        sleep 1
        bash -c "screen -p 0 -S $mcscreen -X eval 'stuff \"stop\"\015'"
        sleep 10
        if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
        then
            echo -e "$fail $service is runing !"
        else
            echo -e "$ok stopped $service !"
        fi
    else
        echo -e "$warn $service is not running !"
    fi
}

case $1 in
    start)
        mc_start;;
    stop)
        mc_stop;;
    *)
        echo -e "Usage: $0 {start|stop}"
        exit 1;;
esac

exit 0
