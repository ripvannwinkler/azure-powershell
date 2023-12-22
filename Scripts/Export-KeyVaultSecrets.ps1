<#
	SYNOPSIS: Exports all secrets from a key vault to the console

	Given a key vault name, this script will export all secrets from the vault and print them to the console.
#>
Param(
	[Parameter(Mandatory)]
	# the vault to export secrets from
	[string]$fromVault
)


$secretNames = $(az keyvault secret list --vault-name $fromVault) | ConvertFrom-Json | Select-Object -Property name

$secrets = @()
$secretNames | ForEach-Object {
	$secret = $(az keyvault secret show --name $_.name --vault-name $fromVault -o json) | ConvertFrom-Json
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
