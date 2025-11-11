## BOOT CMD

### NVMe boot

```
# 扫描并枚举所有 PCI/PCIe 设备
boot_pci_enum=pci enum

# 如果 nvme_need_init变量为 true
# setenv nvme_need_init false：标记 NVMe 已初始化
# nvme scan：扫描并初始化 NVMe 设备
nvme_init=if ${nvme_need_init}; then setenv nvme_need_init false; nvme scan; fi

# 列出设备上标记为可启动的分区
# 结果保存到 devplist变量
# 如果没有找到可启动分区标记，默认使用分区 1
# 对每个候选分区：fstype：检测分区文件系统类型, 如果成功检测到文件系统，则运行 scan_dev_for_boot
scan_dev_for_boot_part=part list ${devtype} ${devnum} -bootable devplist; env exists devplist || setenv devplist 1; for distro_bootpart in ${devplist}; do if fstype ${devtype} ${devnum}:${distro_bootpart} bootfstype; then run scan_dev_for_boot; fi; done; setenv devplist

# run boot_pci_enum：枚举 PCI 设备
# run nvme_init：初始化 NVMe
# if nvme dev ${devnum}：检查指定编号的 NVMe 设备是否存在
nvme_boot=run boot_pci_enum; run nvme_init; if nvme dev ${devnum}; then devtype=nvme; run scan_dev_for_boot_part; fi

# 设置设备编号为 0（第一个 NVMe 设备）
# run nvme_boot：执行 NVMe 启动流程
bootcmd_nvme0=devnum=0; run nvme_boot

boot_targets=mmc0 mmc1 nvme0 scsi0 usb0 pxe dhcp 

distro_bootcmd=scsi_need_init=; setenv nvme_need_init; for target in ${boot_targets}; do run bootcmd_${target}; done

bootcmd=run distro_bootcmd
```

### SATA boot

- 依赖的配置

```
CONFIG_SCSI=y                    # 启用 SCSI 子系统
CONFIG_DM_SCSI=y                 # 启用设备模型的 SCSI 支持

CONFIG_PCI=y                     # 启用 PCI 支持
CONFIG_DM_PCI=y                  # 启用设备模型的 PCI 支持
CONFIG_PCIE_ROCKCHIP=y           # 启用 Rockchip PCIe 控制器
CONFIG_CMD_PCI=y                 # 启用 PCI 命令（pci enum 等）

CONFIG_CMD_GPT=y                 # 启用 GPT 分区表支持
CONFIG_CMD_MTDPARTS=y            # 启用 MTD 分区支持
CONFIG_FDT_FIXUP_PARTITIONS=y    # 启用设备树分区修复
```

```
# SCSI 启动主命令
bootcmd_scsi0=devnum=0; run scsi_boot

# SCSI 启动流程
scsi_boot=run boot_pci_enum; run scsi_init; if scsi dev ${devnum}; then devtype=scsi; run scan_dev_for_boot_part; fi

# SCSI 初始化
scsi_init=if ${scsi_need_init}; then scsi_need_init=false; scsi scan; fi
```

```
run bootcmd_scsi0

# 手动测试命令（在 U-Boot 命令行中）
pci enum        # 枚举 PCI 设备
scsi scan       # 扫描 SCSI/SATA 设备
scsi info       # 显示 SCSI 设备信息
scsi part 0     # 显示分区表
```