#!/usr/bin/env bash
# The build profile chosen on a Raspberry Pi, faked with a device tree model
# mounted over /sys/firmware. Needs sudo. Usage: test/rpi_host/check.sh

set -u
cd "$(dirname "$0")"
sudo mount -t tmpfs tmpfs /sys/firmware
trap 'sudo umount /sys/firmware' EXIT
sudo mkdir -p /sys/firmware/devicetree/base
printf 'Raspberry Pi 4 Model B Rev 1.4\0' | sudo tee /sys/firmware/devicetree/base/model > /dev/null

failures=0
check() {
   local got
   got=$(haxelib run hxcpp Build.xml "$1" | grep -a '^BINDIR=' | cut -d= -f2)
   if [ "$got" = "$2" ]; then
      echo "ok   $1: $got"
   else
      echo "FAIL $1: expected $2, got $got"
      failures=$((failures + 1))
   fi
}
check -DHXCPP_ARM64 LinuxArm64
check -DHXCPP_ARMV7 RPi
exit $failures
