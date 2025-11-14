## 使用 tcpdump 抓包

- 安装 tcpdump

```
sudo apt install tcpdump
```

- 将无线网卡切换为 monitor 模式

> ./enable_sniffer.sh 
```
#!/bin/sh
systemctl stop NetworkManager
ip link set wlan0 down

iwconfig wlan0 mode monitor
ip link set wlan0 up
iw dev wlan0 set channel 1
ip link set wlan0 up
iw dev wlan0 info
```

```
./enable_sniffer.sh
```

- 抓特定 MAC 地址关联的包

```
sudo tcpdump -ni wlan0 -y IEEE802_11_RADIO -U -s0 -v 'wlan addr1 24:ec:99:2d:b8:7b or wlan addr2 24:ec:99:2d:b8:7b'

sudo tcpdump -ni wlan0 -y IEEE802_11_RADIO -U -s0 -v \
  '(wlan addr1 24:ec:99:2d:b8:7b or wlan addr2 24:ec:99:2d:b8:7b) and wlan type data' | \
grep -i icmp
```
