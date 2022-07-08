param(
 [Parameter(Mandatory=$True)]
 [string]
 $keyVaultName,
 
 [Parameter(Mandatory=$True)]
 [string]
 $certificateName,


 [Parameter(Mandatory=$True)]
 [string]
 $filePath,

 [Parameter(Mandatory=$True)]
 [string]
 $certificatePass)


#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"


$password = ConvertTo-SecureString -String $certificatePass -AsPlainText -Force
Import-AzureKeyVaultCertificate -VaultName $keyVaultName -Name $certificateName -FilePath $filePath -Password $password