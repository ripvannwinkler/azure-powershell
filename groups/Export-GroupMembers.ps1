Param(
	[Parameter(Mandatory)]
	# the object id of the target group
	[string]$groupId
)

$group = Get-MgGroup -GroupId $groupId
$members = Get-MgGroupMember -GroupId $groupId
$users = @()

foreach ($member in $members) {
	$user = Get-MgUser -UserId $member.Id
	$users += New-Object PSObject -Property @{
		Group = $group.DisplayName;
		Name  = $user.DisplayName;
		Email = $user.Mail
	}
}

$users | Select-Object -Property Group, Name, Email | Format-Table
