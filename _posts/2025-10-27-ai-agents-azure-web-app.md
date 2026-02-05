---
layout: default
title:  "Ship it! Deploying AI agents to Azure Web Apps"
date:   2025-10-27 09:00:00 +0200
categories: AI agents Azure Python Web Apps
author: Aurora Voje, PhD
---
{% include carousel.html %}

![Deploy AI agent app]({{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/intro_deploy_agent_app.png)
_Figure: AI generated illustration of article's title._

---
**[{{ site.title }}]({{ site.url }})** | By {{ page.author | default: "Aurora Voje" }} | {{ page.date | date: "%B %d, %Y" }}

---

* TOC
{:toc}

# Introduction
{:top}

Welcome to the final post of this AI agent exploration journey! If you've been following along, you've built AI agents in Azure AI Foundry, wrapped them in Streamlit, and orchestrated multi-agent systems with the Python SDK. Now comes the payoff: shipping your application to production where real users can access it.

This post is all about deployment — taking your locally running Streamlit app and making it accessible to the world via Azure Web Apps. I'll walk you through the entire process: from creating the web app resource to configuring environment variables, setting up CI/CD with GitHub Actions, debugging deployment issues, and setting up several development environments.

**Series recap:**
1. ✅ [No Code: How to build agents in Azure AI Foundry]({% post_url 2025-10-15-ai-agents-azure %})
2. ✅ [Portal + Code: How to build a home for an AI agent]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %})
3. ✅ [Code: AI agents with Azure Python SDK]({% post_url 2025-10-27-ai-agents-azure-python-sdk %})
4. 📍 **Deployment: Ship it! Deploying AI agents to Azure Web Apps** (you are here)

By the end of this post, you'll have a fully deployed, production-ready AI agent application running on Azure Web Apps. You'll understand the deployment workflow, how to troubleshoot common issues, and how to manage environment variables and secrets securely.

**Why Azure Web Apps?**

Before diving into the how, let's briefly discuss the why. Azure Web Apps (part of Azure App Service) is a fully managed platform for building, deploying, and scaling web applications. For our AI agent application, it offers several compelling advantages:

- **Managed infrastructure:** No need to manage VMs or containers—Azure handles the underlying infrastructure
- **Built-in CI/CD:** Seamless integration with GitHub, Azure DevOps, and other source control providers
- **Automatic scaling:** Scale up or out based on demand
- **Security features:** Built-in SSL, authentication, and managed identities
- **Multiple deployment slots:** Support for staging and production environments
- **Integrated monitoring:** Application Insights for performance monitoring and debugging

For a Streamlit-based AI agent application which was developed in previous posts, Azure Web Apps provides a straightforward deployment path without the complexity of container orchestration. Though containerized deployment is also supported if you prefer that route.

Ready to ship? Let's deploy! 🚀

* * *

# Azure Web Apps deployment process overview

Understanding the deployment workflow helps troubleshoot issues and optimize your setup. Here's the high-level process:

![Deploy App FLow]({{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/app_deploy_flow.png)
_Figure: Illustration of application's deployment workflow._


**Key components:**

1. **GitHub Repository:** Your source code, including `requirements.txt` or `pyproject.toml` for dependencies. In this post I will show you how to implement versioning with `uv`.
2. **GitHub Actions:** Automates the build and deployment process via YAML workflow files.
3. **Build Artifact:** A ZIP file containing your application code and dependencies.
4. **Oryx Build System:** Azure's build system that detects your Python version, installs dependencies, and prepares the runtime environment.
5. **Azure Web App:** The running instance of your application.

The beauty of this setup is that once configured, every push to your main branch (or selected branch) automatically triggers deployment. No manual intervention is required!

* * *

# Setup and configuration

Let's start by creating and configuring the Azure Web App resource. I'll focus on how to do this via the **Azure Portal**, which is more beginner friendly. As bonus material, and for a more automation friendly approach, I'll also provide the Azure Command Line Interface (CLI) setup in the section [Bonus Material - automation](#bonus-material---automation), at the end of this article. 

**Navigate to Web Apps**

In the Azure Portal, click the ➕ **Create a resource** button and search for "Web App" and click on the icon.

**Configure Basics**

Fill in the required fields, as exemplified by the screenshots below:

<div class="main-carousel" data-flickity='{ "cellAlign": "left", "contain": true, "wrapAround": true }'>
  
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/create_web_app_basics_1.png" alt="Step 1">
    <p>1. Configure basics </p>
  </div>

  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/create_web_app_basics_2.png" alt="Step 2">
    <p>2. Configure basics </p>
  </div>

</div>

- **Subscription:** Select your Azure subscription
- **Resource Group:** Use the same resource group as your AI Foundry project
- **Name:** Choose a unique name (e.g., `dinner-generator` or `dinner-planner`). This becomes part of your URL: `dinner-generator-xxxx.yyyyy.azurewebsites.net`. The name must be globally unique across all Azure Web Apps worldwide, it can only contain alphanumeric characters and hyphens, and cannot start or end with a hyphen. Once the name is created, it cannot be renamed.
- **Publish:** Select "Code" (not Docker Container for this tutorial)
- **Runtime stack:** Python 3.13 (match your development environment)
- **Operating System:** Linux (required for Python)
- **Region:** Same region as your AI Foundry project (e.g., Norway East like I have for my setup)
- **Pricing plan:** For development and testing, the **Basic B1** tier (~$13/month) is sufficient. For production with more traffic, consider **Standard S1** or higher. We will for the purpose of a tutorial stick to **Basic B1**. **Note:** _Deployment slots (for staging/production separation) require Standard tier or higher. I'll get back to this in the section [Staging and production environments](#staging-and-production-environments)._
- **Zone redundancy:** Set as Disabled (Not in screenshot)

Review your settings and click **Create**. Deployment is initialized and takes 1-2 minutes. When it's done, you will be able to see the created app, with your chosen name, under your resources:

<figure>
  <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/created_web_app.png" 
       alt="Application settings configuration" 
       style="width: 100%; height: auto;">
  <figcaption>Figure: Successfully created web app resource. </figcaption>
</figure>

Now that your Web App exists, let's configure it properly for your AI agent application.

**Application settings and environment variables**

Until now in this post series we have been working locally, and kept the environment variables in a local `.env` file.
Your deployed Streamlit app also needs to access them. Here is the easiest way to configure them in the deployed application.

**In the Azure Portal:**

1. Navigate to your Web App resource
2. In the left menu, select **Settings** and **Environment variables**
3. Click **+ Add** and add each environment variable as a key-value pair
4. When done click **Apply** and **Confirm** app restart, if prompted

![Application settings configuration]({{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/app_env_vars_in_azure.png)
_Figure: Adding environment variables in application settings._

> **Security note:** For the first setup a direct insert into the Settings Environment Variables is sufficient. For most secure architecture setup you should consider using Azure Key Vault instead of adding environment variables directly to the app settings. More on this in the [Security best practices](#security-best-practices) section. 

Please refer to **my previous posts:** 
[How to build a home for an ai agent]({% post_url 2025-10-15-ai-agents-azure-and-streamlit%}#environment-variables)
on how to retrieve the agent id and Foundry project endpoint, and to
[AI agents with Azure Python SDK]({% post_url 2025-10-27-ai-agents-azure-python-sdk %}#sheet-utility-functions) and Google's official [Sheets API Python Quickstart guide](https://developers.google.com/sheets/api/quickstart/python) on how to retrieve google app credentials and google sheet id.

> **Encoding note:** The google_app_credentials_json environment variable is originally retrieved as a JSON file, and can be locally stored and used as is. For deployment it has to be converted to a base64 string like so:

```bash
# Minify JSON and encode to base64
cat your-service-account-key.json | jq -c . | base64 > credentials-base64.txt

# View the encoded string
cat credentials-base64.txt
```

Then add the entire base64 string as the `google_app_credentials_json` environment variable in Azure.

**Startup command configuration**

Streamlit apps require a specific startup command: 

1. Go to **Configuration** > **Stack settings**
2. Find the **Startup Command** field
3. Enter the startup command, and click **Apply**:

```bash
#streamlit startup command:
python -m streamlit run app.py --server.port=8000 --server.address=0.0.0.0
```

![Startup command configuration]({{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/app_startup_command.png)
_Figure: Configuring the startup command for Streamlit._


**Granting your app access to Azure AI Foundry**

Your Web App needs permission to access your AI Foundry project. Use **Managed Identity** for secure, credential-free authentication.

**First we need to Enable Managed Identity for the web app:**

![Web app managed identity]({{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/enable_managed_identity.png)
_Figure: Enable web app's managed identity._

  1. Still in your web app, go to **Identity** > **System assigned** tab.
  2. Set the status to **On** and **Save**. This generates an identity for your app.

**Assign the app permissions to Cognitive Services**

1. Navigate to your AI Foundry resource, under **Resource Management** click on the Foundry project
2. In your project go to **Access control (IAM)**, click **+ Add role assignment**
3. In the **Role** tab search for and select **Cognitive Services Contributor** role, click **Next**
4. Under **Members**, select **Managed identity**, choose your app's subscription and select your web app's managed identity, and click **Review + assign**

<div class="main-carousel" data-flickity='{ "cellAlign": "left", "contain": true, "wrapAround": true }'>
  
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/foundry_project_resource.png" alt="Step 1">
    <p>1. Navigate to your Foundry resource's project settings </p>
  </div>

  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/access_control_add_role.png" alt="Step 2">
    <p>2. Add role assignment </p>
  </div>

  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/cognitive_services_contributor_role.png" alt="Step 3">
    <p>3. Choose the Cognitive Services Contributor role </p>
  </div>

<div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/add_role_assignment.png" alt="Step 4">
    <p>4. Find the app you just gave managed identity to, and assign it the role </p>
  </div>

</div>

* * *

# Setting up CI/CD with GitHub Actions

Automated deployment makes life easier. Here I'll show you how to configure GitHub Actions to deploy your app whenever you push code to GitHub. As a prerequisite, I assume you are familiar with basic GitHub usage. 

![Deployment Center]({{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/deployment_center.png)
_Figure: Configuring GitHub deployment in Deployment Center._

**Deployment Center setup**

1. Navigate to your Web App
2. Select **Deployment** > **Deployment Center** in the left menu
3. Choose **GitHub** as the source, authenticate with your GitHub account if needed
4. Select your organization, repository and the branch you want to deploy. I'll use the `main` branch for this demo production setup.
5. Select "Add a workflow"
6. Click **Save**

As you click **Save**, Azure automatically generates a GitHub Actions workflow file and commits it to your repository at `.github/workflows/main_your-app-name.yml` in the chosen branch. 

Azure also creates and stores secrets for `client-id`, `tenant-id` and `subscription-id` in the chosen GitHub repository, and adds a connection to them in the workflow file.
You can find the secrets in your repo here: **GitHub repository Settings (top bar) > Secrets and variable (left menu) > Actions.**

**Customizing the workflow file**

The auto-generated workflow file needs to be adjusted so that package versioning with `uv` can be used in the `CI/CD` setup. In my first posts of this series the project was tiny, so for the first drafts the package versioning with `requirements.txt`
was a good start. Now that I have developed an entire system with a larger number of packages and several deployment environments, I decided to add versioning with `uv` and also updated python version to `python 3.13`.

**How to switch from requirements.txt to uv:**
- [Install and set up uv](https://pydevtools.com/handbook/reference/uv/).
- Create `pyproject.toml` by compiling `requirements.txt` to `pyproject.toml` used by uv by running in terminal: 

```bash
uv pip compile requirements.txt -o pyproject.toml
```

- Run `uv sync` to install all package dependencies and also generate a `uv.lock` file.
- Commit `pyproject.toml`, `uv.lock` and push/merge to the `main` branch.
- It's now safe to remove the `requirements.txt` file and the old `pyenv` or `venv`, if you previously created a python environment.

**Key improvements in the workflow file:**

- Uses `uv` for faster dependency installation
- Properly excludes unnecessary files from the deployment artifact
- Adds `workflow_dispatch` trigger for manual deployment
- Uses artifact upload/download for cleaner build separation

{% highlight yaml linenos %}

#main_dinner-planner.yml

#Docs for the Azure Web Apps Deploy action: https://github.com/Azure/webapps-deploy
#More GitHub Actions for Azure: https://github.com/Azure/actions
#More info on Python, GitHub Actions, and Azure App Service: https://aka.ms/python-webapps-actions

name: Build and deploy Python app to Azure Web App - dinner-planner

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python version
        uses: actions/setup-python@v5
        with:
          python-version: '3.13'

      - name: Install uv
        run: |
          curl -LsSf https://astral.sh/uv/install.sh | sh
          echo "$HOME/.cargo/bin" >> $GITHUB_PATH

      - name: Install dependencies with uv
        run: |
          uv sync
      
      - name: Verify uv.lock exists
        run: |
          echo "Checking for uv.lock and pyproject.toml..."
          ls -la uv.lock pyproject.toml
          echo "uv.lock size: $(wc -c < uv.lock) bytes"    

      - name: Run tests
        run: |
          uv run pytest tests/ || echo "No tests found"

      - name: Upload artifact for deployment jobs
        uses: actions/upload-artifact@v4
        with:
          name: python-app
          path: |
            .
            !.venv/
            !.git/
            !.github/

  deploy:
    runs-on: ubuntu-latest
    needs: build
    permissions:
      id-token: write
      contents: read

    steps:
      - name: Download artifact from build job
        uses: actions/download-artifact@v4
        with:
          name: python-app
      
      - name: Debug - Check downloaded files
        run: |
          echo "Files in artifact:"
          ls -la
          echo "Checking for uv.lock:"
          ls -la uv.lock || echo "uv.lock NOT FOUND!"
          echo "Checking for pyproject.toml:"
          ls -la pyproject.toml || echo "pyproject.toml NOT FOUND!"
      
      - name: Login to Azure
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZUREAPPSERVICE_CLIENTID_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX }}
          tenant-id: ${{ secrets.AZUREAPPSERVICE_TENANTID_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX }}
          subscription-id: ${{ secrets.AZUREAPPSERVICE_SUBSCRIPTIONID_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX }}

      - name: 'Deploy to Azure Web App'
        uses: azure/webapps-deploy@v3
        id: deploy-to-webapp
        with:
          app-name: 'dinner-generator'
          slot-name: 'Production'

{% endhighlight %}

* * *

# Deployment in action

Once everything is configured, let's see the deployment process in action.
Simply pushing the code to your main branch now triggers the automatic deployment process.

```bash
git add .
git commit -m "Update deployment files."
git push origin main
```

**Monitoring the build**

Watch the workflow progress in the Actions tab of your repository. Each step shows real-time logs.

<div class="main-carousel" data-flickity='{ "cellAlign": "left", "contain": true, "wrapAround": true }'>
  
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/github_actions_tab.png" alt="Step 1">
    <p>1. Github Actions main tab, select a workflow. </p>
  </div>

  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/github_actions_workflow.png" alt="Step 2">
    <p>2. Example of completed workflow, triggered by a merge to the main branch. </p>
  </div>

  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/github_actions_build.png" alt="Step 3">
    <p>3. Artifact building steps </p>
  </div>

<div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/github_actions_deploy.png" alt="Step 4">
    <p>4. Artifact deployment steps </p>
  </div>

</div>

There are two main stages in Github Actions - build and deploy the artifact.
An artifact is a packaged version of the essential parts of the code repo into a ZIP file.

**1. Build the artifact - main steps:**
- Set up job: Provisions runner environment on a virtual machine 
- Run actions: Clones your repository, checks code and places it into the runner environment
- Setup Python: Installs the specified Python version
- Install dependencies: Runs `pip install` or `uv sync`, depending on the workflow file setup.
- Run unit tests: if any are created
- Create artifact and upload: Zips your application
- Upload to storage: Uploads the artifact to GitHub artifact storage



**2. Deploy the artifact - main steps:**
- Download artifact - Retrieves the ZIP file created by the build job
- Debug checks - Verifies uv.lock and pyproject.toml are present
- Login to Azure - Authenticates using your stored secrets (client-id, tenant-id, subscription-id)
- Deploy to Azure Web App - Uploads the artifact to your Azure Web App

The entire process typically takes 2-5 minutes.

**Post-deployment: Oryx build**

After GitHub Actions uploads your code to Azure, the Oryx build system takes over and performs these steps:

- Detects Python version from workflow configuration
- Creates a virtual environment on the compute instance which was set up on app creation
- Installs dependencies 
- Configures the runtime
- Starts your application with the configured startup command

You can monitor this in the Azure Web App:

1. Navigate to your Web App
2. Go to **Deployment Center** > **Logs**
3. Click on and view build/deploy logs from GitHub Actions or the app logs from Oryx.

<div class="main-carousel" data-flickity='{ "cellAlign": "left", "contain": true, "wrapAround": true }'>
  
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/deployment_center_logs.png" alt="Step 1">
    <p>1. Deployment Center Logs. </p>
  </div>

  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/deployment_center_app_logs.png" alt="Step 2">
    <p>2. Example of a successful app log. </p>
  </div>

</div>
* * *

# Debugging deployment issues

Don't be discouraged if the deployment doesn't go smoothly. Troubleshooting and debugging is where a lot of the learning and system understanding happens! Below I'll show you how to 
troubleshoot the most common issues.

**Accessing application logs**

To see the deployment error details we can access the app's log stream.

**Log Stream (Real-time):**

1. In Azure Portal, go to your Web App
2. Select **Log stream** in the left menu 
3. Watch logs in real-time as your app starts

**Common issues and solutions**

**Issue 1: Application fails to start**
**Symptom:** Web App shows "Application Error" or doesn't respond

**Common causes:**

- **Wrong startup command:** Verify it matches your app's entry point
- **Missing dependencies:** Check that your `pyproject.toml` is updated and complete
- **Port mismatch:** Streamlit must listen on the port specified by Azure (typically 8000)

**Solution:**

Ensure your startup command is:
```bash
python -m streamlit run app.py --server.port=8000 --server.address=0.0.0.0
```

**Issue 2: Module not found errors**

**Symptom:** `ModuleNotFoundError: No module named 'streamlit'`

**Cause:** Dependencies weren't installed properly

**Solution:**

1. Verify `pyproject.toml` is updated and complete and includes all dependencies:
   ```
   streamlit==1.30.0
   azure-ai-projects==1.0.0
   azure-identity==1.15.0
   pandas==2.1.4
   python-dotenv==1.0.0
   ```

2. Check GitHub Actions logs for installation errors
3. Add print statements to your workflow file to ensure that the package manager is correctly installed (like in line 32 in the workflow file) and that versioning files exist (like in lines 38-42) in the workflow file.

**Issue 3: Authentication failures**

**Symptom:** `DefaultAzureCredential failed to retrieve a token`

**Cause:** Managed identity not configured or lacks permissions

**Solution:**

1. Verify managed identity is enabled in Azure Portal under the app's **Identity**
2. Check role assignments on Microsoft Foundry project 
3. Check that both the Foundry and the Web App resources belong to the same resource group and the same geographical region.

**Issue 4: Environment variables not loading**

**Symptom:** `KeyError: 'dingen_azure_endpoint'` or similar

**Cause:** Environment variables not configured in Web App settings

**Solution:**

1. Verify Web App variables in Azure Portal: **Settings** > **Environment variables**
2. Click **Save** after adding/modifying variables
3. **Restart** the Web App to apply changes: **Overview** > **Restart**

**Issue 5: Build error in GitHub Actions or in Oryx**

**Symptom:** GitHub Actions build or Oryx build returns errors

**Cause:** Sometimes when you push several times to your branch within a short time interval, the new workflow might interfere with the unfinished previous workflow.

**Solution:**

1. Read the log specifics
2. Try to re-run the workflow again, if nothing else in the logs makes sense 


**Issue 6: Build times out or returns a build error**

**Symptom:** GitHub Actions or Oryx build exceeds time limit

**Cause:** Large dependencies (e.g., TensorFlow, PyTorch) take too long to install

**Solution:**

1. Use `uv` for faster installs (already in our workflow)
2. Consider deployment with Docker containers if you implement heavy package dependencies
3. Upgrade to a higher tier Web App plan with better resources



And last but not least, if you're really stuck and you have access to GitHub Copilot or some other AI coding assistant/agent, ask it for help understanding and debugging the errors! 

**Monitoring and detailed logging**

Just a small note on app monitoring. In a real setting, app monitoring would be the way to go. Under the **Monitoring** in the web app's left menu there are a lot of options on how to monitor and diagnose events in your app. One of these is enabling detailed logging, if you're having persistent deployment issues: In **Monitoring** > **App Service logs** turn the File System logging on and save. 

* * *

# The app on the www

After a successful deployment you can now access your app on the world wide web. You can find the default Azure domain link by accessing your web app resource and going to the **Overview** section.

![Web app online]({{ site.baseurl }}/assets/images/2025-10-27-ai-agents-web-app/app_web_address.png)
_Figure: Your web app's default online domain can be found here._

We have now reached the bare minimum of steps required to ship a working application online. The sections below are handy for the aim of professionalizing the setup and showing what other parts are required in a real project scenario.

* * *

# Staging and production environments

For production applications, you want a staging environment to verify changes before deploying to production. There are several options on how to go about this in Azure. I will focus on the most budget friendly option, and also link to a tutorial for the slot configuration option.


**Budget-friendly - option 1: Separate Web Apps**

For smaller projects or tighter budgets, create separate Web Apps for staging and production:

**Create staging Web App:**

Just as described above, create one more web app and call it `dinner-planner-staging` or `dinner-generator-staging` or whatever name you want.
When setting up your CI/CD in the Deployment Center, make sure to connect it to the `staging` branch. Further customize your generated workflow `.yml` file as for the `.yml` production file, but with minor differences indicating that this is your staging app:

- Line 12: set branch to `- staging` 
- Line 51: set name to `python-app-staging`
- Line 69: set name to `python-app-staging`
- Line 87: set name to `Deploy to Azure Web App - Staging`
- Line 91: set app-name to `dinner-planner-staging`
- Note: Be careful with copy-paste: Azure generates separate GitHub secrets for the staging app, and adds them to the new `.yml` file, so these are automatically different too.


> Note: This approach costs less (two Basic B1 instances ~$26/month vs one Standard S1 ~$70/month), but it requires managing two separate Web Apps.

* * *

**More costly - option 2: Deployment slots**

Deployment slots provide isolated environments within the same Web App. Each slot has its own hostname and can have different configurations, but shares the same App Service Plan resources.

Other benefits of deployment slots are:
- Test in a production-like environment before going live
- Zero-downtime deployments via slot swapping
- Easy rollback—just swap back to the previous slot
- Different configurations per slot (connection strings, app settings, etc.)

Follow this [Azure Web Apps tutorial](https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots?tabs=portal) on how to set up deployment slots in the application, if you decide to go for this option.

> **Note:** Deployment slots require **Standard tier or higher**. You'll need to upgrade from Basic B1 (~$13/month) to Standard S1 (~$70/month).



# Security best practices

Until now we have set up our app with inserting environment variables directly into the web app settings. This is fine for demonstration purposes, but in a more realistic setting it would be more security friendly to establish a key vault, store the environment variables as secrets there, and invoke the secrets from the vault. Below are a couple of notes on why and how to set it up.

**Using Azure Key Vault for secrets**

Storing secrets directly in Application Settings is convenient but exposes them to anyone with access to your Web App configuration. Azure Key Vault provides enterprise-grade security with:

- **Hardware-encrypted storage:** Secrets are protected by HSMs (Hardware Security Modules)
- **Granular access control:** Restrict which apps and users can access specific secrets
- **Audit trails:** Track who accessed secrets and when
- **Secret rotation:** Update secrets without redeploying your app
- **Compliance:** Meets HIPAA, PCI-DSS, SOC 2 standards

**High-level setup:**

1. Create a Key Vault resource in Azure Portal
2. Store your secrets (API keys, connection strings, credentials)
3. Grant your Web App's managed identity access to the Key Vault
4. Reference secrets in your Web App settings using: `@Microsoft.KeyVault(VaultName=your-vault;SecretName=your-secret)`

For detailed step-by-step instructions, see Microsoft's official guide: [Use Key Vault references for App Service](https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references).

**Enabling HTTPS only**

HTTPS encrypts all data transmitted between users and your application, protecting sensitive information like login credentials, API keys, and personal data from interception. Without HTTPS, data travels in plain text and can be read by anyone monitoring the network.

Enable HTTPS-only to ensure secure connections:

1. Navigate to your Web App in Azure Portal
2. In the left menu, select **Settings** > **Configuration**
3. Click on the **General settings** tab
4. Find **HTTPS Only** and toggle it to **On**
5. Click **Save** at the top

All HTTP requests will now be automatically redirected to HTTPS.

* * *

# Authentication and authorization

We have now deployed our app without any access restrictions. To restrict access and track users, you can enable authentication. Azure supports multiple identity providers: Microsoft, Google, Facebook and more. Each provider has different access restriction levels — from allowing any authenticated user to limiting access to specific accounts or organizations. The configuration in step 5 links to detailed documentation on these provider-specific settings. Below is a quick setup guide with a link on details regarding provider settings configuration.

**Easy Auth - Azure App Service Authentication**

Enable authentication in the app settings:

- Go to your Web App
- Select **Settings > Authentication** in the left menu
- Click **Add identity provider**
- Choose a provider (Microsoft, Google, Facebook, etc.)
- Configure provider settings, [check detailed configuration guide](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad):
   - Set app registration details (name, client secret expiration)
   - Configure supported account types
   - Set access restrictions
- Set **Restrict access** to "Require authentication"
- Click **Add**

All requests will now require authentication before accessing your app.

* * *

# Custom domain and SSL

Your Web App comes with a `*.azurewebsites.net` domain, but you can add a custom domain.

**Adding a custom domain**

**Prerequisites:**

- You own a domain (e.g., `dinnerplanner.com`)
- Access to your domain's DNS settings

**Steps:**

1. In Azure Portal, go to your Web App
2. Select **Custom domains**
3. Click **+ Add custom domain**
4. Enter your domain (e.g., `app.dinnerplanner.com`)
5. Azure provides DNS records to add to your domain provider

**DNS records (example):**

```
Type: CNAME
Host: app
Value: your-app-name.azurewebsites.net
```


**Verify and bind:**

After DNS propagates (takes 15 minutes to 24 hours):

1. Click **Validate** in Azure Portal
2. Once validated, click **Add custom domain**

**SSL certificate**

Azure provides free managed SSL certificates:

1. After adding custom domain, go to **TLS/SSL settings**
2. Select **Private Key Certificates (.pfx)**
3. Click **+ Create App Service Managed Certificate**
4. Select your custom domain
5. Click **Create**

Your custom domain is now secured with HTTPS! 🎉

* * *

# Bonus material - automation

If you prefer command-line tools or want to automate this process, use the Azure CLI. This section mirrors the portal configuration steps in the same order.

[Follow this link on how to start with Azure CLI](https://learn.microsoft.com/en-us/cli/azure/?view=azure-cli-latest)

<details markdown=1>
<summary>Click to expand bonus material ⏬</summary>

**Step 1: Create the Web App resource**

```bash
# Login to Azure
az login

# Set variables
RESOURCE_GROUP="avo-rg"
LOCATION="norwayeast"
APP_NAME="dinner-generator"
RUNTIME="PYTHON:3.13"

# Create resource group (if not exists)
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create App Service plan (Basic B1 tier)
az appservice plan create \
    --name "${APP_NAME}-plan" \
    --resource-group $RESOURCE_GROUP \
    --sku B1 \
    --is-linux

# Create Web App
az webapp create \
    --resource-group $RESOURCE_GROUP \
    --plan "${APP_NAME}-plan" \
    --name $APP_NAME \
    --runtime $RUNTIME
```

**Step 2: Configure application settings and environment variables**

```bash
# Set application settings
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --settings \
        dingen_azure_endpoint="https://your-project.openai.azure.com/" \
        email_agent_id="your-email-agent-id" \
        google_app_credentials_json="<base64-encoded-json>" \
        google_sheet_id="your-spreadsheet-id"
```

**Encoding Google credentials:**

```bash
# Minify JSON and encode to base64
cat your-service-account-key.json | jq -c . | base64 > credentials-base64.txt

# View the encoded string
cat credentials-base64.txt
```

**Step 3: Configure startup command**

```bash
az webapp config set \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --startup-file "python -m streamlit run app.py --server.port=8000 --server.address=0.0.0.0"
```

**Step 4: Grant access to Azure AI Foundry**

```bash
# Enable Managed Identity
az webapp identity assign \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME

# Get the Web App's managed identity principal ID
PRINCIPAL_ID=$(az webapp identity show \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --query principalId -o tsv)

# Get your AI Foundry project resource ID
AI_PROJECT_ID=$(az resource show \
    --resource-group $RESOURCE_GROUP \
    --name your-ai-project-name \
    --resource-type "Microsoft.CognitiveServices/accounts" \
    --query id -o tsv)

# Assign Cognitive Services Contributor role
az role assignment create \
    --assignee $PRINCIPAL_ID \
    --role "Cognitive Services Contributor" \
    --scope $AI_PROJECT_ID
```

**Step 5: Setting up CI/CD with GitHub Actions**

The GitHub Actions integration shown in the main tutorial uses the Azure Portal's Deployment Center, which automatically creates service principals and GitHub secrets. While this can also be done via GitHub CLI (creating service principals, managing secrets, configuring webhooks), I recommend the Portal approach for reliability and ease of use. The Portal handles authentication and secret management automatically, reducing common configuration errors.

**Step 6: Security configuration with CLI**

**Create and configure Azure Key Vault:**

```bash
VAULT_NAME="dinner-planner-vault"

# Create Key Vault
az keyvault create \
    --name $VAULT_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION

# Store secrets
az keyvault secret set \
    --vault-name $VAULT_NAME \
    --name "GoogleCredentialsJson" \
    --value "<base64-encoded-json>"

# Get Web App's managed identity
PRINCIPAL_ID=$(az webapp identity show \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --query principalId -o tsv)

# Grant Key Vault access
az keyvault set-policy \
    --name $VAULT_NAME \
    --object-id $PRINCIPAL_ID \
    --secret-permissions get list
```

**Enable HTTPS-only:**

```bash
az webapp update \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --https-only true
```

**Step 7: Configure authentication with CLI**

```bash
# Enable Microsoft authentication
az webapp auth microsoft update \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --client-id <your-app-client-id> \
    --client-secret <your-app-client-secret> \
    --yes

# Require authentication
az webapp auth update \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --enabled true \
    --action LoginWithMicrosoft
```

**The below might be handy - accessing user information in code**

Once authentication is enabled, you can access user information in your Streamlit app like this.

```python
import streamlit as st
import os

def get_authenticated_user():
    """Retrieve authenticated user info from Easy Auth headers."""
    user_principal = os.environ.get("X_MS_CLIENT_PRINCIPAL_NAME")
    user_id = os.environ.get("X_MS_CLIENT_PRINCIPAL_ID")
    
    if user_principal:
        return {"name": user_principal, "id": user_id}
    return None

# In your app
user = get_authenticated_user()
if user:
    st.sidebar.write(f"👤 Logged in as: {user['name']}")
```


**Step 8: Custom domain and SSL**

**Add custom domain if you own one:**

```bash
# Add custom domain
az webapp config hostname add \
    --resource-group $RESOURCE_GROUP \
    --webapp-name $APP_NAME \
    --hostname app.your-domain.com
```

**Create managed SSL certificate:**

```bash
# Create managed certificate for custom domain
az webapp config ssl create \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --hostname app.your-domain.com

# Bind SSL certificate to custom domain
az webapp config ssl bind \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --certificate-thumbprint <thumbprint-from-previous-command> \
    --ssl-type SNI
```

> **Note:** Before running these commands, you need to configure DNS records with your domain provider (CNAME record pointing to your Azure Web App). DNS propagation can take 15 minutes to 24 hours.

**Step 9: Debugging with CLI**

**View real-time logs:**

```bash
az webapp log tail \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME
```

**Check managed identity status:**

```bash
az webapp identity show \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME
```

**Enable detailed logging:**

```bash
az webapp log config \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --application-logging filesystem \
    --level information
```
</details>

* * *
# Wrap-up and next steps

Congratulations! 🎉 You've successfully deployed your AI agent application to Azure Web Apps. You now have:

✅ A fully deployed, publicly accessible Streamlit app with an AI agent residing inside it  
✅ Automated CI/CD pipeline with GitHub Actions  
✅ Production and staging deployment environments   
✅ Secure authentication and managed identities  
✅ Knowledge of debugging and troubleshooting techniques

**What you've learned:**

- Setting up Azure Web Apps for Python applications
- Configuring environment variables and startup commands
- Implementing CI/CD with GitHub Actions
- Debugging deployment issues
- Managing staging and production environments
- Securing your application with HTTPS, Key Vault, and authentication

**Where to go from here on app deployment:**

- **Monitoring performance**: Learn to set up Application Insights
- **Scale your app:** Implement auto-scaling for handling more users
- **Optimize costs and performance:** Configure auto-scaling rules, set up budget alerts, and monitor resource usage
- **Explore deployment alternatives:** Try Azure's Container Apps, Kubernetes Service, or Azure Functions for different deployment scenarios

This completes our four-part series on building production-ready AI agents with Azure! We started from the minimum, and now we know how to develop and build systems with AI agents. I hope this journey has demystified agentic AI development and given you practical skills to build your own intelligent applications.


---

*Transparency note: This article is human-written with AI assistance for proofreading and typo correction. Main image generated with AI.*

---

**[Back to top](#top)**

_Found this helpful? Share it with your network and follow for more AI development tutorials!_

Questions? Feedback? Deployment war stories? Drop a comment below—I'd love to hear about your experiences! 💬

{% include giscus.html %}

---


