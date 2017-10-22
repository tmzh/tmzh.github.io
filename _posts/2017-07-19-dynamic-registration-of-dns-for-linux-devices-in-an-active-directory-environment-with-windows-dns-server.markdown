---
author: thamizh85
comments: true
date: 2017-07-19 15:43:13+00:00
layout: post
link: https://ephemeralelectrons.wordpress.com/2017/07/19/dynamic-registration-of-dns-for-linux-devices-in-an-active-directory-environment-with-windows-dns-server/
slug: dynamic-registration-of-dns-for-linux-devices-in-an-active-directory-environment-with-windows-dns-server
title: Dynamic registration of DNS for Linux devices in an Active Directory environment
  with Windows DNS server
wordpress_id: 16
categories:
- SysAdmin
tags:
- DHCP
- DNS
- Dynamic DNS
- Linux
---

While Linux has proliferated extensively in the server arena in the recent past, client networks are still dominated by Windows devices. This means, things that we take for granted in a client environment such as DDNS are not as matured as they are in Windows environment. One may ask whether the recent surge in Linux based clients such as IoT devices has changed this equation. But the nature of these devices is different from Windows based clients that they mostly rely on outbound connection to internet. Since they seldom require other hosts to initiate connection to them, their operation doesn't rely much on Dynamic DNS.

So, what does it take to make a Linux client register dynamically in a Windows environment? At its basic, the entire process relies on Dynamic DNS as explained in [RFC2136](https://tools.ietf.org/html/rfc2136). In a traditional windows environment with AD, this process is taken care by client OS. Every time a Windows PC gets an IP address from DHCP server, it would send a DNS Update (Opcode = 5) request to its registered DNS server. Performed manually, this is same as typing “ipconfig /registerdns” at an elevated command prompt. This behaviour can be modified by accessing DNS section of Advanced TCP/IP settings of a network adapter.

![1 - DNS Properties.png](https://ephemeralelectrons.files.wordpress.com/2017/07/1-dns-properties.png)

When we ask a Linux client to do the same (later I will explain how it can be configured to ask), it won’t work unless the DNS server is configured to accept “Insecure updates” (Which is a major security risk if you need to ask).

Take a look at the capture of Linux client performing DNS update, you can see that the server comes back with a UPDATE REFUSED response.

![2 - Linux DNS Update Capture.png](https://ephemeralelectrons.files.wordpress.com/2017/07/2-linux-dns-update-capture.png)

This is because our DNS server is enabled with secure updates which means only authenticated clients can send update.

![3 - DNS Secure Updates option.png](https://ephemeralelectrons.files.wordpress.com/2017/07/3-dns-secure-updates-option.png)

The client is expected to send a transaction signature along with the update request. There are different types of signatures such as a TSIG resource or the SIG(0) or GSS-TSIG signatures. In Windows world however, only GSS-TSIG signatures as described in [RFC3645](https://tools.ietf.org/html/rfc3645) are understood and accepted.

Looking at a capture from a Windows PC joined to domain, one can see the Windows Device sending Update request with GSS-TSIG resource.

![2 - Windows DNS Update Capture.png](https://ephemeralelectrons.files.wordpress.com/2017/07/2-windows-dns-update-capture.png)

Given this background, let us explore some of the options available to setup DDNS for Linux based clients. In this series of posts, I will explore 3 options:
  1. Configure DHCP server to perform DNS registration on behalf of the clients
  2. Join the Linux devices to AD domain and configure them to dynamically update
  3. Setup a new sub-domain running a dedicated Linux BIND server and configure DNS forwarding on Microsoft DNS server.


Our environment has the following setup:
  1. Microsoft Active Directory environment with DNS server installed in Domain controller and a DHCP server running separately on a different host. All are running on Windows Server 2008 R2.
  2. DNS is configured to accept only Secure updates.
  3. Two Linux devices running Debian Stretch operating system. One of them will act as DNS server in one of the scenarios.


![4 - Lab Topology.png](https://ephemeralelectrons.files.wordpress.com/2017/07/4-lab-topology.png)

The solutions we discuss should meet the following objectives:
  1. Update DNS when the device gets an IP address
  2. Perform periodic update to DNS server to protect against expiry
  3. Fully automated with very little or no hand-coding on client devices, assume no automation tools like Puppet or Chef
  4. Scalable to hundreds or thousands of devices


Point 3 is important to me since I had to work out a solution at work where we are using hundreds of Raspberry Pi’s, all booting the same image cloned on to flash disks. So, editing config files on each of them is not an option (we will come to this later).


* * *

## Configuring DHCP server to perform DNS registration on behalf of the clients


This is the simplest and most reliable solution of the available options. This method makes use of DHCP option 81 as defined in [RFC4702](https://tools.ietf.org/html/rfc4702), which is used to convey a client’s FQDN to a DHCP server as part of DHCP process.


<blockquote>An aside: RFC doesn’t mandate whether a DHCP server should register client’s DNS or not. It is left to site-specific policies, which may differ per the security context of the site.</blockquote>


The default setting in a Microsoft DHCP server scope is as follows (Right click on scope name -> Properties to reach here):

![5 - Default scope properties.png](https://ephemeralelectrons.files.wordpress.com/2017/07/5-default-scope-properties.png)

Understandably, this only updates to DNS server if requested by the client. What happens if we select the option to “Always dynamically update DNS A and PTR records”? Is that what we want?

![6 - Always dynamically update.png](https://ephemeralelectrons.files.wordpress.com/2017/07/6-always-dynamically-update1.png)

If you trigger a DHCP request from the client, you will notice that this doesn’t work.

![7 - No DNS Update.png](https://ephemeralelectrons.files.wordpress.com/2017/07/7-no-dns-update.png)

This setting merely controls whether a DHCP server should update ‘A’ record or not.  The label “Always dynamically update DNS A and PTR records” is misleading since it applies only for the clients that request a DNS update. By default, a client is responsible for updating the A record and DHCP server is responsible for updating the PTR record. Selecting the second option forces DHCP server to update A record as well. But the prerequisite is that the client should request for DNS update.

![8 - DNS Update options.png](https://ephemeralelectrons.files.wordpress.com/2017/07/8-dns-update-options.png)

The two options above correspond to the two cases discussed in [RFC4702](https://tools.ietf.org/html/rfc4702)

![9 - RFC 4702.png](https://ephemeralelectrons.files.wordpress.com/2017/07/9-rfc-4702.png)

For our Linux clients, the option we need is the last check box. Let us turn this on and trigger a DHCP request from our client.

![10 - Dynamically update for Linux clients.png](https://ephemeralelectrons.files.wordpress.com/2017/07/10-dynamically-update-for-linux-clients.png)

When we check the DNS server, we can see that the A record successfully is created.

![11 - Successful Registration.png](https://ephemeralelectrons.files.wordpress.com/2017/07/11-successful-registration.png)

On the capture, we can see secure DNS update message being sent from the DHCP server (Note that the DNS clients always tries insecure updates first and gets rejected by the server).

![12 - Successful Registration Packets.png](https://ephemeralelectrons.files.wordpress.com/2017/07/12-successful-registration-packets.png)

For a home environment, this is almost enough. But for production environments, with multiple DHCP servers, this is not enough. The problem is that, in such setup the DHCP server becomes the owner of the A and PTR records (see below). It is fine as long as the DHCP server is alive to create and remove records. But when it goes down, its peer DHCP server won’t be able to do anything about those records.

![13 - A record owner.png](https://ephemeralelectrons.files.wordpress.com/2017/07/13-a-record-owner.png)

This [link](https://technet.microsoft.com/en-us/library/dd334715(v=ws.10).aspx) explains the issue in more detail. Let us follow the advice, create a dedicated user account for updating DNS and delete the old record with DHCP server as owner. Do not grant any extra privilege to this account. Just adding to DNSUpdateProxy group should be sufficient (Right click on IPv4 -> Properties -> Advanced).

![14 - Dynamic update credentials.png](https://ephemeralelectrons.files.wordpress.com/2017/07/14-dynamic-update-credentials.png)

As usual, let us go ahead to trigger an update.

![15 - DHCP Request.png](/images/2017-07-19-dynamic-registration-of-dns-for-linux-devices-in-an-active-directory-environment-with-windows-dns-server/15-dhcp-request.png)

As expected, new A and PTR record gets created.

![16 - Successful Registration.png](https://ephemeralelectrons.files.wordpress.com/2017/07/16-successful-registration.png)

If we check the ownership, we can find that the record is owned by DNSProxyUpdate group.

![16 - Dynamic update credentials.png](https://ephemeralelectrons.files.wordpress.com/2017/07/16-dynamic-update-credentials1.png)





* * *



Finally, let us discuss the option called “Name Protection” at the bottom of the dialog box.

![17 - Name Protection.png](https://ephemeralelectrons.files.wordpress.com/2017/07/17-name-protection.png)

This forces DHCP server to manage the entire lifecycle of your client’s A and PTR records. If you are going to let your DHCP server manage client’s A record, I don’t see any reason to keep this disabled. It will also protect you from “[Name Squatting](https://technet.microsoft.com/en-us/library/dd759188(v=ws.11).aspx)” by offline clients. [RFC4701 ](https://tools.ietf.org/html/rfc4701)describes the problem as:

![18 - RFC4701.png](https://ephemeralelectrons.files.wordpress.com/2017/07/18-rfc4701.png)

Let us see what it means to turn on this option. First, we keep it disabled and bring two clients online with same hostname, one after other. All is well when the first client comes online and gets an IP address 192.168.179.50.

![19 - DHCP Request.png](https://ephemeralelectrons.files.wordpress.com/2017/07/19-dhcp-request.png)

DNS also gets updated accordingly.

![20 - DNS Update.png](https://ephemeralelectrons.files.wordpress.com/2017/07/20-dns-update.png)

Let us bring another Linux client online and change the hostname to same as this host. Then perform a DHCP request from this host.

![21 - Hostname change.png](https://ephemeralelectrons.files.wordpress.com/2017/07/21-hostname-change.png)

![22 - DHCP Request.png](https://ephemeralelectrons.files.wordpress.com/2017/07/22-dhcp-request.png)

DHCP server assigns IP address 192.168.179.51 and sends an update to DNS server. Note that the DHCP server makes no fuss about two hosts sharing the same hostname. For all it knows, it could be the same host with multiple interfaces.

![23 - DHCP Update.png](https://ephemeralelectrons.files.wordpress.com/2017/07/23-dhcp-update.png)

On the DNS sever side, we see that it accepts this update without any hesitation. The only problem is that this overwrites the existing record, while the client is still online. So, anyone trying to talk the first node ends up talking to the second node.

![24 - DNS overwritten.png](https://ephemeralelectrons.files.wordpress.com/2017/07/24-dns-overwritten.png)

Clearly, DHCP server is not a reliable source of identity. RFC4703 briefly mentions the inability of DHCP server to provide any sort of assurance.

![25 - RFC4703.png](https://ephemeralelectrons.files.wordpress.com/2017/07/25-rfc4703.png)

Let us see what happens when we enable “Name Protection”.

![26 - Enable Name Protection.png](https://ephemeralelectrons.files.wordpress.com/2017/07/26-enable-name-protection.png)

As soon as we enable this option, first thing we notice is that all other options are greyed out. This is because, with Name Protection enabled, it is always the responsibility of DHCP server to perform both A record and PTR record updates.

Let us wipe the slate clean, by releasing IP address from both the clients and deleting the existing DNS & DHCP records.

Now when you bring the first Linux client online, you can see that the DHCP server performs a new type of record registration called DHCID.

![27 - Successful DHCID Capture.png](https://ephemeralelectrons.files.wordpress.com/2017/07/27-successful-dhcid-capture.png)

A new record type DHCID appears in the DNS server.

![28 - Successful DHCID registered.png](https://ephemeralelectrons.files.wordpress.com/2017/07/28-successful-dhcid-registered.png)

Let us bring up the impostor and request DHCP address. It gets an IP address of 192.168.179.51.

![29 - DNS Impersonation.png](https://ephemeralelectrons.files.wordpress.com/2017/07/29-dns-impersonation.png)

As usual, DHCP server is very generous about having two hosts sharing the same hostname.

![30 - Duplicate DHCP Update.png](https://ephemeralelectrons.files.wordpress.com/2017/07/30-duplicate-dhcp-update.png)

But no new DNS entry is created.

![31 - Name protection success.png](https://ephemeralelectrons.files.wordpress.com/2017/07/31-name-protection-success.png)

Looking at the capture, we can see that the DNS registration fails with a response that RRset does not exist.

![32 - DNS Update refused capture.png](https://ephemeralelectrons.files.wordpress.com/2017/07/32-dns-update-refused-capture.png)

This message means that DHCID value calculated from the new update packet doesn’t match with any DHCID RR’s stored in the server. This behaviour is described in [RFC4701](https://tools.ietf.org/html/rfc4701).

![33 - RFC4701.png](https://ephemeralelectrons.files.wordpress.com/2017/07/33-rfc4701.png)

This is as much as we need to know about configuring a Microsoft DHCP server to perform Dynamic DNS for Linux clients. In the upcoming posts, let us explore the other two options.
