---
author: tmzh
comments: true
date: 2017-08-24 15:41:28+00:00
layout: post
slug: 2017-08-24-using-a-bluetooth-serial-console-with-linux
title: Using a bluetooth serial console with linux
wordpress_id: 182
categories:
- Notes
tags:
- bluetooth
- Linux
---

Recently I bought a [bluetooth RS232 serial convertor](https://www.aliexpress.com/store/product/FREE-SHIPPING-Bt578-rs232-wireless-male-female-general-serial-port-bluetooth-adapter-bluetooth-module/719457_1271204185.html). I wasn't sure whether it would work with my Linux laptop. But it turned out to be quite simple to setup.


## Pre-requisites

The following packages are required:
  * bluez
  * bluez-utils
  * byobu (optional)

Bluez provides the bluetooth protocol stack (most likely shipped with the OS), bluez-utils provides the bluetoothctl utility and byobu is a wrapper around screen terminal emulator. You can also use 'screen' directly. Install these using your distributions recommended procedure.

<!--more-->

## Steps

1. Start daemon:
```shell
    Swanky:~$ systemctl start bluetooth
```

2. Discover using bluetoothctl:
```shell
    Swanky:~$ bluetoothctl
    [NEW] Controller <controller-mac-address> xkgt-Swanky [default]
    [bluetooth]# power on
    [bluetooth]# scan on
```

3. Once you can see your device, turn off the scan and pair
```shell
    [bluetooth]# scan off
    [bluetooth]# pair <device-mac-address>
```

4. Exit blutoothctl and create serial device (Note that root privileges are required):
```shell
    [bluetooth]# exit
    Swanky:~$ sudo rfcomm bind 0 <device-mac-address>
```

5. You should now have /dev/rfcomm0. Connect to it using byobu-screen utility:
```shell
    Swanky:~$ byobu-screen /dev/rfcomm0
```

Enjoy your wireless console connection!