# NetBSD 使用

- 启动进入调试模式
```
> boot hd1b:/netbsd.gdb -d                     
```

- 使用 USB 无线网卡

```
ifconfig urtwn0 list scan
ifconfig urtwn0 up
ifconfig urtwn0 nwid "rtbsd" mode 11b

ifconfig rtwn0 nwid "rtbsd" mode 11b
```

- 配置 WPA_SUPPLICANT

> vi /etc/wpa_supplicant.conf
```
network={
ssid="phytium_net"
psk="phytium-net"
}

network={
ssid="rtbsd"
}
```

> vi /etc/rc.conf
```
ifconfig_urtwn0="up"
ifconfig_rtwn0="up"
ipv6_enable="NO"
dhcpcd=YES
wpa_supplicant=YES
```


- 从控制台进入 DDB

```
arm64# ++++
db{0}> break ether_output
db{0}> show breaks
 Map      Count    Address
*0xffffc00001133c90     1    netbsd:ether_multicast_sysctl+0x21c
db{0}> 
db{0}> c
```

## 调试无线网数据包发送流程

```
ether_output -> ifq_enqueue -> if_transmit_lock -> ifp->if_transmit -> if_transmit -> if_start_lock
```

```
break if_transmit
db{2}> show registers
show mbuf ffff0000870cec00
```