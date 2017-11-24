---
author: thamizh85
comments: true
date: 2017-11-24 08:01:28+08:00
layout: post
slug: jumbo-ping-fallacy-using-monte-carlo-simulation-to-model-ping-loss-behavior
title: Jumbo Ping Fallacy: Using Monte-Carlo Simulation to model ping loss behavior
categories:
- Scripting
tags:
- network
- python
- numpy
- probability
- modelling
---
## Background
Recently we had a cabling issue in our core infrastructure which caused around 3 to 12% packet loss across few IP streams. One of my colleagues made an interesting observation that when he tried to ping with large packet size (5000 bytes) the packet loss rose up to 40%. In his opinion, that meant some applications were experiencing up to 40% packet loss. I seldom do large packet ping tests unless I am troubleshooting MTU issues, so to me this observation was interesting. 

At the outset, it may look like an aggravated issue, that some applications relying on large packet sizes experience high packet loss. But once you realize that the ping test results represent ICMP datagram loss and not ethernet frame loss, you will realize that both tests results are the same, but in different units. Interpretting them as two separate test cases is fallacious. Let us explore why.

## Normal ping vs Large ping
In windows a normal ping packet size is 32 bytes and in most environments, the default MTU is 1500 bytes. So a single frame is sufficient to transmit a ping packet. Things get weirder when we ping with large packets. In windows, you can specify the ping packet size using -l option. Note that this size doesn't include the packet header (20 bytes for IP header + 8 bytes for ICMP header). Which means with a 1500 MTU size, we can send only up to 1472 bytes in a single frame. Any length above this must be fragmented.

We can test this easily. Below is the result when pinging with 1472 as the ping size (`ping 8.8.8.8 -n 2 -l 1472`)
```
Capturing on 'Ethernet 2'
    1   0.000000     10.1.1.1 → 8.8.8.8      ICMP 1514 Echo (ping) request  id=0x0001, seq=8/2048, ttl=128
    2   0.015698      8.8.8.8 → 10.1.1.1     ICMP 106 Echo (ping) reply    id=0x0001, seq=8/2048, ttl=45
2 packets captured
```

When we ping with just one more byte, you can see that 2 packets are sent in place of 1 ((`ping 8.8.8.8 -n 2 -l 1473`)

```
Capturing on 'Ethernet 2'
    1   0.000000     10.1.1.1 → 8.8.8.8      IPv4 1514 Fragmented IP protocol (proto=ICMP 1, off=0, ID=4fab)
    2   0.000016     10.1.1.1 → 8.8.8.8      ICMP 35 Echo (ping) request  id=0x0001, seq=10/2560, ttl=128
2 packets captured
```

So when we ping with 5000 bytes, 4 packets are sent. And ICMP protocol considers a datagram to be lost even when one of them fails. So the probability of the ICMP datagram loss is higher than the probability of single frame loss.


But is this what is happening in the ping test result? We can calculate the probability of datagram loss using probability theory but let us defer to it later on and do a numerical simulation first using Monte Carlo simulation.

## Monte Carlo Simulation
[Monte carlo simulation](https://www.wikiwand.com/en/Monte_Carlo_method) is a rather fancy title for a simple simulation using random event generator, but it is quite handy and widely used. Usually Monte Carlo simulation is useful for simulating events that are truly random in nature. In a chaotic backbone network, that handles traffic stream of different kinds, we can assume the frame loss to happen approximately in a random fashion. 

Let us write a short program to simulate random packet loss.  


```python
import random
import numpy as np

sampleCount = 100000                               # total events in our simulation
p = 0.03                                           # ethernet frame loss probability
grpSize = 4                                        # packet count per datagram, 5000 bytes = 4 packets
grpEventCount = int(sampleCount/grpSize)           # datagram count

# generate random packets with p% packet loss
events = np.random.choice([0,1],
                          size=sampleCount,
                          p=[p,1-p])

# group discrete packets into a datagram
grpEvents = events.reshape(grpEventCount,grpSize) 

# function to determine datagram loss
def checkFailure(grpEvent):
    return (np.count_nonzero(grpEvent) < grpSize)    # Return 1 if the success count is less than 3

# count the result
failCount = 0
for grpEvent in grpEvents:
    failCount += checkFailure(grpEvent)
print("The probability of a group failure is {:.2f}%".format(failCount/len(grpEvents)*100))
```

    The probability of a group failure is 11.78%
    

There you see! Even a 3% ethernet frame loss translates to 12% packet loss for jumbo ping test. This is same as what we observed. Does the math agree? 

## Using Probability Theory
If `p` is the probability of a single frame loss, `(1-p)` is the probability of a successful transfer. And a datagram is successful only if all of its frames are successful. So an ICMP datagram which is 4 frame long, will have `(1-p)**4` probability of succesful delivery. To calculate the failure rate, just take its inverse.  

```python
1- (1-p)**4
```
    0.11470719000000007

As expected the simulation is slightly off from the calculated probability. But it will get closer to the real figure when we increase the simulation count.

## Conclusion
The exactness of our calculation hinges on the assumption of random nature of packet loss. While it happened to be close to true in my case, it need not be all the time. The link may be loaded in a bursty manner and since our ping streams are evenly spaced over time, their chances of failure may not be truly random. 


Nevertheless, we should be wary of the difference between a datagram loss and ethernet loss while interpreting results. Consider the MTU of the network path while testing with different packet sizes