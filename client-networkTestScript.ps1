
$sysinfo = Get-CimInstance win32_OperatingSystem | Select-Object CSName, Caption, InstallDate, LastBootUpTime, LocalDateTime, Version, OSArchitecture, SystemDevice
$date = Get-Date

write-host "============================================="
write-host "Client PC Network Info Gathering Script"
write-host "Version 1.1 || Build date: 02/02/2016"
write-host "Modified: 08/22/2017"
write-host "============================================="
write-host ""
write-host "Script run on: "$date
write-host ""
write-host "Base system information"
write-host "============================================="
write-host "Hostname         : " $sysinfo.CSName
write-host "Operating System : " $sysinfo.Caption
write-host "Version          : " $sysinfo.Version
write-host "Architecture     : " $sysinfo.OSArchitecture
write-host "Install Date     : " $sysinfo.InstallDate
write-host "Last Boot        : " $sysinfo.LastBootUpTime
write-host ""
write-host ""

write-host "Detailed network information"
write-host "============================================="
ipconfig /all

write-host ""
Write-host ""
Write-host "Gather local PC IP network statistics "
Write-host "======================================"
Write-host ""
netsh interface ipv4 show ipstats
netsh interface ipv4 show tcpstats
netsh interface ipv4 show udpstats
netsh interface ipv4 show icmpstats

Write-host ""
Write-host "Gather local PC multicast connections "
Write-host "======================================"
netsh interface ipv4 show joins
netsh interface ipv4 show neighbors

Write-host ""
Write-host "Gather local PC smb connection info   "
Write-host "======================================"
net statistics workstation

Write-host ""
Write-host "Anything from BITS waiting?           "
Write-host "======================================"
Get-BitsTransfer

Write-host ""
Write-host "======================================="
Write-host "Gathering local PC netstat connections "
Write-host "======================================="
$iplist = @()
$webiplist = @()
$cleaned2 = @()

$data = netstat -an


FOREACH ($line in $data[4..$data.Count]) {
    
    # Remove the whitespace at the beginning on the line
    $line = $line -replace '^\s+', ''
    
    # Split on whitespaces characteres
    $line = $line -split '\s+'
    
    # Add the list altogether
    $iplist += $line[2]
    

}


# grab all websites (80 and 443) that the client is/was connected to
$webiplist = $iplist | Get-Unique | Select-String -pattern ":80|:443"

Write-host ""
Write-host "Web connections detected, w/ port 80 or 443"
Write-host "==============================================="
$webiplist
Write-host ""


# grab internal servers from the list, then only once, # bug it still dupes some IP's?
$cleaned = $iplist | Get-Unique | Select-String -Pattern "10.10.*" | Get-Unique


FOREACH ($newline in $cleaned) {
    $cleaned2 += ($newline -split ":")[0]
}

Write-host ""
Write-host "Internal servers detected:"
Write-host "==========================================="
$cleaned2
Write-host ""
Write-host "Testing network latency to internal servers"
Write-host "==========================================="
Write-host ""
Foreach($ipaddress in $cleaned2) {
    write-host "Testing: "$ipaddress
    Write-host "==========================================="
    #pathping -q 5 -p 1000 $ipaddress;
    Write-host ""
} 

Write-host ""
Write-host "Testing DNS lookups against internal servers"
Write-host "============================================"
Write-host ""
Foreach($ipaddress2 in $cleaned2) {
    write-host "Testing: "$ipaddress2
    Write-host "==========================================="
    nslookup $ipaddress2;
    Write-host ""
} 


# website testing (hardcoded), could use detected web from previous
[string[]]$InternalURLList = "https://www.google.ca", "www.github.com", "http://linode.com"

Write-host ""
Write-host "Testing HTTP times to web servers"
Write-host "======================================"
Write-host ""
Foreach($Uri in $InternalURLList) {
    try {
        #$MyCreds= Get-Credential
        $results = Measure-Command { $request = Invoke-WebRequest -Uri $Uri -usedefaultcredentials }
        #$results = Measure-Command { $request = Invoke-WebRequest -Uri itshd -Credential $MyCreds}
        #$results = Measure-Command { $request = Invoke-WebRequest -Uri www.google.ca}
        write-host "Testing: "$Uri
        Write-host "==========================================="
        Write-host "URL             : "$Uri
        Write-host "Total Time (ms) : "$results.TotalMilliseconds;
        Write-host "Status Code     : "$request.StatusCode;
        Write-host "Status String   : "$request.StatusDescription;
        Write-host "Content Length  : "$request.RawContentLength;
        Write-host ""

    } catch {
       #$_.Exception.Response.StatusCode.Value__
       Write-host "Exception Status  : "$statuscode = $_.Exception.Status
       Write-host "Exception Message : "$StatusDescription = $_.Exception.Message
    }

}

<# dump out the logs, always nice. found some good ones in here over the years
write-host ""
write-host "Application Event Log Warning/Error Logs (10)"
write-host "============================================="
$ApplicationEvents = Get-EventLog -LogName Application -EntryType Error,Warning -Newest 10

foreach ($event in $ApplicationEvents) {
    write-host "Index          :" $event.Index
    write-host "Event ID       :" $event.EventID
    write-host "Instance ID    :" $event.InstanceId
    write-host "Username       :" $event.UserName
    write-host "Time Generated :" $event.TimeGenerated
    write-host "Source         :" $event.Source
    write-host "Message        :" $event.Message
    write-host ""
}

write-host ""
write-host "System Event Log Warning/Error Logs (10)"
write-host "============================================="
$SystemEvents = Get-EventLog -LogName System -EntryType Error,Warning -Newest 10

foreach ($event in $SystemEvents) {
    write-host "Index          :" $event.Index
    write-host "Event ID       :" $event.EventID
    write-host "Instance ID    :" $event.InstanceId
    write-host "Username       :" $event.UserName
    write-host "Time Generated :" $event.TimeGenerated
    write-host "Source         :" $event.Source
    write-host "Message        :" $event.Message
    write-host ""
}

write-host ""
#>