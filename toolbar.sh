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
# @TODO: Add check on required program.
# @TODO: When full charged change the output AC

# Error Codes {{{1
# 0 - Ok
# 1 - Error in cmd / options

# Default variables {{{1
# Flags :
# flagGetOpts=0

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

# getBatteryTimeEmpty() {{{1
# Return time remaining (in hour) for a given battery
# 1 parm is active bat name
# 2 parm (optional) return all available bat
function getBatteryTimeEmpty() {
  # we need the battery name
  if [[ -n "$1" && "$1" != "false" ]]; then
    local iBatPowerNow=0
    local iBatChargeNow=0
    if [[ -n "$2"  && "$2" != "false" ]]; then
      local aPowerNow=()
      local aChargeNow=()
      while IFS= read -d $'\0' -r bat ; do
        aPowerNow=("${aPowerNow[@]}" "$(cat "$bat"/power_now)")
      done < <(find /sys/class/power_supply/ -maxdepth 1 -mindepth 1 -name "BAT*" -type l -print0)
      for iPower in "${aPowerNow[@]}" ; do
        iBatPowerNow=$(($iBatPowerNow + $iPower))
      done
      unset -v aPowerNow
      while IFS= read -d $'\0' -r bat ; do
        aEnergyNow=("${aEnergyNow[@]}" "$(cat "$bat"/energy_now)")
      done < <(find /sys/class/power_supply/ -maxdepth 1 -mindepth 1 -name "BAT*" -type l -print0)
      for iEnergy in "${aEnergyNow[@]}" ; do
        iBatChargeNow=$(($iBatChargeNow + $iEnergy))
      done
      unset -v aEnergyNow
    else
      iBatPowerNow=$(cat /sys/class/power_supply/"$1"/power_now)
      iBatChargeNow=$(cat /sys/class/power_supply/"$1"/energy_now)
    fi
    iRemainingTime=$((iBatChargeNow / iBatPowerNow))
  fi
  echo ${iRemainingTime}
}

# This function return the time to drain all battery,
# useful for multi battery system
function getAllBatteryTimeEmpty() {
  local iRemainingTime=''
  if [[ -n "$1" && "$1" != "false" ]]; then
    iRemainingTime=$(getBatteryTimeEmpty "$1" 1)
  fi
  echo ${iRemainingTime}
}

# getBatteryTimeFull() {{{1
# Return time remaining (in hour) for a given battery
function getBatteryTimeFull() {
  # we need the battery name
  if [[ -n "$1" && "$1" != "false" ]]; then
    local iBatPowerFull=0
    local iBatChargeNow=0
    if [[ -n "$2"  && "$2" != "false" ]]; then
      local aPowerFull=()
      local aChargeNow=()
      while IFS= read -d $'\0' -r bat ; do
        aPowerFull=("${aPowerNow[@]}" "$(cat "$bat"/energy_full)")
      done < <(find /sys/class/power_supply/ -maxdepth 1 -mindepth 1 -name "BAT*" -type l -print0)
      for iPowerFull in "${aPowerFull[@]}" ; do
        iBatPowerFull=$(($iBatPowerFull + $iPowerFull))
      done
      unset -v aPowerFull
      while IFS= read -d $'\0' -r bat ; do
        aChargeNow=("${aChargeNow[@]}" "$(cat "$bat"/energy_now)")
      done < <(find /sys/class/power_supply/ -maxdepth 1 -mindepth 1 -name "BAT*" -type l -print0)
      for iCharge in "${aChargeNow[@]}" ; do
        iBatChargeNow=$(($iBatChargeNow + $iCharge))
      done
      unset -v aChargeNow
    else
      iBatPowerFull=$(cat /sys/class/power_supply/"$1"/energy_full)
      iBatChargeNow=$(cat /sys/class/power_supply/"$1"/energy_now)
    fi
    iBatRemaining=$((iBatPowerFull - iBatChargeNow))
    iRemainingTime=$((iBatRemaining / iBatChargeNow))
  fi
  echo ${iRemainingTime}
}

# This function return the time to charge all battery,
# useful for multi battery system
function getAllBatteryTimeFull() {
  local iRemainingTime=''
  if [[ -n "$1" && "$1" != "false" ]]; then
    iRemainingTime=$(getBatteryTimeFull "$1" 1)
  fi
  echo ${iRemainingTime}
}

# getCpuTemp() {{{1
function getCpuTemp() {
  local temp=''
  temp=$(acpi -t)
  local regex='^Thermal 0: ok, (.*)\.. degrees C$'
  [[ $temp =~ $regex ]]
  echo "${BASH_REMATCH[1]} °C"
}

# generate toolbar {{{1
function main() {
  # Temp
  cpuTemp="$(getCpuTemp)"
  # CPU
  # Power/Battery Status
  batteryStatus="$(getBatteryStatus)"
  batteryNumber="$(getBatteryNumber)"
  batteryInUse="$(getBatteryInUse)"
  if [[ "${batteryStatus}" == 'DC' ]]; then
    # We are in DC mode → timeToEmpty !
    batteryTime="-$(getAllBatteryTimeEmpty "${batteryInUse}") h"
    batteryWidget="Power($batteryInUse/$batteryNumber): [$batteryStatus $batteryTime]"
  else
    # We should be in AC mode → timeToFull !
    batteryTime="+$(getAllBatteryTimeFull "${batteryInUse}") h"
    batteryWidget="Power($batteryInUse/$batteryNumber): [$batteryStatus $batteryTime]"
  fi

  # Keyboard layout
  sKeyLayout="$(xset -q | awk -F " " '/Group 2/ {print($4)}')"
  if [[ "$sKeyLayout" == "on" ]]; then
    DWM_LAYOUT="ru";
  else
    DWM_LAYOUT="en";
  fi;

  # Volume Level
  DWM_VOL=$( amixer -c1 sget Master | awk -vORS=' ' '/Mono:/ {print($6$4)}' );

  # Date and Time
  DWM_CLOCK=$( date '+%e %b %Y %a | %k:%M' );

  # Overall output command
  DWM_STATUS="CPU: [$cpuTemp] | WiFi: [$DWM_ESSID] | Lang: [$DWM_LAYOUT] | $batteryWidget | Vol: $DWM_VOL | $DWM_CLOCK";
  echo "$DWM_STATUS"
}
main
# }}}
# vim: set ft=sh ts=2 sw=2 tw=80 foldmethod=marker et :
