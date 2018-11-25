# PixelStart.sh
Simple start.sh for Minecraft servers

Support the /restart command ingame.
For this you need to edit the spigot.yml file and change this :
```
  restart-script: ./start.sh
```
to :
```
  restart-script: ./restart.sh
```

## Usage :
### Basic commands :

Start the server.
```bash
$ ./start.sh start
```
Stop the server.
```bash
$ ./start.sh stop
```
Restart the server.
```bash
$ ./start.sh restart
```
Send commands to the screen.
```bash
$ ./start.sh input
```
Displays server status.
```bash
$ ./start.sh status
```
Get the status code from check function.
```bash
$ ./start.sh check
```
Send save-off to server (and save-all) and disable sending `save-all` with `start.sh input`.
```bash
$ ./start.sh saveoff
```
Send save-on to server and enable sending `save-all` with `start.sh input`.
```bash
$ ./start.sh saveon
```
When you use crontab to send regularly a save-all command, using saveoff deny sending "save-all" command, usefull when running backups.

### Watchdog commands :
#### Used with crontab, this script can automatically restart your server when it crashed.

Displays watchdog status.
```bash
$ ./start.sh watchdog
```

Activate monitoring
```bash
$ ./start.sh wdon
```

Desactivate monitoring
```bash
$ ./start.sh wdoff
```

Run this command with crontab every x minutes.
```bash
$ ./start.sh wdcheck
```
Crontab : For every 5 minutes.
```
*/5 * * * * bash /path/to/server/start.sh wdcheck
```
## Check function return code :
### Using ./start.sh check will return a status code, here is some explanation about it.
**From 0 to 7** : Basically, the server file was missing.
When 2, 4 or 6 is returned,it seems there is a server online.

**From 8 to 9** : The server is offline.
* (8 = no server running at specified port)
* (9 = but there is a pid file)

**From 10 to 11** : Server is running **BUT** screen session is not found. (Server out of screen, maybe false positive)
* (10 = port specified was listening)
* (11 = and there is a PID file)

**From 12 to 13** : Server is offline, but there is a screen session. (Can be a false positive, when server is too slow or freezing a lot)
* (12 = Screen session found, but no server was listen at specified port)
* (13 = and there is a PID file)

**From 14 to 15** : Server is running.
* (14 = PID file was missing.)
* (15 = PID file was found.)

## Dependencies :
* curl
* lsof
* screen
* restart.sh file (created by script if missing)
