---
layout: default
title:  "How to build AI agents in Azure AI Foundry"
date:   2025-10-15 14:29:17 +0200
categories: AI agents Azure
---

* TOC
{:toc}

# Introducing AI Agents to the People!
{:top}
During the last year or so, there has been increasing hype around AI agents in the tech industry. News about LLM and agentic advancements are reported on almost weekly. My curiosity about this hype and the need to stay updated led me to a hands-on project where I explore some of the available agentic AI tools. 

I decided to start with Azure, as according to [The State of AI report 2025](https://www.stateof.ai/), Microsoft-owned OpenAI still retains a narrow lead at the LLM frontier. Through my line of work, I have easy access to Azure and all its resources. That said, there are similar agentic tools available in [Google Cloud](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/agent-builder/overview), [AWS](https://aws.amazon.com/bedrock/agents/), and other providers, and it's surely beneficial to check those out as well. 


This is the first post on how to get started exploring the Azure AI Foundry Portal and Agent Services. 
In this post, I'm going to build an AI agent within the framework of an Azure AI Foundry project. I will first build an agent with "no code" in the Azure AI Foundry Portal and test it in the Azure AI Foundry Playground. 

**In upcoming posts** I will further show how to:
- Post: [Build a home for the AI agent with a Streamlit app]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %})
- Post: [Build an agent system in Python with Azure SDK and Streamlit app]({% post_url 2025-10-27-ai-agents-azure-python-sdk %}). Here I will also touch upon "A2A" - i.e., connecting several agents 
- Post: [Agent application deployment with Azure Web Apps]({% post_url 2025-10-27-ai-agents-azure-web-app %}) 

Stay tuned!

## What is Azure AI Foundry?

> [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/what-is-azure-ai-foundry)
 is a unified Azure platform-as-a-service offering for enterprise AI operations, model builders, and application development.
>
> Azure AI Foundry unifies agents, models, and tools under a single management grouping with built-in enterprise-readiness capabilities including tracing, monitoring, evaluations, and customizable enterprise setup configurations.
 
![azure-ai-foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/media/agent-service-the-glue.png) _Figure: Azure AI Foundry unifies agents, models, and tools under an enterprise-ready platform._

## What is an AI agent?
> Agents make decisions, invoke tools, and participate in workflows. Sometimes independently, sometimes in collaboration with other agents or humans. What sets agents apart from assistants is autonomy: assistants support people, agents complete goals. They are foundational to real process automation. 
 Each agent has three core components:
- **Model (LLM):** Powers reasoning and language understanding.
- **Instructions:** Define the agent’s goals, behavior, and constraints.
- **Tools:** Let the agent retrieve knowledge or take action.

[More on definitions: What is Azure AI Foundry Agent Service?](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/overview)

![ai-agent](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/media/what-is-an-agent.png)
_Figure: Core components of an AI agent - Model, Instructions, and Tools working together._





## Use Case Definition
> Please help! What to cook for dinner for the upcoming week?
>
> The customer's need is a dinner planning agent that can help with the weekly challenges of composing a healthy, tasty meal plan while taking into consideration specific preferences, seasonality, and avoiding suggesting recent meals. Once the planning is done, the plan and a shopping list based on the plan should be sent to the user in a nicely rendered email.

The data is in a spreadsheet format where the customer can add entries. The recipe sheet has the following table:

| Recipe       | Time, minutes | Link  | Season | Preference |
|:-------------|:-------------|:------|:-------|:-----------|
| Lasagna      | 120          | www   | all    | weekend    |
| Risotto      | 45           | www   | all    | weekend    |


The history sheet has the following table: 

|Year | Week         | Day    |Recipe |
|:----|:-------------|:-------|:------|
|2025 | 1            | 1      | Salmon with roasted vegetables  |
|2025 | 2            | 2      | Sweet potato soup with fresh bread  |

By the agentic definitions above, we then have the following setup:

- **Input:** 
  - Data of recipes and recently consumed user meals. 
  - User messages. 
  - Agent messages.
  - System events like app session and state.
- **Agent:** 
  - LLM suitable for planning.
  - Instructions like personal meal preferences, seasonal and weekly preferences, latest dinner history to avoid suggesting recently consumed meals.
- **Tools and actions:** 
  - Knowledge retrieval of favorite recipes and recent actual dinners and other preferences. 
  - Email tool with action of sending the user the dinner plan and shopping list. 
  - Memory preservation within the current app session state.
- **Output:** 
  - Agent messages.
  - Weekly dinner plan and shopping list in HTML format. 
  - Plan and shopping list sent to user by email. 

This is, of course, a simple use case, but I hope you can easily contemplate analogies to real solutions and real business use case challenges. 

# Development stages

- No Code: Create agent in AI Foundry Portal and test it in playground (this post)
- Low Code: Build a home for the agent in a Streamlit app (upcoming post)
- Only Code: Build an agent system in Python with Azure SDK and Streamlit app (upcoming post)
- Deployment: Deploy the app with Azure Web Apps (upcoming post)


## Exploration of AI Foundry agent with portal setup

In this link, [Azure AI Foundry - Quickstart](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstarts/get-started-code?tabs=azure-ai-foundry),
 is a step-by-step Microsoft documentation on how to set up your project, deploy a model of choice into it, and build an agent around it. Currently provided models are from Microsoft, OpenAI, DeepSeek, Hugging Face, Meta, and more. In this post, I will include steps on how to set up Azure AI Foundry in the Azure portal and add some tips and tricks regarding the AI Foundry Portal.

### Set up Azure AI Foundry resource in Azure portal
<details markdown=1>
<summary>How to set up and configure Azure AI Foundry resource - click to expand the collapsed content ⏬</summary>

**Basics**

In the Azure portal, create an Azure AI Foundry resource. Look for the ➕ button and type Azure AI Foundry in the search field.


<figure>
  <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/1_az_create_ai_foundry.png" 
       alt="Azure AI Foundry Portal" 
       style="width: 40%; height: auto;">
  <figcaption>Figure: Azure AI Foundry resource creation in Azure portal </figcaption>
</figure>


Fill in metadata about your resource:
- Resource group. Create a new one if you don't have any existing.
- Create a unique AI Foundry resource instance name (Note: An already used name will prevent a successful deployment.) 
- Fill in geographical region. Beware - Not all newest features are available in all regions. For now, Norway will do fine (this is where I am located). If you want to implement cutting-edge features from Azure, it's best to choose Sweden Central if you're in the Nordics. Otherwise, the US region will always have the latest features available. Beware - If in Azure you want to have several resources working together as architectural components of a bigger project infrastructure, they all should be in the same resource group and in the same geographical region, unless the resource at hand is defined as global. 
- Set a unique project name
<figure>
  <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/2_az_create_foundry_project.png" 
       alt="Azure AI Foundry Portal" 
       style="width: 50%; height: auto;">
  <figcaption>Figure: Azure AI Foundry resource creation in Azure portal - Basics</figcaption>
</figure>


**Network**

Choose all networks. Other options are available, check out the links if you need to consider security aspects.
<figure>
  <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/3_az_ai_foundry_network.png" 
       alt="Azure AI Foundry Portal" 
       style="width: 50%; height: auto;">
  <figcaption>Figure: Azure AI Foundry resource creation in Azure portal - Network</figcaption>
</figure>


**Identity**
Choose system assigned for this test project. 
<figure>
  <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/4_az_ai_foundry_identity.png" 
       alt="Azure AI Foundry Portal" 
       style="width: 50%; height: auto;">
  <figcaption>Figure: Azure AI Foundry resource creation in Azure portal - Identity</figcaption>
</figure>


**Encryption and tags**
Leave the entries here empty for now. This needs to be addressed in case of a more serious setup.

**Review and submit**
Submission will trigger final validation. Here you might get errors due to non-unique naming or other potential incompatibilities due to your subscription details. Read the messages and ask the portal copilot if you need to understand them better.

Once the AI Foundry resource is deployed, click the **"Go to resource"** button and then click **"Go to Azure AI Foundry Portal"**.

🎊 🎊 Congrats, you should end up here, and we're ready to play! 🎊 🎊

<figure>
  <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/5_az_ai_foundry_portal.png" 
       alt="Azure AI Foundry Portal" 
       style="width: 70%; height: auto;">
  <figcaption>Figure: Azure AI Foundry portal - project overview </figcaption>
</figure>


</details>

### Build an AI agent in AI Foundry Portal

<details markdown=1>
<summary>How to build an AI agent in Azure AI Foundry Portal - click to expand the collapsed content ⏬</summary>

In the AI Foundry portal on the left sidebar, click the "Agents" button and then click "New Agent". 
A right sidebar will appear with agent settings. We will adjust these now. 

<figure>
  <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/6a_az_create_ai_agent.png" 
       alt="Azure AI Foundry Portal" 
       style="width: 100%; height: auto;">
  <figcaption>Figure: Azure AI Foundry portal - create an AI agent </figcaption>
</figure>


Give the agent a suitable name and choose the LLM model you want to use. In this case, I'll call it planning-agent and choose the gpt-4o model, which is lightweight and suitable for planning purposes of the use case and prototype. You can always easily switch the model. You can find the full list of LLMs under "Model catalog", also in the left sidebar. 

Give the agent instructions on what it should do. Here is an example of my text:

```
You are a dinner planning assistant. 
Generate a 7-day dinner plan based on the user's dietary preferences, 
season and user's favourite dinners located in a spreadsheet. 
Avoid suggesting last week's dinners, which are also in the same spreadsheet. 
When the user is happy with your suggestion, 
send the plan to user's e-mail together with a grocery list. 
Format the e-mail with a kind greeting, dinner output such as:

Monday: dinner for that day 

Tuesday: dinner for that day

Etc

Shopping list:

Ingredient 1, quantity

Ingredient 2, quantity

Etc

Do not display provenance/citations markers in your responses.

Ask user for the email address before sending.

Convert markdown content to HTML before sending the email. 
This ensures proper rendering in the email client."
```

### Add tools to the agent

Continue to click down the right sidebar of the AI Foundry portal by adding tools to the agent. 

<link rel="stylesheet" href="https://unpkg.com/flickity@2/dist/flickity.min.css">
<script src="https://unpkg.com/flickity@2/dist/flickity.pkgd.min.js"></script>

<div class="main-carousel" data-flickity='{ "cellAlign": "left", "contain": true, "wrapAround": true }'>
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/6_az_add_knowledge.png" alt="Step 1">
    <p>1. Add knowledge tool</p>
  </div>
  
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/7_az_agent_add_files.png" alt="Step 2">
    <p>2. Upload files into a vector store</p>
  </div>
  
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/8_az_email_tool.png" alt="Step 3">
    <p>3. Add action of a logic app</p>
  </div>

  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/8b_az_agent_email_tool.png" alt="Step 3">
    <p>4. Add email logic app</p>
  </div>
</div>




Azure has an extensive library of available tools we can add to the agent.
[Check out the library here.](https://ai.azure.com/doc/azure/ai-foundry/agents/how-to/tools/overview?tid=513294a0-3e20-41b2-a970-6d30bf1546fa) 


I will first add a knowledge tool so the agent can access the recipes and recent dinner history. For demonstration purposes, I will convert each sheet to a `.txt` file and add them to the agent via a direct file upload. Note which file extensions are supported. Unfortunately, Excel files are not among them. Click on add and select Files. I originally wanted to add a live spreadsheet from SharePoint to the agent but had difficulties with the SharePoint preview features. Read about how I solved it in my upcoming posts. Read more about the SharePoint preview feature [here](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/tools/sharepoint).

In the adding files section, create a vector store, as we don't have any existing. 

Let's add some agentic actions by choosing Azure Logic Apps. Here we have a selection of pre-configured apps. Choose the Send-email-outlook logic app and follow the portal's lead.

I will keep the model settings as they are, and voice enablement will be out of scope for now. I encourage you to play around and test it!

Our agent is ready to be tested in the portal playground.

**Hot tip:** After the agent is created, you can find the vector store and its content in the left sidebar -> 
`My assets -> Data + indexes -> Vector stores`
. If you later create an agent by code which exists only during an app session state and has knowledge added to it, you will find the associated vector store here as well.

</details>

### Test the AI agent in AI Foundry Playground
In your AI Foundry project's left sidebar, go to **Playgrounds -> Agents playground.**
Select the agent you have created and take it for a little chat. Below you can see tests I conducted to check whether the agent behaves according to its instructions:

<link rel="stylesheet" href="https://unpkg.com/flickity@2/dist/flickity.min.css">
<script src="https://unpkg.com/flickity@2/dist/flickity.pkgd.min.js"></script>

<div class="main-carousel" data-flickity='{ "cellAlign": "left", "contain": true, "wrapAround": true }'>
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/9_az_agent_chat.png" alt="Step 1">
    <p>Ask for agent instructions</p>
  </div>
  
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/10_az_agent_chat.png" alt="Step 2">
    <p>Ask for a plan with specific additional detail requests</p>
  </div>
  
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/11_az_agent_chat.png" alt="Step 3">
    <p>Ask to see the shopping list</p>
  </div>
</div>






# First impression of Azure AI Foundry's state of maturity and further thoughts

What worked well:
- Very easy to get started.
- Nice tutorials and documentation in addittion to the extensive library of agent tools.
- Intuitive UI setup in AI Foundry, you don't always need a tutorial to understand where you need to go,
 and what buttons to press.

What could be better:

Connecting to live documents:

I first wanted to add the Sharepoint (preview) tool, as I wanted the agent to be able to read an excel spreadsheet. 
Here I got stuck in preview features not working as intended, excel file format not yet being supportetd, in addition to corporate file access and firewall restrictions,
as I am working on my company-mac. However, I did manage to solve this by some creativity, see my upcoming posts on how I solved the issue of connection to a live spreadsheet instead of static files.

Email did not always work in playground as it should. Need to figure out what is wrong.

I hope you got a great quickstart on the subject and see you in my next post, expected in November 2025.
All best 🩵! 

---

**[🔝 Back to top 🔝](#top)**

<style>
.carousel-cell {
  width: 70%;
  margin-right: 10px;
  text-align: center;
}

.carousel-cell img {
  width: 100%;
  height: auto;
  border-radius: 8px;
  cursor: zoom-in;
  transition: transform 0.2s ease;
}

.carousel-cell img:hover {
  transform: scale(1.15);
}
</style>





