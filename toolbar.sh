#!/bin/bash
# -*- coding: UTF8 -*-
# ---------------------------------------------
# @author:  Guillaume Seren
# @since:   22/02/2016
# source:   https://github.com/GuillaumeSeren/dwm-bash-toolbar.git
# file:     toolbar.sh
# Licence:  GPLv3
# ---------------------------------------------

# TaskList {{{1
#@TODO: Add check on required program.

# Error Codes {{{1
# 0 - Ok
# 1 - Error in cmd / options

# Default variables {{{1
# Flags :
flagGetOpts=0

# FUNCTION usage() {{{1
# Return the helping message for the use.
function usage()
{
cat << DOC

usage: "$0" options

This script generate a text toolbar


OPTIONS:
    -h  Show this message.

Sample:
  sh toolbar.sh

DOC
}

# GETOPTS {{{1
# Get the param of the script.
while getopts ":h" OPTION
do
    flagGetOpts=1
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    ?)
        echo "commande $1 inconnue"
        usage
        exit
        ;;
    esac
done
# # We check if getopts did not find no any param
# if [ "$flagGetOpts" == 0 ]; then
#     echo 'This script cannot be launched without options.'
#     usage
#     exit 1
# fi

# Function battery
function getBattery() {
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
}

# getBatteryStatus() {{{1
function getBatteryStatus() {
  local batteryStatus=""
  if [ "$( cat /sys/class/power_supply/AC/online )" -eq "1" ]; then
    batteryStatus="AC";
  else
    batteryStatus="DC";
  fi
  echo "${batteryStatus}"
}

# getBattteryNumber() {{{1
# count the number of battery in the system
function getBatteryNumber() {
  declare -a aBattery
  while read -r -d ''; do
    aBattery+=("${filename}")
  done < <(find /sys/class/power_supply/ -maxdepth 1 -mindepth 1 -name "BAT*" -type l -print0)
  local iBatteryNumber=${#aBattery[*]}
  unset -v aBattery
  echo "${iBatteryNumber}"
}

function getBatteryInUse() {
  local sBatInUse=""
  local aBattery=()
  while IFS= read -d $'\0' -r file ; do
    aBattery=("${aBattery[@]}" "$file")
  done < <(find /sys/class/power_supply/ -maxdepth 1 -mindepth 1 -name "BAT*" -type l -print0)
  for sBat in "${aBattery[@]}" ; do
    sState=$(cat "${sBat}"/status)
    # let's trim space
    # sState="${sState##*( )}"
    # echo "cat "${sBat}"/status"
    # echo "${sbat} ${sState}"
    # echo "${sState}"
    if [[ "${sState}" == "Charging" ]]; then
      # echo "test true ${sBat}"
      sBatInUse=$(basename "${sBat}")
    fi
  done
  unset -v aBattery
  echo "${sBatInUse}"
}

# generate toolbar {{{1
function main() {
  # Temp
  # CPU
  # Power/Battery Status
  batteryStatus=$(getBatteryStatus)
  # if [[ "${batteryStatus}" == "AC" ]]; then
  #   # AC MODE
  # else
  #   # DC MODE
  # fi
  batteryNumber=$(getBatteryNumber)
  batteryInUse=$(getBatteryInUse)
  # echo $batteryStatus $batteryNumber  $batteryInUse
  batteryWidget="Power($batteryInUse/$batteryNumber): [$batteryStatus]"
  # echo $batteryWidget
  # exit 3
  # batteryTimeRemaining=
  name=$(getBattery "$")

  # Wi-Fi eSSID
  # if [ "$( cat /sys/class/net/eth1/rfkill1/state )" -eq "1" ]; then
  #   DWM_ESSID=$( /sbin/iwgetid -r );
  # else
  #   DWM_ESSID="OFF";
  # fi;

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
  DWM_STATUS="WiFi: [$DWM_ESSID] | Lang: [$DWM_LAYOUT] | $batteryWidget | Vol: $DWM_VOL | $DWM_CLOCK";
  # xsetroot -name "$DWM_STATUS";
  # sleep $DWM_RENEW_INT;
  # done &
  echo $DWM_STATUS
}
main
# }}}
# vim: set ft=sh ts=2 sw=2 tw=80 foldmethod=marker et :
