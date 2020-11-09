#!/bin/bash
#
# PTUUID identifies installation on sda and mmcblk0
CARD="/dev/mmcblk0";
PTUUID="f1004589";
SSD="/dev/sda";

# Check this Mountpoint, mountet -> /mnt/Backup
Mount="//192.168.1.1/HDD/Backup/server.h"
# Write Image to Directory
DIR="/mnt/Backup/Images";

###   Blink Red Power Led   ###
PID=0;
BLINK() {
    if [[ "$PID" == "0" ]]; then
         while true; do
                 Led="/sys/class/leds/led1/brightness";
                 sudo sh -c "echo 1 > $Led"; sleep 0.25s;
                 sudo sh -c "echo 0 > $Led"; sleep 0.25s
        done &
        PID=$(echo $!);
    else kill "$PID"; PID=0; sudo sh -c "echo 0 > $Led"; fi
}
# Create/Write Images with dd Options
DD() { sudo dd bs=2048k status=progress if="$1" of="$2"; }

# Create Names for Images
Day="$(date +%d-%m-%y)";
BOOT="$DIR/BOOT_Server.img";
ROOT="$DIR/ROOT_Server.img";
SERVER="$DIR/Server_Image_$Day.img";
PiShrink="$DIR/PiShrink_Server.img";
CrImage="${DIR}/CreateNewImage";
#
Log="/var/log/CrImage.log";
Write() { echo "$(date +%H:%M:%S) |-> $1" >> "$Log"; }
# EXIT, if $SSD is not $PTUUID
if ! [[ $(sudo blkid "$SSD") =~ "$PTUUID" ]]; then
    Write "ERROR, $SSD stimmt nicht mit PTUUID $PTUUID überein, EXIT!"; exit 1;
fi
if ! [[ -d "$DIR" ]]; then Write "ERROR, Verzeichnis $Dir existiert nicht! EXIT"; exit 1; fi
###   SSD mountet   ##€
if [[ $(mount | grep "${SSD}2 on / type ext4") ]]; then
    if [[ -f "$CrImage" ]]; then
         Write "SSD: ${SSD}2 gebootet...WriteImage in 30s"; sleep 30;
        if [[ $(ls "${CARD}p2") ]]; then
             if [[ $(mount | grep "$Mount on /mnt/Backup") ]]; then
                 BLINK;
                 Write "WriteImage: Write \$BOOT nach ${CARD}p1"; DD "$BOOT" "${CARD}p1";
                 Write "WriteImage: Write \$ROOT nach ${CARD}p2"; DD "$ROOT" "${CARD}p2";
                 sudo sync; Write "Warte 1 Minuten, bis volles Images erzeugt wird!"; sleep 1m;
                 Write "Erzeuge von $CARD das Image \$SERVER"; DD "$CARD" "$SERVER";
                 sudo sync; Write "Warte 2 Minuten, bis PiShrink Image erzeugt wird!"; sleep 0m;
                 Write "Erzeuge PiShrink Image \$PiShrink"; sudo PiShrink "-s" "$SERVER" "$PiShrink";
                 Write "Image schreiben abgeschlossen! <-|"; sudo sync;
                 sudo rm "$CrImage";
                 BLINK;
             else Write "Netzlaufwerk nicht gemountet"; exit 1; fi
        else Write "SdCard nicht gefunden"; exit 0; fi
    else Write "No New Image"; exit 0; fi
###   SDCARD gemountet   ###
elif [[ $(mount | grep "${CARD}p2 on / type ext4") ]]; then
      Write "SDCARD: ${CARD} gebootet...CreateImage in 30s"; sleep 30s;
      if [[ $(ls "${SSD}2") ]]; then
          if [[ $(mount | grep "$Mount on /mnt/Backup") ]]; then
              BLINK;
              Write "Erzeuge Image \$BOOT von ${SSD}1"; DD "${SSD}1" "$BOOT";
              Write "Erzeuge Image \$ROOT von ${SSD}2"; DD "${SSD}2" "$ROOT";
              Write "Image schreiben abgeschlossen! <-|";
              sudo sh -c "echo '- Create New Image on next boot from $SSD' > $CrImage";
              BLINK; sleep 5s; sudo sync; Reboot 0;
          else Write"Netzwerk nicht gemountet!"; exit 1; fi
      else Write "SdCard gemountet, aber ssd wurde nicht gefunden!"; exit 1; fi
else Write "Weder sdcard noch ssd wurden erkannt!"; exit 1; fi
#
###   Switch Red Power Led off   ###
sudo sh -c ' echo "0" > $Led ';
