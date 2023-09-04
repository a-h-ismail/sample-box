# Sample Box

## First step: reconnaissance

Run nmap
```sh
nmap 192.168.122.115 -p-

Nmap scan report for 192.168.122.115
Host is up (0.00019s latency).
Not shown: 65528 closed tcp ports (conn-refused)
PORT      STATE SERVICE
22/tcp    open  ssh
80/tcp    open  http
139/tcp   open  netbios-ssn
445/tcp   open  microsoft-ds
20064/tcp open  unknown
36111/tcp open  unknown
40000/tcp open  safetynetp
```

Now for the more detailed scan:

```sh
nmap 192.168.122.115 -p22,80,139,445,20064,36111,40000 -A

Nmap scan report for 192.168.122.115
Host is up (0.00091s latency).

PORT      STATE SERVICE     VERSION
22/tcp    open  ssh         OpenSSH 8.4p1 Debian 5+deb11u1 (protocol 2.0)
| ssh-hostkey: 
|   3072 52c5bae471d5068169c4695fdaab82ab (RSA)
|   256 0af1501cb06d16b0a9a67fca96f5783a (ECDSA)
|_  256 1457af29583f5d905d41a7c33c86df6d (ED25519)
80/tcp    open  http        Apache httpd 2.4.56 ((Debian))
|_http-server-header: Apache/2.4.56 (Debian)
|_http-title: CCFE web service
139/tcp   open  netbios-ssn Samba smbd 4.6.2
445/tcp   open  netbios-ssn Samba smbd 4.6.2
20064/tcp open  tcpwrapped
36111/tcp open  tcpwrapped
40000/tcp open  safetynetp?
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Host script results:
| smb2-security-mode: 
|   311: 
|_    Message signing enabled but not required
|_nbstat: NetBIOS name: SAMPLE-BOX, NetBIOS user: <unknown>, NetBIOS MAC: 000000000000 (Xerox)
| smb2-time: 
|   date: 2023-05-17T18:17:17
|_  start_date: N/A

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 154.62 seconds
```

Now we try what we can do with each port:

## Port 22

An SSH server, we have no username or password or SSH key. Ignoring...

## Port 139/445

These are the ports for an SMB server, perform an anonymous login using your file manager, get the first flag:<br>
`Flag: Off to a good start! - 10 points`

## Port 20064

Connect using nc:

```sh
nc 192.168.122.115 20064
V2VsbCB0aG91Z2h0IQpGbGFnOiBDaGFuZ2luZyBlbmNvZGluZyBpcyBub3QgZW5jcnlwdGlvbiwgb2s/IC0gMTUgcG9pbnRz
```

The port number has `64` in its end (hopefully this hint will be enough to know base64). Decode the string:

```sh
echo "V2VsbCB0aG91Z2h0IQpGbGFnOiBDaGFuZ2luZyBlbmNvZGluZyBpcyBub3QgZW5jcnlwdGlvbiwgb2s/IC0gMTUgcG9pbnRz" \
| base64 --decode
Well thought!
Flag: Changing encoding is not encryption, ok? - 15 points
```

## Port 40000

A reverse shell (sandboxed with firejail)

```sh
nc 192.168.122.115 40000
whoami
restricted

ls
Flag.txt

cat Flag.txt
Associate diary 

The webserver admin is among the clumsiest to ever exist. He uses a strong password but reuses it everywhere. 

Flag: Bad password practices – 10 points
```

- Access to /var/www;/root;/usr/lib/cgi-bin;/etc;/var/log is restricted to protect the web application and usernames
- The home directory of "restricted" is owned by root, and is read only for the restricted user


## Port 80

The general idea:

- Load the Homepage.
- Try command injection on latency tool -> nothing
- Try command injection on nslookup tool: Doesn't work with ';' (cuts the first field with delimiter ';'),
other attempts award a Flag and a cookie string
- Run `dirb`, find `robots.txt`. Follow link to login.sh
- Try SQL injection, nothing (impossible level protection)
- Remember that you got a cookie. Use Burpsuite to modify http request to admin.sh and include the cookie.
- Access granted to `admin.sh` , SQL injection in the ID query field reveals the admin password. (remember to always include the cookie)

## Port 22, continued

Login to the `webadmin` user using the credentials obtained.

```sh
ssh webadmin@Box_IP

webadmin@final-box:~$ cat Flag.txt 
The server admin granted me some extra privileges using an alternative user. I can su into it with a password.
Just in case I forget the password, I made this super secure recovery procedure:

A file somewhere can be used to reconstruct the password.
- Each fragment is stored in a line strating with "CCF:"
- A total of 5 fragments exist
- Get each fragment and reverse their order (example frag3,frag2,frag1 becomes frag1,frag2,frag3)
- Replace '{' with 'V', ')' with 'Y' and '*' with 'Z'
- base64 decode the string -> get password

Flag: Bad password practices backfires! - 20 points

```

The file must be somewhere in the system, you can use ls or tree to inspect possible locations.
Run `tree` on the home directory:

```sh
webadmin@sample-box:~$ tree -a /home
/home
├── restricted
│   └── Flag.txt
├── supadmin
│   └── .secrets
└── webadmin
    ├── .bash_logout
    ├── .bashrc
    ├── Flag.txt
    └── .profile
```

We can see the hidden file in the `supadmin` home. It is a binary file (check with `file` command), and the `strings` tool is not installed.
`grep` can treat binary files as normal with the `-a` option.

`grep -a '^CCF:' /home/supadmin/.totally_innocent | cut -f 2 -d : | tac | tr -d '\n' | tr '{' V | tr ')' Y | tr '*' Z | base64 --decode`
We get: `correcthorsebatterystaple`

We saw the supadmin user, so login to it using `su - supadmin`

## Escalate privileges

- Read `/etc/os-release`: Debian based system.
- Run `sudo -l`: We can use tee without password.

There are multiple ways to pull this off with `tee`, the simplest in my opinion is:

- Create a copy of `/etc/group` that is user writable: `cat /etc/group > /tmp/group`
- Edit the temporary copy using `nano`, add the supadmin to group `sudo` (superuser group on Ubuntu/Debian).
- Use `tee` to write the modified group file to the system one.
- Remove the temporary file.

Logout then login to `supadmin`, and you have root now using `sudo`!

## All Flags

Flags:9 (145 points)

- Flag: Off to a good start! - 10 points (SMB anonymous login)
- Flag: Changing encoding is not encryption, ok? - 15 points (decode base64 on port 20064)
- Flag: Bad password practices – 10 points (reverse shell on port 40000)
- Flag: Deja vu - 10 points (in robots.txt)
- Flag: Command injection attempted - 20 points (trying command injection on nslookup tool)
- Flag: Never trust user input - 15 points (SQLi on admin page)
- Flag: Bad password practices backfires! - 20 points (SSH to webadmin)
- Flag: With great power comes great responsibility - 40 points (SSH to root using private key and password)
