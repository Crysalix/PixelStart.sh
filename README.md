# PixelStart.sh
Simple start.sh for Minecraft servers

Support the /restart command ingame
# Usage :
## Basic commands :

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
Showing some status.
```bash
$ ./start.sh status
```

## Watchdog commands :
### Used with crontab, this script can automatically restart your server when it crashed.

Showing watchdog status.
```bash
$./start.sh watchdog
```

Activate monitoring
```bash
$./start.sh wdon
```

Desactivate monitoring
```bash
$./start.sh wdoff
```

Run this command with crontab eveny x minutes.
```bash
$./start.sh wdcheck
```
Crontab : For every 5 minutes.
```
*/5 * * * * bash /path/to/server/start.sh wdcheck
```
### Also you can combine those commands. Example below, for stop the server AND stop watchdog monitoring.
```bash
$ ./start.sh stop wdoff
```
# Auto updater added

This script will try to update himself if new version is found.
