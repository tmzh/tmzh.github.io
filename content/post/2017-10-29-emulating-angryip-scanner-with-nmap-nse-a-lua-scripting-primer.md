---
author: tmzh
categories:
- Scripting
comments: true
date: "2017-10-29T12:08:28Z"
slug: 2017-10-29-emulating-angryip-scanner-with-nmap-scripting-engine-a-lua-scripting-primer
tags:
- lua
- nmap
- network-discovery
title: Emulating Angry IP Scanner with nmap scripting engine - A lua scripting primer
---
Often we have to discover the devices on a network. I use a very simple nmap command for performing a pingsweep. 

`sudo nmap -sn <subnet or ip range>`

On my Windows PC, I wrap it around in a batch script and place it in the search PATH. On Linux, it can be dropped in as an alias in bashrc.

<!--more-->

It is handy, but not complete. I would like to have some extra information such as hostnames (collected by various means not just DNS reverse lookup), platform info etc., Such details are available in tools such as AngryIP scanner, but I don't prefer to launch a GUI tool for single task and keep it running until the task is done. 

So let us try to implement a similar function using nmap script. There are existing scripts in nmap which performs advanced discovery and reconnaissance, but we want something lightweight, more generic and customizable to support more protocols. Nmap scripts run on top of Nmap Scripting Engine which runs on Lua. Learning it would expand the scope of these tools from just being a capable tool to a powerful tool with limitless possibilities. 

Although this was my first attempt at Lua scripting, the endeavour turned out to be fairly simple. True it was not without its share of frustrations, most of which were related to wrapping my head around the way NSE (Nmap Scripting Engine) tosses the data around and lua data structures. But once you get the hang of it, it is really simple. So without much ado, let us get started.

## NSE Script structure
A basic NSE script will have the following 3 sections: 
- The Head section is for meta information about the script. We need not worry about it for primer purpose but it is a good habit to put documentation info here while packaging the script for production. This section also feeds in to the NSE Documentation module ([NSEDoc](https://nmap.org/book/nsedoc.html)) which provides a consistent way to represent the meta information about our script.
- The RULE section determines the scope of the script. It basically acts as a filter of nmap port-scan results that gets filtered to the Action section. The rule section should contain one of the following functions:
  - prerule()
  - hostrule(host)
  - portrule(host, port)
  - postrule()
- The Action section is mostly the brain of the script (although rule section can also contain some of the script logic). This section contains an Action section which reads data from the nmap scanning engine and carries out the script logic. The value returned by this function is also printed on the screen and captured by other nmap output methods. Note that this script is executed iteratively over either list of hosts or a list of (host, port) tuples. The ACTION section is indicated by the presence of a function named `action`.

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

Now take a minute or two to let this sink in... we just created our very own NETBIOS scanner, all in just 7 lines of functional code. There are dedicated standalone [tools](http://unixwiz.net/tools/nbtscan.html) that performs this singular task and we managed to do it using nmap. With just a little more effort, we can add more bells and whistles to this.

The magic that enables this are the excellent inbuilt scanning mechanisms of nmap and hot-pluggable libraries that carry out much of the grunt. By scripting in NSE, we can tap in to this massive capabilities of nmap and automate to our needs. Let us now see how this script works.

## Code Walkthrough
In this script there is no HEAD section. So we start by importing the libraries needed for our script. In Lua, modules are included using `require` function. And we assign the module to a local variable in order to access its namespace (i.e, call the methods that belong to the module). 

```lua
local netbios = require "netbios"
local shortport = require "shortport"
```
The purpose of these libraries will be evident in the later section. 

### RULE section
Next we move to the RULE section. Notice that in Lua, comments are prepended by `--` sequence. 

As mentioned earlier, RULE section acts as filter to identify hosts or ports relevant to our script. Since our script is only interested with NETBIOS query, we have to pick only the hosts that are listening on port UDP/137.

Since this is a common check, nmap includes a 'shortport' module that provides shorthand functions to check port states. `shortport.portnumber` is one such function which will return true only for those ports and protocols listed in its arguements. Refer to online [documentation](https://nmap.org/nsedoc/lib/shortport.html) for exact syntax of this function.

```lua
-- The Rule Section --
portrule = shortport.portnumber({137}, "udp")
```
>NOTE: The Rule section only filters port numbers passed on from the upper layer i.e, the original nmap scan. It doesn't trigger a port scan on its own. That is why when we launch the script, we had to specify port number explicitly (`nmap -sU -p U:137 <host>`). It is still possible to launch a port scan in this section, by calling nmap socket libraries but those are advanced scripting scenarios.

### ACTION Section
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
>NOTE: In Lua functions are assigned to a variable like how we assign a string or integer value to a variable. In this case, code block defining the ACTION logic is assigned to a variable called action. 
>Lua functions are of the format `foo = function ( args ) body end`. It can be defined in a single line. To call the function, call the variable with argument such as `foo('bar')` 

## Where to go next
Since this is only a basic script, we have not customized the output format at all. The hostnames when available gets printed below each host-discovered. If you notice, the print action is executed within the ACTION function whose scope is limited to one host at a time. If we need our output to be consolidated in a tabular form, we can write a postrule function, store and retrieve our findings from nmap registry. Refer to my [script](https://raw.githubusercontent.com/tmzh/Nmap-scripts/master/hostinfo-discover.nse) (work in progress) to see one way of doing it.

I strongly recommend to try this [walkthrough](https://thesprawl.org/research/writing-nse-scripts-for-vulnerability-scanning/) as well. It greatly helped me to get started with NMAP scripting and understanding the way a NSE script is structured.

It won't hurt to improve your understanding of Lua programming language as well. I found this 15 minute [primer](http://tylerneylon.com/a/learn-lua/) to be very useful.

Lastly the best resource for advanced nmap script writing is the existing script library. There are hundreds of scripts and libraries available, study and explore them to see different ways of tackling a challenge. Good luck scripting!