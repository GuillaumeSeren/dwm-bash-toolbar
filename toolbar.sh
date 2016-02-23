#!/bin/bash
# -*- coding: UTF8 -*-
# ---------------------------------------------
# @author:  Guillaume Seren
# @since:   22/02/2016
# source:   https://github.com/GuillaumeSeren/dwm-bash-toolbar.git
# file:     toolbar.sh
# Licence:  GPLv3
# ---------------------------------------------

# Statusbar loop
while true; do
  # Temp
  # Power/Battery Status
  if [ "$( cat /sys/class/power_supply/AC/online )" -eq "1" ]; then
    DWM_BATTERY="AC";
    DWM_RENEW_INT=1;
  else
    # We are on the battery
    # count the number of battery in the system
    declare -a BAT_ARRAY
    while read -r -d ''; do
      BAT_ARRAY+=("${filename}")
    done < <(find /sys/class/power_supply/ -maxdepth 1 -mindepth 1 -name "BAT*" -type l -print0)
    DWM_BATTERY_NUMBER=${#BAT_ARRAY[*]}
    # Now we get the status of each BAT
    declare -A BAT_STATUS
    for i in "$BAT_ARRAY"
    do
      echo "$i"
    done
    # Detect the active battery
    DWM_BATTERY=$(( `cat /sys/class/power_supply/BAT0/energy_now` * 100 / `cat /sys/class/power_supply/BAT0/energy_full` ));
    DWM_RENEW_INT=10;
    unset -v BAT_ARRAY
  fi;

  # Wi-Fi eSSID
  if [ "$( cat /sys/class/net/eth1/rfkill1/state )" -eq "1" ]; then
    DWM_ESSID=$( /sbin/iwgetid -r );
  else
    DWM_ESSID="OFF";
  fi;

  # Keyboard layout
  if [ "`xset -q | awk -F \" \" '/Group 2/ {print($4)}'`" = "on" ]; then
    DWM_LAYOUT="ru";
  else
    DWM_LAYOUT="en";
  fi;

  # Volume Level
  DWM_VOL=$( amixer -c1 sget Master | awk -vORS=' ' '/Mono:/ {print($6$4)}' );

  # Date and Time
  DWM_CLOCK=$( date '+%e %b %Y %a | %k:%M' );

  # Overall output command
  DWM_STATUS="WiFi: [$DWM_ESSID] | Lang: [$DWM_LAYOUT] | Power(/$DWM_BATTERY_NUMBER): [$DWM_BATTERY] | Vol: $DWM_VOL | $DWM_CLOCK";
  xsetroot -name "$DWM_STATUS";
  sleep $DWM_RENEW_INT;
done &
