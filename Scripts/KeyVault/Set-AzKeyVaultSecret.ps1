param(
 [Parameter(Mandatory=$True)]
 [string]
 $keyVaultName,
 
 [Parameter(Mandatory=$True)]
 [string]
 $secretName,


 [Parameter(Mandatory=$True)]
 [string]
 $secretValue)


#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"


$secureSecretValue = ConvertTo-SecureString -String $secretValue -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -SecretValue $secureSecretValue