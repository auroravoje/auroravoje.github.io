---
layout: default
title:  "How to build a home for an AI agent"
date:   2025-10-15 14:29:17 +0200
categories: AI agents Azure Streamlit
author: Aurora Voje, PhD
---

![Build home for AI agent]({{ site.baseurl }}/assets/images/2025-10-15-ai-agents-and-streamlit/intro_build_home_agent.png)
_Figure: AI generated illustration of article's title._

---
**[{{ site.title }}]({{ site.url }})** | By {{ page.author | default: "Aurora Voje" }} | {{ page.date | date: "%B %d, %Y" }}

---

* TOC
{:toc}

# Introduction

The tech community seems to be hyping about AI agents at the moment. All the biggest tech giants offer tools on the subject. In order to make up my own opinion on the topic, I decided to not just talk the talk, but also walk the walk and conduct hands-on agentic AI development. 

[In my previous post]({% post_url 2025-10-15-ai-agents-azure %}) I answered key questions like
- What is an AI agent?
- What is Azure AI Foundry?
- How to build an AI agent in the Azure AI Foundry portal?

If you're new to the subject, check out the post to read up on this background information. I also introduced arguments for why I started with Microsoft, and need to stress again that similar agentic frameworks are provided by [Google Cloud](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/agent-builder/overview), [AWS](https://aws.amazon.com/bedrock/agents/), and other providers, and it's surely beneficial to check those out as well. Hence this article is not an advertisement for any specific provider. 



In this post I move forward and "build a house" for the AI agent, in terms of an app interface, separate from Azure AI Foundry Playground. There are so many wonderful front-end frameworks to choose from. As this is a data science/AI post for Python, Streamlit is an excellent application framework to start with to quickly get up and running a prototype app.



**In upcoming posts** I will further show how to:
- Post: [Build an agent system in Python with Azure SDK and Streamlit app]({% post_url 2025-10-27-ai-agents-azure-python-sdk %}). Here I will also touch upon "A2A" - i.e., connecting several agents 
- Post: [Agent application deployment with Azure Web Apps]({% post_url 2025-10-27-ai-agents-azure-web-app %}) is a tutorial on how to deploy the app I'm building so other users can reach it.

* * *

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
|2025 | 1            | 2      | Sweet potato soup with fresh bread  |

By the agentic definitions discussed in [my previous post]({% post_url 2025-10-15-ai-agents-azure %}), we then have the following setup:

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

## Development stages
- No Code: Create agent in AI Foundry Portal and test it in playground (previous post)
- **AI Foundry Portal and Code: Build a home for the agent in a Streamlit app (this post)**
- Only Code: Build an agent system in Python with Azure SDK and Streamlit app (upcoming post)
- Deployment: Agent application deployment with Azure Web Apps (upcoming post)


* * *

# Housing the AI-agent in a streamlit app 
In the previous post I created the dinner planning agent in Azure AI Foundry Portal. Now that the agent is tested and working well in the portal playground, I will build an application environment in order to interact with the agent. In a real setting a customer would not be able to log into developer's Azure AI Foundry portal. The scope of the current post is a setup with Streamlit on `localhost`.

  
## Combining Streamlit and Azure Python SDK chat functionality

If you have never tried Streamlit apps before, I highly recommend to go through their introductory and chat-app tutorials as a prerequisite for the upcoming code:

- [Create a Streamlit app](https://docs.streamlit.io/get-started/tutorials/create-an-app)  
- [Build a basic LLM chat app with Streamlit](https://docs.streamlit.io/develop/tutorials/chat-and-llm-apps/build-conversational-apps)

I also recommend to have a look at the Azure AI Foundry documentation on how to interact
with an AI agent in Python. Read through the sections below when the Python tab is chosen:

- [Quickstart: Get started with Azure AI Foundry (Foundry projects)](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstarts/get-started-code?tabs=python) with focus on
    - Set up your environment
    - Run a chat completion
    - Chat with an agent

**NB!** The Azure Python SDK code documentation shows how to create an AI agent on the fly. In this post I will show you how to connect to an already existing agent. In the next post I will implement agent creation on app session start, and agent deletion on app session end (or user defined deletion).

## Application Code

You can find the entire codebase in this [link to Gitthub repo](https://github.com/auroravoje/ai-agent/tree/sme-version).

I assume you know how to set up python environments. If not, check out these links. The choice depends on your purpose and preferences.

- [Creation of virtual environments with venv](https://docs.python.org/3/library/venv.html)
- [Managing Multiple Python Versions With pyenv](https://realpython.com/intro-to-pyenv/)
- [Poetry](https://python-poetry.org/)
- [uv](https://pydevtools.com/handbook/reference/uv/)


### Package installation and import

<details markdown=1>
<summary>📦 Package imports and setup - click to expand code ⏬ </summary>

In your preferred python environment setup install the packages from `requirements.txt`.

`pip install -r requirements.txt`

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

if is_local():
    load_dotenv()
```

The `os` package allows us to interact with the operating system. Here it will be used to retreive environment variables from an `.env` file.

The `typing` package is due to inclusion of type hints. This is for code clarity and self-documentation. The type hints are seen in function/method documentation and give information about variable types.

The `dotenv` package is for checking whether the code runs locally or remote, and then retrieve environment variables from an `.env` file, or if the code is deployed, retrieve environment variables from secrets stored in Azure Vault. To learn how this works, please see my upcoming post on deploying the AI agent applications with Azure Web Apps.

The `streamlit` package is the front-end application framework we will use in this prototype.

The `azure` package is the Azure Python SDK.


You also see an import of `streamlit_styles`. This is a custom styling file. Design and styling is not the scope of this article, but is indeed included to make the app appealing. You can view the content in the repo.

Last but not least, the `from utils import *` imports all functions present in the `utils.py` file. More on that below.

</details>

* * *

### Main app code

<details markdown=1>
<summary>📱 App code - click to expand code ⏬</summary>

```python
# app.py
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
            # Prefer immediate rerun if available in Streamlit; 
            # otherwise continue the run so UI renders
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
A step by step explanation to app process flow:

- Set title and browser tab favicon emoji.
- Apply styling and prettify the looks. 
- Create a sidebar with a `reset conversation` button: 
    - Delete conversation related keys which are generated in an app session state.
    - Set chat history to empty, as we are creating a new conversation.
    - Ensure immediate app re-run.

- Main app panel:
    - Set main title.
    - Get agent id from the `.env` file.
    - If no id provided, send error warning.
    - Try/except: create a project client by implementing code from Azure Python SDK documentation linked above.
    - As the app renders multiple times during an app session, the check for `chat_history` runs multiple times. For the very first rendering the list does not exist, so we allocate the empty `chat_history` list. Streamlit app re-runs and checks `st.session_state` in the following cases:
        - Initial page load - First time user visits the app
        - Every user interaction - Button clicks, text input, slider changes, etc.
        - Widget state changes - When any widget value changes
        - Manual reruns - When you call st.rerun() or st.experimental_rerun()
        - File changes (development only) - When you save the .py file (if running locally)
    - Add streamlit widget `st.chat_input()`, a user input panel for chatting.
    - The comments in the if statements and for loops should be self explanatory.

</details>


* * *

### Utility functions
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
```

As mentioned in the package imports and setup section, the function above serves for environment detection, local or remote.

```python
#utils.py
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
    return st.session_state.get('thread_id'), st.session_state.get('run_id')
```

This function implements the Azure Python SDK methods described in the [documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstarts/get-started-code?tabs=python) to connect to the given agent,
create a new thread and run and returns the `thread_id` and `run_id` back to the main app function. 



```python
#utils.py
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
```

Explanatory text

```python
#utils.py
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
This function ensures a safe re-run of the application when the user clicks the 
`Reset conversation` button in the left sidebar panel.


</details>

* * *

### Environment variables

<details markdown=1>
<summary>🔡 Environment variables - click to expand code ⏬</summary>


In order to connect to the correct Azure AI Foundry project and to the correct agent within the project, we need two evironment variables:

* Azure AI Foundry project endpoint: called `dingen_azure_endpoint` in my code.
* Azure AI Foundry Agent id: called `dingen_agent_id` in my code.

The `dingen` is abbreviation for dinner generator.


In the Azure AI Foundry portal you find the endpoint and id values here:
**consider adding carousel**

<link rel="stylesheet" href="https://unpkg.com/flickity@2/dist/flickity.min.css">
<script src="https://unpkg.com/flickity@2/dist/flickity.pkgd.min.js"></script>

<div class="main-carousel" data-flickity='{ "cellAlign": "left", "contain": true, "wrapAround": true }'>
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-and-streamlit/az_project_endpoint.png" alt="Step 1">
    <p>1. Where to find the project endpoint.</p>
  </div>
  
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-15-ai-agents-and-streamlit/az_agent_id.png" alt="Step 2">
    <p>2. Where to find the agent id.</p>
  </div>
</div>


Copy and paste them into your `.env` file in root directory.


```python
#.env
dingen_azure_endpoint = paste value here
dingen_agent_id = paste value here
```

</details>

* * *

  
### Final result

Start the application by running the following line in terminal: 

`streamlit run app.py`. 

The app should by default pop up in your active browser on `localhost:8501`.

![Azure AI Foundry Portal]({{ site.baseurl }}/assets/images/2025-10-15-ai-agents-and-streamlit/app_final_result.png)
_Figure: Final result of the prototype application with initial agent interaction._

# First impression of Azure Python SDK state of maturity and further steps

- Easy to get started
- Decent code documentation for Python
- A lot of available information and opprotunities
- Code runs work as intended. At this stage did not experience bugs and glitches

What could be better:

- Nothing to mention at this stage.

---

*Transparency note: This article is human-written with AI assistance for proofreading and typo correction. Main image generated with AI.*

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
  transform: scale(1.20);
}
</style>



