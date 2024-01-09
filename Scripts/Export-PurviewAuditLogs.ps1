<#

.SYNOPSIS
    Export audit logs from Microsoft Purview to a .csv file.

.DESCRIPTION
    See the following article for more information:
    https://learn.microsoft.com/en-us/purview/audit-log-search-script

#>

param(
	# Include N previous days in the search
	[int]$pastDays = 1,
	# Output results to this file (.csv)
	[string] $outputFile = "\audit-.csv"
)

# Check powershell version
function CheckPowershellVersion()
{
	$majorVersion = $PSVersionTable.PSVersion.Major
	$hasRequiredVersion = $majorVersion -ge 7
	return $hasRequiredVersion
}

function ConnectExchange()
{
	$modules = Get-Module -ListAvailable -Name ExchangeOnlineManagement
	| Where-Object { $_.Version -ge [Version]"3.0.0" }

	if ($modules.Count -lt 1)
	{
		Write-Host "Exchange Online Management PowerShell module not found or out of date."
		$installChoice = Read-Host "Do you want to install the latest version? [y/N]" -ForegroundColor Yellow

		if ($installChoice.ToUpper().StartsWith("Y"))
		{
			Write-Host "Installing Exchange Online Management PowerShell module..."
			Install-Module -Name ExchangeOnlineManagement -Force -Scope CurrentUser
		}
		else
		{
			return $false
		}
	}

	if (-not (Get-Command -Name Get-ConnectionInformation -ErrorAction SilentlyContinue))
	{
		Write-Host "The Get-ConnectionInformation is not available." -ForegroundColor Red
		write-host "Please update your Exchange Online Management PowerShell module." -ForegroundColor Red
		return $false
	}

	$connections = Get-ConnectionInformation
	| Where-Object { $_.Name -match "ExchangeOnline" && $_.State -eq "Connected" }

	if ($connections.Count -eq 0)
	{
		Write-Host "Connecting to Exchange Online..." -foregroundColor Yellow
		Connect-ExchangeOnline -ShowBanner:$false
	}

	return $true
}

if (!(CheckPowershellVersion))
{
	Write-Host "This script requires PowerShell Core 7 or later" -foregroundColor Red
	Exit
}

if (!(ConnectExchange))
{
	Write-Host "Unable to connect to Exchange Online." -ForegroundColor Red
	Exit
}

# Append report timestamp to output file name
$timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
$outputFile = $outputFile.Replace(".csv", "$timestamp.csv")

# Determine search period and interval The maximum search period is 90 days.
# There is a limit of 5000 records per request. To avoid this limit, we use a
# loop with a 60 minute interval
$start = [DateTime]::UtcNow.AddDays(-$pastDays)
$end = [DateTime]::UtcNow
$record = $null
$resultSize = 5000
$intervalMinutes = 60

Write-Host "Start exporting audit logs; start=$($start); end=$($end)"

# Start retrieving audit records
$currentStart = $start
$currentEnd = $end
$totalCount = 0

while ($true)
{
	# Increment interval, stop at end date
	$currentEnd = $currentStart.AddMinutes($intervalMinutes)
	$currentEnd = $(if ($currentEnd -gt $end) { $end } else { $currentEnd })

	# Nothing left to retrieve
	if ($currentStart -eq $currentEnd)
	{
		break
	}

	# Export records for the current session
	Write-Host "Exporting from $($currentStart) to $($currentEnd)"
	$sessionID = [Guid]::NewGuid().ToString() + "_" + "ExtractLogs" + (Get-Date).ToString("yyyyMMddHHmmssfff")
	$currentCount = 0


	do
	{
		$results = Search-UnifiedAuditLog `
			-StartDate $currentStart `
			-EndDate $currentEnd `
			-RecordType $record `
			-SessionId $sessionID `
			-SessionCommand ReturnLargeSet `
			-ResultSize $resultSize

		if (($results | Measure-Object).Count -gt 0)
		{
			# Append results to the output file
			$results | export-csv -Path $outputFile -Append -NoTypeInformation
			$currentTotal = $results[0].ResultCount
			$currentCount += $results.Count
			$totalCount += $results.Count

			# Break out of the loop if we have retrieved all records
			if ($currentTotal -eq $results[$results.Count - 1].ResultIndex)
			{
				Write-Host "Successfully exported $($currentTotal) audit records..."
				break
			}
		}
	}

	# Break if there are no more records to retrieve
	while (($results | Measure-Object).Count -gt 0)

	# Move to the next interval
	$currentStart = $currentEnd
}

Write-Host "Finished exporting $totalCount records between $($start) and $($end)." -foregroundColor Green
