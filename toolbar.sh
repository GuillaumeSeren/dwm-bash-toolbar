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
# @TODO: Change time counter to minute in charge if > 1h
# @TODO: Add color simple color support, check xsetroot
# @TODO: Refactor CPU_USAGE using 2 /proc/stat store old in var
# @TODO: Add getOpts parm to configure the output
# @TODO: Refactor the DWM status construction into a function
# @TODO: Refactor Network change wifi / ether as available
# @TODO: Display AP name in WIFI module
# @TODO: Add WIFI dbm if connected on a hotspot

# Error Codes {{{1
# 0 - Ok
# 1 - Error in cmd / options

# Default variables {{{1
# Flags :
# flagGetOpts=0
dependencies='cat find top awk grep head cut tr pacmd'
separator='|'
# Colors
colorRed=$(tput setaf 1)
colorGreen=$(tput setaf 2)
colorYellow=$(tput setaf 3)
colorBlue=$(tput setaf 4)
colorMagenta=$(tput setaf 5)
colorCyan=$(tput setaf 6)
colorWhite=$(tput setaf 7)
colorReset=$(tput sgr0)

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

# FUNCTION getBatteryStatus() {{{1
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
      if [[ "${sState}" == "Discharging" || "${sState}" == "Charging" ]]; then
        batteryStatus="${sState}"
      fi
    done
  fi
  echo "${batteryStatus}"
}

# FUNCTION getBatteryStatusCharging
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

# FUNCTION getPowerStatus() {{{1
function getPowerStatus() {
  local batteryStatus=""
  if [ "$( cat /sys/class/power_supply/AC/online )" -eq "1" ]; then
    batteryStatus="AC";
  else
    batteryStatus="DC";
  fi
  echo "${batteryStatus}"
}

# FUNCTION getBattteryNumber() {{{1
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

# FUNCTION getBatteryInUse() {{{1
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

# FUNCTION getBatteryTimeEmpty() {{{1
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

# FUNCTION getAllBatteryTimeEmpty() {{{1
# This function return the time to drain all battery,
# useful for multi battery system
function getAllBatteryTimeEmpty() {
  local iRemainingTime=''
  if [[ -n "$1" && "$1" != "false" ]]; then
    iRemainingTime=$(getBatteryTimeEmpty "$1" 1)
  fi
  echo "${iRemainingTime}"
}

# FUNCTION getBatteryTimeFull() {{{1
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
        iBatPowerFull=$((iBatPowerFull + iPowerFull))
      done
      unset -v aPowerFull
      while IFS= read -d $'\0' -r bat ; do
        aChargeNow=("${aChargeNow[@]}" "$(cat "$bat"/energy_now)")
      done < <(find /sys/class/power_supply/ -maxdepth 1 -mindepth 1 -name "BAT*" -type l -print0)
      for iCharge in "${aChargeNow[@]}" ; do
        iBatChargeNow=$((iBatChargeNow + iCharge))
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

# FUNCTION getAllBatteryTimeEmpty() {{{1
# This function return the time to charge all battery,
# useful for multi battery system
function getAllBatteryTimeFull() {
  local iRemainingTime=''
  if [[ -n "$1" && "$1" != "false" ]]; then
    iRemainingTime="$(getBatteryTimeFull "$1" 1)"
  fi
  echo "${iRemainingTime}"
}

# FUNCTION getCpuTemp() {{{1
function getCpuTemp() {
  local temp=''
  temp=$(acpi -t)
  local regex='^Thermal 0: ok, (.*)\.. degrees C$'
  [[ $temp =~ $regex ]]
  echo "${BASH_REMATCH[1]}°C"
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
  #@TODO: Check if output is empty
  volume="$( pacmd list-sinks | grep "volume" | head -n1 | cut -d: -f3 | cut -d% -f1 | tr -d "[:space:]" | cut -d/ -f2 )";
  if [[ -n "${volume}" && "${volume}" != '' ]]; then
    volumeOutput="SND ${volume} %"
  else
    volumeOutput=''
  fi
  echo "${volumeOutput}"
}

# FUNCTION getCpuUsage {{{1
function getCpuUsage() {
  # see https://github.com/Leo-G/DevopsWiki/wiki/How-Linux-CPU-Usage-Time-and-Percentage-is-calculated
  #      user    nice   system  idle      iowait irq   softirq  steal  guest  guest_nice
  # cpu  74608   2520   24433   1117073   6176   4054  0        0      0      0
  # cpu  676303  54969  1047936 3460684   117067 0     5952 		0 		 0 			0
  # CPU_USAGE=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$3+$4)*100/($2+$3+$4+$5+$6+$7+$8+$9+$10+$11)} END {print usage "%"}' )
  CORECOUNT=$(grep -c ^processor /proc/cpuinfo)
  # Use top, skip the first 7 rows, count the sum of the values
  #   in column 9 - the CPU column, do some simple rounding at the end
  CPU_USAGE=$(top -bn 1 | awk -v n=$CORECOUNT 'NR > 7 { s += $9 } END { print int(s / n + .5); }')
  echo "$CPU_USAGE%"
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

# FUNCTION main() {{{1
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
  # BatteryStatus is charging / Discharging
  # BatteryStatus should take a parm to get all bat or just a given one
  batteryStatusCharging=''
  batteryStatusCharging=$(getBatteryStatusCharging)
  batteryNumber="$(getBatteryNumber)"
  # In AC if batteryInUse is null hide batInfo
  batteryInUse="$(getBatteryInUse)"

  if [[ "${powerStatus}" == 'DC' ]]; then
    # We are in DC mode → timeToEmpty !
    batteryTime="$(getAllBatteryTimeEmpty "${batteryInUse}")"
    if [[ "${batteryTime}" == "0" ]]; then
      # Send a notification if remaining time on bat is less 1H
      notify-send -t 10 -u critical 'BAT' '→ BAT is less 1 H'
    fi
    batteryTimeOutput="-${batteryTime} h"
  else
    # We should be in AC mode → timeToFull !
    batteryTime="$(getAllBatteryTimeFull "${batteryInUse}")"
    # We need battery state charging / Discharging / unknown
    # if [[ "${batteryTime}" == "0" && "${batteryStatusCharging}" != "Charging" && "${batteryStatusCharging}" == '' ]]; then
    if [[ "${batteryStatusCharging}" == "Charging" ]]; then
      batteryTimeOutput="+${batteryTime} h"
    else
      batteryTimeOutput="${batteryStatusCharging}"
    fi
  fi
  batteryPack=''
  if [[ "${batteryInUse}" != '' ]]; then
    batteryPack="$batteryInUse/$batteryNumber"
  fi
  batteryWidget="$batteryPack $powerStatus $batteryTimeOutput"

  # Volume Level
  DWM_VOL="$(getVolume)"

  # Date and Time
  DWM_DATE=$( date '+%Y-%m-%d %a' );
  DWM_CLOCK=$( date '+%k:%M' );
  CPU_USAGE=$(getCpuUsage)

  DWM_STATUS="CPU $CPU_USAGE @ $cpuTemp ${separator} $batteryWidget ${separator} $DWM_VOL ${separator} $DWM_DATE ${separator} $DWM_CLOCK";
  echo "$DWM_STATUS"
}
main
# }}}

# vim: set ft=sh ts=2 sw=2 tw=80 foldmethod=marker et :
