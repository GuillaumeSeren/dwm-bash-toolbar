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
# @TODO: Add getOpts parm to configure the output
# @TODO: Refactor the DWM status construction into a function
# @TODO: Extract separator to a parm with default value to |
# @TODO: When full charged change the output AC
# @TODO: When BAT charging is less than 1H switch display to minute
# @TODO: Refactor Network change wifi / ether as available
# @TODO: Display AP name in WIFI module
# @TODO: Add WIFI dbm if connected on a hotspot
# @TODO: Add color simple color support

# Error Codes {{{1
# 0 - Ok
# 1 - Error in cmd / options

# Default variables {{{1
# Flags :
# flagGetOpts=0
dependencies='cat find'

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

# getBatteryStatus() {{{1
# $1 BAT_NUM if null return 'worst' state
function getBatteryStatus() {
  local batteryStatus=""
  if [[ -n "$1" && "$1" != "false" ]]; then
    batteryStatus="$(cat /sys/class/power_supply/"${1}"/status)"
  else
    while IFS= read -d $'\0' -r file ; do
      aBattery=("${aBattery[@]}" "$file")
    done < <(find /sys/class/power_supply/ -maxdepth 1 -mindepth 1 -name "BAT*" -type l -print0)
    for sBat in "${aBattery[@]}" ; do
      sState=$(cat "${sBat}"/status)
      if [[ "${sState}" == "Discharging" || "${sState}" == "Charging" || "${sState}" == "Unknown" ]]; then
        batteryStatus="${sState}"
      fi
    done
  fi
  echo "${batteryStatus}"
}

# getBatteryStatusCharging
function getBatteryStatusCharging() {
  local batteryStatusOutput=''
  local batteryStatus=''
  batteryStatus=$(getBatteryStatus)
  # check *only* 'Charging' status
  if [[ "${batteryStatus}" == "Charging" ]]; then
    batteryStatusOutput="${batteryStatus}"
  fi
  echo "${batteryStatusOutput}"
}

# getPowerStatus() {{{1
function getPowerStatus() {
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
        iBatPowerNow=$((iBatPowerNow + iPower))
      done
      unset -v aPowerNow
      while IFS= read -d $'\0' -r bat ; do
        aEnergyNow=("${aEnergyNow[@]}" "$(cat "$bat"/energy_now)")
      done < <(find /sys/class/power_supply/ -maxdepth 1 -mindepth 1 -name "BAT*" -type l -print0)
      for iEnergy in "${aEnergyNow[@]}" ; do
        iBatChargeNow=$((iBatChargeNow + iEnergy))
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
  echo "${iRemainingTime}"
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
    iRemainingTime="$(getBatteryTimeFull "$1" 1)"
  fi
  echo "${iRemainingTime}"
}

# getCpuTemp() {{{1
function getCpuTemp() {
  local temp=''
  temp=$(acpi -t)
  local regex='^Thermal 0: ok, (.*)\.. degrees C$'
  [[ $temp =~ $regex ]]
  echo "${BASH_REMATCH[1]} °C"
}

# FUNCTION checkDependencies() {{{1
# Test if needed dependencies are available.
function checkDependencies()
{
  deps_ok='YES'
  for dep in $1
  do
    if  ! which "$dep" &>/dev/null;  then
      echo "This script requires $dep to run but it is not installed"
      deps_ok='NO'
    fi
  done
  if [[ "$deps_ok" == "NO" ]]; then
    echo "This script need : $1"
    echo "Please install them, before using this script !"
    exit 3
  else
    return 0
  fi
}

# FUNCTION getVolume() {{{1
function getVolume() {
  # Volume Level
  local volume=''
  local volumeOutput=''
  volume="$( pacmd list-sinks | grep "volume" | head -n1 | cut -d: -f3 | cut -d% -f1 | tr -d "[:space:]" | cut -d/ -f2 )";
  if [[ -n "${volume}" && "${volume}" != '' ]]; then
    volumeOutput="SND ${volume} %"
  else
    volumeOutput=''
  fi
  echo "${volumeOutput}"
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

# main() {{{1
# generate toolbar
function main() {
  # echo ">>>> Checking dependencies"
  checkDependencies "$dependencies"
  # Temp
  cpuTemp="$(getCpuTemp)"
  # CPU
  # Power/Battery Status
  # Power is AC / DC of the machine
  powerStatus="$(getPowerStatus)"
  # BatteryStatus is charging / Discharging / Unknown
  # BatteryStatus should take a parm to get all bat or just a given one
  # batteryStatus="$(getBatteryStatus)"
  batteryStatusCharging=$(getBatteryStatusCharging)
  batteryNumber="$(getBatteryNumber)"
  batteryInUse="$(getBatteryInUse)"
  if [[ "${powerStatus}" == 'DC' ]]; then
    # We are in DC mode → timeToEmpty !
    batteryTime="$(getAllBatteryTimeEmpty "${batteryInUse}")"
    if [[ "${batteryTime}" == "0" ]]; then
      batteryTimeOutput="-${batteryTime} h"
    else
      batteryTimeOutput="-${batteryTime} h"
    fi
  else
    # We should be in AC mode → timeToFull !
    batteryTime="$(getAllBatteryTimeFull "${batteryInUse}")"
    # We need battery state charging / Discharging / unknown
    if [[ "${batteryTime}" == "0" && "${batteryStatusCharging}" != "Charging" && "${batteryStatusCharging}" != '' ]]; then
      batteryTimeOutput="${batteryStatusCharging}"
    else
      batteryTimeOutput="+${batteryTime} h"
    fi
  fi
  batteryWidget="$batteryInUse/$batteryNumber $powerStatus $batteryTimeOutput"

  # Volume Level
  DWM_VOL="$(getVolume)";

  # Date and Time
  DWM_DATE=$( date '+%Y-%m-%d %a' );
  DWM_CLOCK=$( date '+%k:%M' );
  CPU_USAGE=$(top -b -n2 -p 1 | fgrep "Cpu(s)" | tail -1 | awk -F'id,' -v prefix="$prefix" '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%s%.1f %%\n", prefix, 100 - v }')
  # Overall output command
  DWM_STATUS="CPU $CPU_USAGE @ $cpuTemp | $batteryWidget | $DWM_VOL | $DWM_DATE | $DWM_CLOCK";
  echo "$DWM_STATUS"
}
main
# }}}

# vim: set ft=sh ts=2 sw=2 tw=80 foldmethod=marker et :
