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

# getBatteryInUse() {{{1
# Retrun the name of the draining/charging battery
function getBatteryInUse() {
  local sBatInUse=""
  local aBattery=()
  while IFS= read -d $'\0' -r file ; do
    aBattery=("${aBattery[@]}" "$file")
  done < <(find /sys/class/power_supply/ -maxdepth 1 -mindepth 1 -name "BAT*" -type l -print0)
  for sBat in "${aBattery[@]}" ; do
    sState=$(cat "${sBat}"/status)
    if [[ "${sState}" == "Discharging" || "${sState}" == "Charging" ]]; then
      sBatInUse=$(basename "${sBat}")
    fi
  done
  unset -v aBattery
  echo "${sBatInUse}"
}

# getBatteryTime() {{{1
# Return time remaining (in hour) for a given battery
function getBatteryTime() {
  local iTime=0
  # we need the battery name
  if [[ -n "$1" && "$1" != "false" ]]; then
    local iBatFull=$(cat /sys/class/power_supply/"$1"/energy_full)
    local iBatChargeNow=$(cat /sys/class/power_supply/"$1"/energy_now)
    iTime=$((iBatFull - iBatChargeNow))
    iTime=$((iTime / iBatChargeNow))
  fi
  echo "${iTime}"
}

# generate toolbar {{{1
function main() {
  # Temp
  # CPU
  # Power/Battery Status
  batteryStatus="$(getBatteryStatus)"
  batteryNumber="$(getBatteryNumber)"
  batteryInUse="$(getBatteryInUse)"
  batteryTime="~$(getBatteryTime $batteryInUse)h"
  batteryWidget="Power($batteryInUse/$batteryNumber): [$batteryStatus $batteryTime]"

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
  echo "$DWM_STATUS"
}
main
# }}}
# vim: set ft=sh ts=2 sw=2 tw=80 foldmethod=marker et :
