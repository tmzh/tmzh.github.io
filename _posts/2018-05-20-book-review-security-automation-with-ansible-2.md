---
author: thamizh85
comments: true
date: 2018-05-20 12:00:00+08:00
layout: post
slug: 2018-05-20-book-review-security-automation-with-ansible-2
title: Book Review - Security Automation with Ansible 2
categories:
- Security
tags:
- review
- ansible
- automation
---

Security is a huge, complex, rapidly changing field. Advancements in infrastructue hosting, development methodologies has had the most impact on this domain. Thanks to automation, instances are spawned and deleted in a matter of second. Continuous development/Continuous Integration means that an average lifetime of a block of code is ever decreasing. Code review and vulnerability assessments based on static code and IP are hardly affordable at current rate of change. At the same time, the rate of proliferation of technology has seen comparable increase in risk vectors, vulnerabilities and attack methodologies. To keep up with this pace, automation in security operations has become more important than ever. 

<!--more-->

Unfortunately even within the CyberSecurity field, this automation domain is quite nascent and has sparse literature. So I was quite excited when I got a chance to review "Security Automation with Ansible 2" by Akash Mahajan and Madhu Akula. Before reading any further, if you are a security engineer struggling with these problems, grab hold of this book. It is quite extensive in scope and examples.  

The book starts with a brief introduction on Ansible, its installation procedures and works its way up to complex workflows, covering all major aspects of security automation. Some of the workflows discussed in the book includes- hardening various types of application deployments, continuous scanning for CICD workflow using Jenkins and OWASP ZAP, automated vulnerability scanning using Nessus, continuous security scans using OpenScap, vulnerability assessments of docker containers and cloud deployments. The book even goes on to discuss peripheral topics such as setup workflows for malware analysis, openstack, debops (Debian-based Data Center), private VPN using algo, anti-censorship software (Streisand) etc., In short you won't find many tools missing in this book. Even if you are a practising expert on security automation, you will find something new to learn or inspired to use. 

Ansible is the engine for all the examples, acting as Swiss army knife to drive the automation of every aspects of security operations. Despite that, the authors didn't discriminate against other automation tools and ignore them. For example, tools such Elasticsearch, AWS Lambda are already built for automation. Ansible's role in these examples is to simplify the deployment of these tools and ensure consistency in deployment of these tools. One might argue this can encourage broader adoption of these tools on disparate workflows.  

If I have any suggestions, I would love to see some of these examples distilled into abstract policies or best practices for DevSec automation. "The practice of System and Network Administration" by Limoncelli is the golden standard for practical IT related writing. In their own words, their book sets out to discuss "those principles and ideas of system administration which do not change on a day-to-day basis". Too much focus on existing tools can potentially affect the longevity of the book. Admittedly this is somewhat harder to do for a field which is still nascent and unpredictable. Irrespective of this, the book is still a valuable resource and every CyberSecurity professional will find it useful. You can find a copy of the book in [Amazon](http://a.co/argCc3H) or [Packt](https://www.packtpub.com/virtualization-and-cloud/security-automation-ansible-2)
