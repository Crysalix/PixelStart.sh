#!/bin/bash

#Colors
ok="[\e[0;32m OK \e[0;39m]"
warn="[\e[1;33mWARN\e[0;39m]"
fail="[\e[0;31mFAIL\e[0;39m]"
info="[\e[0;36mINFO\e[0;39m]"
warning="\e[0;31mWARNING!\e[0;39m"
threedot="[....]"

#Settings
mcscreen='mcserver'
service='spigot-1.8.8.jar'
path=$(pwd)
MMIN='1G'
MMAX='4G'

#Functions
function root_check(){
    if [ $(whoami) = "root" ]; then
        for ((r=0 ; r<5 ; r++))
            do
                echo -e "$warning Run Minecraft Server as root is not recommended !"
                sleep 0.5
        done
        read -p "Do you want to continue [y/N]? " yn
        yn=$(echo $yn | awk '{print tolower($0)}')
        if [ -z $yn ] || [ $yn != "y" ]; then
            echo Abort.
            exit 1
        fi
    fi
}

function mc_start(){
    root_check
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

function mc_startmc(){
    echo -e "$info Starting $service..."
    bash -c "screen -dmS $mcscreen java -Xms$MMIN -Xmx$MMAX -jar $path/$service nogui"
    if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
    then
        echo -e "$ok $service started !"
    else
        echo -e "$fail Can't start $service !"
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

function mc_restart(){
    if [ -z $who ] || [ $who != "mc" ]; then
        mc_stop
        mc_start
    elif [ $who = "mc" ]; then
        echo "Restart Server !" >> log.txt
        mc_startmc
    fi
}

case $1 in
    start)
        mc_start;;
    stop)
        mc_stop;;
    restart)
        who=$2
        mc_restart;;
    *)
        echo -e "Usage: $0 {start|stop|restart}"
        exit 1;;
esac

exit 0
