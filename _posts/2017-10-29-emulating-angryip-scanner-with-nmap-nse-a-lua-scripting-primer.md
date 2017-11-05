---
author: thamizh85
comments: true
date: 2017-10-29 12:08:28+08:00
layout: post
slug: emulating-angryip-scanner-with-nmap-scripting-engine-a-lua-scripting-primer
title: Emulating Angry IP Scanner with nmap scripting engine - A lua scripting primer
categories:
- Scripting
tags:
- lua
- nmap
- network-discovery
---
## Introduction
Often we have to discover the devices on a network. I use a very simple nmap command for performing a pingsweep. 

`sudo nmap -sn <subnet or ip range>`

On my work PC which runs Windows, I wrap it around in a batch script and place it in the search PATH. On Linux it can be dropped in as an alias in bashrc.

It is handy, but not complete. I would like to have some extra information such as hostnames (collected by various means not just DNS reverse lookup), platform info etc., Such details are available in tools such as AngryIP scanner, but I don't prefer to launch a GUI tool for single task and keep it running until the task is done. 

So I wanted to see if a similar function can be implemented using nmap script. There are existing scripts in nmap which performs advanced discovery and reconnaissance, but I wanted something lightweight, one which is least intrusive and outputs results in the format I desire. So I decided to try my hand in writing a script in NSE (Nmap Scripting Engine). The Nmap Scripting Engine, like Wireshark, uses Lua language. Learning it would expand the scope of these tools from just being a capable tool to a powerful tool with limitless possibilities. 

The endeavour turned out to be fairly simple, but not without its share of frustrations, most of which were related to wrapping my head around the way NSE (Nmap Scripting Engine) tosses the data around and lua data structures. But once you get the hang of it, it is really simple. So without much ado, let us get started.

## NSE Script structure
A basic NSE script will have the following 3 sections: 
- Head section is for meta information about the script. We need not worry about it for primer purpose but it is a good habit to put documentation info here while packaging script for production.
- Rule section determines the scope of the script. It basically acts as a filter of nmap port-scan results that gets filtered to the Action section. The rule section has to be one of the following:
  - prerule()
  - hostrule(host)
  - portrule(host, port)
  - postrule()
- Action section is mostly the brain of the script (although rule section can also contain some of the script logic). This section contains an Action section which reads data from the nmap scanning engine and carries out the script logic. The value returned by this function is also printed on the screen and captured by other nmap output methods. Note that this script is executed iteratively over either list of hosts or a list of (host, port) tuples. 

## Diving In
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

Take a minute to gape at the results- you have your very own NETBIOS scanner, all in just 7 lines of functional code. There are standalone [tools](http://unixwiz.net/tools/nbtscan.html) that exists just to perform this singular task and we did it using a generic swiss army knife tool such as nmap. 

The magic that enables this are the excellent inbuilt scanning mechanisms of nmap and hot-pluggable libraries that carry out much of the grunt. By scripting in NSE, we can tap in to this massive capabilities of nmap and automate to our needs.

## Code Walkthrough
For simplicity sake, I had skipped the HEAD section. Next thing you notice is the  Lua's comment syntax. Comments starts with `--`

Next we import the libraries necessary for our script. In Lua, modules are included using `require` function. And we assign the module to a local variable in order to access its namespace (i.e, call the methods that belong to the module). 

```lua
local netbios = require "netbios"
local shortport = require "shortport"
```
The purpose of these libraries will be evident in the later section. 

Next we move to the RULE section. Since our script is only interested with NETBIOS query, we have to pick only the hosts that are listening on port UDP/137.

But determining whether a host is listening on a port is not so trivial. We have to check it against few valid states ('open' or 'filtered'). 'shortport' module abstracts this detail from us and allows us to simply filter port status. It is not necessary to use this  module if you can write your own conditions.

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

## Where to go next
Since this is only a basic script, we have not customized the output format at all. The hostnames when available gets printed below each host-discovered. If you notice, the print action is executed within the ACTION function whose scope is limited to one host at a time. If we need our output to be consolidated in a tabular form, we can write a postrule function, store and retrieve our findings from nmap registry. Refer to my [script](https://raw.githubusercontent.com/thamizh85/Nmap-scripts/master/hostinfo-discover.nse) (work in progress) to see one way of doing it.

I strongly recommend trying the tutorial at this [site](https://thesprawl.org/research/writing-nse-scripts-for-vulnerability-scanning/) for further study. It greatly helped me to get started with NMAP scripting and understanding the way a NSE script is structured.

It won't hurt to improve your understanding of LUA programming language as well. I found this 15 minute [primer](http://tylerneylon.com/a/learn-lua/) to be very useful.

Lastly the greatest resource for advanced nmap script writing is the existing script library. There are hundreds of scripts and libraries available, study and explore them to see different ways of tackling a challenge. Good luck scripting!