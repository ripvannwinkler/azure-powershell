Unregister-ScheduledTask -TaskName uptime
$tt = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval 0:01
$ta = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\uptime.ps1"
$tp = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount
Register-ScheduledTask -Principal $tp -Action $ta -Trigger $tt -TaskName "uptime" -Description "Ping the uptime monitor"

$events = @(
	Get-WinEvent  -FilterXml @'
     <QueryList>
      <Query Id="0" Path="Microsoft-Windows-TaskScheduler/Operational">
       <Select Path="Microsoft-Windows-TaskScheduler/Operational">
        *[EventData/Data[@Name='TaskName']='\uptime']
       </Select>
      </Query>
     </QueryList>
'@  -ErrorAction Stop -MaxEvents 2
)
$events

Invoke-WebRequest -Method Get -Uri 'https://uptime.promosvcs.com/api/push/f75TEya6Nm?status=up&msg=OK&ping=' | Out-Null
