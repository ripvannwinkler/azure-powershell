Param(
	[Parameter(Mandatory)]
	# the vault to export secrets from
	[string]$fromVault,

	[Parameter(Mandatory = $false)]
	# the vault to import secrets to
	[string]$toVault = "destination-vault-name"
)

$secretNames = $(az keyvault secret list --vault-name $fromVault) | ConvertFrom-Json | Select-Object -Property name

$secretNames | ForEach-Object {
	$secret = $(az keyvault secret show --name $_.name --vault-name $fromVault -o json) | ConvertFrom-Json
	Write-Output "az keyvault secret set --vault-name $toVault --name `"$($_.name)`" --value `"$($secret.value)`" --output none"
}

