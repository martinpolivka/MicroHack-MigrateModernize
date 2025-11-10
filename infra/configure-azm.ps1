Set-StrictMode -Version 3.0

######################################################
##############   CONFIGURATIONS   ###################
######################################################

$SkillableEnvironment = $false
$environmentName = "crgmig23" # Set your environment name here for non-Skillable environments

######################################################
##############   INFRASTRUCTURE FUNCTIONS   #########
######################################################

function Import-AzureModules {
    Write-LogToBlob "Importing Azure PowerShell modules"
    
    # Ensure we're using Az modules and remove any AzureRM conflicts
    Import-Module Az.Accounts, Az.Resources -Force
    Get-Module -Name AzureRM* | Remove-Module -Force
    
    Write-LogToBlob "Azure PowerShell modules imported successfully"
}
function Get-AuthenticationHeaders {
    Write-LogToBlob "Getting access token for REST API calls"
    
    try {
        $accessTokenObject = Get-AzAccessToken -ResourceUrl "https://management.azure.com/"
        
        # Handle both SecureString and plain string token formats
        if ($accessTokenObject.Token -is [System.Security.SecureString]) {
            $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($accessTokenObject.Token))
        }
        else {
            $token = $accessTokenObject.Token
        }

        $headers = @{
            "authorization" = "Bearer $token"
            "content-type"  = "application/json"
        }
        
        Write-LogToBlob "Authentication headers obtained successfully"
        
        return $headers
    }
    catch {
        Write-LogToBlob "Failed to get authentication headers: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Get-EnvironmentLocation {
    param(
        [string]$EnvironmentName
    )
    
    # Determine resource group name based on environment type
    $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
    
    try {
        $existingRg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
        if ($existingRg) {
            return $existingRg.Location
        } else {
            return "swedencentral"  # Default to Sweden as requested
        }
    } catch {
        return "swedencentral"  # Fallback to Sweden
    }
}

function New-AzureEnvironment {
    param(
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Creating Azure environment: $EnvironmentName"
    
    try {
        # Get location from existing resource group or use Sweden as default
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $location = Get-EnvironmentLocation -EnvironmentName $EnvironmentName
        
        Write-LogToBlob "Environment location: $location"
        
        $templateFile = '.\templates\lab197959-template2 (v6).json'
        
        Write-LogToBlob "Creating resource group: $resourceGroupName"
        New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
        
        Write-LogToBlob "Deploying ARM template..."
        New-AzResourceGroupDeployment `
            -Name $EnvironmentName `
            -ResourceGroupName $resourceGroupName `
            -TemplateFile $templateFile `
            -prefix $EnvironmentName `
            -Verbose
        
        Write-LogToBlob "Azure environment created successfully"
    }
    catch {
        Write-LogToBlob "Failed to create Azure environment: $($_.Exception.Message)" "ERROR"
        throw
    }
}

######################################################
##############   LOGGING FUNCTIONS   ################
######################################################

function Write-LogToBlob {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    # Hardcoded storage account data
    $STORAGE_SAS_TOKEN = "?sv=2024-11-04&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2026-01-30T22:09:19Z&st=2025-11-05T13:54:19Z&spr=https&sig=mBoL3bVHPGSniTeFzXZ5QdItTxaFYOrhXIOzzM2jvF0%3D"
    $STORAGE_ACCOUNT_NAME = "azmdeploymentlogs"
    $CONTAINER_NAME = "logs"
    $LOG_BLOB_NAME = "$environmentName.log.txt"
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console
    Write-Host $logEntry
    
    if ($SkillableEnvironment -eq $false) {
        return
    }

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
    # Hardcoded storage account data
    $STORAGE_SAS_TOKEN = "?sv=2024-11-04&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2026-01-30T22:09:19Z&st=2025-11-05T13:54:19Z&spr=https&sig=mBoL3bVHPGSniTeFzXZ5QdItTxaFYOrhXIOzzM2jvF0%3D"
    $STORAGE_ACCOUNT_NAME = "azmdeploymentlogs"
    $CONTAINER_NAME = "logs"
    $LOG_BLOB_NAME = "$environmentName.log.txt"
    
    if (-not $SkillableEnvironment) {
        Write-LogToBlob "Skillable environment disabled, skipping blob logging initialization"
        return
    }

    try {
        $ctx = New-AzStorageContext -StorageAccountName $STORAGE_ACCOUNT_NAME -SasToken $STORAGE_SAS_TOKEN
        
        $initialLog = "=== Script execution started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===`nEnvironment: $environmentName`n"
        
        $tempFile = "$env:TEMP\$([System.Guid]::NewGuid()).txt"
        Set-Content -Path $tempFile -Value $initialLog -NoNewline
        
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

######################################################
##############   MIGRATE TOOL FUNCTIONS   ###########
######################################################

function Register-MigrateTools {
    param(
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Registering Azure Migrate tools"
    
    try {
        $Headers = Get-AuthenticationHeaders
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $migrateProjectName = "${EnvironmentName}-azm"
        
        $registerToolApi = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/MigrateProjects/$migrateProjectName/registerTool?api-version=2020-06-01-preview"
        
        Write-LogToBlob "Registering Server Discovery tool"
        Write-LogToBlob "URI: $registerToolApi"
        Invoke-RestMethod -Uri $registerToolApi `
            -Method POST `
            -Headers $Headers `
            -ContentType 'application/json' `
            -Body '{"tool": "ServerDiscovery"}' | Out-Null
        Write-LogToBlob "Server Discovery tool registered successfully"

        Write-LogToBlob "Registering Server Assessment tool"
        Invoke-RestMethod -Uri $registerToolApi `
            -Method POST `
            -Headers $Headers `
            -ContentType 'application/json' `
            -Body '{"tool": "ServerAssessment"}' | Out-Null
        Write-LogToBlob "Server Assessment tool registered successfully"
    }
    catch {
        Write-LogToBlob "Failed to register Migrate tools: $($_.Exception.Message)" "ERROR"
        throw
    }
}

######################################################
##############   ARTIFACT FUNCTIONS   ###############
######################################################

function Get-DiscoveryArtifacts {
    Write-LogToBlob "Downloading discovery artifacts"
    
    try {
        $remoteZipFilePath = "https://github.com/crgarcia12/migrate-modernize-lab/raw/refs/heads/main/lab-material/Azure-Migrate-Discovery.zip"
        $localZipFilePath = Join-Path (Get-Location) "importArtifacts.zip"
        
        Write-LogToBlob "Downloading artifacts from: $remoteZipFilePath"
        Invoke-WebRequest $remoteZipFilePath -OutFile $localZipFilePath
        Write-LogToBlob "Downloaded artifacts to: $localZipFilePath"
        
        return $localZipFilePath
    }
    catch {
        Write-LogToBlob "Failed to download discovery artifacts: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Start-ArtifactImport {
    param(
        [string]$LocalZipFilePath,
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Starting artifact import process"
    
    try {
        $Headers = Get-AuthenticationHeaders
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $masterSiteName = "${EnvironmentName}mastersite"
        $apiVersionOffAzure = "2024-12-01-preview"
        
        # Upload the ZIP file to OffAzure and start import
        $importUriUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/masterSites/$masterSiteName/Import?api-version=$apiVersionOffAzure"
        Write-LogToBlob "Import URI: $importUriUrl"
        
        $importResponse = Invoke-RestMethod -Uri $importUriUrl -Method POST -Headers $Headers
        $blobUri = $importResponse.uri
        $jobArmId = $importResponse.jobArmId.Trim()

        Write-LogToBlob "Blob URI: $blobUri"
        Write-LogToBlob "Job ARM ID: $jobArmId"

        Write-LogToBlob "Uploading ZIP to blob..."
        $fileBytes = [System.IO.File]::ReadAllBytes($LocalZipFilePath)
        $uploadBlobHeaders = @{
            "x-ms-blob-type" = "BlockBlob"
            "x-ms-version"   = "2020-04-08"
        }
        Invoke-RestMethod -Uri $blobUri -Method PUT -Headers $uploadBlobHeaders -Body $fileBytes -ContentType "application/octet-stream"
        Write-LogToBlob "Successfully uploaded ZIP to blob"
        
        return $jobArmId
    }
    catch {
        Write-LogToBlob "Failed to start artifact import: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Wait-ImportJobCompletion {
    param(
        [string]$JobArmId
    )
    
    Write-LogToBlob "Waiting for import job completion"
    
    $JobArmId = $JobArmId.Trim()

    try {
        $Headers = Get-AuthenticationHeaders
        $apiVersionOffAzure = "2024-12-01-preview"
        $jobUrl = "https://management.azure.com$($JobArmId)?api-version=$apiVersionOffAzure"
        $waitTimeSeconds = 20
        $maxAttempts = 50 * (60 / $waitTimeSeconds)  # 50 minutes timeout
        $attempt = 0
        $jobCompleted = $false
     
        do {
            # Refresh token every 5 attempts (approximately every 1-3 minutes)
            if ($attempt % 5 -eq 0) {
                $Headers = Get-AuthenticationHeaders
            }
            
            $jobStatus = Invoke-RestMethod -Uri $jobUrl -Method GET -Headers $Headers
            $jobResult = $jobStatus.properties.jobResult
            Write-LogToBlob "Attempt $($attempt + 1): Job status - $jobResult"

            if ($jobResult -eq "Completed") {
                $jobCompleted = $true
                break
            }
            elseif ($jobResult -eq "Failed") {
                Write-LogToBlob "====  Import job failed === " -Level "ERROR"
                Write-LogToBlob ($jobResult | ConvertTo-Json -Depth 10) -Level "ERROR"
                Write-LogToBlob "====  End Import job failed === " -Level "ERROR"
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
            Write-LogToBlob "Import job completed successfully. Machines imported."
        }
    }
    catch {
        Write-LogToBlob "Failed while waiting for import job completion: $($_.Exception.Message)" "ERROR"
        throw
    }
}

######################################################
##############   SITE AND COLLECTOR FUNCTIONS   #####
######################################################

function Get-WebAppSiteDetails {
    param(
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Getting WebApp Site details"
    
    try {
        $Headers = Get-AuthenticationHeaders
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $masterSiteName = "${EnvironmentName}mastersite"
 $apiVersionOffAzure = "2024-12-01-preview"
        
        $webAppSiteUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/MasterSites/$masterSiteName/WebAppSites/${EnvironmentName}webappsite?api-version=$apiVersionOffAzure"
        Write-LogToBlob "WebApp Site URI: $webAppSiteUri"

        $webAppSiteResponse = Invoke-RestMethod -Uri $webAppSiteUri -Method GET -Headers $Headers
        $webAppSiteId = $webAppSiteResponse.id
        
        # Extract agent ID from siteAppliancePropertiesCollection
        $webAppAgentId = $null
        if ($webAppSiteResponse.properties.siteAppliancePropertiesCollection -and $webAppSiteResponse.properties.siteAppliancePropertiesCollection.Count -gt 0) {
            $webAppAgentId = $webAppSiteResponse.properties.siteAppliancePropertiesCollection[0].agentDetails.id
            Write-LogToBlob "WebApp Agent ID: $webAppAgentId"
        } else {
            Write-LogToBlob "No appliance properties found in WebApp site" "WARN"
        }
        
        Write-LogToBlob "WebApp Site retrieved successfully"
        
        return @{
            SiteId = $webAppSiteId
            AgentId = $webAppAgentId
        }
    }
    catch {
        Write-LogToBlob "Failed to get WebApp Site details: $($_.Exception.Message)" "WARN"
        return @{
            SiteId = $null
            AgentId = $null
        }
    }
}

function Get-SqlSiteDetails {
    param(
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Getting SQL Site details"
    
    try {
        $Headers = Get-AuthenticationHeaders
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $masterSiteName = "${EnvironmentName}mastersite"
        $apiVersionOffAzure = "2024-12-01-preview"
        
        $sqlSiteUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/MasterSites/$masterSiteName/SqlSites/${EnvironmentName}sqlsites?api-version=$apiVersionOffAzure"
        Write-LogToBlob "SQL Site URI: $sqlSiteUri"

        $sqlSiteResponse = Invoke-RestMethod -Uri $sqlSiteUri -Method GET -Headers $Headers
        $sqlSiteId = $sqlSiteResponse.id
        
        # Extract agent ID from siteAppliancePropertiesCollection
        $sqlAgentId = $null
        if ($sqlSiteResponse.properties.siteAppliancePropertiesCollection -and $sqlSiteResponse.properties.siteAppliancePropertiesCollection.Count -gt 0) {
            $sqlAgentId = $sqlSiteResponse.properties.siteAppliancePropertiesCollection[0].agentDetails.id
            Write-LogToBlob "SQL Agent ID: $sqlAgentId"
        } else {
            Write-LogToBlob "No appliance properties found in SQL site" "WARN"
        }
        
        Write-LogToBlob "SQL Site retrieved successfully"
        
        return @{
            SiteId = $sqlSiteId
            AgentId = $sqlAgentId
        }
    }
    catch {
        Write-LogToBlob "Failed to get SQL Site details: $($_.Exception.Message)" "WARN"
        return @{
            SiteId = $null
            AgentId = $null
        }
    }
}

function Get-VMwareCollectorAgentId {
    param(
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Getting VMware Collector Agent ID"
    
    try {
        $Headers = Get-AuthenticationHeaders
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
 $apiVersionOffAzure = "2024-12-01-preview"
        
        $vmwareSiteUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/VMwareSites/${EnvironmentName}vmwaresite?api-version=$apiVersionOffAzure"
        $vmwareSiteResponse = Invoke-RestMethod -Uri $vmwareSiteUri -Method GET -Headers $Headers
        
        Write-LogToBlob "VMware Site Response received"
        Write-LogToBlob "$($vmwareSiteResponse | ConvertTo-Json -Depth 10)"
        
        $agentId = $vmwareSiteResponse.properties.agentDetails.id
        Write-LogToBlob "Agent ID extracted: $agentId"
        
        return $agentId
    }
    catch {
        Write-LogToBlob "Failed to get VMware Collector Agent ID: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Invoke-VMwareCollectorSync {
    param(
        [string]$AgentId,
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Synchronizing VMware Collector"
    
    try {
        $Headers = Get-AuthenticationHeaders
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $assessmentProjectName = "${EnvironmentName}asmproject"
        $vmwareCollectorName = "${EnvironmentName}vmwaresitevmwarecollector"
        
        $vmwareCollectorUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/vmwarecollectors/$($vmwareCollectorName)?api-version=2018-06-30-preview"
        Write-LogToBlob "VMware Collector URI: $vmwareCollectorUri"
        
        $vmwareCollectorBody = @{
            "id"         = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/vmwarecollectors/$vmwareCollectorName"
            "name"       = "$vmwareCollectorName"
            "type"       = "Microsoft.Migrate/assessmentprojects/vmwarecollectors"
            "properties" = @{
                "agentProperties" = @{
                    "id"               = "$AgentId"
                    "lastHeartbeatUtc" = "2025-04-24T09:48:04.3893222Z"
                    "spnDetails"       = @{
                        "authority"     = "authority"
                        "applicationId" = "appId"
                        "audience"      = "audience"
                        "objectId"      = "objectid"
                        "tenantId"      = "tenantid"
                    }
                }
                "discoverySiteId" = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/VMwareSites/${EnvironmentName}vmwaresite"
            }
        } | ConvertTo-Json -Depth 10
        
        Write-LogToBlob "VMware Collector Body:"
        Write-LogToBlob "$vmwareCollectorBody"

        $response = Invoke-RestMethod -Uri $vmwareCollectorUri `
            -Method PUT `
            -Headers $Headers `
            -ContentType 'application/json' `
            -Body $vmwareCollectorBody

        Write-LogToBlob "VMware Collector sync response:"
        Write-LogToBlob "$($response | ConvertTo-Json -Depth 10)"
        
        Write-LogToBlob "VMware Collector synchronized successfully"
    }
    catch {
        Write-LogToBlob "Failed to synchronize VMware Collector: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function New-WebAppCollector {
    param(
        [string]$EnvironmentName,
        [string]$WebAppSiteId,
        [string]$WebAppAgentId
    )
    
    Write-LogToBlob "Creating WebApp Collector"
    
    try {
        if (-not $WebAppAgentId -or -not $WebAppSiteId) {
            Write-LogToBlob "Skipping WebApp Collector creation - missing WebApp agent ID or site ID" "WARN"
            return $false
        }

        $Headers = Get-AuthenticationHeaders

        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $assessmentProjectName = "${EnvironmentName}asmproject"
        $webAppCollectorName = "${EnvironmentName}webappsitecollector"
        $webAppApiVersion = "2025-09-09-preview"
        
        $webAppCollectorUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/webappcollectors/$($webAppCollectorName)?api-version=$webAppApiVersion"
        Write-LogToBlob "WebApp Collector URI: $webAppCollectorUri"
        
        $webAppCollectorBody = @{
            "id" = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/webappcollectors/$webAppCollectorName"
            "name" = "$webAppCollectorName"
            "type" = "Microsoft.Migrate/assessmentprojects/webappcollectors"
            "properties" = @{
                "agentProperties" = @{
                    "id" = $WebAppAgentId
                    "version" = $null
                    "lastHeartbeatUtc" = $null
                    "spnDetails" = @{
                        "authority" = "authority"
                        "applicationId" = "appId"
                        "audience" = "audience"
                        "objectId" = "objectid"
                        "tenantId" = "tenantid"
                    }
                }
                "discoverySiteId" = $WebAppSiteId
            }
        } | ConvertTo-Json -Depth 10
        
        Invoke-RestMethod -Uri $webAppCollectorUri `
            -Method PUT `
            -Headers $Headers `
            -ContentType 'application/json' `
            -Body $webAppCollectorBody | Out-Null
            
        Write-LogToBlob "WebApp Collector created successfully"
        return $true
    }
    catch {
        Write-LogToBlob "Failed to create WebApp Collector: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function New-SqlCollector {
    param(
        [string]$EnvironmentName,
        [string]$SqlSiteId,
        [string]$SqlAgentId
    )
    
    Write-LogToBlob "Creating SQL Collector"
    
    try {
        if (-not $SqlAgentId -or -not $SqlSiteId) {
            Write-LogToBlob "Skipping SQL Collector creation - missing SQL agent ID or site ID" "WARN"
            return $false
        }

        $Headers = Get-AuthenticationHeaders

        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $assessmentProjectName = "${EnvironmentName}asmproject"
        $sqlCollectorName = "${EnvironmentName}sqlsitescollector"
        $sqlApiVersion = "2025-09-09-preview"
        
        $sqlCollectorUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/sqlcollectors/$($sqlCollectorName)?api-version=$sqlApiVersion"
        Write-LogToBlob "SQL Collector URI: $sqlCollectorUri"
        
        $sqlCollectorBody = @{
            "id" = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/sqlcollectors/$sqlCollectorName"
            "name" = "$sqlCollectorName"
            "type" = "Microsoft.Migrate/assessmentprojects/sqlcollectors"
            "properties" = @{
                "agentProperties" = @{
                    "id" = $SqlAgentId
                    "version" = $null
                    "lastHeartbeatUtc" = $null
                    "spnDetails" = @{
                        "authority" = "authority"
                        "applicationId" = "appId"
                        "audience" = "audience"
                        "objectId" = "objectid"
                        "tenantId" = "tenantid"
                    }
                }
                "discoverySiteId" = $SqlSiteId
            }
        } | ConvertTo-Json -Depth 10
        
        Invoke-RestMethod -Uri $sqlCollectorUri `
            -Method PUT `
            -Headers $Headers `
            -ContentType 'application/json' `
            -Body $sqlCollectorBody | Out-Null
            
        Write-LogToBlob "SQL Collector created successfully"
        return $true
    }
    catch {
        Write-LogToBlob "Failed to create SQL Collector: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

######################################################
##############   ASSESSMENT FUNCTIONS   #############
######################################################

function New-MigrationAssessment {
    param(
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Creating migration assessment"
    
    try {
        $Headers = Get-AuthenticationHeaders
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $assessmentProjectName = "${EnvironmentName}asmproject"
        $location = Get-EnvironmentLocation -EnvironmentName $EnvironmentName
        
        $assessmentBody = @{
            "type" = "Microsoft.Migrate/assessmentprojects/assessments"
            "apiVersion" = "2024-03-03-preview"
            "name" = "$assessmentProjectName/assessment2"
            "location" = $location
            "tags" = @{}
            "kind" = "Migrate"
            "properties" = @{
                "settings" = @{
                    "performanceData" = @{
                        "timeRange" = "Day"
                        "percentile" = "Percentile95"
                    }
                    "scalingFactor" = 1
                    "azureSecurityOfferingType" = "MDC"
                    "azureHybridUseBenefit" = "Yes"
                    "linuxAzureHybridUseBenefit" = "Yes"
                    "savingsSettings" = @{
                        "savingsOptions" = "RI3Year"
                    }
                    "billingSettings" = @{
                        "licensingProgram" = "Retail"
                        "subscriptionId" = "$subscriptionId"
                    }
                    "azureDiskTypes" = @()
                    "azureLocation" = $location
                    "azureVmFamilies" = @()
                    "environmentType" = "Production"
                    "currency" = "USD"
                    "discountPercentage" = 0
                    "sizingCriterion" = "PerformanceBased"
                    "azurePricingTier" = "Standard"
                    "azureStorageRedundancy" = "LocallyRedundant"
                    "vmUptime" = @{
                        "daysPerMonth" = "31"
                        "hoursPerDay" = "24"
                    }
                }
                "details" = @{}
                "scope" = @{
                    "azureResourceGraphQuery" = @"
migrateresources
| where id contains "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/vmwareSites/${EnvironmentName}vmwaresite"
"@
                    "scopeType" = "AzureResourceGraphQuery"
                }
            }
        } | ConvertTo-Json -Depth 10

        $assessmentUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentProjects/$assessmentProjectName/assessments/assessment2?api-version=2024-03-03-preview"
        
        Write-LogToBlob "Assessment URI: $assessmentUri"
        Write-LogToBlob "Assessment Body: $assessmentBody"
        
        $response = Invoke-RestMethod `
            -Uri $assessmentUri `
            -Method PUT `
            -Headers $Headers `
            -ContentType 'application/json' `
            -Body $assessmentBody

        Write-LogToBlob "Assessment created successfully"
        Write-LogToBlob "Assessment response: $($response | ConvertTo-Json -Depth 10)"
    }
    catch {
        Write-LogToBlob "Failed to create migration assessment: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function New-SqlAssessment {
    param(
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Creating SQL Assessment"
    
    try {
        $Headers = Get-AuthenticationHeaders
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $assessmentProjectName = "${EnvironmentName}asmproject"
        $masterSiteName = "${EnvironmentName}mastersite"
        $location = Get-EnvironmentLocation -EnvironmentName $EnvironmentName
        
        # Generate random suffix for assessment name
        $assessmentRandomSuffix = -join ((65..90) + (97..122) | Get-Random -Count 3 | ForEach-Object {[char]$_})
        $assessmentName = "assessment$assessmentRandomSuffix"
        $apiVersion = "2024-03-03-preview"
        
        $assessmentBody = @{
            "type" = "Microsoft.Migrate/assessmentprojects/assessments"
            "apiVersion" = "$apiVersion"
            "name" = "$assessmentProjectName/$assessmentName"
            "location" = $location
            "tags" = @{}
            "kind" = "Migrate"
            "properties" = @{
                "settings" = @{
                    "performanceData" = @{
                        "timeRange" = "Day"
                        "percentile" = "Percentile95"
                    }
                    "scalingFactor" = 1
                    "azureSecurityOfferingType" = "MDC"
                    "osLicense" = "Yes"
                    "azureLocation" = $location
                    "preferredTargets" = @("SqlMI")
                    "discountPercentage" = 0
                    "currency" = "USD"
                    "sizingCriterion" = "PerformanceBased"
                    "savingsSettings" = @{
                        "savingsOptions" = "SavingsPlan1Year"
                    }
                    "billingSettings" = @{
                        "licensingProgram" = "Retail"
                        "subscriptionId" = "$subscriptionId"
                    }
                    "sqlServerLicense" = "Yes"
                    "azureSqlVmSettings" = @{
                        "instanceSeries" = @(
                            "Ddsv4_series",
                            "Ddv4_series",
                            "Edsv4_series",
                            "Edv4_series"
                        )
                    }
                    "entityUptime" = @{
                        "daysPerMonth" = 31
                        "hoursPerDay" = 24
                    }
                    "azureSqlManagedInstanceSettings" = @{
                        "azureSqlInstanceType" = "SingleInstance"
                        "azureSqlServiceTier" = "SqlServiceTier_Automatic"
                    }
                    "azureSqlDatabaseSettings" = @{
                        "azureSqlComputeTier" = "Provisioned"
                        "azureSqlPurchaseModel" = "VCore"
                        "azureSqlServiceTier" = "SqlServiceTier_Automatic"
                        "azureSqlDataBaseType" = "SingleDatabase"
                    }
                    "environmentType" = "Production"
                    "enableHadrAssessment" = $true
                    "disasterRecoveryLocation" = $location
                    "multiSubnetIntent" = "DisasterRecovery"
                    "isInternetAccessAvailable" = $true
                    "asyncCommitModeIntent" = "DisasterRecovery"
                }
                "details" = @{}
                "scope" = @{
                    "azureResourceGraphQuery" = @"
migrateresources
| where id contains "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/vmwareSites/${EnvironmentName}vmwaresite" or
    id contains "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/MasterSites/$masterSiteName/WebAppSites/${EnvironmentName}webappsite" or
    id contains "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/MasterSites/$masterSiteName/SqlSites/${EnvironmentName}sqlsites"
"@
                    "scopeType" = "AzureResourceGraphQuery"
                }
            }
        } | ConvertTo-Json -Depth 10

        $assessmentUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/sqlassessments/$($assessmentName)?api-version=$apiVersion"
        
        Write-LogToBlob "SQL Assessment URI: $assessmentUri"
        Write-LogToBlob "SQL Assessment Body: $assessmentBody"
        
        $response = Invoke-RestMethod `
            -Uri $assessmentUri `
            -Method PUT `
            -Headers $Headers `
            -ContentType 'application/json' `
            -Body $assessmentBody

        Write-LogToBlob "SQL Assessment created successfully"
        Write-LogToBlob "SQL Assessment response: $($response | ConvertTo-Json -Depth 10)"
        
        return $assessmentName
    }
    catch {
        Write-LogToBlob "Failed to create SQL assessment: $($_.Exception.Message)" "ERROR"
        throw
    }
}

######################################################
##############   BUSINESS CASE FUNCTIONS   ##########
######################################################

function New-BusinessCaseOptimizeForPaas {
    param(
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Creating OptimizeForPaas Business Case"
    
    try {
        $Headers = Get-AuthenticationHeaders
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $assessmentProjectName = "${EnvironmentName}asmproject"
        $masterSiteName = "${EnvironmentName}mastersite"
        $location = Get-EnvironmentLocation -EnvironmentName $EnvironmentName
        
        # Generate random suffix for business case name
        $randomSuffix = -join ((65..90) + (97..122) | Get-Random -Count 3 | ForEach-Object {[char]$_})
        $businessCaseName = "buizzcase$randomSuffix"
        $businessCaseApiVersion = "2025-09-09-preview"
        
        $businessCaseBody = @{
            "type" = "Microsoft.Migrate/assessmentprojects/businesscases"
            "apiVersion" = "$businessCaseApiVersion"
            "name" = "$assessmentProjectName/$businessCaseName"
            "location" = $location
            "kind" = "Migrate"
            "properties" = @{
                "businessCaseScope" = @{
                    "scopeType" = "Datacenter"
                    "azureResourceGraphQuery" = @"
migrateresources
| where id contains "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/vmwareSites/${EnvironmentName}vmwaresite" or
    id contains "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/MasterSites/$masterSiteName/WebAppSites/${EnvironmentName}webappsite" or
    id contains "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/MasterSites/$masterSiteName/SqlSites/${EnvironmentName}sqlsites"
"@
                }
                "settings" = @{
                    "commonSettings" = @{
                        "targetLocation" = $location
                        "infrastructureGrowthRate" = 0
                        "currency" = "USD"
                        "workloadDiscoverySource" = "Appliance"
                        "businessCaseType" = "OptimizeForPaas"
                    }
                    "azureSettings" = @{
                        "savingsOption" = "RI3Year"
                    }
                }
                "details" = @{}
            }
        } | ConvertTo-Json -Depth 10

        $businessCaseUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/businesscases/$($businessCaseName)?api-version=$businessCaseApiVersion"
        
        Write-LogToBlob "OptimizeForPaas Business Case URI: $businessCaseUri"
        Write-LogToBlob "OptimizeForPaas Business Case Body: $businessCaseBody"
        
        $response = Invoke-RestMethod -Uri $businessCaseUri `
            -Method PUT `
            -Headers $Headers `
            -ContentType 'application/json' `
            -Body $businessCaseBody

        Write-LogToBlob "OptimizeForPaas Business Case created successfully"
        Write-LogToBlob "OptimizeForPaas Business Case response: $($response | ConvertTo-Json -Depth 10)"
        
        return $businessCaseName
    }
    catch {
        Write-LogToBlob "Failed to create OptimizeForPaas Business Case: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function New-BusinessCaseIaasOnly {
    param(
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Creating IaaSOnly Business Case"
    
    try {
        $Headers = Get-AuthenticationHeaders
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $assessmentProjectName = "${EnvironmentName}asmproject"
        $masterSiteName = "${EnvironmentName}mastersite"
        $location = Get-EnvironmentLocation -EnvironmentName $EnvironmentName
        
        # Generate random suffix for business case name
        $randomSuffix = -join ((65..90) + (97..122) | Get-Random -Count 3 | ForEach-Object {[char]$_})
        $businessCaseName = "buizzcase$randomSuffix"
        $businessCaseApiVersion = "2025-09-09-preview"
        
        $businessCaseBody = @{
            "type" = "Microsoft.Migrate/assessmentprojects/businesscases"
            "apiVersion" = "$businessCaseApiVersion"
            "name" = "$assessmentProjectName/$businessCaseName"
            "location" = $location
            "kind" = "Migrate"
            "properties" = @{
                "businessCaseScope" = @{
                    "scopeType" = "Datacenter"
                    "azureResourceGraphQuery" = @"
migrateresources
| where id contains "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/vmwareSites/${EnvironmentName}vmwaresite" or
    id contains "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/MasterSites/$masterSiteName/WebAppSites/${EnvironmentName}webappsite" or
    id contains "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OffAzure/MasterSites/$masterSiteName/SqlSites/${EnvironmentName}sqlsites"
"@
                }
                "settings" = @{
                    "commonSettings" = @{
                        "targetLocation" = $location
                        "infrastructureGrowthRate" = 0
                        "currency" = "USD"
                        "workloadDiscoverySource" = "Appliance"
                        "businessCaseType" = "IaaSOnly"
                    }
                    "azureSettings" = @{
                        "savingsOption" = "RI3Year"
                    }
                }
                "details" = @{}
            }
        } | ConvertTo-Json -Depth 10

        $businessCaseUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/businesscases/$($businessCaseName)?api-version=$businessCaseApiVersion"
        
        Write-LogToBlob "IaaSOnly Business Case URI: $businessCaseUri"
        Write-LogToBlob "IaaSOnly Business Case Body: $businessCaseBody"
        
        $response = Invoke-RestMethod -Uri $businessCaseUri `
            -Method PUT `
            -Headers $Headers `
            -ContentType 'application/json' `
            -Body $businessCaseBody

        Write-LogToBlob "IaaSOnly Business Case created successfully"
        Write-LogToBlob "IaaSOnly Business Case response: $($response | ConvertTo-Json -Depth 10)"
        
        return $businessCaseName
    }
    catch {
        Write-LogToBlob "Failed to create IaaSOnly Business Case: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function New-HeterogeneousAssessment {
    param(
        [string]$EnvironmentName
    )
    
    Write-LogToBlob "Creating Heterogeneous Assessment"
    
    try {
        $Headers = Get-AuthenticationHeaders
        $subscriptionId = (Get-AzContext).Subscription.Id
        $resourceGroupName = if ($SkillableEnvironment) { "on-prem" } else { "${EnvironmentName}-rg" }
        $assessmentProjectName = "${EnvironmentName}asmproject"
        $location = Get-EnvironmentLocation -EnvironmentName $EnvironmentName
        
        # Generate random suffix for heterogeneous assessment name
        $heteroAssessmentRandomSuffix = -join ((65..90) + (97..122) | Get-Random -Count 3 | ForEach-Object {[char]$_})
        $heteroAssessmentName = "default-all-workloads$heteroAssessmentRandomSuffix"
        $heteroApiVersion = "2024-03-03-preview"
        
        $heteroAssessmentBody = @{
            "type" = "Microsoft.Migrate/assessmentProjects/heterogeneousAssessments"
            "apiVersion" = "$heteroApiVersion"
            "name" = "$assessmentProjectName/$heteroAssessmentName"
            "location" = $location
            "tags" = @{}
            "kind" = "Migrate"
            "properties" = @{
                "assessmentArmIds" = @(
                    "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/AssessmentProjects/$assessmentProjectName/assessments/assessment*",
                    "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/sqlassessments/assessment*"
                )
            }
        } | ConvertTo-Json -Depth 10

        $heteroAssessmentUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Migrate/assessmentprojects/$assessmentProjectName/heterogeneousAssessments/$($heteroAssessmentName)?api-version=$heteroApiVersion"
        
        Write-LogToBlob "Heterogeneous Assessment URI: $heteroAssessmentUri"
        Write-LogToBlob "Heterogeneous Assessment Body: $heteroAssessmentBody"
        
        $response = Invoke-RestMethod -Uri $heteroAssessmentUri `
            -Method PUT `
            -Headers $Headers `
            -ContentType 'application/json' `
            -Body $heteroAssessmentBody

        Write-LogToBlob "Heterogeneous Assessment created successfully"
        Write-LogToBlob "Heterogeneous Assessment response: $($response | ConvertTo-Json -Depth 10)"
        
        return $heteroAssessmentName
    }
    catch {
        Write-LogToBlob "Failed to create Heterogeneous Assessment: $($_.Exception.Message)" "ERROR"
        throw
    }
}

######################################################
##############   MAIN EXECUTION FUNCTION   ##########
######################################################

function Invoke-AzureMigrateConfiguration {
    param(
        [bool] $SkillableEnvironment,
        [string] $EnvironmentName
    )
    
    # Environment name and prefix for all azure resources
    if ($SkillableEnvironment) {
        $environmentName = "lab@lab.LabInstance.ID"
    }
    else {
        $environmentName = $EnvironmentName
    }
   
    Write-LogToBlob "=== Starting Azure Migrate Configuration ==="
    Write-LogToBlob "Environment: $EnvironmentName"
    Write-LogToBlob "Skillable Mode: $SkillableEnvironment"
    
    try {
        # Step 1: Initialize modules and logging
        Import-AzureModules
        Initialize-LogBlob
        
        # Step 2: Create Azure environment (skip if Skillable)
        if (-not $SkillableEnvironment) {
            New-AzureEnvironment -EnvironmentName $EnvironmentName
        }
        
        # Step 3: Register Azure Migrate tools
        Register-MigrateTools -EnvironmentName $EnvironmentName
        
        # Step 4: Download and import discovery artifacts
        $localZipPath = Get-DiscoveryArtifacts
        $jobArmId = Start-ArtifactImport -LocalZipFilePath $localZipPath -EnvironmentName $EnvironmentName
        Wait-ImportJobCompletion -JobArmId $jobArmId
        
        # Step 5: Get site details for WebApp and SQL
        $webAppSiteDetails = Get-WebAppSiteDetails -EnvironmentName $EnvironmentName
        $sqlSiteDetails = Get-SqlSiteDetails -EnvironmentName $EnvironmentName
        
        # Step 6: Configure VMware Collector
        $agentId = Get-VMwareCollectorAgentId -EnvironmentName $EnvironmentName
        Invoke-VMwareCollectorSync -AgentId $agentId -EnvironmentName $EnvironmentName
        
        # Step 7: Create WebApp and SQL Collectors (if available)
        $webAppCollectorCreated = New-WebAppCollector -EnvironmentName $EnvironmentName -WebAppSiteId $webAppSiteDetails.SiteId -WebAppAgentId $webAppSiteDetails.AgentId
        $sqlCollectorCreated = New-SqlCollector -EnvironmentName $EnvironmentName -SqlSiteId $sqlSiteDetails.SiteId -SqlAgentId $sqlSiteDetails.AgentId
        
        # Step 8: Create assessments
        New-MigrationAssessment -EnvironmentName $EnvironmentName
        $sqlAssessmentName = New-SqlAssessment -EnvironmentName $EnvironmentName
        
        # Step 9: Create business cases
        $paasBusinessCaseName = New-BusinessCaseOptimizeForPaas -EnvironmentName $EnvironmentName
        $iaasBusinessCaseName = New-BusinessCaseIaasOnly -EnvironmentName $EnvironmentName
        
        # Step 10: Create heterogeneous assessment
        $heteroAssessmentName = New-HeterogeneousAssessment -EnvironmentName $EnvironmentName
        
        Write-LogToBlob "=== Azure Migrate Configuration Completed Successfully ==="
        Write-LogToBlob "Summary of created resources:"
        Write-LogToBlob "- VMware Collector: Synchronized"
        Write-LogToBlob "- WebApp Collector: $(if ($webAppCollectorCreated) { 'Created' } else { 'Skipped' })"
        Write-LogToBlob "- SQL Collector: $(if ($sqlCollectorCreated) { 'Created' } else { 'Skipped' })"
        Write-LogToBlob "- VM Assessment: Created"
        Write-LogToBlob "- SQL Assessment: $sqlAssessmentName"
        Write-LogToBlob "- PaaS Business Case: $paasBusinessCaseName"
        Write-LogToBlob "- IaaS Business Case: $iaasBusinessCaseName"
        Write-LogToBlob "- Heterogeneous Assessment: $heteroAssessmentName"
    }
    catch {
        Write-LogToBlob "=== Azure Migrate Configuration Failed ===" "ERROR"
        Write-LogToBlob "Error: $($_.Exception.Message)" "ERROR"
        throw
    }
}

######################################################
##############   SCRIPT EXECUTION   #################
######################################################

# Execute the main function
try {
    Invoke-AzureMigrateConfiguration `
        -SkillableEnvironment $SkillableEnvironment `
        -EnvironmentName $environmentName
} catch {
    Write-Host "Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}