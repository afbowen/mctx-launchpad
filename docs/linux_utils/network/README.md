
# Dedicated USB WiFi Interface
There are instances in which it's advantageous to have a separate WiFi interface on a user
computer. For instance, a Raspberry Pi may live within a system where it serves as a wireless
access point (WAP) for its own isolated WiFi network with no Internet connection. To access the
network and the Pi using a computer with a single WiFi interface, one would have to disconnect
from the preferred WiFi network (say, one with Internet access) in order to join the one hosted by
the Pi. This prohibits the user computer from being able to talk to the Internet while talking to
the RPi, making it impossible to control the user computer remotely via SSH or remote desktop.
Adding secondary WiFi interface makes it possible to communicate on both the Pi and the preferred
WiFi network (i.e. Internet) simultaneously.

This document explains how to set up a specific USB WiFi adapter (D-Link AC1300) and configure a
WiFi connection with a Raspberry Pi serving as a WAP for a WLAN that it not connected to the
Internet.

### Glossary
- RPi: Raspberry Pi
- WAP: Wireless Access Point
- WLAN: Wireless Local Area Network
- NIC: Network Interface Controller (USB WiFi adapter, in this case)

### Assumptions
Note that this procedure is making the following assumptions:
- The RPi is serving as a WAP on a network called `Pi_WAP` (`10.20.0.0/24`) with IP `10.20.0.1`
- The user is `pi` and the network password is `raspberry`
- The USB WiFi adapter has device ID `wlx04bad60b3885`
- The user computer is currently set with the correct time (e.g. via an NTP sync over the Internet)
- Procedures are conducted on the user computer
- The TCC's default (built-in) WiFi interface has device ID `wlp61s0`


## Setup D-Link AC1300
The D-Link AC1300 is a compact USB-A WiFi adapter. To use it with a Linux system, minor setup is
required.

### Procedure
1. Add the repository containing the driver for the AC1300's chipset (RealTek RTL8xxx).
   ```
   sudo add-apt-repository ppa:kelebek333/kablosuz
   ```
2. Install the target RealTek chipset drivers (for RTL8822bu).
   ```
   sudo apt-get install rtl8822bu-dkms
   ```
3. Add the driver (RTL88x2bu) as a kernel module.
   ```
   sudo modprobe 88x2bu
   ```
3. Add the driver's name to `/etc/modules` so Linux loads the driver at system boot-up.
   ```
   echo 88x2bu | sudo tee /etc/modules  # Load at boot
   ```


## Configuring the WiFi Connection to the Raspberry Pi WAP
Connecting to the Raspberry Pi WiFi network is as simple as selecting the network through the
standard network settings provided by the Linux OS GUI. That said, it's important to set up the
connection in such a way to mitigate common headaches. This procedure will help ensure that...
- The connection to the Raspberry Pi is only available via the USB WiFi adapter.
    - The user computer's default (built-in) WiFi interface should never try to connect to the RPi.
- The user computer only routes traffic destined for the RPi to the RPi's network.
    - All traffic unrelated to the Pi (Internet requests, etc.) is routed through the default WiFi
      interface to the prefferred network.
- The user computer automatically updates the date and time on the RPi on connection.
    - Since the RPi is on its own isolated network with no Internet connection, it cannot sync its
      clock with NTP servers.
    - Incorrect date/time on the Raspberry Pi can cause confusion when using the system or
      examining timestamps in log files generated on the RPi.

### Procedure
**Note that all of the following sub-procedures must be completed!**
#### Connect and Disable Default Route
1. Complete the `Setup D-Link AC1300` procedure (above).
2. Ensure the user computer is not currently connected to a VPN.
3. Plug in the USB WiFi adapter if it is not already plugged in.
4. Get the USB WiFi adapter's device ID (unplug, re-plug if necessary).
   ```
   nmcli dev
   ```
5. If the target network or "copies" (`Pi_WAP`, `Pi_WAP\ 1`. `Pi_WAP\ 2`, etc.) exist as known
   connections, delete them.
    a. Check if the connection exists in the list of known connections.
       ```
       nmcli con
       ```
    b. Delete the target connection if it exists.
       ```
       sudo nmcli con del Pi_WAP
       ```
6. Ensure the RPi is turned on and check if the target WiFi network (`Pi_WAP`) is visible.
   ```
   nmcli dev wifi
   ```
7. Connect to the target network with the credentials via the USB WiFi interface.
   ```
   sudo nmcli dev wifi connect Pi_WAP password raspberry ifname wlx04bad60b3885
   ```
8. Tell Linux to never use this connection as a default route for traffic (e.g. Internet requests).
   ```
   sudo nmcli con mod Pi_WAP ipv4.never-default yes
   ```

#### Sync RPi Date and Time on Connect
Network interfaces and connections are managed by the `NetworkManager` service. When a network
event occurs (e.g. an interface connects to a network), this service executes scripts in the
`/etc/NetworkManager/dispatcher.d/` directory. This makes it possible to add custom commands to be
executed when network event occurs.
1. Go to the `/etc/NetworkManager/dispatcher.d/` directory.
   ```
   cd /etc/NetworkManager/dispatcher.d/
   ```
2. Create and open a file called `99-user-scripts`.
   ```
   sudo nano 99-user-scripts
   ```
3. Enter the following script text, substituting the name of your USB NIC in for `wlx04bad60b3885`.
   ```
   #!/bin/sh

   IF=$1
   STATUS=$2
   ROUTER=$DHCP4_ROUTERS

   # Handle USB NIC network event involving router `10.20.0.1`
   if [ "$IF" = "wlx04bad60b3885" ] && [ "$ROUTER" = "10.20.0.1" ]
   then
       case $STATUS in
           up)
               # For output log
               echo "UP"

               # Only route traffic destined for the WAP to the WAP (not technically necessary)
               ip route add $DHCP4_ROUTERS via $DHCP4_ROUTERS dev $IF

               # Sync the WAP time to system time
               date_now=$(date "+%Y-%m-%d")
               time_now=$(date "+%T")
               cmd="sudo date -s '$date_now $time_now'"
               ssh pi@$DHCP4_ROUTERS $cmd
               ;;
           *)
               echo "NOT UP"
               ;;
           esac

   # Handle USB NIC network event involving anything other than router `10.20.0.1`
   # Since access to some networks is controlled via SSL certificate (not password), all network
   # devices connected to the computer holding the cert are eligible to connect. This means that a
   # USB NIC might try and connect to .cruisecorp when it should be reserved for a Raspberry Pi
   # router.
   elif [ "$IF" = "wlx04bad60b3885" ] && [ "$ROUTER" != "10.20.0.1" ]
   then
       case $STATUS in
           up)
               # For output log
               echo "wlx04bad60b3886 connecting to .cruisecorp, rerouting to wlp61s0..."
               nmcli con down .cruisecorp
               nmcli dev wifi connect .cruisecorp ifname wlp61s0
               ;;
           *)
               echo "NOT UP"
               ;;
       esac
   fi
   ```
4. Save the file with sequence `Ctrl + O` → `Enter` → `Ctrl + X`
5. Make `99-user-scripts` executable.
   ```
   sudo chmod +x 99-user-scripts
   ```

#### Generate Share Public SSH Key with RPi
When `99-user-scripts` is executed, it needs to send a "set date" (`date -s`) command to the RPi
via SSH. Since `99-user-scripts` is executed by `NetworkManager`, it is executing as `root`, which
has a different public key than the user account. The RPi will prevent an SSH connection (and thus
a time sync) until it has the public key for `root` in its `.ssh/authorized_keys` directory.
1. Change user to `root`.

   ```
   sudo su
   ```
2. Change direcotry to `~/.ssh`.
   ```
   cd ~/.ssh
   ```
3. Check and see if an `ed25519` key already exists in the `.ssh` directory (nothing will be
   be returned if it does not exist).
   ```
   ls ed25519.pub
   ```
4. If a key does **not** exist, generate a new `ed25519` key.
   ```
   ssh-keygen -t ed25519
   ```
5. Copy the SSH key to the RPi, enter `yes` and the password (e.g. `raspberry`) when prompted).
   ```
   ssh-copy-id pi@10.20.0.1
   ```
6. Change user back to personal user.
   ```
   exit
   ```

#### Finishing Up
1. Restart `NetworkManager` to ensure all changes take effect.
   ```
   sudo service network-manager restart
   ```



## Helpful Commands
### Time
#### Get Unix time
```
date "+%s"
```

#### Get Date (YYYY-MM-DD) and Time (HH:MM:SS)
```
date_now=$(date "+%Y-%m-%d")
time_now=$(date "+%T")
```

#### Set Time (18:22:17 on Nov 20, 2022)
```
sudo date -s '2022-11-20 18:22:17'
```


### Connecting to WiFi
#### Show Connected Network Interfaces and Status
```
nmcli dev
```

#### Show Known Wi-Fi Connections (networks) and Status
```
nmcli con
```

#### Show Available WiFi Networks and Status
```
nmcli dev wifi
```

#### Register, Connect USB NIC to Pi_WAP Network
```
sudo nmcli dev wifi connect Pi_WAP password raspberry ifname wlx04bad60b3885
```

#### Connect/Disconnect to/from Network
```
nmcli con down Pi_WAP
nmcli con up Pi_WAP
```

#### Delete WiFi Connection (forget network)
```
sudo nmcli con del Pi_WAP
```


### Route Controls
#### Prevent default for connection
```
sudo nmcli con mod Pi_WAP ipv4.never-default yes
```

#### Add Route to RPi via RPi WAP with NIC
```
sudo ip route add 10.20.0.1 via 10.20.0.1 dev wlx04bad60b3885
```

#### Delete Default Routes for NIC
```
sudo ip route del default dev wlx04bad60b3885
```


### Network Interface Controls
#### Turn Interface On/Off
```
sudo ifup wlx04bad60b3885
sudo ifdown wlx04bad60b3885
```

#### Restart Network Service
```
sudo service network-manager restart
#sudo /etc/init.d/networking restart
#sudo systemctl restart systemd-networkd
```


### Debug
# Check Logged Output of /etc/NetworkManager/dispatcher.d/ Scripts
```
sudo journalctl -u NetworkManager-dispatcher
```

#### Directory of Known Network Connection Profiles
```
cd /etc/NetworkManager/system-connections
```

#### Other (Empty) Network Directories
```
#/etc/systemd/network/
#/etc/network/interfaces.d
```

#### USB Connect/Disconnect Rules (like dispatch.d, but for USB)
```
#/etc/udev/rules
```


# TO ONLY CONNECT TO ONE DEVICE

- Add global variable for interface $USB_WiFi=wlx04bad60b3885
- IF = USB_WiFi
- Add script /etc/NetworkManager/dispatcher.d/99-user-scripts
```
#!/bin/sh

# Change the metric of the default route only on interface enp0s3
IF=$1
STATUS=$2
# MY_METRIC=1

if [ "$IF" = "wlx04bad60b3885" ]
then
	 case "$STATUS" in
                up)
                ip route del default dev $IF
                ip route add $DHCP4_ROUTERS via $DHCP4_ROUTERS dev $IF
		#ip route add default via $DHCP4_ROUTERS dev $IF metric $MY_METRIC
                ;;
                *)
                ;;
        esac
fi

```
- `sudo nmcli con mod Pi_WAP ipv4.never-default yes`
- `sudo service network-manager restart`
- `sudo nmcli dev wifi connect Pi_WAP password raspberry ifname wlx04bad60b3885`


# SIMPLIFIED
- `sudo nmcli dev wifi connect Pi_WAP password raspberry ifname wlx04bad60b3885
- `sudo nmcli con mod Pi_WAP ipv4.never-default yes`
- `sudo service network-manager restart`


# On connect
- Set IP route
- Set RPi date and time with current date and time
- Need root account to have shared SSH key with Pi
