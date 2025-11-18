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

The tech community is hyping about AI agents at the moment. All the biggest tech giants offer tools on the subject. In order to make up my own opinion on the topic, I decided to not just talk the talk, but also walk the walk and conduct hands-on agentic AI development. 

[In my previous post]({% post_url 2025-10-15-ai-agents-azure %}) I answered key questions like
- What is an AI agent?
- What is Azure AI Foundry?
- How to build an AI agent in the Azure AI Foundry portal?

If you're new to the subject, check out the post to read up on this background information. I also introduced arguments for why I started with Microsoft, and need to stress again that similar agentic frameworks are provided by [Google Cloud](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/agent-builder/overview), [AWS](https://aws.amazon.com/bedrock/agents/), and other providers, and it's surely beneficial to check those out as well. Hence, this article is not an advertisement for any specific provider. This is just what was easily available to me, and I plan on looking into more providers myself. Possibly a comparison post will appear in the future.  

In this post I move forward and "build a house" for the AI agent, in terms of an app interface, separate from the Azure AI Foundry Playground. There are so many wonderful front-end frameworks to choose from. As this is a AI/data science post for Python, Streamlit is an excellent application framework to start with, in order to quickly get up and running with a prototype app.

**In upcoming posts** I will further show how to:
- Post: [Build an agent system in Python with Azure SDK and Streamlit app]({% post_url 2025-10-27-ai-agents-azure-python-sdk %}). Here I will build an AI agent with code and also touch upon "A2A" - that is, connecting several agents. 
- Post: [Agent application deployment with Azure Web Apps]({% post_url 2025-10-27-ai-agents-azure-web-app %}) is a tutorial on how to deploy the app I'm building so other users can reach it.

* * *

# Use Case Definition

A recap from previous post on the use case definition.

> I will solve the following use case:
>
> The current family need is a dinner planning agent that can help with the weekly challenges of composing a healthy, tasty meal plan while taking into consideration specific preferences, seasonality, and avoiding suggesting recent meals. Once the planning is done, the plan and a shopping list based on the plan should be sent to the user in a nicely rendered email.

The data is in a spreadsheet format where the customer can add entries. The recipe sheet has the following table:

| Recipe       | Time, minutes | Link  | Season | Preference |
|:-------------|:-------------|:------|:-------|:-----------|
| Lasagna      | 120          | www   | all    | weekend    |
| ⋮             |⋮             |⋮      |⋮      |⋮           |
| Risotto      | 45           | www   | all    | weekend    |


The history sheet has the following table: 

|Year | Week         | Day    |Recipe |
|:----|:-------------|:-------|:------|
|2025 | 1            | 1      | Salmon with roasted vegetables  |
| ⋮    | ⋮            | ⋮       | ⋮                                 |
|2025 | 40           | 7      | Sweet potato soup with fresh bread  |

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

This is, of course, a simple use case, but I hope you can contemplate analogies to real solutions and real business use case challenges. 

# Development stages

A recap from previous post on the development stages. As I would do in a real product development setting, I divide the development into 4 chronological stages and hence also into 4 articles of this series:

- No Code: Create agent in AI Foundry Portal and test it in playground ([previous post]({% post_url 2025-10-15-ai-agents-azure %}))
- **AI Foundry Portal and Code: Build a home for the agent in a Streamlit app (this post)**
- Only Code: Build an agent system in Python with Azure SDK and Streamlit app ([upcoming post]({% post_url 2025-10-27-ai-agents-azure-python-sdk %}))
- Deployment: Agent application deployment with Azure Web Apps ([upcoming post]({% post_url 2025-10-27-ai-agents-azure-web-app %}))


* * *

# Housing the AI agent in a Streamlit app 

In the previous post, we created the dinner planning agent in Azure AI Foundry Portal. Now that the agent is tested and working well in the portal playground, I will build an application environment in order to interact with the agent. In a real setting, a customer would not be able to log into the developer's Azure AI Foundry portal. The scope of the current post is a setup with Streamlit on `localhost`.

  
## Combining Streamlit and Azure Python SDK chat functionality

If you have never tried Streamlit apps before, I highly recommend going through their introductory and chat-app tutorials as a prerequisite for the upcoming code:

- [Create a Streamlit app](https://docs.streamlit.io/get-started/tutorials/create-an-app)  
- [Build a basic LLM chat app with Streamlit](https://docs.streamlit.io/develop/tutorials/chat-and-llm-apps/build-conversational-apps)

I also recommend having a look at the Azure AI Foundry documentation on how to interact
with an AI agent in Python. Read through the sections below when the Python tab is chosen:

- [Quickstart: Get started with Azure AI Foundry (Foundry projects)](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstarts/get-started-code?tabs=python) with focus on
    - Set up your environment
    - Run a chat completion
    - Chat with an agent

**NB!** The Azure Python SDK code documentation shows how to create an AI agent on the fly. In this post I will show you how to connect to an already existing agent. In the next post I will implement agent creation on app session start, and agent deletion on app session end (or user defined deletion).

## Application Code

You can find the entire codebase on Github. Follow this [link to my Github repo with specific branch](https://github.com/auroravoje/ai-agent/tree/sme-version) to see the code version discussed in this article. You will need to clone the repo in order to make the code run. You will also need to add a `.env` file to your local setup. For details check out the [Environment variables](#environment-variables) section.

I assume you know how to set up Python environments. If not, check out these links. The choice depends on your purpose and preferences.

- [uv](https://pydevtools.com/handbook/reference/uv/)
- [Poetry](https://python-poetry.org/)
- [Managing Multiple Python Versions With pyenv](https://realpython.com/intro-to-pyenv/)
- [Creation of virtual environments with venv](https://docs.python.org/3/library/venv.html)

Below I will walk you step by step through the code and explain the details.

### Package installation and import

In your preferred python environment setup install the packages from `requirements.txt`.

`pip install -r requirements.txt`

The `app.py` file is the main file where the application code is rendered. We start with package imports.

{% highlight python linenos %}
#app.py - package imports
import os

import streamlit as st
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

import utils
from streamlit_styles import apply_style_background, apply_style_blur
{% endhighlight %}

The `os` package allows us to interact with the operating system. Here it will be used to retrieve environment variables from an `.env` file.

The `typing` package is due to inclusion of type hints. This is for code clarity and self-documentation. The type hints are seen in function/method documentation and give information about variable types.

The `dotenv` package is for checking whether the code runs locally or remote, and then retrieving environment variables from an `.env` file, or if the code is deployed, retrieving environment variables from secrets stored in Azure Vault, or in general other secret storage options. To learn how this works in Azure, please see my upcoming post on deploying the AI agent applications with Azure Web Apps.

The `streamlit` package is the front-end application framework we will use in this prototype.

The `azure` package is the Azure Python SDK.


You also see an import of `streamlit_styles`. This is a custom styling file. Design and styling is not the scope of this article, but is indeed included to make the app visually appealing. You can view the content in the repo.

Last but not least, the `import utils` imports the `utils` module. More on that below.

* * *

### Main app code

{% highlight python linenos %}
# app.py ...
if utils.is_local():
    load_dotenv()

def main() -> None:
    st.set_page_config(page_title="Dinner Generator", page_icon="🍲")

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

    if "chat_history" not in st.session_state:
        st.session_state["chat_history"] = []

    user_input = st.chat_input(
        "Hi! Let's plan your dinners 😀. Enter your requests here ..."
    )

    if user_input:
        # Display user message in chat
        st.session_state["chat_history"].append(("user", user_input))
        # Send user message to agent and get a response
        thread_id, run_id = utils.send_user_message(client, agent_id, user_input)
        if thread_id and run_id:
            responses = utils.get_responses(client, thread_id, run_id)
            for response in responses:
                # Append response to chat history
                st.session_state["chat_history"].append(("assistant", response))
            # Display chat history
            for role, message in st.session_state["chat_history"]:
                if role == "user":
                    st.chat_message("user").markdown(message)
                else:
                    st.chat_message("assistant").markdown(message)


if __name__ == "__main__":
    main()
{% endhighlight %}

A step by step explanation to app process flow:
- Line 2: Check if the code runs locally or remote by calling the `is_local()` function from `utils.py`. If local, load environment variables from the `.env` file.
- Line 6: Set title and browser tab favicon emoji.
- Line 8: Apply styling and prettify the looks. The files can be found in the repo linked above. 
- Line 11: Create a sidebar with a `reset conversation` button: Sometimes the user wants to start a new conversation with the agent. This can be due to various reasons. For example, the user wants to change the topic, or the agent has gone off track. The button allows the user to reset the conversation while keeping the app session alive. The following actions are taken when the button is clicked: 
    - Line 16: Delete conversation related keys which are generated in an app session state.
    - Line 19: Set chat history to empty, as we are creating a new conversation.
    - Line 21: Ensure immediate app re-run.

- Main app panel:
    - Line 24: Set main title.
    - Line 26: Get agent id from the `.env` file.
    - Line 28: If no id provided, send error warning.
    - Line 32: Try/except: create a project client by implementing code from Azure Python SDK documentation linked above.
    - Line 41: As the app renders multiple times during an app session, the check for `chat_history` runs multiple times. For the very first rendering the list does not exist, so we allocate the empty `chat_history` list. Streamlit app re-runs and checks `st.session_state` in the following cases:
        - Initial page load - First time user visits the app
        - Every user interaction - Button clicks, text input, slider changes, etc.
        - Widget state changes - When any widget value changes
        - Manual reruns - When you call st.rerun() or st.experimental_rerun()
        - File changes (development only) - When you save the .py file (if running locally)
    - Line 44: Add streamlit widget `st.chat_input()`, a user input panel for chatting.
    - Line 48: See the comments for detailed explanation of the combination of if-tests, for loops and if-else tests. 

* * *

### Utility functions

The `utils.py` file contains utility functions that are used in the main app code. Below I will explain each function in detail.
{% highlight python linenos %}
#utils.py - package imports
import os

import streamlit as st
from azure.ai.agents.models import ListSortOrder
from azure.ai.projects import AIProjectClient
{% endhighlight %}

The package imports are similar to those in the main app code, with the addition of `ListSortOrder` from `azure.ai.agents.models`, which is used to sort messages when retrieving them from the agent.

{% highlight python linenos %}
#utils.py 
def is_local() -> bool:
    """Return True when running in a local/dev environment."""
    is_deployed = os.environ.get("DEPLOYED") == "1" or not os.path.exists(".env")
    return not is_deployed
{% endhighlight %}

As mentioned in the package imports and setup section, the `is_local()` function serves for environment detection, local or remote.

{% highlight python linenos %}
#utils.py
def send_user_message(
    client: AIProjectClient, agent_id: str, user_message: str
) -> tuple[str | None, str | None]:
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
    if "thread_id" not in st.session_state:
        thread = client.agents.threads.create()
        st.session_state["thread_id"] = thread.id

    # post user message to that thread
    client.agents.messages.create(
        thread_id=st.session_state["thread_id"],
        role="user",
        content=user_message,
    )

    # create and process a run for that message
    run = client.agents.runs.create_and_process(
        thread_id=st.session_state["thread_id"],
        agent_id=agent_id,
    )
    st.session_state["run_id"] = getattr(run, "id", None)
    return st.session_state.get("thread_id"), st.session_state.get("run_id")
{% endhighlight %}

The `send_user_message()` function implements the Azure Python SDK methods described in the [Azure documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstarts/get-started-code?tabs=python) to connect to the given agent,
create a new thread and run, and returns the `thread_id` and `run_id` back to the main app function. 



{% highlight python linenos %}
#utils.py
def get_responses(client: AIProjectClient, thread_id: str, run_id: str) -> list[str]:
    """Fetch assistant responses for a given thread/run.

    Args:
        client: An initialized Azure AIProjectClient.
        thread_id: The thread identifier.
        run_id: The run identifier to filter messages by.

    Returns:
        A list of response strings (may be empty).
    """
    messages = client.agents.messages.list(
        thread_id=thread_id, order=ListSortOrder.ASCENDING
    )
    responses: list[str] = []
    for message in messages:
        if getattr(message, "run_id", None) == run_id and getattr(
            message, "text_messages", None
        ):
            # append the final text value for the message if present
            text_obj = message.text_messages[-1].text
            value = getattr(text_obj, "value", None)
            if value:
                responses.append(value)
    return responses
{% endhighlight %}

The `get_responses()` function creates a list of messages in the current `run_id` and `thread_id`, appends the message if there is one, and returns the list of agent responses.


{% highlight python linenos %}
#utils.py
def safe_rerun() -> None:
    """Attempt to rerun the Streamlit app, with a safe fallback."""
    try:
        st.experimental_rerun()
    except Exception:
        st.stop()
{% endhighlight %}

The `safe_rerun()` function ensures a safe re-run of the application when the user clicks the 
`Reset conversation` button in the left sidebar panel.

* * *

### Environment variables

In order to connect to the correct Azure AI Foundry project and to the correct agent within the project, we need two environment variables:

* Azure AI Foundry project endpoint: in my code called `dingen_azure_endpoint`.
* Azure AI Foundry Agent id: in my code called `dingen_agent_id`.

The `dingen` is an abbreviation for dinner generator. A brief comment on lower case for environment variables: usually they are set in upper case, but as you will see in the upcoming article on app deployment, I use Azure Vault to store the secrets, and it is easier to keep the naming consistent across local and remote setups.

In the Azure AI Foundry portal, you find the endpoint and id values here:
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


Create an `.env` file in the project's root directory, and copy and paste the values from the portal into the file, so the `is_local()` function finds the environment variables on app run.


{% highlight python linenos %}
#.env
dingen_azure_endpoint = paste value here
dingen_agent_id = paste value here
{% endhighlight %}
* * *

  
### Final result

Start the application by running the following line in terminal: 

`streamlit run app.py`. 

The app should by default pop up in your active browser on `localhost:8501`.

![Azure AI Foundry Portal]({{ site.baseurl }}/assets/images/2025-10-15-ai-agents-and-streamlit/app_final_result.png)
_Figure: Final result of the prototype application with initial agent interaction._

# First impression of Azure Python SDK state of maturity and further steps
Here I will share my first impression of the Azure Python SDK for AI Foundry, based on my hands-on experience described above.

**What worked well:**

- Easy to get started.
- Decent code documentation for Python.
- A lot of available information and opportunities for versatile agent capabilities.
- The code runs as intended. At this stage I did not experience bugs or glitches.

**Difficulties I ran into:**

- Nothing to mention at this stage, but I will update this section in upcoming posts as I dive deeper into the SDK capabilities.

I hope you were able to run your own app locally and upskilled your agentic abilities with me.
See you in the next one 🩵!  

---

*Transparency note: This article is human-written with AI assistance for proofreading and typo correction. Main image generated with AI.*


---
**[🔝 Back to top 🔝](#top)**

{% include giscus.html %}


<style>
.main-carousel {
  margin: 20px 0;
}

.carousel-cell {
  width: 80%;
  margin-right: 15px;
  text-align: center;
  counter-increment: carousel-cell;
}

.carousel-cell img {
  display: block;
  width: 100%;
  max-width: 600px;
  height: auto;
  min-height: 300px;
  object-fit: contain;
  border-radius: 8px;
  cursor: zoom-in;
  transition: transform 0.2s ease;
  margin: 0 auto;
}

.carousel-cell img:hover {
  transform: scale(1.5);
}

.carousel-cell p {
  margin-top: 10px;
  font-style: italic;
  color: #666;
}

/* Fix for GitHub Pages theme conflicts */
.main-carousel .flickity-viewport {
  height: auto !important;
  min-height: 500px;
}

.main-carousel .flickity-slider {
  height: auto !important;
}
</style>


