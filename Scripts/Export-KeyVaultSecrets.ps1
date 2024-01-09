<#

.SYNOPSIS
		Exports secrets from a key vault to the console

#>

Param(
	# the vault to export secrets from
	[Parameter(Mandatory)]
	[string]$vaultName
)


$secretNames = $(az keyvault secret list --vault-name $vaultName) | ConvertFrom-Json | Select-Object -Property name

$secrets = @()
$secretNames | ForEach-Object {
	$secret = $(az keyvault secret show --name $_.name --vault-name $vaultName -o json) | ConvertFrom-Json
	$secrets += [PSCustomObject]@{
		Name  = $_.name
		Value = $secret.value
	}
}


$secrets | Format-Table

Write-Output "To import the secrets to another vault, run the following commands:"
Write-Output ""

$secrets | ForEach-Object {
	Write-Output "az keyvault secret set --vault-name `$vaultName --name $($_.Name) --value `"$($_.Value)`""
}
