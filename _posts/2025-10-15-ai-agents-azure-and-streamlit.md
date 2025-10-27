---
layout: default
title:  "How to build a streamlit home for Azure AI Foundry agents"
date:   2025-10-15 14:29:17 +0200
categories: AI agents Azure Streamlit
---

* TOC
{:toc}

# Introduction
Background. Agent hype, latest LLM advancements, curiosity, hands-on how-to. PwC Microsoft partner, therefore I have easy access to Azure and all its resources. Similar agentic tools available in Google Cloud, AWS and other providers.
Microsoft + OpenAi.

This is the first post on how to get started exploring in Foundry playground, low/medium code on wrapping/housing the agent in a simple streamlit app user interface. In upcoming posts I will show you how to lift the project to a higher level of coding and further discuss how to deploy the app with Azure Web Apps, so more peole can benefit from the agent, so stay tuned!

In this post I'm going to build an AI-agent within the framework of an Azure AI Foundry project. I will first build an agent with "no code" in the Azure AI Foundry Portal, and test it in the Azure AI Foundry Playground. 

Next I will wrap a streamlit app code around the agent, so I can interact with it via environments other than the portal playground. 

**In upcoming posts** I will further show how to:
- Post: Build an AI agent with code, implementation with azure python SDK 
- Post: Utilise "A2A", ie connecting several agents with different abilities together 
- Post: Agent application deployment with Azure Web Apps 


## What is Azure AI Foundry?

> [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/what-is-azure-ai-foundry)
 is a unified Azure platform-as-a-service offering for enterprise AI operations, model builders, and application development.
>
> Azure AI Foundry unifies agents, models, and tools under a single management grouping with built-in enterprise-readiness capabilities including tracing, monitoring, evaluations, and customizable enterprise setup configurations.
 
![azure-ai-foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/media/agent-service-the-glue.png) _Figure: Azure AI Foundry unifies agents, models, and tools under enterprise-ready platform._

## What is an AI-agent?
> Agents make decisions, invoke tools, and participate in workflows. Sometimes independently,  sometimes in collaboration with other agents or humans. What sets agents apart from assistants is autonomy: assistants support people, agents complete goals. They are foundational to real process automation. 
 Each agent has three core components:
- **Model (LLM):** Powers reasoning and language understanding
- **Instructions:** Define the agent’s goals, behavior, and constraints
- **Tools:** Let the agent retrieve knowledge or take action

[More on definitions: What is Azure AI Foundry Agent Service?](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/overview)

![ai-agent](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/media/what-is-an-agent.png)
_Figure: Core components of an AI agent - Model, Instructions, and Tools working together._





## Use Case Definition
> Please help! What to cook for dinner for the upcoming week?
>
> Customer's need is a dinner planning agent, which can help out with weekly challenges of composing a healthy, tasty meal plan, while taking into consideration specific preferences, seasonality and avoid recent meals. Once the planning is done, the plan and a shopping list based on the plan, should be sent to the user in a nicely rendered per e-amil.

- **Input:** 
  - Data of recipes and recently had user meals 
  - User messages 
  - Agent messages
  - System events like app session initiation and state
- **Agent:** 
  - LLM suitable for planning, like gpt4o-mini
  - Instructions like personal meal preferences, seasonal and weekly preferences, latest dinner history to avoid suggesting recently had meals.
- **Tools and actions:** 
  - Knowledge retrieval of favourite recipes and recent actual dinners and other preferences 
  - Email tool with action of sending user the dinner plan and shopping list 
  - Memory preservation within the current app session state.
- **Output:** 
  - Agent messages
  - Weekly dinner plan and shopping list in html-format 
  - Plan and shopping list sent to user as e-mail 

This is of course a simple use case, but I hope you can easily contemplate on analogies to real solutions and real business use case challenges. 

# Development stages
**TODO:** Add steps and images here

## Exploration of AI Foundry agent with portal setup

In this link, [Azure AI Foundry - Quickstart](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstarts/get-started-code?tabs=azure-ai-foundry),
 is a step-by-step Microsoft documentation on how to set up your project, deploy a model of choice (provides models from Microsoft, OpenAI, DeepSeek, Hugging Face, Meta, and more.
) into it, and build an agent around it. In this post I will include steps on how to set up Azure Ai Foundry in the Azure portal, include updated images and notes of changes in the portal front-end, which is in the writing moment a bit different compared with the original documentation. I will also add some tips and trics regarding the Ai Foundry Portal.

### Set up Azure AI Foundry resource in Azure portal
<details markdown=1>
<summary>How to configure Azure AI Foundry resource - click to expand the collapsed content ⏬</summary>

**Basics**

In Azure portal create an Azure AI Foundry resource. Look for the ➕ button and type Azure AI Foundry in the search field.


<figure>
  <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/1_az_create_ai_foundry.png" 
       alt="Azure AI Foundry Portal" 
       style="width: 40%; height: auto;">
  <figcaption>Figure: Azure AI Foundry resource creation in Azure portal </figcaption>
</figure>


Fill in metadata about your resource:
- Resource group. Create a new if you don't have any existing.
- Create a unique AI Foundry resource instance name (NB! An already used naming will prevent a successful deploy.) 
- Fill in geographical region. Beware - Not all newest features are available in all regions. For now Norway will do fine (this is where I am located). If you want to implement cutting edge features from Azure, it's best to choose Sweden Central, if you're in the Nordics. Otherwise US-region will always have latest features available. Beware - If in Azure you want to have several resources working together as architectural componens of a bigger project infrastructure, they all should be in the same resource group and in the same geographical region, unless the resource at hand is defined global. 
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
Leave the entries here empty for now. This needs to be addressed in case of a more serious setup

**Review and submit**
Submission will trigger final validation. Here you might get errors due to non-unique naming or other potential incompatibilities due to your subscription details. Read the messages and ask portal copilot, if you need to understand them better.

Once the AI Foundry resource is deployed, click the **"go to resource - button"** and the click the **"Go to Azure AI Foundry Portal"**

<figure>
  <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/5_az_ai_foundry_portal.png" 
       alt="Azure AI Foundry Portal" 
       style="width: 70%; height: auto;">
  <figcaption>Figure: Azure AI Foundry portal - project overview </figcaption>
</figure>

🎊 Gongrats, you should end up here, and we're ready to play! 🎊

</details>

### Build an Ai agent in AI Foundry Portal
In the AI Foundry portal on the left sidebar click "Agents" button and then click "New Agent". 
A right sidebar will appear with agent settings. We will
adjust these now. 

Give the agent a suitable name and choose the LLM-model you want to use. In this case I'll choose gpt-4o which is light weight and suitable for planning purposes of the use case. You can find the full list of LLMs under "Models", also in the left sidebar. 

Give the agent a instructions of what it should do. Here is an example:

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

Igredient 2, quantity

Etc

Do not display provenance/citations markers in your responses.

Ask user for the e-mail address before sending

Convert markdown content to HTML before sending the email. 
This ensures proper rendering in the email client."
```

### Add tools to the agent

Original data:


Tools:

Azure has an extensive library of avaialble tools we can add to the agent:[Library of agentic tools](https://ai.azure.com/doc/azure/ai-foundry/agents/how-to/tools/overview?tid=513294a0-3e20-41b2-a970-6d30bf1546fa) 


I will first add a knowledge tool, so the agent can access recipes and recipe history. Click on add, and select Files. 
I first wanted to add the Sharepoint (preview) tool, as I wanted the agent to be able to read an excel spreadsheet. Here I got stuck in corporate file access and firewall restrictions, no ability of adding excel files. See my next post on how I solved the issue of connection to a live spreadsheet instead of static files. So for demonstration purposes we will convert each sheet to ```.txt``` files and add it to the agent via a direct file upload. Note which file extensions are supported. 


Create a vector store, as we don't have any existing. 


Let's add some agentic actions by choosing the Azure Logic Apps. Here we have pre-configured apps, choose Send-email-outlook logic app. Follow the protal's lead.

I will not touch the model settings or voice enable the agent for now, but here you also can play around.

Our agent is ready to be tested in the portal playground

**Hot tip** After the agent is created you can find the vector store and its contents in left sidebar -> My assets -> Data + indexes -> Vector stores. If you later create an agent by code which exists only during a session state, and has knowledge added to it, you will find the associated vector store here as well.


### Testing Ai agent in AI Foundry playground
Left sidebar -> Playgrounds -> Agents playground
Select the agent you have created and take it for a little chat

* * *

## Housing the AI-agent in a streamlit app 
Now that all is working well in the portal playground, we need to build an app customer friendly environment around the agent. In a real setting a customer would not be able to log into developer's portal.

Below I'll show how this can be done with streamlit. The scope of current post is a setup on `localhost`.
  
  
### Streamlit chat functionality

If you have never tried Streamlit apps before, I highly recommend to go through their introductory and chat-app tutorials as a prerequisite for the upcoming code:

- [Create a streamlit app](https://docs.streamlit.io/get-started/tutorials/create-an-app)  
- [Build a basic LLM chat app with streamlit](https://docs.streamlit.io/develop/tutorials/chat-and-llm-apps/build-conversational-apps)

### Application Code

[Link to repo](https://github.com/auroravoje/ai-agent/tree/sme-version)

Connect to azure via azure python SDK + .env vars
Add link to the repo with correct branch. 

#### Package installation and import

<details markdown=1>
<summary>📦 Package imports and setup - click to expand code ⏬ </summary>
```python
#app.py - package imports
import os
from typing import Optional, Tuple, List, Any
from dotenv import load_dotenv
import streamlit as st
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential
from azure.ai.agents.models import ListSortOrder
from streamlit_styles import apply_style_background, apply_style_blur
from utils import *
```

</details>

You also see an import of custom styling. This is not the scope of this article, but is included to make the app appear a bit less boring. You can view the content in the repo link.

* * *

#### Environment variables

In order to connect to the correct Azure AI Foundry project and to the correct agent within the project, you might in time get several per project, we need two evironment variables:
* Azure endpoint: called `dingen_azure_endpoint` in my code
* Agent id: called `dingen_agent_id` in my code
(_dingen_ is abbreviation for dinner generator)

In the Azure AI Foundry portal you find the values here, copy and paste the into your `.env` file in root directory.

<details markdown=1>
<summary>🔡 Environment variables - click to expand code ⏬</summary>
```python
dingen_azure_endpoint = pastehere
dingen_agent_id = pastehere
```

</details>

* * *

#### Utility functions
<details markdown=1>
<summary>🔧 Utility functions - click to expand code ⏬</summary>
```python
#utils.py 
def is_local() -> bool:
    """Return True when running in a local/dev environment.

    The function checks the LOCAL_DEV environment variable and the presence
    of a local .env file to determine whether the app is running locally.
    """
    return os.environ.get("LOCAL_DEV") == "1" or os.path.exists(".env")

if is_local():
    load_dotenv()
        
def create_thread(client: AIProjectClient, agent_id: str, user_message: str) -> Tuple[Optional[str], Optional[str]]:
    """Create a new thread, post a user message, and start processing a run.

    Args:
        client: An initialized Azure AIProjectClient.
        agent_id: The agent identifier to run.
        user_message: The user's message to post to the new thread.

    Returns:
        A tuple of (thread_id, run_id). Returns (None, None) on failure.
    """
    thread = client.agents.threads.create()
    client.agents.messages.create(
        thread_id=thread.id,
        role="user",
        content=user_message,
    )
    run = client.agents.runs.create_and_process(thread_id=thread.id, agent_id=agent_id)
    if getattr(run, "status", None) == "failed":
        st.error(f"Run failed: {getattr(run, 'last_error', None)}")
        return None, None
    return thread.id, getattr(run, "id", None)

def send_user_message(client: AIProjectClient, agent_id: str, user_message: str) -> Tuple[Optional[str], Optional[str]]:
    """Post a user message to an existing thread (or create one) and start a run.

    This function stores thread and run identifiers in Streamlit ``session_state``
    so that the conversation persists across reruns.

    Args:
        client: An initialized Azure AIProjectClient.
        agent_id: The agent identifier to run.
        user_message: The user's message to post.

    Returns:
        A tuple (thread_id, run_id). Either may be None on failure.
    """
    # create thread once per session
    if 'thread_id' not in st.session_state:
        thread = client.agents.threads.create()
        st.session_state['thread_id'] = thread.id

    # post user message to that thread
    client.agents.messages.create(
        thread_id=st.session_state['thread_id'],
        role="user",
        content=user_message,
    )

    # create and process a run for that message
    run = client.agents.runs.create_and_process(
        thread_id=st.session_state['thread_id'],
        agent_id=agent_id,
    )
    st.session_state['run_id'] = getattr(run, "id", None)
    return st.session_state.get('thread_id'), getattr(run, "id", None)

def get_responses(client: AIProjectClient, thread_id: str, run_id: str) -> List[str]:
    """Fetch assistant responses for a given thread/run.

    Args:
        client: An initialized Azure AIProjectClient.
        thread_id: The thread identifier.
        run_id: The run identifier to filter messages by.

    Returns:
        A list of response strings (may be empty).
    """
    messages = client.agents.messages.list(thread_id=thread_id, order=ListSortOrder.ASCENDING)
    responses: List[str] = []
    for message in messages:
        if getattr(message, "run_id", None) == run_id and getattr(message, "text_messages", None):
            # append the final text value for the message if present
            text_obj = message.text_messages[-1].text
            value = getattr(text_obj, "value", None)
            if value:
                responses.append(value)
    return responses

def safe_rerun() -> None:
    """Attempt to rerun the Streamlit app, with a safe fallback.

    Uses ``st.experimental_rerun()`` when available; otherwise calls
    ``st.stop()`` which ends the current run and allows Streamlit to render a
    fresh UI on the next interaction.
    """
    try:
        # prefer the API if available
        if hasattr(st, "experimental_rerun"):
            st.experimental_rerun()
        else:
            # immediate safe fallback
            st.stop()
    except Exception:
        # last-resort fallback
        st.stop()
```

</details>

* * *

#### Main app code

<details markdown=1>
<summary>📱 App code - click to expand code ⏬</summary>
```python
# app.y
def main() -> None:
    st.set_page_config(
        page_title="Dinner Generator",
        page_icon ="🍲"
    )

    apply_style_background()
    apply_style_blur()

    with st.sidebar:
        st.write("## Controls")
        st.write("Manage your session.")
        if st.button("Reset conversation", key="reset"):
            # remove only conversation-related keys (keep session alive)
            for k in ("thread_id", "run_id", "chat_history"):
                st.session_state.pop(k, None)
            # Ensure chat_history exists so the UI renders immediately
            st.session_state.setdefault("chat_history", [])
            # Prefer immediate rerun if available in Streamlit; otherwise continue the run so UI renders
            if hasattr(st, "experimental_rerun"):
                st.experimental_rerun()

    
    st.title("AI Dinner Planning Agent")

    agent_id = os.getenv("dingen_agent_id")

    if not agent_id:
        st.error("Missing environment variable: dingen_agent_id")
        return

    try:
        client = AIProjectClient(
            endpoint=os.getenv("dingen_azure_endpoint"),
            credential=DefaultAzureCredential(),
        )
    except Exception as e:
        st.error(f"Failed to create Azure client: {e}")
        return
    
    if 'chat_history' not in st.session_state:
        st.session_state['chat_history'] = []

    user_input = st.chat_input("Hi! Let's plan your dinners 😀. Enter your requests here ...")

    
    if user_input:
        # Display user message in chat
        st.session_state['chat_history'].append(('user', user_input))
        # Send user message to agent and get a response
        thread_id, run_id = send_user_message(client, agent_id, user_input)
        if thread_id and run_id:
            responses = get_responses(client, thread_id, run_id)
            for response in responses:
                # Append response to chat history
                st.session_state['chat_history'].append(('assistant', response))
            # Display chat history
            for role, message in st.session_state['chat_history']:
                if role == 'user':
                    st.chat_message("user").markdown(message)
                else:
                    st.chat_message("assistant").markdown(message)
                    
            
if __name__ == "__main__":
    main()
```

</details>
  
#### Final result
![Azure AI Foundry Portal]({{ site.baseurl }}/assets/images/2025-10-15-ai-agents-azure/app_final_result.png)
_Figure: Final result of the prototype application._

# Evaluation of Azure's documentation, state of maturity and further steps







