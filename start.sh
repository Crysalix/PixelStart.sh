#!/bin/bash

# ==================================
# Pixeltools by Crysalix
# ==================================
# Minecraft Launcher
mclauncherv="16032001"

#Colors
ok="[\e[0;32m OK \e[0;39m]"
warn="[\e[1;33mWARN\e[0;39m]"
fail="[\e[0;31mFAIL\e[0;39m]"
info="[\e[0;36mINFO\e[0;39m]"
warning="\e[0;31mWARNING!\e[0;39m"
threedot="[....]"

# ==================================
# Update Check
# ==================================

if [ -f updater.sh ];then
    rm updater.sh
else
    echo -e "$info Checking for start.sh update..."
    currentmclauncherv=$(curl -fs http://dev.pixe-life.org/pixeltools/files/v/mclauncherversion)
    if [ $currentmclauncherv -gt $mclauncherv ]; then
	echo -e "$ok Version $currentmclauncherv found !"
        wget -O updater.sh http://dev.pixe-life.org/pixeltools/files/updater/start.sh >/dev/null 2>&1
        bash updater.sh $0 $*&&exit 0
    elif [ $currentmclauncherv -le $mclauncherv ]; then
	echo -e "$ok No update found !"
    else
	echo -e "$fail Can't connect to server !"
    fi
fi

# ==================================
# Load Settings
# ==================================

if [ -f start.sh.conf ];then
    source start.sh.conf
else
    echo 'rootdir=$(pwd)' > start.sh.conf
    echo "mcscreen='mcserver'" >> start.sh.conf
    echo "service='spigot.jar'" >> start.sh.conf
    echo "MMIN='1G'" >> start.sh.conf
    echo "MMAX='3G'" >> start.sh.conf
fi

source start.sh.conf

# ==================================
# Functions
# ==================================

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

function mc_check(){
if [ ! -f "$pwd/$service" ];then
    echo -e "$fail $service is missing !";
    exit 1
fi
}

function mc_status(){
    if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
    then
        echo -e "$ok $service is running !"
    else
        echo -e "$warn $service is not running !"
    fi
}

function mc_start(){
    if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
        then
        echo -e "$warn $service is running !"
    else
        echo -e "$info Starting $service..."
        screen -dmSU $mcscreen java -Xms$MMIN -Xmx$MMAX -jar $rootdir/$service nogui
        sleep 10
        if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
        then
            echo -e "$ok $service started !"
        else
            echo -e "$fail Can't start $service !"
        fi
    fi
}

function mc_startmc(){
    screen -dmSU $mcscreen java -Xms$MMIN -Xmx$MMAX -jar $rootdir/$service nogui
    if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
    then
        echo -e "$ok $service started !"
    else
        echo -e "$fail Can't start $service !"
    fi
}

function mc_stop(){
    echo -n "[....] Sending save-all & stop command."
    failstatus=0
    if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
    then
        screen -p 0 -S $mcscreen -X eval 'stuff \015save-all\015' > /dev/null
        sleep 1
        screen -p 0 -S $mcscreen -X eval 'stuff \015stop\015' > /dev/null
        status=0
        until [ $status = 15 ] || [ $status = 20 ]
        do
            if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
            then
                echo -n "."
                sleep 1
                ((status++))
            else
                status=20
            fi
        done
        if [ $status = 15 ]
        then
            echo -e -n "\n$fail Checking Timeout after 15 sec for $mcscreen server."
            failstatus=1
        elif [ $status = 20 ]
        then
            echo -e -n "\n$ok Stoped $mcscreen server."
        fi
    else
        echo -e -n "\n$warn Server $mcscreen is not running !"
    fi
    if [ $failstatus = 0 ]
    then
        echo -e "\n$ok Done !"
    elif [ $failstatus = 1 ]
    then
        echo -e "\n$fail Error when stoping server"
        read -p "Do you want to force QUIT command [y/N]? " -t 10 yn
        yn=$(echo $yn | awk '{print tolower($0)}')
        if [ $yn = "y" ]; then
            mc_forcestop
        fi
    fi
}

function mc_forcestop(){
    echo -n "$threedot Sending KILL command."
    if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
    then
        screen -S $mcscreen -X quit > /dev/null
        status=0
        until [ $status = 10 ] || [ $status = 15 ]
        do
            if ps ax | grep -v grep | grep -i SCREEN | grep $mcscreen > /dev/null
            then
                echo -n "."
                sleep 1
                ((status++))
            else
                status=15
            fi
        done
        if [ $status = 10 ]
        then
            echo -e -n "\n$fail Checking Timeout after 10 sec for $mcscreen server."
        elif [ $status = 15 ]
        then
            echo -e -n "\n$ok Killed server $mcscreen."
        fi
    else
        echo -e -n "\n$info Server $mcscreen already stopped."
    fi
    echo -e "\n$ok Done !"
}

function mc_restart(){
    if [ -z $who ] || [ $who != "mc" ]; then
        mc_stop
        sleep 1
        mc_start
    elif [ $who = "mc" ]; then
        mc_startmc
    fi
}

function mc_log(){
    echo -e "$warn Ctrl + C = quit"
    sleep 1
    cd $rootdir/logs
    tail -f latest.log
}

root_check
mc_check

case $1 in
    start)
        mc_start;;
    stop)
        mc_stop;;
    restart)
        who=$2
        mc_restart;;
    log)
        mc_log;;
    status)
        mc_status;;
    *)
        echo -e "Usage: $0 {start|stop|restart|log|status}"
        exit 1;;
esac

exit 0
