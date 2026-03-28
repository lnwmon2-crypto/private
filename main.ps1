$ErrorActionPreference  = "SilentlyContinue"
$ProgressPreference     = "SilentlyContinue"
$WarningPreference      = "SilentlyContinue"
$VerbosePreference      = "SilentlyContinue"
$ConfirmPreference      = "None"

# ============================================================
# HELPER FUNCTIONS
# ============================================================
function RegSet($path, $name, $value, $type = "DWord") {
    If (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -EA SilentlyContinue
}
function SvcKill($name) {
    $s = Get-Service -Name $name -EA SilentlyContinue
    If ($s) {
        Stop-Service    $name -Force           -EA SilentlyContinue
        Set-Service     $name -StartupType Disabled -EA SilentlyContinue
        sc.exe config   $name start= disabled  2>$null | Out-Null
    }
}

# ============================================================
# [A] POWER PLAN — "final premium v.0.1 custom by nelly stephod"
# ============================================================

$planName = "final premium v.0.1"

# ลบ plan เดิมที่ชื่อเดียวกัน
powercfg -list 2>$null | Select-String $planName | ForEach-Object {
    $g = ($_ -split "\s+")[3]
    If ($g) { powercfg -delete $g 2>$null | Out-Null }
}

# Clone จาก High Performance
$raw     = powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
$planGuid = ($raw | Select-String "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}").Matches[0].Value

If ($planGuid) {
    powercfg -changename $planGuid $planName "custom by nelly stephod" 2>$null | Out-Null

    # CPU — min 5% max 99% (Boost aggressive ไม่ร้อน idle)
    powercfg -setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 5   2>$null | Out-Null  # CPU min 5%
    powercfg -setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 99  2>$null | Out-Null  # CPU max 99%
    powercfg -setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 2   2>$null | Out-Null  # Boost = Aggressive

    # Core Parking OFF
    powercfg -setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 2>$null | Out-Null
    powercfg -setacvalueindex $planGuid 54533251-82be-4824-96c1-47b60b740d00 ea062031-0e34-4ff1-9b6d-eb1059334028 100 2>$null | Out-Null

    # Monitor/Sleep/Hibernate OFF
    powercfg -setacvalueindex $planGuid 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0   2>$null | Out-Null
    powercfg -setacvalueindex $planGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0   2>$null | Out-Null
    powercfg -hibernate off 2>$null | Out-Null

    # USB Selective Suspend OFF
    powercfg -setacvalueindex $planGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0   2>$null | Out-Null

    # PCI-E Power Management OFF
    powercfg -setacvalueindex $planGuid 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0   2>$null | Out-Null

    # Wireless Adapter Max Performance
    powercfg -setacvalueindex $planGuid 19caa586-e017-445c-aa8f-b354b1f44b69 12bbebe6-58d6-4636-95bb-3217ef867c1a 0   2>$null | Out-Null

    # Hard Disk — ไม่ sleep
    powercfg -setacvalueindex $planGuid 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0   2>$null | Out-Null

    powercfg -setactive $planGuid 2>$null | Out-Null
}

# ============================================================
# [B] KERNEL / CPU SCHEDULING
# ============================================================

RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "IRQ8Priority"            1
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "IRQ16Priority"           2
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "IRQ9Priority"            1

# Power Throttling OFF
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1

# Timer Resolution — 0.5ms
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" 1

# Spectre / Meltdown OFF (+5-15% CPU performance)
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "MitigationOptions"      0 "QWord"
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "MitigationAuditOptions" 0 "QWord"

# Context Switch Reduction
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "DisableExceptionChainValidation" 1

# BCD
bcdedit /deletevalue useplatformclock   2>$null | Out-Null
bcdedit /set useplatformtick  yes       2>$null | Out-Null
bcdedit /set disabledynamictick yes     2>$null | Out-Null
bcdedit /set tscsyncpolicy    Enhanced  2>$null | Out-Null
bcdedit /set bootmenupolicy   Standard  2>$null | Out-Null
bcdedit /set nx               OptIn     2>$null | Out-Null

# Crash Control
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" "AutoReboot"          0
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" "CrashDumpEnabled"    0
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" "LogEvent"            0
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" "SendAlert"           0

# Kill Timeout
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" "250" "String"
RegSet "HKCU:\Control Panel\Desktop"            "WaitToKillAppTimeout"     "250" "String"
RegSet "HKCU:\Control Panel\Desktop"            "HungAppTimeout"           "250" "String"
RegSet "HKCU:\Control Panel\Desktop"            "AutoEndTasks"             "1"   "String"
RegSet "HKCU:\Control Panel\Desktop"            "ForegroundLockTimeout"    0
RegSet "HKCU:\Control Panel\Desktop"            "MenuShowDelay"            "0"   "String"

# ============================================================
# [C] NETWORK — ABSOLUTE MAXIMUM
# ============================================================

# --- C1: Nagle OFF + DelAck ทุก Interface ---
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
    Set-ItemProperty $_.PSPath "TcpAckFrequency" 1    -Type DWord -EA SilentlyContinue
    Set-ItemProperty $_.PSPath "TCPNoDelay"      1    -Type DWord -EA SilentlyContinue
    Set-ItemProperty $_.PSPath "TcpDelAckTicks"  0    -Type DWord -EA SilentlyContinue
    Set-ItemProperty $_.PSPath "MTU"             1500 -Type DWord -EA SilentlyContinue
}

# --- C2: TCP Global Stack สุดขีด ---
$tcp = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
RegSet $tcp "DefaultTTL"                    64
RegSet $tcp "MaxUserPort"                   65534
RegSet $tcp "TcpTimedWaitDelay"             30
RegSet $tcp "TCPMaxDupAcks"                2
RegSet $tcp "SackOpts"                      1
RegSet $tcp "Tcp1323Opts"                   1
RegSet $tcp "EnablePMTUDiscovery"           1
RegSet $tcp "GlobalMaxTcpWindowSize"        16777216   # 16MB
RegSet $tcp "TcpWindowSize"                16777216   # 16MB
RegSet $tcp "MaxDupAcksForFastRetransmit"  2
RegSet $tcp "TCPMaxConnectRetransmissions"  2
RegSet $tcp "DisableTaskOffload"            0
RegSet $tcp "EnableDCA"                     1
RegSet $tcp "MaxFreeTcbs"                   65536
RegSet $tcp "MaxHashTableSize"              65536
RegSet $tcp "MaxConnections"                0xffffffff
RegSet $tcp "TcpMaxSackBlocks"              8          # SACK blocks สูงสุด
RegSet $tcp "EnableTCPChimney"              0
RegSet $tcp "EnableRSS"                     1
RegSet $tcp "EnableTCPA"                    1          # TCP Acknowledgement Offload
RegSet $tcp "TCPInitialRTT"                 3          # ms — ลด initial RTT estimate
RegSet $tcp "KeepAliveTime"                 7200000
RegSet $tcp "KeepAliveInterval"             1000

# --- C3: UDP / AFD EXTREME ---
$afd = "HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"
RegSet $afd "DefaultReceiveWindow"             1048576    # 1MB per socket
RegSet $afd "DefaultSendWindow"               1048576    # 1MB per socket
RegSet $afd "FastSendDatagramThreshold"       1500
RegSet $afd "MaxFastTransmit"                 32
RegSet $afd "NonBlockingSendSpecialBuffering"  1
RegSet $afd "DynamicSendBufferDisable"         0
RegSet $afd "MaxBufferredReceiveBytes"         33554432   # 32MB
RegSet $afd "MaxBufferredSendBytes"            33554432   # 32MB
RegSet $afd "DoNotForceSendAlways"             1
RegSet $afd "EnableDynamicBacklog"             1
RegSet $afd "MinimumDynamicBacklog"            20
RegSet $afd "MaximumDynamicBacklog"            65535
RegSet $afd "DynamicBacklogGrowthDelta"        10
RegSet $afd "IrpStackSize"                     14
RegSet $afd "PriorityBoost"                    1          # Boost thread setelah recv
RegSet $afd "TransmitIoLength"                 65536      # Transmit chunk size

# --- C4: WINSOCK ---
RegSet "HKLM:\SYSTEM\CurrentControlSet\Services\WinSock2\Parameters" "MaxSockAddrLength" 128
RegSet "HKLM:\SYSTEM\CurrentControlSet\Services\WinSock2\Parameters" "MinSockAddrLength" 16

# --- C5: netsh TCP ---
netsh int tcp set global autotuninglevel=normal        2>$null | Out-Null
netsh int tcp set global rsc=disabled                  2>$null | Out-Null
netsh int tcp set global timestamps=disabled           2>$null | Out-Null
netsh int tcp set global initialRto=2000               2>$null | Out-Null
netsh int tcp set global maxsynretransmissions=2       2>$null | Out-Null
netsh int tcp set global nonsackrttresiliency=disabled 2>$null | Out-Null
netsh int tcp set global ecncapability=disabled        2>$null | Out-Null
netsh int tcp set global fastopen=enabled              2>$null | Out-Null
netsh int tcp set global hystart=disabled              2>$null | Out-Null
netsh int tcp set global pacingprofile=off             2>$null | Out-Null

# --- C6: QoS ปลดล็อก ---
RegSet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit"  0
RegSet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "MaxOutstandingSends" 0
RegSet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QOS"    "Tc Supported"        1

# MMCSS Network
RegSet "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xffffffff
RegSet "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness"   0
RegSet "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NoLazyMode"             1

# --- C7: DNS สุดขีด ---
$adapters = Get-NetAdapter | Where-Object {
    $_.Status -eq "Up" -and
    $_.InterfaceDescription -notlike "*Virtual*" -and
    $_.InterfaceDescription -notlike "*Loopback*" -and
    $_.InterfaceDescription -notlike "*Bluetooth*"
}
ForEach ($a in $adapters) {
    Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ServerAddresses "1.1.1.1","1.0.0.1" -EA SilentlyContinue
}
ipconfig /flushdns 2>$null | Out-Null

$dns = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
RegSet $dns "MaxCacheTtl"                86400
RegSet $dns "MaxNegativeCacheTtl"         0
RegSet $dns "NegativeSOACacheTime"        0
RegSet $dns "NetFailureCacheTime"         0
RegSet $dns "CacheHashTableBucketSize"    1
RegSet $dns "CacheHashTableSize"          384
RegSet $dns "MaxSOACacheEntryTtlLimit"    0
RegSet $dns "AdaptiveTimeoutInitialValue" 50      # ms — ลด initial DNS timeout

# --- C8: Network Adapter Advanced ---
$cpuCount = [int](Get-CimInstance Win32_Processor | Select-Object -First 1).NumberOfLogicalProcessors

ForEach ($a in $adapters) {
    $n = $a.Name

    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Receive Buffers"               -DisplayValue "4096"     -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Transmit Buffers"              -DisplayValue "4096"     -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Interrupt Moderation"          -DisplayValue "Disabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Interrupt Moderation Rate"     -DisplayValue "Off"      -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "TCP Checksum Offload (IPv4)"   -DisplayValue "Enabled"  -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "TCP Checksum Offload (IPv6)"   -DisplayValue "Enabled"  -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "UDP Checksum Offload (IPv4)"   -DisplayValue "Enabled"  -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "UDP Checksum Offload (IPv6)"   -DisplayValue "Enabled"  -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "IP Checksum Offload"           -DisplayValue "Tx Enabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Large Send Offload V2 (IPv4)"  -DisplayValue "Disabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Large Send Offload V2 (IPv6)"  -DisplayValue "Disabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Receive Side Scaling"          -DisplayValue "Enabled"  -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Flow Control"                  -DisplayValue "Disabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Energy Efficient Ethernet"     -DisplayValue "Disabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Green Ethernet"                -DisplayValue "Disabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Power Saving Mode"             -DisplayValue "Disabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Wake on Magic Packet"          -DisplayValue "Disabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Wake on Pattern Match"         -DisplayValue "Disabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Jumbo Packet"                  -DisplayValue "Disabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Jumbo Frame"                   -DisplayValue "Disabled" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Speed & Duplex"                -DisplayValue "1.0 Gbps Full Duplex" -EA SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $n -DisplayName "Packet Priority & VLAN"        -DisplayValue "Packet Priority & VLAN Disabled" -EA SilentlyContinue

    # RSS Queue = min(cpuCount, 4)
    Set-NetAdapterRss -Name $n -NumberOfReceiveQueues ([Math]::Min($cpuCount,4)) -EA SilentlyContinue

    # Power Management
    $pwr = Get-NetAdapterPowerManagement -Name $n -EA SilentlyContinue
    If ($pwr) {
        $pwr.ArpOffload        = "Disabled"
        $pwr.NSOffload         = "Disabled"
        $pwr.WakeOnMagicPacket = "Disabled"
        $pwr.WakeOnPattern     = "Disabled"
        $pwr | Set-NetAdapterPowerManagement -EA SilentlyContinue
    }
    Disable-NetAdapterPowerManagement -Name $n -EA SilentlyContinue
}

# --- C9: MSI Mode ทุก PCI Device ---
$pci = "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI"
Get-ChildItem $pci -EA SilentlyContinue | ForEach-Object {
    Get-ChildItem $_.PSPath -EA SilentlyContinue | ForEach-Object {
        $msi = "$($_.PSPath)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        $aff = "$($_.PSPath)\Device Parameters\Interrupt Management\Affinity Policy"
        If (Test-Path $msi) {
            Set-ItemProperty $msi "MSISupported"   1 -Type DWord -EA SilentlyContinue
            Set-ItemProperty $msi "MessageNumber"  4 -Type DWord -EA SilentlyContinue  # MSI-X 4 vectors
        }
        If (Test-Path $aff) {
            Set-ItemProperty $aff "DevicePolicy"          0 -Type DWord -EA SilentlyContinue
            Set-ItemProperty $aff "AssignmentSetOverride" 0 -Type DWord -EA SilentlyContinue
        }
    }
}

# --- C10: Firewall — FiveM ports ---
@(
    @{n="FiveM UDP IN  30120"; p="UDP"; d="in";  port=30120},
    @{n="FiveM UDP OUT 30120"; p="UDP"; d="out"; port=30120},
    @{n="FiveM TCP IN  30120"; p="TCP"; d="in";  port=30120},
    @{n="FiveM TCP OUT 30120"; p="TCP"; d="out"; port=30120},
    @{n="FiveM UDP IN  40120"; p="UDP"; d="in";  port=40120},
    @{n="FiveM UDP OUT 40120"; p="UDP"; d="out"; port=40120},
    @{n="FiveM UDP IN  30110"; p="UDP"; d="in";  port=30110},
    @{n="FiveM UDP OUT 30110"; p="UDP"; d="out"; port=30110}
) | ForEach-Object {
    netsh advfirewall firewall delete rule name=$_.n 2>$null | Out-Null
    netsh advfirewall firewall add rule name=$_.n protocol=$_.p dir=$_.d localport=$_.port action=allow 2>$null | Out-Null
}

# --- C11: Delivery Optimization OFF (กิน bandwidth) ---
RegSet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0
SvcKill "DoSvc"

# ============================================================
# [D] FiveM / CitizenFX DEEP TWEAKS
# ============================================================

# CitizenFX Registry
RegSet "HKCU:\SOFTWARE\CitizenFX"         "net_maxPackets"       "128" "String"
RegSet "HKCU:\SOFTWARE\CitizenFX"         "net_showCondition"    "0"   "String"
RegSet "HKCU:\SOFTWARE\CitizenFX"         "game_enforcegameencryption" "0" "String"
RegSet "HKCU:\SOFTWARE\CitizenFX\Network" "netFrameTime"         "0"   "String"
RegSet "HKCU:\SOFTWARE\CitizenFX\Network" "rateLimitBypass"      "1"   "String"
RegSet "HKCU:\SOFTWARE\CitizenFX\Network" "netTimeout"           "15000" "String"  # ลด Timeout 15s
RegSet "HKCU:\SOFTWARE\CitizenFX\Network" "netRateThreshold"     "0"   "String"   # ปิด Rate Limiter

# IFEO — Process Priority สุดขีด (High ไม่ใช่ Realtime — ปลอดภัย)
$ifeo = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
@("FiveM.exe","FiveM_b3095.exe","GTA5.exe","GTA5_Enhanced.exe",
  "CitizenFX_SubProcess.exe","FiveM_ChromeBrowser.exe","fivem_server.exe") | ForEach-Object {
    $p = "$ifeo\$_\PerfOptions"
    RegSet $p "CpuPriorityClass" 3  # High
    RegSet $p "IoPriority"       3  # High
    RegSet $p "PagePriority"     5  # Normal-Above
}

# MMCSS Tasks — Games + FiveM dedicated
$mm = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks"
@("Games","FiveM","GTA5") | ForEach-Object {
    $t = "$mm\$_"
    RegSet $t "Affinity"            0
    RegSet $t "Background Only"     "False" "String"
    RegSet $t "Clock Rate"          10000
    RegSet $t "GPU Priority"        8
    RegSet $t "Priority"            6
    RegSet $t "Scheduling Category" "High"  "String"
    RegSet $t "SFIO Priority"       "High"  "String"
}

# ============================================================
# [E] GPU — ABSOLUTE MAXIMUM
# ============================================================

$gpuDrv = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
RegSet $gpuDrv "HwSchMode"    2   # HAGS ON
RegSet $gpuDrv "TdrDelay"     60  # ป้องกัน false TDR
RegSet $gpuDrv "TdrDdiDelay"  60
RegSet $gpuDrv "TdrLevel"     0   # ปิด TDR

# D3D Flip — ลด Present Latency
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Video" -Recurse -EA SilentlyContinue |
    Where-Object { $_.PSChildName -eq "0000" } | ForEach-Object {
    Set-ItemProperty $_.PSPath "D3DFlipMode"           2 -EA SilentlyContinue
    Set-ItemProperty $_.PSPath "VRROptimizationEnable" 0 -EA SilentlyContinue
    Set-ItemProperty $_.PSPath "PreferD3DFlip"         1 -EA SilentlyContinue
}

# NVIDIA
RegSet "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NVTweak" "Coolbits" 24

$nvDrv = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak"
RegSet $nvDrv "EnableMidBufferPreemption"    0  # ลด GPU stutter
RegSet $nvDrv "EnableCEPreemption"           0
RegSet $nvDrv "EnableMidGfxPreemptionVGPU"  0
RegSet $nvDrv "RMGpsBandwidthBoostEnable"    1  # เปิด GPU Bandwidth Boost
RegSet $nvDrv "RMDeepL2"                     0  # ปิด L2 Lazy mode
RegSet $nvDrv "RMFastGC"                     1  # Fast Garbage Collection

# NVIDIA Telemetry ปิด
@("NvTelemetryContainer","NvContainerLocalSystem","NvContainerNetworkService","NvDisplayContainer") | ForEach-Object {
    Stop-Service $_ -Force -EA SilentlyContinue
    Set-Service  $_ -StartupType Disabled -EA SilentlyContinue
}

# ============================================================
# [F] RAM / MEMORY ABSOLUTE MAX
# ============================================================

$mem = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
RegSet $mem "DisablePagingExecutive"          1
RegSet $mem "LargeSystemCache"                0
RegSet $mem "ClearPageFileAtShutdown"         0
RegSet $mem "HeapDeCommitFreeBlockThreshold"  0x00040000
RegSet $mem "HeapDeCommitTotalFreeThreshold"  0x00100000
RegSet $mem "NonPagedPoolSize"                0
RegSet $mem "PagedPoolSize"                   0
RegSet $mem "SessionPoolSize"                 48
RegSet $mem "SessionViewSize"                 192
RegSet $mem "PoolUsageMaximum"                96     # ใช้ RAM Pool ได้ 96%
RegSet $mem "PhysicalAddressExtension"        1      # PAE ON

$pre = "$mem\PrefetchParameters"
RegSet $pre "EnablePrefetcher"     0
RegSet $pre "EnableSuperfetch"     0
RegSet $pre "EnableBootTrace"      0
RegSet $pre "EnableRobustCodegen"  0

# I/O Page Lock 75% RAM
$totalRAM = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum
RegSet $mem "IoPageLockLimit" ([Math]::Floor(($totalRAM / 1MB) * 0.75) * 1024)

# Large Pages
RegSet $mem "LargePageDrivers" "*" "String"

# ============================================================
# [G] STORAGE / DISK
# ============================================================

fsutil behavior set disable8dot3      1 2>$null | Out-Null
fsutil behavior set disablelastaccess  1 2>$null | Out-Null
fsutil behavior set memoryusage        2 2>$null | Out-Null
fsutil behavior set mftzone            2 2>$null | Out-Null
fsutil behavior set encryptpagingfile  0 2>$null | Out-Null   # ปิด Encrypt PageFile (เร็วขึ้น)

# Write Cache เปิดทุก Disk
Get-WmiObject -Class Win32_DiskDrive -EA SilentlyContinue | ForEach-Object {
    $disk = New-Object -ComObject "Shell.Application" -EA SilentlyContinue
}
Get-PhysicalDisk -EA SilentlyContinue | Set-PhysicalDisk -MediaType SSD -EA SilentlyContinue

# ============================================================
# [H] SERVICES KILL — ขั้นสุด
# ============================================================

@(
    # Microsoft Telemetry / Diagnostics
    "DiagTrack","dmwappushservice","WdiSystemHost","WdiServiceHost",
    "diagnosticshub.standardcollector.service","PcaSvc","wercplsupport","WerSvc",

    # Xbox / Game Bar
    "XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc",

    # Search / Index
    "WSearch",

    # Superfetch / Memory
    "SysMain",

    # Fax / Print / Remote
    "Fax","PrintNotify","RemoteRegistry","TabletInputService",

    # Network กิน Bandwidth
    "SharedAccess","lmhosts","NvTelemetryContainer","DoSvc",

    # Notification / Sync / Push
    "WpnService","CDPSvc","OneSyncSvc","UnistoreSvc","UserDataSvc",
    "SEMgrSvc","ScDeviceEnum","SCardSvr",

    # Misc useless
    "RetailDemo","MapsBroker","PhoneSvc","MessagingService",
    "wisvc","TrkWks","MSDTC","lfsvc","icssvc",
    "WbioSrvc",  # Biometric (ปิดถ้าไม่ใช้ fingerprint)
    "BthAvctpSvc","bthserv",  # Bluetooth
    "AJRouter",  # AllJoyn Router
    "ALG",       # Application Layer Gateway
    "Spooler",   # Print Spooler (ไม่ใช้ปริ้นได้ปิด)
    "browser"    # Computer Browser
) | ForEach-Object { SvcKill $_ }

RegSet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry"      0
RegSet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "MaxTelemetryAllowed" 0

# ============================================================
# [I] WINDOWS DEFENDER — ลด impact + Exclude FiveM
# ============================================================

Set-MpPreference -DisableRealtimeMonitoring        $true -EA SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring        $true -EA SilentlyContinue
Set-MpPreference -DisableIOAVProtection            $true -EA SilentlyContinue
Set-MpPreference -DisableScriptScanning            $true -EA SilentlyContinue
Set-MpPreference -DisableArchiveScanning           $true -EA SilentlyContinue
Set-MpPreference -DisableIntrusionPreventionSystem $true -EA SilentlyContinue
Set-MpPreference -DisableEmailScanning             $true -EA SilentlyContinue
Set-MpPreference -DisableRemovableDriveScanning    $true -EA SilentlyContinue
Set-MpPreference -ScanAvgCPULoadFactor              5    -EA SilentlyContinue
Set-MpPreference -EnableLowCpuPriority             $true -EA SilentlyContinue
Set-MpPreference -MAPSReporting                    0     -EA SilentlyContinue
Set-MpPreference -SubmitSamplesConsent             2     -EA SilentlyContinue  # Never send samples

@("$env:LOCALAPPDATA\FiveM","$env:ProgramFiles\FiveM","$env:ProgramFiles(x86)\FiveM") |
    ForEach-Object { Add-MpPreference -ExclusionPath $_ -EA SilentlyContinue }
@("FiveM.exe","GTA5.exe","GTA5_Enhanced.exe","CitizenFX_SubProcess.exe","fivem_server.exe") |
    ForEach-Object { Add-MpPreference -ExclusionProcess $_ -EA SilentlyContinue }

# ============================================================
# [J] INPUT / MOUSE
# ============================================================

RegSet "HKCU:\Control Panel\Mouse" "MouseSpeed"       "0"   "String"
RegSet "HKCU:\Control Panel\Mouse" "MouseThreshold1"  "0"   "String"
RegSet "HKCU:\Control Panel\Mouse" "MouseThreshold2"  "0"   "String"
RegSet "HKCU:\Control Panel\Mouse" "MouseHoverTime"   "0"   "String"
RegSet "HKCU:\Control Panel\Mouse" "DoubleClickSpeed" "500" "String"
RegSet "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" "MouseDataQueueSize"  16
RegSet "HKLM:\SYSTEM\CurrentControlSet\Services\mouhid\Parameters"   "MouseDataQueueSize"  16
RegSet "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" "KeyboardDataQueueSize" 16
RegSet "HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters" "PollStatusIterations"  1

# ============================================================
# [K] VISUAL — OFF ทั้งหมด
# ============================================================

RegSet "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
RegSet "HKCU:\Control Panel\Desktop"            "DragFullWindows"     "0" "String"
RegSet "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate"       "0" "String"
RegSet "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0

# Game DVR OFF
RegSet "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled"        0
RegSet "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "HistoricalCaptureEnabled" 0
RegSet "HKCU:\System\GameConfigStore" "GameDVR_Enabled"                        0
RegSet "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode"                2
RegSet "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode"       1
RegSet "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" 1
RegSet "HKCU:\System\GameConfigStore" "GameDVR_EFSEFeatureFlags"               0
RegSet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowgameDVR"      0

# Game Mode ON
RegSet "HKCU:\SOFTWARE\Microsoft\GameBar" "AutoGameModeEnabled"       1
RegSet "HKCU:\SOFTWARE\Microsoft\GameBar" "AllowAutoGameMode"         1
RegSet "HKCU:\SOFTWARE\Microsoft\GameBar" "UseNexusForGameBarEnabled" 0

# ============================================================
# [L] GROUP POLICY
# ============================================================

$pol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows"
RegSet "$pol\WindowsUpdate\AU"        "NoAutoUpdate"                    0
RegSet "$pol\WindowsUpdate\AU"        "AUOptions"                       2
RegSet "$pol\WindowsUpdate\AU"        "ScheduledInstallDay"             0
RegSet "$pol\DeliveryOptimization"    "DODownloadMode"                  0
RegSet "$pol\DataCollection"          "AllowTelemetry"                  0
RegSet "$pol\DataCollection"          "MaxTelemetryAllowed"             0
RegSet "$pol\CurrentVersion\PushNotifications" "NoToastApplicationNotification" 1
RegSet "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1

# Auto Maintenance OFF
RegSet "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" "MaintenanceDisabled" 1

# Sleep Study OFF
powercfg /sleepstudy /output nul 2>$null | Out-Null
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\Power" "EnergySaverBatteryThreshold" 0

# ============================================================
# [M] NTOSKRNL / SYSTEM EXTRAS
# ============================================================

# ปิด Windows Error Reporting ทั้งหมด
RegSet "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled"        1
RegSet "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "DontSendAdditionalData" 1
RegSet "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "LoggingDisabled" 1

# ปิด Customer Experience Improvement Program
RegSet "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" "CEIPEnable" 0

# ปิด Event Log (ลด Disk Write / CPU ตอนเล่นเกม)
RegSet "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog" "Start" 4

# ปิด Windows Insider
RegSet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" "AllowBuildPreview"          0
RegSet "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" "EnableConfigFlighting"      0

# Shutdown / Restart เร็วขึ้น
RegSet "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "PowerdownAfterShutdown" "1" "String"
RegSet "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled"      0

# ============================================================
# [N] APPLY FINAL — Flush DNS + Refresh Policy
# ============================================================

ipconfig /flushdns         2>$null | Out-Null
ipconfig /registerdns      2>$null | Out-Null
netsh winsock reset        2>$null | Out-Null
netsh int ip reset         2>$null | Out-Null
