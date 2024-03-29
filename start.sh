#!/bin/bash

# ==================================
# Minecraft Launcher
# ==================================
# mclauncherv="18112001"

#Colors
ok="[\e[1;32m OK \e[0;39m]"
info="[\e[1;36mINFO\e[0;39m]"
warn="[\e[1;33mWARN\e[0;39m]"
fail="[\e[1;31mFAIL\e[0;39m]"
warning="\e[1;31mWARNING!\e[0;39m"
#Other settings...
rootdir=$(dirname $(readlink -f $0))
logfile='.start.log'

# ==================================
# Main Function
# ==================================

pt_log(){
    currDate="$(date +%H:%M:%S' '%d/%m/%y)"
    case $2 in
        ok)
            echo -e "[$currDate] $ok $1"
            echo -e "[$currDate] [ OK ] $1" >> $rootdir/$logfile;;
        info)
            echo -e "[$currDate] $info $1"
            echo -e "[$currDate] [INFO] $1" >> $rootdir/$logfile;;
        warn)
            echo -e "[$currDate] $warn $1"
            echo -e "[$currDate] [WARN] $1" >> $rootdir/$logfile;;
        fail)
            echo -e "[$currDate] $fail $1"
            echo -e "[$currDate] [FAIL] $1" >> $rootdir/$logfile;;
        *)
            echo -e "[$currDate] [....] $1"
            echo -e "[$currDate] [....] $1" >> $rootdir/$logfile;;
    esac
}

getDate(){
	echo $(date +%H:%M:%S' '%d/%m/%y)
}

root_check(){
    if [ $(whoami) = "root" ];then
        for ((r=0 ; r<5 ; r++));do
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

# ==================================
# Load Settings
# ==================================

if [ ! -f $rootdir/restart.sh ];then
    echo -e "[$(getDate)] $info Creating restart.sh file."
    echo -e "#!/bin/bash" > $rootdir/restart.sh
    echo -e "nohup bash start.sh restart fromserver >/dev/null 2>&1 &" >> $rootdir/restart.sh
    chmod 740 $rootdir/restart.sh
fi

mc_conf(){
    echo "screen='$screen'" > $rootdir/.start.conf
    echo "serverfile='$serverfile'" >> $rootdir/.start.conf
    echo "MMIN='$MMIN'" >> $rootdir/.start.conf
    echo "MMAX='$MMAX'" >> $rootdir/.start.conf
    echo "#Using this with crontab, you can allow or deny sending \"save-all\" command to console. Usefull when running backups." >> $rootdir/.start.conf
    echo "saves='$saves'" >> $rootdir/.start.conf
    echo "#Watchdog : if true, script will attempt to start server when './start.sh wdcheck' get it offline." >> $rootdir/.start.conf
    echo "#Must be run with crontab ( */5 * * * * bash $rootdir/start.sh wdcheck ) for check every 5 minutes." >> $rootdir/.start.conf
    echo "watchDog='$watchDog'" >> $rootdir/.start.conf
    echo "#Don't edit the last two line." >> $rootdir/.start.conf
    echo "lastSHA='$lastSHA'" >> $rootdir/.start.conf
    echo "lastCheck='$lastCheck'" >> $rootdir/.start.conf
}

if [ -f $rootdir/.start.conf ];then
    source $rootdir/.start.conf
else
    screen='mcserver'
    serverfile='spigot.jar'
    MMIN='1G'
    MMAX='3G'
    saves='true'
    watchDog='false'
    lastSHA='abcdefghijklmnopqrstuvwxyz'
    lastCheck='0000000000'
    mc_conf
    pt_log 'Default configuration file created.' 'info'
    echo -e "[$(getDate)] $warn Edit new config file if required."
    exit 0
fi

# ==================================
# Update Check
# ==================================

currCheck=$(($lastCheck+3600))
if [ 0$(date +"%s") -gt 0$currCheck ];then
    currentmclauncherv=$(curl -fs https://api.github.com/repos/Crysalix/PixelStart.sh/commits/master | grep sha | head -1 | cut --delimiter=\" -f 4)
    echo -e "[$(getDate)] $info Checking for start.sh update..."
    if [ "$currentmclauncherv" != "$lastSHA" ]; then
        lastCheck=$(date +"%s")
        lastSHA=$currentmclauncherv
        mc_conf
        echo -e "[$(getDate)] $ok New version found !"
        wget -O $rootdir/start.sh https://raw.githubusercontent.com/Crysalix/PixelStart.sh/master/start.sh >/dev/null 2>&1
        bash $rootdir/start.sh $0 $*&&exit 0
    else
        echo -e "[$(getDate)] $ok No update found."
    fi
    lastCheck=$(date +"%s")
    mc_conf
fi

# ==================================
# Vars
# ==================================

# Get server port
if [ -f $rootdir/server.properties ];then
    serverPort=$(grep server-port $rootdir/server.properties | cut -d= -f2)
else
    pt_log "Can't find server.properties file. First time server started ?" 'warn'
    checkServerPort=25565
    while [ $checkServerPort -lt 25665 ];do
        pt_log "Trying port $checkServerPort"
        if [ "$(lsof -i:$checkServerPort -t)" ];then
            pt_log "Port is used !" 'warn'
            ((checkServerPort++))
        else
            serverPort=$checkServerPort
            pt_log "Using port $serverPort" 'ok'
            break
        fi
    done
fi

# Get late-bind option for delaying timeout or not.
if [ -f $rootdir/spigot.yml ] && [ "$(grep late-bind $rootdir/spigot.yml | grep true)" ];then
    timeout=60
else
    timeout=30
fi

# ==================================
# Minecraft Functions
# ==================================

mc_start(){
    pt_log 'Init server start.'
    if [ $(mc_check) = 8 ] || [ $(mc_check) = 9 ];then
        echo -en "[$(getDate)] [....] Starting server (timeout set at $timeout sec)"
        cd $rootdir
        screen -dmSU $screen java -Xms$MMIN -Xmx$MMAX -jar $rootdir/$serverfile --log-strip-color nogui
        count=0
        until [ $count -gt $timeout ];do
            if [ -z "$(lsof -i:$serverPort -t)" ];then
                echo -n "."
                sleep 1
                ((count++))
            else
                count=999
            fi
        done
        if [ $count = 999 ];then
            echo -e "Done"
            lsof -i:$serverPort -t > $rootdir/.start.pid
            pt_log "Server started with PID : $(cat .start.pid)" 'info'
            wd_on
        else
            echo -e "."
            pt_log 'Server fail at boot ? Timeout after $timeout sec' 'warn'
            mc_status
            exit 1
        fi
    else
        pt_log 'Error when start the server !' 'fail'
        mc_status
        exit 1
    fi
}

mc_stop(){
    pt_log 'Init server stop.'
    wd_off
    if [ $(mc_check) -ge 14 ];then
        echo -en "[$(getDate)] [....] Sending save-all & stop command."
        screen -p 0 -S $screen -X stuff "save-all$(printf \\r)"
        sleep 1
        screen -p 0 -S $screen -X stuff "stop$(printf \\r)"
        count=0
        pid=$(cat $rootdir/.start.pid) # && || if file is missing
        until [ $count -gt 30 ];do
            if [ "$(ps $pid | grep -v PID)" ];then
                echo -n "."
                sleep 1
                ((count++))
            else
                count=999
            fi
        done
        if [ $count = 999 ];then
            echo -e "Done"
            pt_log 'Server stoped.' 'info'
            if [ -f $rootdir/.start.pid ];then
                rm $rootdir/.start.pid
            fi
        else
            echo -e "."
            pt_log 'Server fail when trying to stop it ? Timeout after 30 sec' 'warn'
            mc_status
            exit 1
        fi
    elif [ $(mc_check) -ge 12 ];then
        pt_log 'Server is already stoped, but screen is alive.' 'warn'
        echo -en "[$(getDate)] [....] Trying to kill the screen..."
        screen -X -S $screen kill
        sleep 1
        if ps ax | grep -v grep | grep -i SCREEN | grep $screen > /dev/null
            then
            echo -e " $fail Error !"
            echo -e "[$(getDate)] [....] Showing status..."
            sleep 1
            mc_status
        else
            echo -e " $ok Done."
        fi
    else
        pt_log 'Error when stop the server !' 'fail'
        mc_status
        exit 1
    fi
}

mc_restart(){
    status=0
    if [ $1 ] && [ $1 = 'fromserver' ];then
        pt_log 'Server restart requested from server... Waiting for server stop.'
        count=0
        pid=$(cat $rootdir/.start.pid)
        until [ $count -gt 30 ];do
            if [ "$(ps $pid | grep -v PID)" ];then
                echo -n "."
                sleep 1
                ((count++))
            else
                count=999
            fi
        done
        if [ $count = 999 ];then
            echo -e "Done"
            pt_log 'Server stoped.' 'info'
            if [ -f $rootdir/.start.pid ];then
                rm $rootdir/.start.pid
            fi
        else
            echo -e "."
            pt_log 'Server fail when trying to stop it ? Timeout after 30 sec' 'warn'
            mc_status
            exit 1
        fi
    else
        pt_log 'Server restart requested...'
        if [ $(mc_check) -ge 12 ];then
            mc_stop
        else
            pt_log 'But the server is not running !' 'warn'
            ((status++))
        fi
        sleep 1
    fi
    if [ $(mc_check) = 8 ] || [ $(mc_check) = 9 ];then
        mc_start
    else
        pt_log 'But the server is already running !' 'warn'
        ((status++))
    fi
    if [ $status = 2 ];then
        pt_log 'Hum... There is something wrong here !' 'fail'
        mc_status
        exit 1
    fi
}

mc_saveoff(){
    pt_log 'Trying to suspend saves.'
    if [ $(mc_check) -ge 14 ];then
        saves='false'
        mc_conf
        screen -p 0 -S $screen -X stuff "save-off$(printf \\r)"
        screen -p 0 -S $screen -X stuff "save-all$(printf \\r)"
        pt_log 'Suspending saves.' 'ok'
    else
        pt_log "Can't suspend saves, server is offline !" 'fail'
        mc_status
        exit 1
    fi
}

mc_saveon(){
    pt_log 'Trying to re-enabe saves.'
    if [ $(mc_check) -ge 14 ];then
        saves='true'
        mc_conf
        screen -p 0 -S $screen -X stuff "save-on$(printf \\r)"
        pt_log 'Re-enabling saves.' 'ok'
    else
        pt_log "Can't re-enabling saves, server is offline !" 'fail'
        mc_status
        exit 1
    fi
}

mc_status(){
    echo -e "[$(getDate)] [....] Showing status..."
    echo -e "[$(getDate)] $info Server location :    $rootdir"
    echo -ne "[$(getDate)] $info Server file :        $serverfile"
    if [ -f $rootdir/$serverfile ]; then
        echo -e " $ok Found it !"
    else
        echo -e " $warn Missing !"
    fi
    echo -ne "[$(getDate)] $info Server screen name : $screen"
    if ps ax | grep -v grep | grep -i SCREEN | grep $screen > /dev/null
    then
        echo -e " $ok Screen found !"
    else
        echo -e " $warn Screen not found !"
    fi
    echo -en "[$(getDate)] $info Server port :        $serverPort"
    if [ "$(lsof -i:$serverPort -t)" ];then
        echo -e " $ok Server is listen."
        status=0
    else
        echo -e " $warn No server is listen that port !"
        status=1
    fi
    echo -en "[$(getDate)] $info PID File :"
    if [ -f $rootdir/.start.pid ]; then
        pid=$(cat $rootdir/.start.pid)
        echo -e "           $pid $ok Found it !"
    else
        echo -e "           x $warn Missing !"
    fi
    echo -en "[$(getDate)] $info save-all input :"
    if [ $saves = 'true' ];then
        echo -e "     Allow command"
    else
        echo -e "     Deny command"
    fi
    echo -en "[$(getDate)] $info WatchDog status :"
    if [ $watchDog = 'true' ];then
        echo -e "    ON"
    else
        echo -e "    OFF"
    fi
    case $(mc_check) in
        0|1|2|3|4|5|6|7)
            echo -e "[$(getDate)] $warn \e[1;31mSERVER FILE IS MISSING !\e[0;39m";;
        8|9)
            echo -e "[$(getDate)] $warn \e[1;31mSERVER IS OFFLINE !\e[0;39m";;
        10|11)
            echo -e "[$(getDate)] $fail \e[1;31mSERVER IS OUT OF SCREEN !\e[0;39m"
            sleep 1
            mc_rescue;;
        12|13)
            echo -e "[$(getDate)] $warn \e[1;31mSERVER IS OFFLINE !\e[0;39m";;
        14|15)
            echo -e "[$(getDate)] $ok \e[1;32mSERVER IS ONLINE !\e[0;39m";;
        *)
            echo -e "[$(getDate)] $fail I GOT AN UNEXPECTED ERROR !"
            echo -e "[$(getDate)] [....] Ask my developers for help.";;
    esac
}

mc_check(){
    check=0
    if [ -f $rootdir/$serverfile ];then
        ((check+=8))
    fi
    if ps ax | grep -v grep | grep -i SCREEN | grep $screen > /dev/null
    then
        ((check+=4))
    fi
    if [ "$(lsof -i:$serverPort -t)" ];then
        ((check+=2))
    fi
    if [ -f $rootdir/.start.pid ];then
        ((check+=1))
    fi
    echo $check
}

mc_input(){
    if [ $(mc_check) -ge 14 ];then
        i=0
        for param in "$@";do
            if [ $i -eq 0 ];then
                ((i=$i+1))
            else
                command="$command$param"
                command="$command "
            fi
        done
        if [ -z $command ];then
            echo -e "Usage: $0 input <args>"
            exit 1
        fi
        if [ $2 != 'save-all' ];then
            pt_log "Sending command to console : /$command" 'info'
            bash -c "screen -p 0 -S $screen -X eval 'stuff \"$command\"\015'"
        elif [ $2 = 'save-all' ] && [ $saves = 'true' ];then
            bash -c "screen -p 0 -S $screen -X eval 'stuff \"$command\"\015'"
        fi
    elif [ $2 != 'save-all' ];then
        echo -e "[$(getDate)] $fail Trying to send command but server is offline."
        mc_status
        exit 1
    fi
}

mc_rescue(){
    if [ -f $rootdir/.start.pid ]; then
        pid=$(cat $rootdir/.start.pid)
        if [ $(ps $pid | grep -v PID) ];then
            echo -e "Found a process matching that PID. Send SIGTERM signal ?"
            read -p "Do you want to proceed [y/N] ? " yn
            if [ -z $yn ] || [ $yn != "y" ]; then
                echo Abort.
                exit 1
            else
                kill -SIGTERM $pid
                until [ -z "$(ps $pid | grep -v PID)" ];do
                    echo -n "."
                    sleep 1
                    ((status++))
                done
                    echo -e "Done."
            fi
        fi
    else
        echo -e "There is no PID file..."
    fi
}

#Watchdog
wd_status(){
    echo -en "[$(getDate)] $info WatchDog status :"
    if [ $watchDog = 'true' ];then
        echo -e " ON"
        echo -e "$warning Remember to set a crontab task running this script regularly."
        echo -e "$warning ( */5 * * * * bash $rootdir/start.sh wdcheck ) for every 5 minutes."
    else
        echo -e " OFF"
    fi
    echo -e "[$(getDate)] $info Watchdog can check if you server is offline and restart it."
    echo -e "[$(getDate)] $info Use wdon and wdoff for switch watchdog status."
    echo -e "Watchdog Usage: $0 {watchdog|wdcheck|wdon|wdoff}"
}

wd_check(){
    if [ $watchDog = 'true' ];then
        check=$(mc_check)
        case $check in
            0|1|2|3|4|5|6|7)
                echo -e "[$(getDate)] $warn \e[1;31mWATCHDOG : CRITICAL ERROR : File is missing !\e[0;39m"
                pt_log 'WATCHDOG : CRITICAL ERROR : File is missing !' 'fail';;
            8|9)
                echo -e "[$(getDate)] $warn \e[1;31mWATCHDOG : SERVER IS OFFLINE !\e[0;39m"
                pt_log 'WATCHDOG : SERVER IS OFFLINE ! RESTARTING...' 'warn'
                bash -c "$rootdir/start.sh start";;
            10|11)
                echo -e "[$(getDate)] $fail \e[1;31mWATCHDOG : SERVER IS OUT OF SCREEN !\e[0;39m"
                pt_log 'WATCHDOG : SERVER IS OUT OF SCREEN ! Trying to fix it...' 'fail'
                mc_rescue;;
            12|13)
                echo -e "[$(getDate)] $warn \e[1;31mWATCHDOG : SERVER IS OFFLINE BUT SCREEN STILL ALIVE !\e[0;39m"
                pt_log 'WATCHDOG : SERVER IS OFFLINE BUT SCREEN STILL ALIVE !' 'warn'
                bash -c "$rootdir/start.sh restart";;
            14|15)
                echo -e "[$(getDate)] $ok \e[1;32mWATCHDOG : SERVER IS ONLINE !\e[0;39m";;
            *)
                echo -e "[$(getDate)] $fail I GOT AN UNEXPECTED ERROR !"
                echo -e "[$(getDate)] [....] Ask my developers for help.";;
        esac
    else
        echo -e "[$(getDate)] [....] WATCHDOG DISABLED !"
        echo -e "[$(getDate)] [....] WATCHDOG : I will do nothing until you set watchDog='true' in .start.conf !"
    fi
}

wd_off(){
    watchDog='false'
    mc_conf
    pt_log 'Watchdog turned OFF' 'ok'
}

wd_on(){
    watchDog='true'
    mc_conf
    pt_log 'Watchdog turned ON' 'ok'
}

#Go!
root_check

case $1 in
    start)
        mc_start "$2";;
    stop)
        mc_stop "$2";;
    restart)
        mc_restart "$2";;
    saveon)
        mc_saveon;;
    saveoff)
        mc_saveoff;;
    status)
        mc_status;;
    check)
        mc_check;;
    input)
        mc_input "$@";;
    watchdog)
        wd_status;;
    wdcheck)
        wd_check;;
    wdon)
        wd_on;;
    wdoff)
        wd_off;;
    *)
        echo -e "Usage: $0 {start|stop|restart|status|check|input|watchdog}"
        exit 1;;
esac
exit 0
