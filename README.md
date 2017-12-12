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
Showing some status.
```bash
$ ./start.sh status
```
Send save-off to server (and save-all).
```bash
$ ./start.sh saveoff
```
Send save-on to server.
```bash
$ ./start.sh saveon
```
When you use crontab to send regularly a save-all command, using saveoff deny sending "save-all" command, usefull when running backups. (./start.sh input save-all)

### Watchdog commands :
#### Used with crontab, this script can automatically restart your server when it crashed.

Showing watchdog status.
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

Run this command with crontab eveny x minutes.
```bash
$ ./start.sh wdcheck
```
Crontab : For every 5 minutes.
```
*/5 * * * * bash /path/to/server/start.sh wdcheck
```
#### Also you can combine those commands. Example below, for stop the server AND stop watchdog monitoring.
```bash
$ ./start.sh stop wdoff
```
## Dependencies :
* screen
* restart.sh file
