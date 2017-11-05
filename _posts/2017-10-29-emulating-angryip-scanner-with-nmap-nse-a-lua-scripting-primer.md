---
author: thamizh85
comments: true
date: 2017-10-29 12:08:28+08:00
layout: post
slug: emulating-angryip-scanner-with-nmap-scripting-engine-a-lua-scripting-primer
title: Emulating angryip scanner with nmap scripting engine - A lua scripting primer
categories:
- Scripting
tags:
- lua
- nmap
- network-discovery
---
##Introduction
Often we have to discover the devices on a network. I use a very simple nmap command for performing a pingsweep. 

`sudo nmap -sn <subnet or ip range>`

On my work PC which runs Windows, I wrap it around in a handy batch script and place it in the search PATH. On Linux it can be dropped in as an alias in bashrc.

It is handy, but not complete. I would like to have some extra information such as hostnames (collected by various means not just DNS reverse lookup), platform info etc., Such details are available in tools such as AngryIP scanner, but I don't prefer to launch a GUI tool for single task and keep it running until the task is done. 

So I wanted to see if a similar function can be implemented using nmap script. There are existing scripts in nmap which performs advanced discovery and reconnaissance, but I wanted something lightweight, one which is least intrusive and outputs results in the format I desire. So I decided to try writing my own script in NSE (Nmap Scripting Engine) which uses Lua language. I always wanted to learn Lua since it is the language of choice for two of my favorite platforms, Wireshark and Nmap. Learning it would expand the scope of these tools from just being a capable tool to a powerful tool with limitless possibilities. 

The endeavour turned out to be fairly simple, but not without its share of frustrations, most of which were related to wrapping my head around the way NSE (Nmap Scripting Engine) tosses the data around and lua data structures. But once you get the hang of it, it is really simple. So without much ado, let us get started.

##NSE Script structure
A basic NSE script will have the following 3 sections: 
- Head section is for meta information about the script. We can get back to it later while packaging the script. 
- Rule section determines the scope of the script. It basically acts as a filter of nmap port-scan results that gets passed on the Action section. The rule section has to be one of the following:
  - prerule()
  - hostrule(host)
  - portrule(host, port)
  - postrule()
- Action section is mostly the brain of the script (although rule section can also contain some of the script logic). This section contains an Action section which reads data from the nmap scanning engine and carries out the script logic. The value returned by this function is also printed on the screen and captured by other nmap output methods. Note that this script is executed iteratively over either list of hosts or a list of (host, port) tuples. 

##Diving In
So let us go ahead and create a basic script. Our script will scan the target network and fetch the hostname from NETBIOS. Create a script file with .nse (I used host-discover.nse) extension as follows:

```lua
local netbios = require "netbios"
local shortport = require "shortport"

-- The Rule Section --
portrule = shortport.portnumber({137}, "udp")

-- The Action Section --
action = function(host,port)
    local nbt_status, netbios_name = netbios.get_server_name(host)
    return netbios_name
end
```
Now run this script against your local network as below:

`nmap --script host-discover.nse 10.1.1.0/24 -sU -p 137`

There you go, you have your very own NETBIOS scanner, all in just 7 lines of code. Now give that a moment to sink in. There are standalone tools that exists just to perform this singular task and we did it using a generic swiss army knife tool such as nmap. 

The magic that enables this are the excellent scanning mechanisms inbuilt in to nmap and hot-pluggable libraries that carry out much of the grunt. By scripting in NSE, we can tap in to this massive capabilities of nmap and automate to our needs.

## Code Walkthrough
For simplicity sake, I had skipped the HEAD section. First thing you notice is the  Lua's comment syntax. Comments starts with `--`

Next we import the libraries necessary for our script. In Lua, modules are included using `require` function. And we assign the module to a local variable in order to access its namespace (i.e, call the methods that belong to the module). 

```lua
local netbios = require "netbios"
local shortport = require "shortport"
```
The purpose of these libraries will be evident in the later section. 

Next we move to the RULE section. Since our script is only interested with NETBIOS query, we have to pick only the hosts that are listening on port UDP/137.

But determining whether a host is listening on a port is not straightforward,even if nmap parent process has advised you the probable state of the port. We have to check it against few valid states ('open' or 'filtered'). 'shortport' module abstracts this detail from us and allows us to simply filter port status. It is not necessary to use this  module if you can write your own conditions.

```lua
-- The Rule Section --
portrule = shortport.portnumber({137}, "udp")
```
NOTE: The Rule section only filters port numbers passed on from the upper layer i.e, the original nmap scan. It doesn't trigger a port scan on its own. That is why when we launch the script, we had to specify port number explicitly (`nmap -sU U:137 <host>`). It is still possible to launch a port scan in this section, by calling nmap socket libraries but those are advanced scripting scenarios.

Next comes the ACTION section. Our action section here is a function that takes (host, port) as argument. It means the host object and port object are available to this function for evaluating logic. If we need other variables, they have to be declared outside this function.

Since for NETBIOS query we only need the host our action function will take only 'host' as argument. We call the get_server_name function of [netbios](https://nmap.org/nsedoc/lib/netbios.html#get_server_name) module. From the documentation we can see that this function returns two values, query status and query result which we capture under two local variables. For our simple task, we need not check the result status and go ahead to return the name variable directly. In Lua, if a variable doesn't exist it returns nil which is acceptable for our scenario.
```lua
-- The Action Section --
action = function(host,port)
    local nbt_status, netbios_name = netbios.get_server_name(host)
    return netbios_name
end
```
This returned value is processed by nmap scripting engine and printed in the output window. 

http://tylerneylon.com/a/learn-lua/

https://thesprawl.org/research/writing-nse-scripts-for-vulnerability-scanning/



Here are the requirements:
1) Should list all up endpoints on the network
2) Should provide meta information about the endpoint such as hostnames where possible
3) Should use the most common means for extracting this meta info, such NBQUERY, SMB CONNECT, snmp etc.,
4) Should have the ability to 
2) Should be as less intrusive as possible