# Blob logging configuration - Replace these values with your actual storage account details
$STORAGE_SAS_TOKEN = "?sv=2024-11-04&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2026-01-30T22:09:19Z&st=2025-11-05T13:54:19Z&spr=https&sig=mBoL3bVHPGSniTeFzXZ5QdItTxaFYOrhXIOzzM2jvF0%3D"  # Replace with your SAS token
$environmentName = "lab@lab.LabInstance.ID"
$resourceGroup = "on-prem"

$STORAGE_ACCOUNT_NAME = "azmdeploymentlogs"  # Replace with your storage account name
$CONTAINER_NAME = "logs"

# Initialize logging

$LOG_BLOB_NAME = "$environmentName.log"

function Write-LogToBlob {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console
    Write-Host $logEntry
    
    # Write to blob using Az.Storage commands
    try {
        # Create storage context using SAS token
        $ctx = New-AzStorageContext -StorageAccountName $STORAGE_ACCOUNT_NAME -SasToken $STORAGE_SAS_TOKEN
        
        # Get existing blob content to append
        $existingContent = ""
        try {
            Get-AzStorageBlobContent -Blob $LOG_BLOB_NAME -Container $CONTAINER_NAME -Context $ctx -Force -Destination "$env:TEMP\templog.txt" -ErrorAction Stop | Out-Null
            $existingContent = Get-Content "$env:TEMP\templog.txt" -Raw -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\templog.txt" -Force -ErrorAction SilentlyContinue
        }
        catch {
            # Blob doesn't exist yet, that's fine
            Write-Host "Creating new log blob..." -ForegroundColor Yellow
        }
        
        # Append new log entry
        $newContent = $existingContent + $logEntry + "`n"
        
        # Write back to blob
        $tempFile = "$env:TEMP\$([System.Guid]::NewGuid()).txt"
        Set-Content -Path $tempFile -Value $newContent -NoNewline
        Set-AzStorageBlobContent -File $tempFile -Blob $LOG_BLOB_NAME -Container $CONTAINER_NAME -Context $ctx -Force | Out-Null
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        
    }
    catch {
        Write-Host "Failed to write log to blob: $($_.Exception.Message)" -ForegroundColor Red
        # Fallback to local file if blob fails
        $localLogFile = ".\script-execution.log"
        Add-Content -Path $localLogFile -Value $logEntry
    }
}

function Initialize-LogBlob {
    try {
        # Create storage context using SAS token
        $ctx = New-AzStorageContext -StorageAccountName $STORAGE_ACCOUNT_NAME -SasToken $STORAGE_SAS_TOKEN
        
        $initialLog = "=== Script execution started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===`nEnvironment: $environmentName`n"
        
        # Create initial log file
        $tempFile = "$env:TEMP\$([System.Guid]::NewGuid()).txt"
        Set-Content -Path $tempFile -Value $initialLog -NoNewline
        
        # Upload to blob
        Set-AzStorageBlobContent -File $tempFile -Blob $LOG_BLOB_NAME -Container $CONTAINER_NAME -Context $ctx -Force | Out-Null
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        
        Write-Host "Initialized log blob: $LOG_BLOB_NAME" -ForegroundColor Green
        
    }
    catch {
        Write-Host "Failed to initialize log blob: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Check if storage account '$STORAGE_ACCOUNT_NAME' and container '$CONTAINER_NAME' exist" -ForegroundColor Red
        Write-Host "Also verify SAS token permissions and expiration" -ForegroundColor Red
        
        # Fallback to local file
        $localLogFile = ".\script-execution.log"
        $initialLog = "=== Script execution started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===`nEnvironment: $environmentName`n"
        Set-Content -Path $localLogFile -Value $initialLog -NoNewline
        Write-Host "Created local log file as fallback: $localLogFile" -ForegroundColor Yellow
    }
}

# Initialize the log blob
Initialize-LogBlob

Write-LogToBlob "Starting LAB: $environmentName"
Write-LogToBlob "Starting script execution for environment: $environmentName"

try {
    $subscriptionId = (Get-AzContext).Subscription.Id
    $masterSiteName = "$($environmentName)mastersite"
    $migrateProjectName = "${environmentName}-azm"

    $apiVersionOffAzure = "2024-12-01-preview"

    $remoteZipFilePath = "https://github.com/crgarcia12/migrate-modernize-lab/raw/refs/heads/main/lab-material/Azure-Migrate-Discovery.zip"
    $localZipFilePath = Join-Path (Get-Location) "importArtifacts.zip"
    Write-LogToBlob "Downloading artifacts from: $remoteZipFilePath"
    Invoke-WebRequest $remoteZipFilePath -OutFile $localZipFilePath
    Write-LogToBlob "Downloaded artifacts to: $localZipFilePath"

    # Skillable deployment is through their platform
    # Create resource group and deploy ARM template
    # Write-LogToBlob "Creating resource group: ${environmentName}-rg"
    # New-AzResourceGroup -Name "${environmentName}-rg" -Location "swedencentral"
    # Write-LogToBlob "Deploying ARM template..."
    # New-AzResourceGroupDeployment `
    #     -Name $environmentName `
    #     -ResourceGroupName "${environmentName}-rg" `
    #     -TemplateFile '.\templates\lab197959-template2 (v6).json' `
    #     -prefix $environmentName `
    #     -Verbose

    # Get access token for REST API calls
    Write-LogToBlob "Getting access token for REST API calls"
    $accessTokenObject = Get-AzAccessToken -ResourceUrl "https://management.azure.com/"
    
    # Handle both SecureString and plain string token formats
    if ($accessTokenObject.Token -is [System.Security.SecureString]) {
        # Token is SecureString (newer Azure PowerShell versions)
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($accessTokenObject.Token))
    } else {
        # Token is already a plain string (older Azure PowerShell versions)
        $token = $accessTokenObject.Token
    }

    $headers = @{} 
    $headers.Add("authorization", "Bearer $token")
    $headers.Add("content-type", "application/json") 
    Write-LogToBlob "Bearer token: " + $token

    $registerToolApi = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Migrate/MigrateProjects/$migrateProjectName/registerTool?api-version=2020-06-01-preview"
    Write-LogToBlob "Registering Server Discovery tool"
    Write-LogToBlob "uri: $registerToolApi"
    Invoke-RestMethod -Uri $registerToolApi `
        -Method POST `
        -Headers $headers `
        -ContentType 'application/json' `
        -Body '{   "tool": "ServerDiscovery" }' | Out-Null
    Write-LogToBlob "Server Discovery tool registered successfully"

    Write-LogToBlob "Registering Server Assessment tool"
    Invoke-RestMethod -Uri $registerToolApi `
        -Method POST `
        -Headers $headers `
        -ContentType 'application/json' `
        -Body '{   "tool": "ServerAssessment" }' | Out-Null
    Write-LogToBlob "Server Assessment tool registered successfully"




    # Upload the ZIP file to OffAzure and start import
    $importUriUrl = "https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.OffAzure/masterSites/${masterSiteName}/Import?api-version=${apiVersionOffAzure}"
    Write-LogToBlob "Starting import process..."
    $importdiscoveredArtifactsResponse = Invoke-RestMethod -Uri $importUriUrl -Method POST -Headers $headers
    $blobUri = $importdiscoveredArtifactsResponse.uri
    $jobArmId = $importdiscoveredArtifactsResponse.jobArmId

    Write-LogToBlob "Blob URI: $blobUri"
    Write-LogToBlob "Job ARM ID: $jobArmId"

    Write-LogToBlob "Uploading ZIP to blob..."
    $fileBytes = [System.IO.File]::ReadAllBytes($localZipFilePath)
    $uploadBlobHeaders = @{
        "x-ms-blob-type" = "BlockBlob"
        "x-ms-version"   = "2020-04-08"
    }
    Invoke-RestMethod -Uri $blobUri -Method PUT -Headers $uploadBlobHeaders -Body $fileBytes -ContentType "application/octet-stream"
    Write-LogToBlob "Successfully uploaded ZIP to blob"

    $jobUrl = "https://management.azure.com${jobArmId}?api-version=${apiVersionOffAzure}"
 
    Write-LogToBlob "Polling import job status..."
    $waitTimeSeconds = 20
    $maxAttempts = 50 * (60 / $waitTimeSeconds)  # 50 minutes timeout
    $attempt = 0
    $jobCompleted = $false
 
    do {
        $jobStatus = Invoke-RestMethod -Uri $jobUrl -Method GET -Headers $headers
        $jobResult = $jobStatus.properties.jobResult
        Write-LogToBlob "Attempt $($attempt): Job status - $jobResult"

        if ($jobResult -eq "Completed") {
            $jobCompleted = $true
            break
        }
        elseif ($jobResult -eq "Failed") {
            Write-LogToBlob "Import job failed" "ERROR"
            throw "Import job failed."
        }
 
        Start-Sleep -Seconds $waitTimeSeconds
        $attempt++
    } while ($attempt -lt $maxAttempts)
 
    if (-not $jobCompleted) {
        Write-LogToBlob "Timed out waiting for import job to complete" "ERROR"
        throw "Timed out waiting for import job to complete."
    }
    else {
        Write-LogToBlob "Import job completed successfully. Imported machines."
    }


    $environmentName = "mig19"
    $resourceGroup = "$environmentName-rg"



    # Create VMware Collector
    Write-LogToBlob "Creating VMware Collector" -ErrorAction Continue
    $assessmentProjectName = "${environmentName}asmproject"
    $vmwarecollectorName = "${environmentName}vmwaresitevmwarecollector"

    # Get site first
    $vmwareSiteUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.OffAzure/VMwareSites/$($environmentName)vmwaresite?api-version=2024-12-01-preview"
    $vmwareSiteResponse = Invoke-RestMethod -Uri $vmwareSiteUri -Method GET -Headers $headers


    $vmwareCollectorUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/vmwarecollectors/$($vmwarecollectorName)?api-version=2018-06-30-preview"
    $vmwareCollectorBody = @{
        "id" = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/vmwarecollectors/$vmwarecollectorName"
        "name" = "$vmwarecollectorName"
        "type" = "Microsoft.Migrate/assessmentprojects/vmwarecollectors"
        "properties" = @{
            "agentProperties" = @{
                "id" = "$($vmwareSiteResponse.properties.agentDetails.id)"
                "lastHeartbeatUtc" = "2025-04-24T09:48:04.3893222Z"
                "spnDetails" = @{
                    "authority" = "authority"
                    "applicationId" = "appId"
                    "audience" = "audience"
                    "objectId" = "objectid"
                    "tenantId" = "tenantid"
                }
            }
            "discoverySiteId" = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.OffAzure/VMwareSites/$($environmentName)vmwaresite"
        }
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri $vmwareCollectorUri `
        -Method PUT `
        -Headers $headers `
        -ContentType 'application/json' `
        -Body $vmwareCollectorBody    

    # Script execution completed
    Write-LogToBlob "Script execution completed"

}
catch {
    Write-LogToBlob "Script execution failed: $($_.Exception.Message)" "ERROR"
    throw
}