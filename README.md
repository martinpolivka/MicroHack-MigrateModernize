

# Azure Migration & Modernization MicroHack

This MicroHack scenario walks through a complete migration and modernization journey using Azure Migrate and GitHub Copilot. The experience covers discovery, assessment, business case development, and application modernization for both .NET and Java workloads.

## MicroHack Context

This MicroHack provides hands-on experience with the entire migration lifecycle - from initial discovery of on-premises infrastructure through to deploying modernized applications on Azure. You'll work with a simulated datacenter environment and use AI-powered tools to accelerate modernization.

**Key Technologies:**
- Azure Migrate for discovery and assessment
- GitHub Copilot for AI-powered code modernization
- Azure App Service for hosting modernized applications

## Environment creation

Install Azure PowerShell and authenticated to your Azure subscription:
```PowerShell
Install-Module Az
Connect-AzAccount
```

Please note:
- You need Administrator rights to install Azure PowerShell. If it's not an option for you, install it for the current user using `Install-Module Az -Scope CurrentUser`
- It takes some time (around 10 minutes) to install. Please, complete this task in advance.
- If you have multiple Azure subscriptions avaialble for your account, use `Connect-AzAccount -TenantId YOUR-TENANT-ID` to authenticate against specific one.

Once you are authenticated to Azure via PowerShell, run the following script to create the lab environment:

```Powershell
# Download and execute the environment creation script directly from GitHub
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-creation/New-MicroHackEnvironment.ps1" -OutFile "$env:TEMP\New-MicroHackEnvironment.ps1"
& "$env:TEMP\New-MicroHackEnvironment.ps1"
```

## Start your lab

**Business Scenario:**
You're working with an organization that has on-premises infrastructure running .NET and Java applications. Your goal is to assess the environment, build a business case for migration, and modernize applications using best practices and AI assistance.

## Objectives

After completing this MicroHack you will:

- Understand how to deploy and configure Azure Migrate for infrastructure discovery
- Know how to build compelling business cases using Azure Migrate data
- Analyze migration readiness across servers, databases, and applications
- Use GitHub Copilot to modernize .NET Framework applications to modern .NET
- Leverage AI to migrate Java applications from AWS dependencies to Azure services
- Deploy modernized applications to Azure App Service

## MicroHack Challenges

### General Prerequisites

This MicroHack has specific prerequisites to ensure optimal learning experience.

**Required Access:**
- Azure Subscription with Contributor permissions
- GitHub account with GitHub Copilot access

**Required Software:**
- Visual Studio 2022 (for .NET modernization)
- Visual Studio Code (for Java modernization)
- Docker Desktop
- Java Development Kit (JDK 8 and JDK 21)
- Maven

**Azure Resources:**
The lab environment provides:
- Resource Group: `on-prem`
- Hyper-V host VM with nested virtualization
- Pre-configured virtual machines simulating datacenter workloads
- Azure Migrate project with sample data

**Estimated Time:**
- Challenge 1: 45-60 minutes
- Challenge 2: 30-45 minutes
- Challenge 3: 45-60 minutes
- Challenge 4: 60-75 minutes
- **Total: 3-4 hours**

### Alternative: Using GitHub Codespaces

If you don't have the required software (Visual Studio 2022, VS Code, Docker Desktop, JDK, Maven) installed locally, you can use **GitHub Codespaces** to complete the modernization challenges (Challenge 3 and Challenge 4) in a pre-configured cloud development environment.

**What is GitHub Codespaces?**

GitHub Codespaces provides a complete, configurable development environment in the cloud. It comes pre-installed with development tools and can run directly in your browser or through VS Code, eliminating the need for local software installation.

**How to Use GitHub Codespaces for Application Modernization:**

1. **Fork the Repository:**
   - Navigate to [https://github.com/CZSK-MicroHacks/MicroHack-MigrateModernize](https://github.com/CZSK-MicroHacks/MicroHack-MigrateModernize)
   - Click the "Fork" button in the top-right corner
   - Select your account as the owner and click "Create fork"

2. **Launch GitHub Codespaces:**
   - In your forked repository, click the green "Code" button
   - Select the "Codespaces" tab
   - Click "Create codespace on main" (or the branch you want to work on)
   - Wait for the codespace to initialize (this may take 1-2 minutes)

3. **Install GitHub Copilot App Modernization Extension:**
   - Once the codespace opens, go to the Extensions view (Ctrl+Shift+X or Cmd+Shift+X)
   - Search for "GitHub Copilot app modernization"
   - Click "Install" on the extension by Microsoft
   - The extension will automatically install GitHub Copilot dependencies if needed
   - Ensure you're signed in to your GitHub account with Copilot access

4. **Install Required Development Tools:**
   
   For **.NET Application Modernization** (Challenge 3):
   ```bash
   # .NET 9 SDK is typically pre-installed in Codespaces
   # Verify installation:
   dotnet --version
   ```

   For **Java Application Modernization** (Challenge 4):
   ```bash
   # JDK and Maven are typically pre-installed in Codespaces
   # Verify installation:
   java -version
   mvn --version
   
   # If you need different JDK versions, you can use SDKMAN (if installed):
   # sdk install java 21-open
   # sdk install java 8-open
   ```

5. **Example Prompts for Autonomous Modernization:**

   **For ASP.NET Applications:**
   ```
   Find the ASP.NET application in this repository (ContosoUniversity) and modernize it to the latest .NET version. Analyze the codebase, identify dependencies, upgrade to .NET 9, migrate authentication from Windows AD to Microsoft Entra ID, and ensure cloud readiness for Azure App Service deployment.
   ```

   **For Java Applications:**
   ```
   Find the Java application in this repository (AssetManager) and modernize it for Azure. Perform an AppCAT assessment, identify migration opportunities, upgrade from Java 8 to Java 21, migrate from AWS S3 to Azure Blob Storage, migrate from RabbitMQ to Azure Service Bus, and prepare for containerized deployment.
   ```

6. **Monitor the Autonomous Process:**
   - GitHub Copilot will analyze your codebase and create a migration plan
   - Review the plan in the generated `plan.md` or similar files
   - The extension works autonomously but may prompt you to:
     - Allow operations (click "Allow" when prompted)
     - Confirm migration steps (type "Continue" or "Proceed")
     - Review security validations (CVE scans)
   - Monitor progress in real-time through the GitHub Copilot Chat panel

7. **Review and Apply Changes:**
   - After each migration task completes, review the proposed changes
   - Check the `progress.md` or `dotnet-upgrade-report.md` files for detailed logs
   - Click "Keep" to apply changes or "Discard" if you disagree
   - Test the modernized application before deploying
   - Use the integrated terminal to run builds and tests

8. **Best Practices:**
   - **Monitor actively:** While the process is autonomous, stay engaged to approve operations
   - **Review carefully:** Check each change for correctness and security
   - **Test incrementally:** Validate changes after each major migration step
   - **Commit frequently:** Save your work regularly using Git in the codespace
   - **Check validation:** Ensure all automated tests and CVE scans pass

**Benefits of Using Codespaces:**
- No local software installation required
- Consistent development environment
- Pre-configured with common tools
- Accessible from any device with a browser
- Easy collaboration and sharing
- Integrated with GitHub workflows

**Resource Management:**
- Codespaces are billed based on compute time and storage
- Stop or delete codespaces when not in use
- Your work is automatically saved and can be resumed later

---

## Challenge 1 - Prepare a Migration Environment

### Goal

Set up Azure Migrate to discover and assess your on-premises infrastructure. You'll install and configure an appliance that collects data about your servers, applications, and dependencies.

### Actions

**Understand Your Environment:**
1. Access the Azure Portal using the provided credentials
2. Navigate to the `on-prem` resource group
3. Connect to the Hyper-V host VM (`lab@lab.LabInstance.Id-vm`)
4. Explore the nested VMs running inside the host

![Hyper-V Manager showing nested VMs](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/00915.png)

5. Verify that applications are running (e.g., http://172.100.2.110)

![Application running in nested VM](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/0013.png)

**Create Azure Migrate Project:**  

6. Create a new Azure Migrate project in the Azure Portal
7. Name your project (e.g., `migrate-prj`)
8. Select an appropriate region (e.g., Europe)

![Azure Migrate Discovery page](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/0090.png)

**Deploy the Azure Migrate Appliance:**

9. Generate a project key for the appliance
10. Download the Azure Migrate appliance VHD file

![Download appliance VHD](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/0091.png)

11. Extract the VHD inside your Hyper-V host (F: drive recommended)

![Extract VHD to F drive](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/00914.png)

12. Create a new Hyper-V VM using the extracted VHD:
    - Name: `AZMAppliance`
    - Generation: 1
    - RAM: 16384 MB
    - Network: NestedSwitch

![Create new VM in Hyper-V](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/0092.png)

![Select VHD file](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/00925.png)

13. Start the appliance VM

**Configure the Appliance:**

14. Accept license terms and set appliance password: `Demo!pass123`

![Send Ctrl+Alt+Del to appliance](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/0093.png)

15. Wait for Azure Migrate Appliance Configuration to load in browser

![Appliance Configuration Manager](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/00932.png)

16. Paste and verify your project key
17. Login to Azure through the appliance interface

![Login to Azure](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/00945.png)

18. Add Hyper-V host credentials (username: `adminuser`, password: `demo!pass123`)

![Add credentials](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/00946.png)

19. Add discovery source with Hyper-V host IP: `172.100.2.1`

![Add discovery source](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/00948.png)

20. Add credentials for Windows, Linux, SQL Server, and PostgreSQL workloads (password: `demo!pass123`)
    - Windows username: `Administrator`
    - Linux username: `demoadmin`
    - SQL username: `sa`

![Add workload credentials](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/009491.png)

21. Start the discovery process

### Success Criteria

- ✅ You have successfully connected to the Hyper-V host VM
- ✅ You can access nested VMs and verify applications are running
- ✅ Azure Migrate project has been created
- ✅ Appliance is deployed and connected to Azure Migrate

![Appliance in Azure Portal](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/00951.png)

- ✅ All appliance services show as running in Azure Portal

![Appliance services running](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/00952.png)

- ✅ Discovery process has started collecting data from your environment

### Learning Resources

- [Azure Migrate Overview](https://learn.microsoft.com/azure/migrate/migrate-services-overview)
- [Azure Migrate Appliance Architecture](https://learn.microsoft.com/azure/migrate/migrate-appliance-architecture)
- [Hyper-V Discovery with Azure Migrate](https://learn.microsoft.com/azure/migrate/tutorial-discover-hyper-v)
- [Azure Migrate Discovery Best Practices](https://learn.microsoft.com/azure/migrate/best-practices-assessment)

---

## Challenge 2 - Analyze Migration Data and Build a Business Case

### Goal

Transform raw discovery data into actionable insights by cleaning data, grouping workloads, creating business cases, and performing technical assessments to guide migration decisions.

### Actions

**Review Data Quality:**
1. Navigate to already prepared (with suffix `-azm`) Azure Migrate project overview

![Azure Migrate project overview](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/0095.png)

2. Open the Action Center to identify data quality issues

![Action Center with data issues](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/01005.png)

3. Review common issues (powered-off VMs, connection failures, missing performance data)
4. Understand the impact of data quality on assessment accuracy

**Group Workloads into Applications:**

5. Navigate to Applications page under "Explore applications"
6. Create a new application definition for "ContosoUniversity"
7. Set application type as "Custom" (source code available)
8. Link relevant workloads to the application
9. Filter and select all ContosoUniversity-related workloads

![Link workloads to application](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/01002.png)

10. Set criticality and complexity ratings

**Build a Business Case:**

11. Navigate to Business Cases section
12. Create a new business case named "contosouniversity"
13. Select "Selected Scope" and add ContosoUniversity application
14. Choose target region: West US 2
15. Configure Azure discount: 15%
16. Build the business case and wait for calculations

**Analyze an Existing Business Case:**

17. Open the pre-built "businesscase-for-paas" business case
18. Review annual cost savings and infrastructure scope
19. Examine current on-premises vs future Azure costs
20. Analyze CO₂ emissions reduction estimates
21. Review migration strategy recommendations (Rehost, Replatform, Refactor)
22. Examine Azure cost assumptions and settings

**Perform Technical Assessments:**

23. Navigate to Assessments section

![Assessments overview](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/01007.png)

24. Open the "businesscase-businesscase-for-paas" assessment

![Assessment details](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/01008.png)

25. Review recommended migration paths (PaaS preferred)
26. Analyze monthly costs by migration approach
27. Review Web Apps to App Service assessment details
28. Identify "Ready with conditions" applications
29. Review ContosoUniversity application details
30. Check server operating system support status
31. Identify out-of-support and extended support components
32. Review PostgreSQL database version information
33. Examine software inventory on each server

![Software inventory details](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/01010.png)

**Complete Knowledge Checks:**

34. Find the count of powered-off Linux VMs

![Filter powered-off Linux VMs](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/01001.png)

35. Count Windows Server 2016 instances

![Windows Server 2016 count](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/01004.png)

36. Calculate VM costs for the ContosoUniversity application

![Application costs](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/01011.png)

37. Identify annual cost savings from the business case
38. Determine security cost savings

### Success Criteria

- ✅ You understand data quality issues and their impact on assessments
- ✅ Applications are properly grouped with related workloads
- ✅ Business case successfully created showing cost analysis and ROI
- ✅ You can navigate between business cases and technical assessments
- ✅ Migration strategies (Rehost, Replatform, Refactor) are clearly understood
- ✅ Application readiness status is evaluated for cloud migration
- ✅ Out-of-support components are identified for remediation
- ✅ You can answer specific questions about your environment using Azure Migrate data

### Learning Resources

- [Azure Migrate Business Case Overview](https://learn.microsoft.com/azure/migrate/concepts-business-case-calculation)
- [Azure Assessment Best Practices](https://learn.microsoft.com/azure/migrate/best-practices-assessment)
- [Application Discovery and Grouping](https://learn.microsoft.com/azure/migrate/how-to-create-group-machine-dependencies)
- [Migration Strategies: 6 Rs Explained](https://learn.microsoft.com/azure/cloud-adoption-framework/migrate/azure-best-practices/contoso-migration-refactor-web-app-sql)

---

## Challenge 3 - Modernize a .NET Application

### Goal

Modernize the Contoso University .NET Framework application to .NET 9 and deploy it to Azure App Service using GitHub Copilot's AI-powered code transformation capabilities.

> **💡 Tip:** If you don't have Visual Studio 2022 installed locally, you can use **GitHub Codespaces** to complete this challenge. See the [Alternative: Using GitHub Codespaces](#alternative-using-github-codespaces) section above for setup instructions.

### Actions

**Setup and Preparation:**
1. Navigate to [https://github.com/CZSK-MicroHacks/MicroHack-MigrateModernize](https://github.com/CZSK-MicroHacks/MicroHack-MigrateModernize) and click the "Fork" button in the top-right corner

![Fork the repository](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/fork-button.png)

2. Select your account as the owner and click "Create fork"

![Create fork dialog](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/create-fork.png)

3. Once the fork is created, click the "Code" button and copy your forked repository URL

4. **Option A - Local Development with Visual Studio 2022:**
   - Open Visual Studio 2022
   - Select "Clone a repository" and paste your forked repository URL
   - Navigate to Solution Explorer and locate the ContosoUniversity project
   - Rebuild the project to verify it compiles successfully

   **Option B - Using GitHub Codespaces:**
   - In your forked repository on GitHub, click the green "Code" button
   - Select "Codespaces" tab and click "Create codespace on main"
   - Wait for the codespace to initialize
   - Install the "GitHub Copilot app modernization" extension from the Extensions marketplace
   - Open the ContosoUniversity project folder in the integrated terminal

5. Verify the application builds successfully (for Codespaces: run `dotnet build` in the terminal)

![Application running in IIS Express](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/0030.png)

**Assess and Upgrade to .NET 9:**

6. Right-click the ContosoUniversity project and select "Modernize" (or use GitHub Copilot Chat with the prompt: "Modernize this .NET application to the latest version")

![Right-click Modernize menu](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/0040.png)

7. Sign in to GitHub Copilot if prompted
8. Select Claude Sonnet 4.5 as the model
9. Click "Upgrade to a newer .NET version"
10. Allow GitHub Copilot to analyze the codebase
11. Review the upgrade plan when presented
12. Allow operations when prompted during the upgrade process
13. Wait for the upgrade to complete (marked by `dotnet-upgrade-report.md` appearing)

**Migrate to Azure:**

14. Right-click the project again and select "Modernize"
15. Click "Migrate to Azure" in the GitHub Copilot Chat window
16. Wait for GitHub Copilot to assess cloud readiness

**Resolve Cloud Readiness Issues:**
17. Open the `dotnet-upgrade-report.md` file

![Upgrade report with cloud readiness issues](https://raw.githubusercontent.com/CZSK-MicroHacks/MicroHack-MigrateModernize/refs/heads/main/lab-material/media/0080.png)

18. Review the Cloud Readiness Issues section
19. Click "Migrate from Windows AD to Microsoft Entra ID"
20. Allow GitHub Copilot to implement the authentication changes
21. Ensure all mandatory tasks are resolved
22. Review the changes made to authentication configuration

**Deploy to Azure:**

23. Allow GitHub Copilot to complete the Azure App Service deployment
24. Verify the deployment succeeds
25. Test the deployed application in Azure

### Success Criteria

- ✅ ContosoUniversity solution cloned and builds successfully
- ✅ Application upgraded from .NET Framework to .NET 9
- ✅ Upgrade report generated showing all changes and issues
- ✅ Authentication migrated from Windows AD to Microsoft Entra ID
- ✅ All mandatory cloud readiness issues resolved
- ✅ Application successfully deployed to Azure App Service
- ✅ Deployed application is accessible and functional

### Learning Resources

- [GitHub Copilot for Visual Studio](https://learn.microsoft.com/visualstudio/ide/visual-studio-github-copilot-extension)
- [Modernize .NET Applications](https://learn.microsoft.com/dotnet/architecture/modernize-with-azure-containers/)
- [Migrate to .NET 9](https://learn.microsoft.com/dotnet/core/migration/)
- [Azure App Service for .NET](https://learn.microsoft.com/azure/app-service/quickstart-dotnetcore)
- [Microsoft Entra ID Authentication](https://learn.microsoft.com/azure/active-directory/develop/quickstart-v2-aspnet-core-webapp)

---

## Challenge 4 - Modernize a Java Application

### Goal

Modernize the Asset Manager Java Spring Boot application for Azure deployment, migrating from AWS dependencies to Azure services using GitHub Copilot App Modernization in VS Code.

> **💡 Tip:** If you don't have Docker Desktop, VS Code, Java, or Maven installed locally, you can use **GitHub Codespaces** to complete this challenge. See the [Alternative: Using GitHub Codespaces](#alternative-using-github-codespaces) section above for setup instructions.

### Actions

**Environment Setup:**
1. **Option A - Local Development (Windows):**
   - Open Docker Desktop and ensure it's running
   - Open Terminal and run the setup commands:
     ```bash
     mkdir C:\gitrepos\lab
     cd C:\gitrepos\lab
     git clone https://github.com/CZSK-MicroHacks/MicroHack-MigrateModernize.git
     cd .\migrate-modernize-lab\src\AssetManager\
     code .
     ```
   - Login to GitHub from VS Code
   - Install GitHub Copilot App Modernization extension if not present

   **Option B - Using GitHub Codespaces:**
   - Fork the repository at [https://github.com/CZSK-MicroHacks/MicroHack-MigrateModernize](https://github.com/CZSK-MicroHacks/MicroHack-MigrateModernize)
   - In your forked repository, click the green "Code" button
   - Select "Codespaces" tab and click "Create codespace on main"
   - Wait for the codespace to initialize (Docker is pre-installed)
   - Install the "GitHub Copilot app modernization" extension from the Extensions marketplace
   - Navigate to the AssetManager directory: `cd src/AssetManager`

2. Ensure you're logged in to GitHub with Copilot access

**Validate Application Locally:**

3. Open Terminal in VS Code (View → Terminal)
4. Run `scripts\startapp.cmd` (Windows) or `scripts/startapp.sh` (Linux/Codespaces)
5. Wait for Docker containers (RabbitMQ, Postgres) to start
6. Allow network permissions when prompted
7. Verify application is accessible at http://localhost:8080
8. Stop the application by closing console windows (or Ctrl+C in Codespaces)

**Perform AppCAT Assessment:**

9. Open GitHub Copilot App Modernization extension in the Activity bar
10. Ensure Claude Sonnet 4.5 is selected as the model
11. Click "Migrate to Azure" to begin assessment
12. Wait for AppCAT CLI installation to complete
13. Review assessment progress in the VS Code terminal
14. Wait for assessment results (9 cloud readiness issues, 4 Java upgrade opportunities)

**Analyze Assessment Results:**

15. Review the assessment summary in GitHub Copilot chat
16. Examine issue prioritization:
    - Mandatory (Purple) - Critical blocking issues
    - Potential (Blue) - Performance optimizations
    - Optional (Gray) - Future improvements
17. Click on individual issues to see detailed recommendations
18. Focus on the AWS S3 to Azure Blob Storage migration finding

**Execute Guided Migration:**

19. Expand the "Migrate from AWS S3 to Azure Blob Storage" task
20. Read the explanation of why this migration is important
21. Click the "Run Task" button to start the migration
22. Review the generated migration plan in the chat window and `plan.md` file
23. Type "Continue" in the chat to begin code refactoring

**Monitor Migration Progress:**

24. Watch the GitHub Copilot chat for real-time status updates
25. Check the `progress.md` file for detailed change logs
26. Review file modifications as they occur:
    - `pom.xml` and `build.gradle` updates for Azure SDK dependencies
    - `application.properties` configuration changes
    - Spring Cloud Azure version properties
27. Allow any prompted operations during the migration

**Validate Migration:**

28. Wait for automated validation to complete:
    - CVE scanning for security vulnerabilities
    - Build validation
    - Consistency checks
    - Test execution
29. Review validation results in the chat window
30. Allow automated fixes if validation issues are detected
31. Confirm all validation stages pass successfully

**Test Modernized Application:**

32. Open Terminal in VS Code
33. Run `scripts\startapp.cmd` (Windows) or `scripts/startapp.sh` (Linux/Codespaces) again
34. Verify the application starts with Azure Blob Storage integration
35. Test application functionality at http://localhost:8080
36. Confirm no errors related to storage operations

**Optional: Continue Modernization:**

37. Review other migration tasks in the assessment report
38. Execute additional migrations as time permits
39. Track progress through the `plan.md` and `progress.md` files

### Success Criteria

- ✅ Docker Desktop is running and containers are functional
- ✅ Asset Manager application cloned and runs locally
- ✅ AppCAT assessment completed successfully
- ✅ Assessment identifies 9 cloud readiness issues and 4 Java upgrade opportunities
- ✅ AWS S3 to Azure Blob Storage migration executed via guided task
- ✅ Maven/Gradle dependencies updated with Azure SDK
- ✅ Application configuration migrated to Azure Blob Storage
- ✅ All validation stages pass (CVE, build, consistency, tests)
- ✅ Modernized application runs successfully locally
- ✅ Migration changes tracked in dedicated branch for rollback capability

### Learning Resources

- [GitHub Copilot for VS Code](https://code.visualstudio.com/docs/copilot/overview)
- [Azure SDK for Java](https://learn.microsoft.com/azure/developer/java/sdk/)
- [Migrate from AWS to Azure](https://learn.microsoft.com/azure/architecture/aws-professional/)
- [Azure Blob Storage for Java](https://learn.microsoft.com/azure/storage/blobs/storage-quickstart-blobs-java)
- [Spring Cloud Azure](https://learn.microsoft.com/azure/developer/java/spring-framework/)
- [AppCAT Assessment Tool](https://learn.microsoft.com/azure/developer/java/migration/migration-toolkit-intro)

---

## Finish

Congratulations! You've completed the Azure Migration & Modernization MicroHack. 

**What You've Accomplished:**

Throughout this MicroHack, you've gained hands-on experience with the complete migration lifecycle:

### Challenge 1: Migration Preparation

- Explored a simulated datacenter environment with nested Hyper-V VMs
- Created and configured an Azure Migrate project for discovery
- Downloaded, installed, and configured the Azure Migrate appliance
- Connected the appliance to on-premises infrastructure with proper credentials
- Initiated continuous discovery for performance and dependency data collection

### Challenge 2: Migration Analysis & Business Case

- Reviewed and cleaned migration data using Azure Migrate's Action Center
- Grouped related VMs into logical applications (ContosoUniversity)
- Built business cases showing financial justification with cost savings and ROI analysis
- Analyzed technical assessments for cloud readiness and migration strategies
- Evaluated workload readiness across VMs, databases, and web applications
- Navigated migration data to identify issues, costs, and modernization opportunities

### Challenge 3: .NET Application Modernization

- Cloned and configured the Contoso University .NET application repository
- Used GitHub Copilot App Modernization extension in Visual Studio
- Performed comprehensive code assessment for cloud readiness
- Upgraded application from legacy .NET Framework to .NET 9
- Migrated from Windows AD to Microsoft Entra ID authentication
- Resolved cloud readiness issues identified in the upgrade report
- Deployed the modernized application to Azure App Service

### Challenge 4: Java Application Modernization

- Set up local Java development environment with Docker and Maven
- Ran the Asset Manager application locally to validate functionality
- Used GitHub Copilot App Modernization extension in VS Code
- Performed AppCAT assessment for Azure migration readiness (9 cloud readiness issues, 4 Java upgrade opportunities)
- Executed guided migration tasks to modernize the application
- Migrated from AWS S3 to Azure Blob Storage with automated code refactoring
- Validated migration success through automated CVE, build, consistency, and test validation
- Tested the modernized application locally

---

**Skills Acquired:**

- Azure Migrate configuration and management
- Business case development and financial analysis
- AI-powered code modernization with GitHub Copilot
- Migration strategy selection (Rehost, Replatform, Refactor)
- Cloud readiness assessment and remediation
- Azure App Service deployment
- AppCAT assessment for Java applications
- Automated validation and testing workflows

**Key Takeaways:**

This workshop demonstrated the complete migration lifecycle from discovery to deployment:
- **Assessment First**: Azure Migrate provides comprehensive discovery and financial justification before migration
- **AI-Powered Modernization**: GitHub Copilot dramatically accelerates code modernization while maintaining quality
- **Platform Migration**: Successfully migrated dependencies (S3 to Blob Storage, Windows AD to Entra ID) alongside application code
- **Validation at Every Step**: Automated testing ensures functionality is preserved throughout modernization
- **Multiple Technology Stacks**: Experience with both .NET and Java modernization approaches

---

### Next Steps & Learning Paths

**Continue Your Azure Journey:**

- [Azure Migrate Documentation](https://learn.microsoft.com/azure/migrate/) - Deep dive into migration tools and strategies
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/) - Learn enterprise architecture best practices
- [GitHub Copilot for Azure](https://learn.microsoft.com/azure/developer/github-copilot/) - Explore AI-powered development tools

**Hands-On Labs:**

- [Azure Migration Center](https://azure.microsoft.com/migration/) - Additional migration resources and tools
- [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/) - Reference architectures and patterns
- [Microsoft Learn - Azure Migration Path](https://learn.microsoft.com/training/paths/migrate-modernize-innovate-azure/) - Structured learning modules

**Continue Modernization:**

- Explore additional migration scenarios in your own environments
- Practice with other workload types (containers, databases, etc.)
- Experiment with GitHub Copilot for other modernization tasks
- Continue with other migration tasks identified in the assessment reports
- Explore containerization options for deploying to AKS or Azure Container Apps
- Implement additional Azure services like Azure Service Bus (replacing RabbitMQ)
- Apply Java runtime upgrades using the identified opportunities
- Configure managed identities for passwordless authentication

If you want to give feedback, please don't hesitate to open an issue on the repository or get in touch with one of us directly.

Thank you for investing the time and see you next time!

---

## Additional Resources

- [Azure Migrate Documentation](https://learn.microsoft.com/azure/migrate/)
- [Azure Migration Center](https://azure.microsoft.com/migration/)
- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/)
- [Microsoft Learn - Azure Migration Path](https://learn.microsoft.com/training/paths/migrate-modernize-innovate-azure/)
