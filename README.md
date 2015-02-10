AGM
===

Automates various functions of the Telstra Gateway Max Cable Modem.

Ruby script to drive the web interface of the Telstra Gateway Max Cable Modem.

Introduction
------------

This came into being because the AC wireless firmware is buggy with the Cable Modem.
I found I had to reboot the modem daily to maintain good connectivity.
If the modem wasn't rebooted daily the performance would deteriorate until it stopped passing network traffic.

Features:

- Reboots modem
- Displays connections status
- Displays connected devices
- Displays system logs
- Can save/read username and password to/from file that is only viewable by user

License
-------

This software is licensed as CC-BA (Creative Commons By Attrbution)

http://creativecommons.org/licenses/by/4.0/legalcode

Requirements
------------

Software:

- Ruby
- PhantomJS

Ruby Gems:

 - rubygems
 - nokogiri
 - getopt
 - selenium-webdriver
 - phantomjs
 - fileutils
 - terminal-table
 - net-ping
 - highline

 Usage
 =====

 ```
$ agm.rb -h

Usage: agm.rb -[bcdhlmorsvwg:u:p:t:]

-V:	Display version information
-h:	Display usage information
-g:	Specify Gateway IP or hostname
-u:	Specify Gateway username
-p:	Specify Gateway password
-s:	Display Status
-d:	Display DHCP Leases
-w:	Display Wireless Information
-b:	Display Broadband Status
-l:	Display System Logs
-o:	Display Overview
-r:	Reboot Gateway
-c:	Check connectivity (reboots gateway is test site is down)
-t:	Test address
-m:	Mask values
-v:	Verbose mode
```

Examples
========

Connect to router and display status

```
$ agm.rb -s -g 192.168.1.254 -u admin -p blah
+----------------------------------+-------------------------------+
|                        Status Information                        |
+----------------------------------+-------------------------------+
| Item                             | Value                         |
+----------------------------------+-------------------------------+
| Standard Specification Compliant | XuroXXXXXX X.X and XXXXXX X.X |
+----------------------------------+-------------------------------+
| Hardware Version                 | XXXXXXX-XXX                   |
+----------------------------------+-------------------------------+
| Software Version                 | XXXX_XXXXXX                   |
+----------------------------------+-------------------------------+
| Software Version(Linux)          | X.X.XX.XX.XX.XX               |
+----------------------------------+-------------------------------+
| Cable MAC Address                | XX:XX:XX:XX:XX:XX             |
+----------------------------------+-------------------------------+
| Device MAC Address               | XX:XX:XX:XX:XX:XX             |
+----------------------------------+-------------------------------+
| Cable Modem Serial Number        | XXXXXXXXXXXXX                 |
+----------------------------------+-------------------------------+
| CM certificate                   | Installed                     |
+----------------------------------+-------------------------------+
| System Up Time                   | X XXys XXh:XXm:XXs            |
+----------------------------------+-------------------------------+
| Network Access                   | Allowed                       |
+----------------------------------+-------------------------------+
| Cable Modem IP Address           | XX.XXX.XX.XXX                 |
+----------------------------------+-------------------------------+
```

Reboot gateway (default gateway address and saved username/password):

```
$ agm.rb -r
```

Check gateway (default gateway address and saved username/password):

```
$ agm.rb -c
```

Display broadband status (default gateway address and saved username/password):

```
$ agm.rb -b
+-----------------+--------------------------+
|           Broadband Information            |
+-----------------+--------------------------+
| Item            | Value                    |
+-----------------+--------------------------+
| IP Address      | XXX.XXX.XXX.XXX          |
+-----------------+--------------------------+
| IPv6 Address    | ----::----               |
+-----------------+--------------------------+
| Duration        | D: 00 H: 01 M: 00 S: 00  |
+-----------------+--------------------------+
| Expires         | Sun Dec 21 16:48:23 2014 |
+-----------------+--------------------------+
| Subnet Mask     | XXX.XXX.XXX.X            |
+-----------------+--------------------------+
| Default Gateway | XXX.XXX.XXX.X            |
+-----------------+--------------------------+
| Primary DNS     | XX.X.XXX.XX              |
+-----------------+--------------------------+
| Secondary DNS   | XX.X.XXX.XXX             |
+-----------------+--------------------------+
```

Display logs (default gateway address and saved username/password):

```
$ agm.rb -l

+-------------------------------+-------+----------------------------+------------------------+-------------------------+
|                                                      System Logs                                                      |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Description                   | Count | Last Occurence             | Target                 | Source                  |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| IP packet w/MC or BC SRC addr |  8    |  Sun Aug 03 02:12:16 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XX.XX.XXX:XXXXX    |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  60   |  Sun Aug 03 09:35:17 2014  |  XXX.X.X.XXX:XX        |  XXX.XXX.X.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| SYN Flood                     |  1    |  Sun Aug 03 10:01:25 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XXX.XX.XX:XXXXX    |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  31   |  Sun Aug 03 13:38:37 2014  |  XXX.X.X.XXX:XX        |  XXX.XXX.X.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| SYN Flood                     |  1    |  Sun Aug 03 13:40:21 2014  |  XXX.XXX.X.XX:XXXXX    |  XX.XXX.XXX.XXX:XXXXX   |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  15   |  Sun Aug 03 16:43:27 2014  |  XXX.X.X.XXX:XX        |  XXX.XXX.X.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| SYN Flood                     |  1    |  Sun Aug 03 17:33:16 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XX.XXX.X:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  5    |  Sun Aug 03 17:43:27 2014  |  XXX.X.X.XXX:XX        |  XXX.XXX.X.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| SYN Flood                     |  2    |  Sun Aug 03 18:10:23 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XX.XX.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| IP packet w/MC or BC SRC addr |  3    |  Sun Aug 03 18:31:37 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XXX.XXX.XXX:XXXX   |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  5    |  Sun Aug 03 18:42:06 2014  |  XXX.X.X.XXX:XX        |  XXX.XXX.X.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| IP packet w/MC or BC SRC addr |  3    |  Sun Aug 03 18:48:58 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XXX.XXX.XXX:XXXX   |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  270  |  Tue Aug 05 00:06:59 2014  |  XXX.X.X.XXX:XX        |  XXX.XXX.X.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| SYN Flood                     |  1    |  Tue Aug 05 00:22:14 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XXX.XXX.XXX:XXXXX  |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  888  |  Fri Aug 08 22:55:27 2014  |  XXX.X.X.XXX:X         |  XXX.XXX.X.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| SYN Flood                     |  2    |  Fri Aug 08 23:48:29 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XXX.XXX.XXX:XXXXX  |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  236  |  Sun Aug 10 07:06:58 2014  |  XXX.X.X.XXX:X         |  XXX.XXX.X.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| SYN Flood                     |  2    |  Sun Aug 10 07:46:28 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XX.XXX.XXX:XXXXX   |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  30   |  Sun Aug 10 13:06:57 2014  |  XXX.X.X.XXX:X         |  XXX.XXX.X.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| IP packet w/MC or BC SRC addr |  4    |  Sun Aug 10 13:32:24 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XX.XXX.XXX:XXXXX   |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  150  |  Tue Aug 12 04:13:04 2014  |  XXX.X.X.XXX:X         |  XXX.XXX.X.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| IP packet w/MC or BC SRC addr |  11   |  Tue Aug 12 09:05:38 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XXX.XXX.XXX:XX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  71   |  Thu Aug 14 09:32:11 2014  |  XXX.X.X.XXX:X         |  XXX.XXX.X.XX:XXXXX     |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| SYN Flood                     |  1    |  Fri Aug 15 07:34:36 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XXX.XXX.XXX:XXXXX  |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| IP packet w/MC or BC SRC addr |  17   |  Fri Aug 15 10:09:34 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XXX.XX.XXX:XXXX    |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  232  |  Sat Sep 20 17:26:34 2014  |  XXX.XXX.XXX.XXX:XXXX  |  XXX.XXX.X.XX:XXX       |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| IP packet w/MC or BC SRC addr |  2    |  Sat Sep 20 21:39:38 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XXX.XX.XXX:XXXXX   |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  216  |  Mon Oct 13 10:19:36 2014  |  XXX.X.X.XXX:XX        |  XXX.XXX.X.XX:X         |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| IP packet w/MC or BC SRC addr |  1    |  Tue Oct 14 09:27:02 2014  |  XXX.XXX.X.XX:XXXXX    |  XXX.XXX.XXX.XXX:XXXXX  |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
| Teardrop or derivative        |  738  |  Sat Dec 20 03:44:51 2014  |  XXX.XXX.XXX.XXX:XX    |  XXX.XXX.X.XX:XXXX      |
+-------------------------------+-------+----------------------------+------------------------+-------------------------+
```