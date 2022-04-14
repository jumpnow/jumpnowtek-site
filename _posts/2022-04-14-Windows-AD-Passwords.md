---
layout: post
title: Passwords in Windows AD
date: 2022-04-14 09:00:00
categories: security
tags: [rdp, nmap, hydra, brute-force]
---

Write up for a Windows Server class assignment.

# Assignment

* Demonstrate a dictionary password attack against Windows Remote Desktop
* Write a Group Policy to lock out accounts after X failed attempts
* Identify where AD stores passwords on disk and how they are protected
* What are Microsoft best practice policies on passwords

Final project will be a video with notes captured here.

## Workstation Setup

* Enable **RDP** service
* Ensure firewall not blocking **RDP** port ([nmap][nmap]?)

(Provide screenshots)

## Dictionary Attack Demonstration

A brute-force attack over a network connection would take far too long so use a dictionary atttack.

* Use an open-source tool like [ncrack][ncrack] or [hydra][hydra]
* Use a common word list (rockyou.txt? something smaller?)
* Show logs of failed and successful attempts

(Provide screenshots)

## Group Policy to Lock Accounts

* Show the account lockout **GPO**
* Demonstrate the account lockout
* Auto-unlock after expiry? (TBD)

(Provide screenshots)

## AD Passwords on Disk

* Where are password stored in AD?
* What hash algorithm is used?
* Are hashes salted, peppered? (encrypted?)

Brute-force attacks against hashes is potentially practical depending on the hash Win AD is using (NTLM?).
A dictionary or hybrid mask attack is likely a better approach ([hashcat][hashcat]).

(Provide screenshots)

## AD Passwords in Memory (maybe)

* Is [mimikatz][mimikatz] still an option with Win Server 2019/ Windows 10?

May not have time to explore this.

## Best Practices

* How is password policy (length, complexity, reuse) configured in AD?
* What are Microsoft recommended best policy practices regarding passwords

(Provide links)


[nmap]: https:/nmap.org
[ncrack]: https://nmap.org/ncrack/
[hydra]: https://www.kali.org/tools/hydra/
[hashcat]: https://hashcat.net/hashcat/
[mimikatz]: https://github.com/gentilkiwi/mimikatz
