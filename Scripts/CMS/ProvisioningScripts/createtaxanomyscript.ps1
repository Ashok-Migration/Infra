<#
.DESCRIPTION
    This Script is for Creating Taxanomy Group & Taxanomy Columns as per the input from the XML file
    XML files it will look for inputs are
    Taxonomy.xml
.INPUTS
    tenant                  - This is the name of the tenant that you are running the script
    TemplateParametersFile  - This should be the json file having RoleName for Logging
    sp_user                 - This is the user email ID of the tenant which will be used for running the script
    sp_password             - This is the user password of the tenant which will be used for running the script
    InstrumentationKey      - This is the Instrumentation Key which will be used for logging Exceptions in Azure Application Insight

.OUTPUTS
    Creates all Taxanomy Group & Taxanomy Columns as per the input from the XML file

.NOTES

-----------------------------------------------------------------------------------------------------------------------------------
Script name : createtaxanomyscript.ps1
Authors : Microsoft Services
Version : V1.0
Dependencies : SharePoint Online PnP PowerShell cmdlets
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
Version Changes:
Date:       Version: Changed By:         Info:
17/07/2020  V1.0     Microsoft Services  Initial script creation
-----------------------------------------------------------------------------------------------------------------------------------
#>
[CmdletBinding()]
param (
  $tenant, # Enter the tenant name
  $TemplateParametersFile,
  $sp_user,
  $sp_password,
  $InstrumentationKey
)

Write-host "Started" -ForegroundColor Green

Write-host $TemplateParametersFile -ForegroundColor Yellow
Write-host $tenant -ForegroundColor Yellow

$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
$JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
  $JsonParameters = $JsonParameters.parameters
}

$RoleName = $JsonParameters.RoleName.value


Write-host $InstrumentationKey -ForegroundColor Yellow
Write-host $contenttypehub -ForegroundColor Yellow
Write-host $sp_user -ForegroundColor Yellow
Write-host $sp_password -ForegroundColor Yellow

$secstr = New-Object -TypeName System.Security.SecureString
$sp_password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }

$contenttypehub = "https://" + $tenant + ".sharepoint.com/sites/contentTypeHub"
Write-host $contenttypehub -ForegroundColor Yellow

#region --Taxonomy Creation ---
function Create-Taxanomy() {

  try {
    Add-Type -Path (Resolve-Path $PSScriptRoot'.\Assemblies\Microsoft.SharePoint.Client.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'.\Assemblies\Microsoft.SharePoint.Client.Runtime.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'.\Assemblies\Microsoft.SharePoint.Client.Taxonomy.dll')
    Add-Type -Path (Resolve-Path $PSScriptRoot'.\Assemblies\Microsoft.ApplicationInsights.dll')

    $client = New-Object Microsoft.ApplicationInsights.TelemetryClient  
    
    $client.InstrumentationKey = $InstrumentationKey
    if (($null -ne $client.Context) -and ($null -ne $client.Context.Cloud)) {
      $client.Context.Cloud.RoleName = $RoleName
    }

    $client.TrackEvent("Main function started...")

    $spContext = New-Object Microsoft.SharePoint.Client.ClientContext($contenttypehub)
    $admin = $sp_user
    $password = $secstr
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin, $password)
    $spContext.Credentials = $credentials
    $web = $spContext.Web
    $spContext.Load($web)
    $spContext.ExecuteQuery()

  }
  catch {
    Write-host "Error in Authentication..." $_.Exception.Message -ForegroundColor Red 
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = "Error in Authentication..." + $_.Exception.Message  
    $client.TrackException($telemtryException) 
  }

  $client.TrackEvent("Authentication success...")

  $termsPath = Resolve-Path $PSScriptRoot'.\resources\Taxonomy.xml'

  $client.TrackEvent("Reading Term Store Info & Terms started")

  $termStore = Get-TermStoreInfo $spContext
  $termsXML = Get-TermsToImport $termsPath

    

  Create-Groups $spContext $termStore $termsXML

  Write-host "Completed" -ForegroundColor Green
  $client.TrackEvent("Completed...")
}
   
function Get-TermStoreInfo($spContext) {
  $spTaxSession = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($spContext)
  $spTaxSession.UpdateCache();
  $spContext.Load($spTaxSession)

  try {
    $spContext.ExecuteQuery()
    $client.TrackEvent("Reading Term Store Info & Terms completed")
  }
  catch {
    Write-host "Error while loading the Taxonomy Session " $_.Exception.Message -ForegroundColor Red 
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException) 
  }

  if ($spTaxSession.TermStores.Count -eq 0) {
    write-host "The Taxonomy Service is offline or missing" -ForegroundColor Red
    $client.TrackEvent("The Taxonomy Service is offline or missing.")
  }

  $termStores = $spTaxSession.TermStores
  $spContext.Load($termStores)

  try {
    $spContext.ExecuteQuery()
    $termStore = $termStores[0]
    Write-Host "Connected to TermStore: $($termStore.Name) ID: $($termStore.Id)"
    $client.TrackEvent("Connected to TermStore: $($termStore.Name) ID: $($termStore.Id)")
  }
  catch {
    Write-host "Error details while getting term store ID" $_.Exception.Message -ForegroundColor Red
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }

  return $termStore

}

function Get-TermsToImport($xmlTermsPath) {
  [Reflection.Assembly]::LoadWithPartialName("System.Xml.Linq") | Out-Null

  try {
    $xDoc = [System.Xml.Linq.XDocument]::Load($xmlTermsPath, [System.Xml.Linq.LoadOptions]::None)
    return $xDoc
  }
  catch {
    Write-Host "Unable to read taxonomy xml. Exception:" $_.Exception.Message -ForegroundColor Red
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
    $telemtryException.Exception = $_.Exception.Message  
    $client.TrackException($telemtryException)
  }
}

function Create-Groups($spContext, $termStore, $termsXML) {
     
  foreach ($groupNode in $termsXML.Descendants("Group")) {
    $client.TrackEvent("Group creation for Taxanomy started...")
    $group = $null;
    $name = Get-AttributeValue $groupNode "Name"
    if ($name -ne '') {
      $description = Get-AttributeValue $groupNode "Description"
        
      Write-Host "Processing Group: $name " -NoNewline
      $client.TrackEvent("Processing Group: $name")

      $spContext.Load($termStore.Groups);
      $spContext.ExecuteQuery();

      $group = $termStore.Groups | Where-Object { $_.Name -eq $name }
	
      if ($group.Name -eq $null) {
        $groupGuid = [GUID]::NewGuid();
        $group = $termStore.CreateGroup($name, $groupGuid);
           
        $spContext.Load($group);

        try {
          $spContext.ExecuteQuery();
          write-host "Inserted" -ForegroundColor Green
          $client.TrackEvent("Group Inserted, Name: " + $group.Name)
        }
        catch {
          Write-host "Error creating new Group " $name " " $_.Exception.Message -ForegroundColor Red 
          $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"  
          $telemtryException.Exception = "Error creating new Group " + $name + $_.Exception.Message  
          $client.TrackException($telemtryException)
        }
      }
      else {
        write-host "Already exists" -ForegroundColor Yellow
        $client.TrackEvent("Group Already exists, " + $group.Name)
      }
	
      Create-TermSets $termsXML $group $termStore $spContext
    }
    else {
      Write-Host "Name missing for the group in Taxonomy xml"
      $client.TrackEvent("Name missing for the group in Taxonomy xml")
    }

  }

  try {
    $termStore.CommitAll();
    $spContext.ExecuteQuery();
  }
  catch {
    Write-Host "Error commiting changes to server. Exception:$_.Exception.Message" -foregroundcolor red
    $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"
    $telemtryException.Exception = "Error commiting changes to server," + $_.Exception.Message
    $client.TrackException($telemtryException)
  }
}

function Create-TermSets($termsXML, $group, $termStore, $spContext) {
	
  $termSets = $termsXML.Descendants("TermSet") | Where { $_.Parent.Parent.Attribute("Name").Value -eq $group.Name }

  #Check if the given term set exists already

  $termSetsInTermStore = $group.TermSets
  $spContext.Load($termSetsInTermStore)
  $spContext.ExecuteQuery()

  foreach ($termSetNode in $termSets) {
    $errorOccurred = $false


    $name = Get-AttributeValue $termSetNode "Name"
    if ($name -ne '') {
      $id = [GUID]::NewGuid();
      $description = Get-AttributeValue $termSetNode "Description"
      $customSortOrder = Get-AttributeValue $termSetNode "CustomSortOrder"
      Write-host "Processing TermSet $name ... " -NoNewLine
      $client.TrackEvent("Processing TermSet $name ...")
		
      $termSet = $termSetsInTermStore | Where-Object { $_.Name -eq $name }
                
		
      if ($termSet -eq $null -or $termSet -eq '') {
        $termSet = $group.CreateTermSet($name, $id, $termStore.DefaultLanguage);
        $termSet.Description = $description;
            
        if ($customSortOrder -ne $null) {
          $termSet.CustomSortOrder = $customSortOrder
        }
            
        $termSet.IsAvailableForTagging = Get-BooleanAttributeValue $termSetNode "IsAvailableForTagging" 
        $termSet.IsOpenForTermCreation = Get-BooleanAttributeValue $termSetNode "IsOpenForTermCreation"

        try {
          #load terms
          $termSet = $termStore.GetTermSet($id);
          $spContext.Load($termSet)
          $spContext.ExecuteQuery()
        }
        catch {
          Write-host "Error occured while create Term Set" $name $_.Exception.Message -ForegroundColor Red
          $errorOccurred = $true
                    
          $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"
          $telemtryException.Exception = "Error occured while create Term Set " + $name, + $_.Exception.Message
          $client.TrackException($telemtryException)
        }

        write-host "created" -ForegroundColor Green
        $client.TrackEvent("Term Set created, " + $name)
      }
      else {
        write-host "Already exists" -ForegroundColor Yellow
        $client.TrackEvent("Term Set Already exists, " + $name)
      }
			
      $termSetTerms = $termSet.GetAllTerms()
      $spContext.Load($termSetTerms)
      $spContext.ExecuteQuery()
        
      if (!$errorOccurred) {
        if ($termSetNode.Element("Terms") -ne $null -and $termSetNode.Element("Terms").Elements("Term") -ne $null) {
               
          foreach ($termNode in $termSetNode.Element("Terms").Elements("Term")) {
            Create-Term $termNode $null $termSet $termStore $termStore.DefaultLanguage $spContext $termSetTerms                  
          }
        }	
      }						
    }
    else {
      Write-Host "Name missing for the termset in Taxonomy xml"
      $client.TrackEvent("Name missing for the termset in Taxonomy xml")
    }

  }
}

function Create-Term($termNode, $parentTerm, $termSet, $store, $lcid, $spContext, $termSetTerms) {
  $id = [GUID]::NewGuid();
  $name = Get-AttributeValue $termNode "Name"
  $isUpdated = Get-BooleanAttributeValue $termNode "isUpdated"
    
  if ($name -ne '') {
   
    $term = $null;
    if ($termSetTerms -ne $null -or $termSetTerms -ne '') {
      $term = $termSetTerms | Where-Object { $_.Name -eq $name }
      if ($term -ne $null) {
        $spContext.Load($term);
        $spContext.ExecuteQuery();
      }
        
    }

    $errorOccurred = $false
	
    write-host "Processing Term $name ..." -NoNewLine 
    $client.TrackEvent("Processing Term $name ...")

    if (($term -eq $null -or $term -eq '') -and -not($isUpdated) ) {
      if ($parentTerm -ne $null) {
        $term = $parentTerm.CreateTerm($name, $lcid, $id);
      }
      else {
        
        $term = $termSet.CreateTerm($name, $lcid, $id);
      }

      $term.IsAvailableForTagging = Get-BooleanAttributeValue $termNode "IsAvailableForTagging"
      if ($customSortOrder -ne $null) {
        $term.CustomSortOrder = $customSortOrder
      }

            
      if ($termNode.Element("Labels") -ne $null -and $termNode.Element("Labels").Elements("Label") -ne $null) {
        foreach ($label in $termNode.Element("Labels").Elements("Label")) {
          $isLanguageDefault = Get-BooleanAttributeValue $label "IsDefaultForLanguage"
          if ( $isLanguageDefault -ne $true) {
            $labelValue = Get-AttributeValue $label "Value"
            $labelLanguage = Get-AttributeValue $label "Language"
            $labelIsDefaultLabel = Get-BooleanAttributeValue $label "IsDefaultForLanguage"
            $labelTerm = $term.CreateLabel($labelValue, [int]$labelLanguage, $labelIsDefaultLabel)
          }
        }
      }


      try {
        $spContext.Load($term);
        $spContext.ExecuteQuery();
        write-host " created" -ForegroundColor Green
        $client.TrackEvent("Term created, $name")	
      }
      catch {
        Write-host "Error occured while create Term" $name $_.Exception.Message -ForegroundColor Red
        $errorOccurred = $true
                
        $telemtryException = New-Object "Microsoft.ApplicationInsights.DataContracts.ExceptionTelemetry"
        $telemtryException.Exception = "Error occured while create Term " + $name + $_.Exception.Message
        $client.TrackException($telemtryException)
      }
    }
    else {
      # Rename term
      if ($term -eq $null -or $term -eq '') {
        Write-host "Term does not exist. It was renamed" -ForegroundColor Yellow
        $client.TrackEvent("Term does not exist. It was renamed")
            
      }
      else {
        Rename-Term $termNode $term $name
      }
            
    }
     
    if (!$errorOccurred) {
      if ($termNode.Element("Terms") -ne $null -and $termNode.Element("Terms").Elements("Term") -ne $null) {
        $allTerms = $termSet.GetAllTerms()
        $spContext.Load($allTerms)
        $spContext.ExecuteQuery()

        foreach ($childTermNode in $termNode.Element("Terms").Elements("Term")) {
          Create-Term $childTermNode $term $termSet $store $lcid $spContext $allTerms
        }
      }

    }
  }
  else {
    Write-Host "Name missing for the term in Taxonomy xml"
    $client.TrackEvent("Name missing for the term in Taxonomy xml")
  }
}

function Rename-Term($termNode, $term) {

  $name = Get-AttributeValue $termNode "Name"
  $isUpdated = Get-BooleanAttributeValue $termNode "isUpdated"
  if ($isUpdated) {
    $newName = Get-AttributeValue $termNode "UpdatedName"
    $term.name = $newName
    write-host $name "updated to "$newName -ForegroundColor Green
    $client.TrackEvent($name + " updated to " + $newName)
  }
  else {
    write-host "Already exists" -ForegroundColor Yellow
    $client.TrackEvent("Already exists")
  }

}

function Get-AttributeValue($node, $attributeName) {

  $attributeValue = ''
  if ($node.Attribute($attributeName) -ne $null) {
    $attributeValue = $node.Attributes($attributeName).Value
  }

  return $attributeValue

}

function Get-BooleanAttributeValue($node, $attributeName) {

  $booleanAttributeValue = $false
  $attributeValue = Get-AttributeValue $node $attributeName
  if ($attributeValue -ne '') {
    $booleanAttributeValue = [bool]::Parse($attributeValue)
  }

  return $booleanAttributeValue

}

#endregion

Create-Taxanomy



   
