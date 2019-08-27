<# 
Dit script draait als Azure runbook en ververst ieder uur de JSON files in de blobstorage.
Voor meer info: https://hermanronk.nl
Code: https://github.com/HermanRonk/ProfitExportToAzureBlob

Het is eigenlijk netter om de Azure Credential store in Azure automation te gebruiken, maar voor deze voorbeeld code heb ik dat even achterwegen gelaten.

#>

# 1. Profit variabelen
$token = 'Voer hier het token in dat je op profitkey.hermanronk.nl gemaakt hebt'
$encodedToken = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($token))
$authValue = "AfasToken $encodedToken"
$Headers = @{
    Authorization = $authValue
}
$url = 'https://**URL_VAN_PROFIT_OMGEVING**/Profitrestservices/metainfo'
$file = '.\todo.json'

# 2. Azure variabelen
$StorageAccountName = 'Naam van Storage Account'
$StorageSAKey = 'Access Key Storage Account '
$ContainerName = "Naam van Storage blob"

# 3. Azure connectie:
$connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzureRmAccount -ServicePrincipal -Tenant $connection.TenantID -ApplicationID $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint
$context = New-AzureStorageContext -StorageAccountName $StorageAccountname -StorageAccountKey $StorageSAKey
Set-AzureRmCurrentStorageAccount -Context $Context

# 4. Profit Data ophalen
Invoke-WebRequest -Uri $url -OutFile $file -Headers $Headers
$todo = Get-Content -Raw -Path $file | ConvertFrom-Json
foreach ($conn in $todo.getConnectors.id) {
    $url = 'https://**URL_VAN_PROFIT_OMGEVING**/profitrestservices/connectors/' + $conn + '?skip=-1&take=-1'
    $file = '.\' + $conn + '.json'
    Invoke-WebRequest -Uri $url -OutFile $file -Headers $Headers -UseBasicParsing
    $filename = $conn + '.json'
    Set-azurestorageblobcontent -File $file -container $ContainerName -Blob $filename -Context $Context -Force
}
