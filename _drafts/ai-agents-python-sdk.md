---
layout: default
title:  "AI agents with Azure Python SDK"
date:   2025-10-27 09:00:00 +0200
categories: AI agents Azure Python
author: Aurora Voje, PhD
draft: true
---
{% include carousel.html %}

![Build home for AI agent]({{ site.baseurl }}/assets/images/2025-10-27-ai-agents-python-sdk/intro_ai_agent_az_py_sdk.png)
_Figure: AI generated illustration of article's title._

---
**[{{ site.title }}]({{ site.url }})** | By {{ page.author | default: "Aurora Voje" }} | {{ page.date | date: "%B %d, %Y" }}

---

* TOC
{:toc}


# Introduction

Welcome to the deep end of agentic development! If you've been following along with this series, you've seen how to build AI agents in the Microsoft Foundry Portal and wrap them in a Streamlit interface. Now it's time to roll up our sleeves and go full SDK—defining agents, tools, and multi-agent connections entirely in Python code.

This is the third article in my series on building production-ready AI agents, and fair warning: it's code-heavy. If you're looking for a gentle introduction to agentic concepts, I recommend starting with my [earlier posts]({% post_url 2025-10-15-ai-agents-azure %}). But if you're ready to see how agent orchestration works under the hood with the Azure Python SDK—including the tricky bits like Agent-to-Agent (A2A) communication and dynamic data ingestion—you're in the right place.

**What I'll cover:**
- Building AI agents programmatically with the Azure SDK
- Creating and managing vector stores for RAG
- Connecting multiple specialized agents via A2A communication
- Integrating dynamic data sources (spoiler: Google Sheets to the rescue)
- Managing agent lifecycle and resource cleanup

**Series roadmap:**
1. ✅ [No Code: Build agents in Microsoft Foundry Portal]({% post_url 2025-10-15-ai-agents-azure %})
2. ✅ [Portal + Code: House your agent in Streamlit]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %})
3. 📍 **Code: Build the full agent system with SDK** (you are here)
4. 🔜 [Deployment: Ship your agent app to Azure Web Apps]({% post_url 2025-10-27-ai-agents-azure-web-app %})

By the end of this post, you'll have a complete understanding of how to architect, code, and manage multi-agent systems using Azure's Python SDK. Let's bring that agentic hype down to earth.

Ready? Let's code. 🚀

* * *

# Use case definition

Let's do a brief recap from previous posts on the use case definition. 
> I will solve the following use case:
>
> The current family need is a dinner planning agent that can help with the weekly challenges of composing a healthy, tasty meal plan while taking into consideration specific preferences, seasonality, and avoiding suggesting recent meals. Once the planning is done, the plan and a shopping list based on the plan should be sent to the user in a nicely rendered email.

The data is in a spreadsheet format where the customer can add entries. The spreadsheet contains two tabs: recipe data and dinner history. Please refer to this section of my [previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#use-case-definition) for a detailed view of the data details. 

By the agentic definitions, discussed in this section of my [previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#use-case-definition), we then have the following setup:


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

* * *

# All the way with SDK

I have a confession to make right away. My original plan "All the way with SDK" did not work. It is more "Almost all the way with SDK". I did not manage to make the email tool work as intended with the SDK, so I had to fall back to creating an email agent in the Foundry Portal, and connect it to the SDK-created dinner planning agent. Here are the links to [Microsoft Foundry logic apps with python documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/tools-classic/logic-apps?view=foundry-classic&pivots=python) and [SDK code examples on GitHub](https://github.com/azure-ai-foundry/foundry-samples/blob/main/samples-classic/python/getting-started-agents/logic_apps/user_logic_apps.py), that I tested. If you have managed to make it work and feel like sharing your hack, feel free to reach out to me in the discussion section at the bottom of the post.

However, all other parts of the agent system are created with the Azure Python SDK, and I will show you how to do it. On the bonus side, I got to test the Agent-to-Agent (A2A) communication functionality of the SDK, which is a very important feature, and seems to work well. 

Currently, in agentic development, it is advised to create smaller specialized connected agents rather than one large all-in-one super agent. This is due to several key advantages:

- **Context efficiency:** Smaller agents require less context, working better within LLM token limitations
- **Better tool selection:** Fewer tools per agent means faster, more accurate decision-making by the LLM
- **Maintainability:** Each agent can be tested and improved independently
- **Scalability:** New capabilities can be added as new agents without modifying existing ones
- **Reusability:** Specialized agents can be reused across different applications and workflows


I will still be housing my agent in a Streamlit application environment, as I did in my [previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#final-result). As this is a follow-up post, I will not repeat all the details on Streamlit app building and chat functionalities. Please refer to [this section in my previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#combining-streamlit-and-azure-python-sdk-chat-functionality), and links therein, for details on Streamlit-related topics. I consider them as prerequisites for this post.

## Application overview

To remind you of what we are building, the figure carousel below shows screenshots of the application frontend. If you have read my [previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#final-result), you will recognize the layout of the main window, which is unchanged. I have added a couple of new practical features to the sidebar and created a new page for recipe viewing.



<div class="main-carousel" data-flickity='{ "cellAlign": "left", "contain": true, "wrapAround": true }'>
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-python-sdk/app_frontend.png" alt="Step 1">
    <p>1. Application landing page, agent chat.</p>
  </div>
  
  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-python-sdk/recipe_viewer_recipes.png" alt="Step 2">
    <p>2.1 Recipe Viewer page, browse recipes .</p>
  </div>

  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-python-sdk/recipe_viewer_dinner_hist.png" alt="Step 3">
    <p>2.2 Recipe Viewer page, browse recent dinner history.</p>
  </div>

  <div class="carousel-cell">
    <img src="{{ site.baseurl }}/assets/images/2025-10-27-ai-agents-python-sdk/delete_resources.png" alt="Step 4">
    <p>3. Delete resources shows messages in the sidebar upon successfull deletion.</p>
  </div>
</div>


- The "Create Dinner Plan" page is the landing page where we can communicate with the agent. The agent is created automatically by starting a new app session.
- The "Recipe Viewer" page is a helper page to browse user's favorite recipe collection and recent dinner history. This is a view of the data that is dynamically extracted from the user's spreadsheets.
- The "Reset conversation" button's functionality is unchanged from the previous post, and allows you to start a new chat session with the originally initiated agent, if it gets stuck.
- The "Delete resources" is a new button. It removes all created resources in the current app session. For now, resource deletion is set as a manual procedure, in order to keep control over resource management via the app. Resource management can also be done in the Foundry Portal, under the Agent section.


## System architecture

Now that we have established a visual understanding of the application frontend, and before we dive into the code, let's view the system architecture in a systematic manner. Since the last post the system has grown due to process automation, so the code had to be even more modularized. The more modules we implement, the more important it is to have a map to understand how the different parts fit together.

The system architecture diagram below illustrates the high-level architecture of the application.
This is a request-driven diagram view, showing how user requests flow down through the application layers to the data sources and Azure services. If you want to check out even more detailed diagrams, please have a look at the `diagrams.md` in [my repository](https://github.com/auroravoje/ai-agent/tree/az-py-sdk-article).


![System architecture diagram]({{ site.baseurl }}/assets/images/2025-10-27-ai-agents-python-sdk/system_architecture.png)
_Figure: Diagram of system architecture._

As visualised by the figure carousel with app screenshots above, and seen in the system architecture figure, the application has three main user interface components:
1. Chat interface for agent interactions.
2. Recipe viewer for browsing recipes and dinner history.
3. Sidebar controls for session management.

**The chat interface** covers message handling and triggers agent initialization with instructions, LLM model and agent tools. One of the tools I used in the portal in my [previous post]({% post_url 2025-10-15-ai-agents-azure %}#add-tools-to-the-agent) is the file search tool, to which I manually uploaded `.txt` files containing recipe data and dinner history. In the current SDK-based application version, I have replaced the manual file upload with a `FileSearchTool` object, which ingests data via an integration with the Google Sheets API. This way the agent gets data directly from the user's Google spreadsheets. If the data changes, the agent will always have access to the latest data without manual file uploads. More on why and how, regarding Google Sheets integration, can be found in the section [Sheet utility functions](#sheet-utility-functions) below. 

The other agent tool I implemented in the portal earlier, is the email tool. As mentioned, I did not manage to get the SDK implementation to work properly. Hence, there is now a persistent email agent in the Foundry portal handling the email-sending functionality. This agent is then connected to the planning agent created via the SDK. More details on A2A communication can be found in the section [Agent utility functions](#agent-utility-functions) below.

**The recipe viewer** data from the Google Sheets API can also be transformed to dataframes and displayed in the recipe viewer page. More details on this can be found in the section [Sheet utility functions](#sheet-utility-functions) below.

**The sidebar controls** govern the agent conversation reset and resource cleanup. This is triggered by the sidebar "Reset conversation" button, or by the "Delete resources" button. The former only deletes the app session state chat history and keeps the agent alive. The latter deletes all Azure-created resources in the current app session. More on this under the section [Cleanup utility functions](#cleanup-utility-functions) below.

**The UI styling** is again not in the scope of this post, but can be found in the `streamlit_styles.py` file in the repository. I have added minor adjustments to accommodate readability in light and dark app modes.

* * *
 
## Application code

Now we should be ready to go through the code file by file. Please confer with the system architecture diagram above to have a visual understanding of how the different parts of the code interplay.

### Package installation and import

In this section I will explain the packages new to the application version. For explanation on reused packages, please refer to this section of my [previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#package-installation-and-import).

{% highlight python linenos %}
#app.py - package imports
import os

import pandas as pd
import streamlit as st
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

import agent_utils
import chat_utils
import cleanup_utils
import data_utils
import utils
from streamlit_styles import apply_style_background, apply_style_blur

{% endhighlight %}

The `pandas` package is used for data manipulation, particularly converting from `.json` format from the Google Sheets API to dataframes, which are further displayed in the "View Recipes" page by the `st.dataframe()` display element. 

The `azure.ai.agents.models` provides models and tools for Microsoft Foundry AI agents. In order to utilize the email tool, the `ConnectedAgentTool` is used to connect two agents together. More on this under the section [Agent utility functions](#agent-utility-functions).

The `sheets_utils` file contains utilities for handling spreadsheet data, and `agent_instructions` includes the primary instructions for the dinner planning agent. In previous posts the instructions were residing inside the Microsoft Foundry Portal Agent configuration.

* * *

### Rendering and control wrapper functions

After package imports, as in previous post, the `utils.is_local()` checks whether the environment is local or remote, and loads environment variables accordingly. Then I define rendering and sidebar control functions. They act as wrappers around code, previously written directly in `app.py`'s `main()` function. This separation improves code organization and makes the upcoming `main()` function easier to read. Could we put the wrapper functions inside a separate file? Sure, in a larger project it would make sense to further modularize them into their own file, but for this demo application I find it acceptable to keep them here for now.

{% highlight python linenos %}
# app.py ...
if utils.is_local():
    load_dotenv()


def render_dinner_plan_page(project_client: AIProjectClient, agent_id: str) -> None:
    """Render the dinner planning chat interface.

    Args:
        project_client: An initialized Azure AIProjectClient.
        agent_id: The ID of the AI agent to use for chat interactions.
    """
    st.title("🤖 AI Dinner Planning Agent 🫜")

    chat_utils.initialize_chat_history()

    user_input = st.chat_input(
        "Hi! Let's plan your dinners 😀. Enter your requests here ..."
    )

    if user_input:
        chat_utils.handle_user_input(user_input, project_client, agent_id)

    chat_utils.display_chat_history()

{% endhighlight %}

The `render_dinner_plan_page()` function sets the main title, initializes chat history, captures user input, processes it, and displays the chat history. 


{% highlight python linenos %}
# app.py ...

def render_recipe_viewer_page(
    recipes_data: pd.DataFrame, dinner_history: pd.DataFrame
) -> None:
    """Render the recipe viewer page.

    Args:
        recipes_data: DataFrame containing recipe information.
        dinner_history: DataFrame containing dinner history.
    """
    st.title("📒 Recipe Viewer")
    st.info("Recipe viewing functionality is under development.")
    st.dataframe(recipes_data)
    st.title("Dinner History")
    st.dataframe(dinner_history)

{% endhighlight %}

The `render_recipe_viewer_page()` function displays the recipe data and dinner history in a tabular format using Streamlit's `st.dataframe()`. 

{% highlight python linenos %}
# app.py ...

def render_sidebar_controls(project_client: AIProjectClient) -> None:
    """Render sidebar control buttons.

    Args:
        project_client: An initialized Azure AIProjectClient.
    """
    with st.sidebar:
        st.write("## Controls")
        st.write("Manage your session.")

        if st.button("🔁 Reset conversation", key="reset"):
            chat_utils.reset_conversation()

        if st.button("❌ Delete resources", key="cleanup"):
            cleanup_utils.cleanup_and_clear_session(project_client)

{% endhighlight %}

The `render_sidebar_controls()` function provides sidebar buttons for resetting the conversation and deleting agent related Azure resources on button click.

* * *

### Main app code 

The `main()` function orchestrates the overall application flow. It sets up the page configuration, applies styles, checks for cleanup status, prepares recipe data, connects to Azure services, initializes the dinner planning agent, retrieves the email agent, handles page selection, and renders the appropriate page based on user choice. Finally, it adds sidebar controls for cleanup.

{% highlight python linenos %}
# app.py ...
def main() -> None:
    """Main application entry point."""
    st.set_page_config(page_title="Dinner Generator", page_icon="🍲")

    apply_style_background()
    apply_style_blur()

    if st.session_state.get("cleanup_done"):
        st.info(
            "Resources deleted. Please refresh the page to restart the application."
        )
        st.stop()

    with st.spinner("Loading recipe data..."):
        recipes_data, dinner_history, combined_df = data_utils.prepare_recipe_data()

    endpoint = os.getenv("dingen_azure_endpoint")
    if not endpoint:
        st.error(
            "Azure endpoint not configured. Please set 'dingen_azure_endpoint' in your environment."
        )
        st.stop()

    project_client = AIProjectClient(
        endpoint=endpoint,
        credential=DefaultAzureCredential(),
    )

    with st.spinner("Initializing AI agent..."):
        agent_id = agent_utils.get_or_create_agent(project_client, combined_df)
        agent = project_client.agents.get_agent(agent_id)

    page = st.sidebar.selectbox("Select a page", ["Create Dinner Plan", "View Recipes"])

    if page == "Create Dinner Plan":
        render_dinner_plan_page(project_client, agent.id)
    else:
        render_recipe_viewer_page(recipes_data, dinner_history)

    render_sidebar_controls(project_client)


if __name__ == "__main__":
    main()

{% endhighlight %}

* * *

### Utility functions

Due to code refactoring the `utils.py` has decreased in size and now has only two functions. Both are described in my previous post [here]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#utility-functions). I decided to keep the `utils.py` file for future utility function additions on general system utilities.

{% highlight python linenos %}
# utils.py
import os

import streamlit as st


def is_local() -> bool:
    """Return True when running in a local/dev environment.

    Returns:
        True if running locally, False if deployed.
    """
    is_deployed = os.environ.get("DEPLOYED") == "1" or not os.path.exists(".env")
    return not is_deployed


def safe_rerun() -> None:
    """Attempt to rerun the Streamlit app, with a safe fallback.

    Tries to use st.rerun(), falls back to stop if that fails.
    """
    try:
        st.rerun()
    except Exception:
        st.stop()


{% endhighlight %}

There is a small change from previous use of `st.experimental_rerun()` to `st.rerun()` in `def safe_rerun()`. 
The `st.rerun()` function is the current recommended way to trigger a rerun in Streamlit, and is available since `streamlit 1.27.0` version. The `experimental_` prefix was removed when it became a stable feature.

* * * 

### Data utility functions
The data utility function contains package imports, constants like the 14-day limit for dinner history, which tabs in the spreadsheet to read data from, and the wrapper function `def prepare_recipe_data()`. It is decorated with `@st.cache_data(ttl=300)` decorator, which caches the prepared data every 5 minutes to avoid rapid repeated fetches during a session. 


{% highlight python linenos %}
# data_utils.py

"""Data preparation utilities for recipe and dinner history."""

import tempfile

import pandas as pd
import streamlit as st

import sheets_utils

# Constants
DINNER_HISTORY_LIMIT = 14
RECIPES_WORKSHEET_INDEX = 0
DINNER_HISTORY_WORKSHEET_INDEX = 2


@st.cache_data(ttl=300)  # Cache for 5 minutes
def prepare_recipe_data() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """Fetch and normalize recipe and dinner history data.

    Returns:
        Tuple of (recipes_data, dinner_history, combined_normalized_df).
    """

    recipes_data = sheets_utils.get_recipe_data(worksheet_index=RECIPES_WORKSHEET_INDEX)
    dinner_history = sheets_utils.get_recipe_data(
        worksheet_index=DINNER_HISTORY_WORKSHEET_INDEX, limit=DINNER_HISTORY_LIMIT
    )

    dinner_history_norm = sheets_utils.normalize_df_for_indexing(
        dinner_history, source="dinner_history"
    )
    recipes_data_norm = sheets_utils.normalize_df_for_indexing(
        recipes_data, source="recipes"
    )

    combined_df = pd.concat(
        [recipes_data_norm, dinner_history_norm], ignore_index=True, sort=False
    )

    return recipes_data, dinner_history, combined_df


{% endhighlight %}

The function fetches data from Google Sheets, normalizes them for vector indexing, and combines them into a single, normalized dataframe. It returns two regular dataframes for recipes and dinner history view, and a combined dataframe for the vector store upload and agent use. I will explain the normalization and combination steps in more detail in the [Sheets utility functions](#sheet-utility-functions) section.


{% highlight python linenos %}
# data_utils.py ...

def df_to_temp_json(df: pd.DataFrame, ndjson: bool = True) -> str:
    """Serialize DataFrame to a temporary JSON file.

    Args:
        df: DataFrame to serialize.
        ndjson: If True, writes newline-delimited JSON (one JSON object per line).
            If False, writes a single JSON array.

    Returns:
        The file path to the temporary JSON file.
    """
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".json")
    if ndjson:
        # orient='records' + lines=True produces NDJSON
        df.to_json(tmp.name, orient="records", lines=True, force_ascii=False)
    else:
        df.to_json(tmp.name, orient="records", force_ascii=False)
    return tmp.name

{% endhighlight %}

The `df_to_temp_json()` is called from the `agent_utils.py` section, but resides in the `data_utils.py` file due to it being a generic data transformation function. This function serializes a pandas DataFrame to a temporary JSON file. It supports two formats: newline-delimited JSON (NDJSON) where each row is a separate JSON object on a new line, and standard JSON array format. The function returns the file path to the created temporary JSON file, which can then be used for uploading to the Azure Foundry vector store. The JSON format is often chosen for agentic data ingestion. More on this in the [Sheet utility functions](#sheet-utility-functions) and the [Agent utility functions](#agent-utility-functions) sections.

* * * 

### Sheet utility functions

Let's talk about dynamic data fetching, processing and enabling AI agent to do Retrieval Augmented Generation (RAG). If you have read my previous post on [How to build a home for an AI agent]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}), you might remember that I mentioned having difficulties connecting to dynamic data sources like Excel spreadsheets using the Microsoft Foundry portal. The same is true for Azure Python SDK. In this post I will show one way of getting around this limitation by fetching data from Google Sheets, reformatting the data, and uploading it to the Foundry agent to give it specific knowledge. 

The base of the app build will still be in Streamlit, the agentic parts will still be with Microsoft Foundry, but the current dynamic data limitations between Microsoft Excel spreadsheets and Microsoft Foundry will be bypassed by using Google Sheets as data source, until it improves. Google exposes Google Sheets as API endpoints. From the API endpoint we can retrieve spreadsheet data in JSON format, which we then can feed to the agent via the `FileSearchTool`. As we trigger the agent creation, the data is further added to an automatically created Microsoft Foundry vector store. 

**Enabling Google Sheets API in Google Cloud** 

To connect to Google Sheets programmatically, you'll need to:

1. Enable the Google Sheets API in your Google Cloud project
2. Create authentication credentials (I use service account)
3. Share your Google Sheet with the service account email

For detailed step-by-step instructions, follow Google's official [Sheets API Python Quickstart guide](https://developers.google.com/sheets/api/quickstart/python), which covers all the necessary setup including enabling the API and creating credentials.

Once configured, we will need these two pieces of information to insert into your `.env` file:
- Google sheet id, `google_sheet_id` in my code
- Service account credentials file in JSON format, `google_app_credentials` in my code. 

**A key point to be aware of:** 
The service account credentials can be provided in two formats: as a file path to a local JSON file, or as raw JSON/base64-encoded JSON string in an environment variable. If you are deploying the app to a cloud environment like Azure Web Apps, you cannot use your `google_app_credentials` JSON file in the format you retrieve it from the Google Cloud Console. You need to convert it to a JSON/base64-encoded file and store it as an environment variable in the app deployment settings. More on this in my upcoming post on [Agent application deployment with Azure Web Apps]({% post_url 2025-10-27-ai-agents-azure-web-app %}). In the current post this is one of the reasons for having two environment variables: `google_app_credentials` retrieved from Google and used for local development, and `google_app_credentials_json` the base64-encoded version, which is used on deployment. This dual approach additionally prevents GitHub Copilot from accidentally locally getting hold of my credentials, which can happen if I insert them as raw JSON into the `.env` file, and ask a question about the `.env` configuration. I set the credential folder file path separately from my repo, and don't grant Copilot access to the credentials folder.

Let's jump into the code.

{% highlight python linenos %}
# sheets_utils.py

import base64
import json
import os
import tempfile

import gspread
import pandas as pd
import streamlit as st
from google.oauth2.service_account import Credentials
{% endhighlight %}

New packages are imported into `sheets_utils.py`:
The `base64` package is used to decode base64-encoded credentials from environment variables into readable JSON.
The `json` package is used to parse JSON credentials from strings and validate credential structure.
The `tempfile` package is used to write JSON credentials to a temporary file, as the Google API needs a file path. It is also used to create temporary JSON files for uploading to Azure Foundry vector store.
The `gspread` package is used for interacting with Google Sheets. 
The `google.oauth2.service_account` module is used to handle Google service account authentication for accessing the Sheets API.


The first function in the file is `def _materialize_service_account_file()`. It is called from `def get_recipe_data()` defined below it, and handles the dual-format JSON credential scenario. The function materializes the JSON file into a temporary file at runtime.

{% highlight python linenos %}
# sheets_utils.py ...
def _materialize_service_account_file() -> str:
    """Return a filesystem path to the Google service account JSON.

    Accepts any of these:
      1. google_app_credentials points to an existing file path.
      2. google_app_credentials holds raw JSON (starts with '{').
      3. google_app_credentials holds base64 of the JSON.
      4. google_app_credentials_json (alt var) with raw or base64 JSON.

    Writes a temp file if needed (cached in st.session_state to avoid duplicates).

    Returns:
        Filesystem path to the service account JSON file.

    Raises:
        ValueError: If service account key is not provided or invalid.
    """
    cache_key = "_svc_acct_path"
    if cache_key in st.session_state:
        return st.session_state[cache_key]

    val_primary = os.getenv("google_app_credentials", "")
    val_alt = os.getenv("google_app_credentials_json", "")

    def try_decode(raw: str) -> str | None:
        raw = raw.strip()
        if not raw:
            return None
        # Raw JSON
        if raw.startswith("{"):
            return raw
        # Possibly base64
        try:
            decoded = base64.b64decode(raw).decode("utf-8")
            if decoded.strip().startswith("{"):
                return decoded
        except Exception:
            pass
        return None

    # 1. Existing file path?
    if val_primary and os.path.isfile(val_primary):
        st.session_state[cache_key] = val_primary
        return val_primary

    # 2/3: Try primary as JSON / base64
    json_text = try_decode(val_primary) or try_decode(val_alt)
    if not json_text:
        raise ValueError(
            "Google service account key not provided. Set google_app_credentials (path or JSON) "
            "or google_app_credentials_json (JSON/base64)."
        )

    # Validate JSON parses
    try:
        parsed = json.loads(json_text)
        if "client_email" not in parsed:
            raise ValueError("Service account JSON missing client_email.")
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid service account JSON: {e}") from e

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".json")
    with open(tmp.name, "w", encoding="utf-8") as f:
        f.write(json_text)
    st.session_state[cache_key] = tmp.name
    return tmp.name

{% endhighlight %}

The function first checks if the `google_app_credentials` environment variable points to an existing file path. If so, it returns that path directly. If not, it attempts to decode the value as either raw JSON or base64-encoded JSON. If successful, it writes the JSON content to a temporary file and returns the path to that file. The function caches the file path in `st.session_state` to avoid creating multiple temporary files during a session.


{% highlight python linenos %}
# sheets_utils.py ...
@st.cache_resource
def get_recipe_data(
    sheet_id: str | None = None,
    worksheet_index: int = 0,
    limit: int | None = None,
) -> pd.DataFrame:
    """Fetch Google Sheets data and return it as a pandas DataFrame.

    This is a helper for Streamlit apps dynamic data fetch. It uses a service account
    JSON key file to authenticate with the Google Sheets API and reads the
    chosen worksheet into a DataFrame. The function is cached with
    ``st.cache_resource`` to avoid repeated auth calls during a session.

    Args:
        sheet_id: Optional Google Sheets ID. If not provided the environment
            variable ``google_sheet_id`` is used.
        worksheet_index: Index of the worksheet/tab to read (0-based).
        limit: If provided, return only the last N rows (useful for dinner history).


    Returns:
        A pandas DataFrame containing the sheet records. If the sheet is
        empty, returns an empty DataFrame.

    Raises:
        FileNotFoundError: If the key file cannot be found.
        ValueError: If required identifiers are missing.
        Exception: Other errors from the Google API will propagate.
    """

    sheet_id = sheet_id or os.getenv("google_sheet_id")

    if not sheet_id:
        raise ValueError("Google sheet id is not provided (google_sheet_id).")

    KEY_FILE = _materialize_service_account_file()

    # Google Sheets scope
    scopes = [
        "https://www.googleapis.com/auth/spreadsheets.readonly",
        "https://www.googleapis.com/auth/drive.readonly",
    ]

    # Authenticate
    if not os.path.exists(KEY_FILE):
        raise FileNotFoundError(
            f"Google service account key file not found: {KEY_FILE}"
        )

    credentials = Credentials.from_service_account_file(KEY_FILE, scopes=scopes)
    client = gspread.authorize(credentials)

    # Open the sheet and select worksheet by index
    spreadsheet = client.open_by_key(sheet_id)
    worksheets = spreadsheet.worksheets()
    if worksheet_index < 0 or worksheet_index >= len(worksheets):
        raise IndexError(
            f"worksheet_index {worksheet_index} out of range (0..{len(worksheets)-1})"
        )

    sheet = worksheets[worksheet_index]
    # Fetch data based on limit
    if limit:
        # Get all values to find actual data rows (excluding empty rows)
        all_values = sheet.get_all_values()

        if len(all_values) <= 1:  # Only header or empty
            data = pd.DataFrame()
        else:
            # Get header
            header = all_values[0]
            # Get last N data rows, exclude header
            total_data_rows = len(all_values) - 1
            if total_data_rows <= limit:
                # If fewer rows than limit, take all
                data_rows = all_values[1:]
            else:
                data_rows = all_values[-(limit):]

            data = pd.DataFrame(data_rows, columns=header)
    else:
        records = sheet.get_all_records()
        data = pd.DataFrame(records)

    return data

{% endhighlight %}

The `get_recipe_data()` function fetches data from a specified Google Sheet and worksheet tab, returning it as a pandas DataFrame. It uses the service account credentials to authenticate with the Google Sheets API. If a `limit` is provided, it retrieves only the last N rows of data, which is useful for fetching recent dinner history. The function is decorated with `@st.cache_resource` to cache the authenticated API client and avoid repeated authentication calls during a session.

{% highlight python linenos %}
# sheets_utils.py ...

def normalize_df_for_indexing(df: pd.DataFrame, source: str) -> pd.DataFrame:
    """Return a DataFrame with a consistent schema for vector indexing.

    The normalized DataFrame contains:
    - doc_id: stable string id
    - content: text to embed (concatenation of sensible text cols)
    - _source: marker for origin (recipes / dinner_history)
    - raw_metadata: dict of the original row values (kept for retrieval/filtering)

    Args:
        df: Input DataFrame to normalize.
        source: Source identifier (e.g., 'recipes' or 'dinner_history').

    Returns:
        Normalized DataFrame with columns: doc_id, content, _source, raw_metadata.
    """
    df = df.copy()
    df["_source"] = source
    # ensure doc_id
    if "id" in df.columns:
        df["doc_id"] = df["id"].astype(str)
    else:
        df["doc_id"] = df.index.astype(str)

    # choose text columns to combine into `content` (common recipe-like candidates)
    candidates = [
        "Recipe",
        "Time, minutes",
        "Link",
        "Season",
        "Preference",
        "week",
        "day",
    ]
    text_cols = [c for c in candidates if c in df.columns]
    if not text_cols:
        # fallback: use all object-like columns
        text_cols = [c for c in df.columns if df[c].dtype == object]

    if not text_cols:
        # last resort: stringify entire row
        df["content"] = df.astype(str).agg(" ".join, axis=1)
    else:
        # Fill NaN, cast everything to str, then join
        df["content"] = (
            df[text_cols]
            .fillna("")
            .apply(lambda row: " ".join(row.astype(str)), axis=1)
        )
    # preserve original metadata as a dict per row (excluding the computed content)
    meta_cols = [c for c in df.columns if c not in ("content",)]
    df["raw_metadata"] = df[meta_cols].apply(lambda r: r.to_dict(), axis=1)

    # return only the consistent set of columns expected by your uploader
    return df[["doc_id", "content", "_source", "raw_metadata"]]

{% endhighlight %}

The `normalize_df_for_indexing()` function standardizes the input DataFrame to a consistent schema suitable for vector indexing, enabling RAG for the AI agent. It creates a `doc_id` for each row, concatenates relevant text columns into a single `content` field, adds a `_source` column to indicate the origin of the data, and compiles the original row values into a `raw_metadata` dictionary. This normalized format ensures compatibility with the vector store uploader. The combined dataframe is further used in the `data_utils.df_to_tmp_json()` where it is reformatted and prepared for vector store upload.

**Recipes table before normalization**

| Recipe       | Time, minutes | Link  | Season | Preference |
|:-------------|:-------------|:------|:-------|:-----------|
| Pasta Carbonara      | 45          | www   | Year-round    | weekday    |
| Grilled Salmon      | 30           | www   | Year-round    | weekday    |

**Dinner History table before normalization**

|Year | Week         | Day    |Recipe |
|:----|:-------------|:-------|:------|
|2025 | 48           | 1      | Pizza  |


**Combined table after normalization:** 

Vector-indexable format enabling further Retrieval Augmented Generation

|doc_id | content                                          | _source         | raw_metadata|
|:------|:-------------------------------------------------|:----------------|:------------|
|1      | Pasta Carbonara Year-round                       | recipes         | {Recipe: "...", ...}|
|2      | Grilled Salmon 30 ...                            | recipes         | {Recipe: "...", ...}|
|3      | 48 1 Pizza                                       | dinner_history  | {week: "48", ...}|


Now the AI agent can perform RAG by searching the vector store:
- Query "Pasta, year-round" → finds row 1 (semantic similarity match)
- Query "what did we eat week 48 day 1" → finds row 3 (context-aware search)

The agent retrieves this information from the vector store and uses it to augment its responses with accurate, up-to-date recipe and dinner history data.


* * * 

### Agent utility functions

The `agent_utils.py` module is where the magic happens—this is where we programmatically create and configure our AI agents using the Azure Python SDK. This section covers the core agent lifecycle: creation, tool configuration, vector store setup, and the integration of Agent-to-Agent (A2A) communication.

{% highlight python linenos %}
# agent_utils.py

"""Agent initialization and management utilities."""

import os

import pandas as pd
import streamlit as st
from azure.ai.agents.models import ConnectedAgentTool, FilePurpose, FileSearchTool
from azure.ai.projects import AIProjectClient

import data_utils  
from agent_instructions import primary_description, primary_instructions
{% endhighlight %}

There are no new package imports with respect to the previous post, but there are a couple of new modules imported from the `azure` package: The `ConnectedAgentTool` is used to connect the above-mentioned portal-created email agent to the planning agent. The `FilePurpose` is used to tell Azure what a specific file upload is used for. In our case, the combined DataFrame in JSON format is for agent retrieval. The `FileSearchTool` is used to create a file search tool for the agent, which allows it to search the vector store for relevant information. Further we import `data_utils` to access the `df_to_temp_json()` function, which serializes the combined DataFrame into a temporary JSON file for uploading to the vector store, and last but not least, we import the `primary_description` and `primary_instructions` from the `agent_instructions.py` file. This file contains the instructions and description for the planning agent, which are used when creating the agent in Azure Foundry on app session run.


{% highlight python linenos %}
# agent_utils.py ...

def get_or_create_agent(
    project_client: AIProjectClient, combined_df: pd.DataFrame
) -> str:
    """Get existing agent or create new one.

    Args:
        project_client: Azure AI Project client.
        combined_df: Combined and normalized recipe data.

    Returns:
        Agent ID string.
    """
    if "agent_id" not in st.session_state:
        return initialize_agent(project_client, combined_df)
    return st.session_state["agent_id"]


{% endhighlight %}

The `def get_or_create_agent()` function is called from `app.py` and checks if an agent ID is already stored in the Streamlit session state. If not, it calls the `def initialize_agent()` function to create a new agent with the provided project client and combined DataFrame. It returns the agent ID, which is stored in the session state for future use. 


{% highlight python linenos %}
# agent_utils.py ...

def initialize_agent(project_client: AIProjectClient, combined_df: pd.DataFrame) -> str:
    """Initialize agent with vector store and email connection.

    Args:
        project_client: Azure AI Project client.
        combined_df: Combined and normalized recipe data.

    Returns:
        Agent ID string.
    """
    # Email agent (A2A connection)
    email_agent_id = os.getenv("email_agent_id")
    if email_agent_id:
        email_agent = project_client.agents.get_agent(email_agent_id)
        connected_agent = ConnectedAgentTool(
            id=email_agent.id,
            name=email_agent.name,
            description=email_agent.description,
        )
        email_tools = connected_agent.definitions
    else:
        email_tools = []
        st.warning("Email agent not configured")

    # File upload and vector store
    json_path = data_utils.df_to_temp_json(combined_df, ndjson=True)
    file = project_client.agents.files.upload(
        file_path=json_path, purpose=FilePurpose.AGENTS
    )
    file_id = getattr(file, "id", None) or file.get("id")

    vector_store = project_client.agents.vector_stores.create_and_poll(
        file_ids=[file_id],
        name=f"dingen_vectorstore_{int(pd.Timestamp.utcnow().timestamp())}",
    )
    vector_store_id = getattr(vector_store, "id", None) or vector_store.get("id")

    # Create file search tool
    file_search = FileSearchTool(vector_store_ids=[vector_store_id])

    # Create agent
    agent = project_client.agents.create_agent(
        model="gpt-4o",
        name="dinner-planning-agent",
        instructions=primary_instructions,
        description=primary_description,
        tools=file_search.definitions + email_tools,
        tool_resources=file_search.resources,
    )

    # Store in session state
    agent_id = getattr(agent, "id", None) or agent.get("id")
    st.session_state["agent_id"] = agent_id
    st.session_state["file_id"] = file_id
    st.session_state["vector_store_id"] = vector_store_id

    return agent_id

{% endhighlight %}

The `def initialize_agent()` function is close to the code equivalent of what we did by clicking around in Microsoft Foundry Portal to build our first agent in my [previous post]({% post_url 2025-10-15-ai-agents-azure %}#build-an-ai-agent-in-ai-foundry-portal). One exception is the agent-to-agent connection. The function initializes the AI agent with a vector store and an email connection. It first checks if an email agent ID is provided in the environment variables. If so, it retrieves the email agent and prepares it for A2A connection. Then it serializes the combined DataFrame into a temporary JSON file using the `data_utils.df_to_temp_json()` function, uploads it to Azure Foundry, and creates a vector store from the uploaded file. The function then creates a file search tool for the agent, which allows it to search the vector store for relevant information. Finally, it creates the agent with the specified model, instructions, description, and tools, and stores the agent ID, file ID, and vector store ID in the Streamlit session state for future use.

* * *

### Chat utility functions

When it comes to upgrade from previous code version, the chat utility functions were previously written directly in the `app.py`. For better code organization and maintainability, I decided to refactor them into a separate module named `chat_utils.py`. This modular approach allows for cleaner code in the main application file and makes it easier to manage and test chat-related functionalities independently.

{% highlight python linenos %}
# chat_utils.py

"""Chat interaction utilities."""
import streamlit as st
from azure.ai.agents.models import ListSortOrder
from azure.ai.projects import AIProjectClient


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
    return st.session_state.get("thread_id"), getattr(run, "id", None)
{% endhighlight %}

There are no new package imports with respect to the previous post, and `def send_user_message()` is moved from `utils.py` in [previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#utility-functions) to `chat_utils.py` without changes. 

{% highlight python linenos %}
# chat_utils.py...

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

The `def get_responses()` is also unchanged with respect to previous article, only moved from `utils.py` in [previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#utility-functions) to `chat_utils.py`. 

{% highlight python linenos %}
# chat_utils.py...

def initialize_chat_history() -> None:
    """Initialize chat history in session state if not already present."""
    if "chat_history" not in st.session_state:
        st.session_state["chat_history"] = []
{% endhighlight %}

The chat initalization is moved from `app.py`, lines 59-63 in [previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#main-app-code), to the `def initialize_chat_history()` function.

{% highlight python linenos %}
# chat_utils.py...

def handle_user_input(
    user_input: str, project_client: AIProjectClient, agent_id: str
) -> None:
    """Handle user input by sending message and processing response.

    Args:
        user_input: The user's message text.
        project_client: An initialized Azure AIProjectClient.
        agent_id: The agent identifier to run.
    """
    st.session_state["chat_history"].append({"role": "user", "content": user_input})

    try:
        with st.spinner("Sending your request to the agent..."):
            thread_id, run_id = send_user_message(project_client, agent_id, user_input)

        if thread_id and run_id:
            responses = get_responses(project_client, thread_id, run_id)
            for response in responses:
                st.session_state["chat_history"].append(
                    {"role": "assistant", "content": response}
                )
    except Exception as e:
        st.error(f"Error communicating with agent: {e}")
        st.session_state["chat_history"].append(
            {
                "role": "assistant",
                "content": "Sorry, I encountered an error. Please try again.",
            }
        )
{% endhighlight %}

The processing of user input is moved from `app.py`, lines 48-57 in [previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#main-app-code), to the `def handle_user_input()` function.


{% highlight python linenos %}
# chat_utils.py...

def display_chat_history() -> None:
    """Render chat history messages."""
    for message in st.session_state.get("chat_history", []):
        with st.chat_message(message["role"]):
            st.markdown(message["content"])
{% endhighlight %}

The chat display is moved from `app.py`, lines 59-63 in [previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#main-app-code), to the `def display_chat_history()` function.


{% highlight python linenos %}
# chat_utils.py...

def reset_conversation() -> None:
    """Reset conversation state (thread, run, chat history)."""
    st.session_state.pop("thread_id", None)
    st.session_state.pop("run_id", None)
    st.session_state.pop("chat_history", None)
    st.rerun()

{% endhighlight %}

Similarly, the resetting of chat history is moved from `app.py`'s sidebar controls, lines 15-19 in [previous post]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#main-app-code), to the `def reset_conversation()` function.

* * * 

### Cleanup utility functions

In order to properly clean up the resources created during the app session, such as the agent, vector store, and uploaded file, I have created a separate module named `cleanup_utils.py`. This module contains functions that handle the deletion of these resources and the clearing of the Streamlit session state. By isolating the cleanup logic into its own module, we can maintain a cleaner codebase and ensure that resource management is handled consistently.

{% highlight python linenos %}
# cleanup_utils.py

"""Resource cleanup utilities."""
import streamlit as st
from azure.ai.projects import AIProjectClient

import utils


def cleanup_resources(project_client: AIProjectClient) -> dict[str, bool]:
    """Delete agent, vector store, and file.

    Args:
        project_client: Azure AI Project client.

    Returns:
        Dictionary with deletion status for each resource.
    """
    deleted = {"agent": False, "vector_store": False, "file": False}

    # Delete agent
    agent_id = st.session_state.get("agent_id")
    if agent_id:
        try:
            project_client.agents.delete_agent(agent_id)
            deleted["agent"] = True
            st.write("✓ Agent deleted successfully")
        except Exception as e:
            st.error(f"Failed to delete agent {agent_id}: {type(e).__name__}: {e}")

    # Delete vector store
    vector_store_id = st.session_state.get("vector_store_id")
    if vector_store_id:
        try:
            vs_client = project_client.agents.vector_stores

            # Try different delete methods
            if hasattr(vs_client, "delete_vector_store"):
                vs_client.delete_vector_store(vector_store_id)
            elif hasattr(vs_client, "delete"):
                vs_client.delete(vector_store_id)
            elif hasattr(vs_client, "begin_delete"):
                poller = vs_client.begin_delete(vector_store_id)
                poller.result()
            else:
                raise AttributeError(
                    f"No delete method found. Available methods: {dir(vs_client)}"
                )

            deleted["vector_store"] = True
            st.write("✓ Vector store deleted successfully")
        except Exception as e:
            st.error(
                f"Failed to delete vector store {vector_store_id}: {type(e).__name__}: {e}"
            )

    # Delete file
    file_id = st.session_state.get("file_id")
    if file_id:
        try:
            project_client.agents.files.delete(file_id=file_id)
            deleted["file"] = True
            st.write("✓ File deleted successfully")
        except Exception as e:
            st.error(f"Failed to delete file {file_id}: {type(e).__name__}: {e}")

    return deleted

{% endhighlight %}

The `def cleanup_resources()` function deletes the agent, vector store, and file associated with the current session. It retrieves the IDs of these resources from the Streamlit session state and attempts to delete each one using the appropriate methods from the Azure AI Project client. The function returns a dictionary indicating the deletion status of each resource.


{% highlight python linenos %}
# cleanup_utils.py ...

def cleanup_and_clear_session(project_client: AIProjectClient) -> None:
    """Cleanup Azure resources and clear all session state.

    This permanently deletes the agent, vector store, and files from
    Azure, then clears all session state including conversation history.
    """
    # Show what we're about to delete
    resources_to_delete = []
    if st.session_state.get("agent_id"):
        resources_to_delete.append(f"agent ({st.session_state.get('agent_id')})")
    if st.session_state.get("vector_store_id"):
        resources_to_delete.append(
            f"vector_store ({st.session_state.get('vector_store_id')})"
        )
    if st.session_state.get("file_id"):
        resources_to_delete.append(f"file ({st.session_state.get('file_id')})")

    if not resources_to_delete:
        st.warning("No resources to delete.")
        return

    deleted = cleanup_resources(project_client)

    # Show summary
    success_count = sum(deleted.values())
    st.write(f"Deletion summary: {success_count}/{len(deleted)} resources deleted")

    # Clear session state keys
    for k in (
        "agent_id",
        "vector_store_id",
        "file_id",
        "thread_id",
        "run_id",
        "chat_history",
    ):
        st.session_state.pop(k, None)

    # Set flag to prevent recreation on rerun
    st.session_state["cleanup_done"] = True

    if success_count > 0:
        st.success("Session cleared. Restarting application...")
        utils.safe_rerun()

{% endhighlight %}

The `def cleanup_and_clear_session()` function orchestrates the cleanup process by first identifying which resources need to be deleted based on the session state. It calls the `cleanup_resources()` function to perform the deletions and then provides a summary of the deletion results. Afterward, it clears relevant keys from the Streamlit session state to reset the application state. A flag is set to prevent the agent from being recreated on rerun after cleanup. If any resources were successfully deleted, it triggers a safe rerun of the application to reflect the cleared state.

* * *

### Environment variables

In order to be able to run the code, we need to create an `.env` file in the project's root directory, and copy and paste the following values from the Foundry portal and Google Cloud Console into the file, so the `is_local()` function finds the environment variables on app run:

* Microsoft Foundry project endpoint: in my code called `dingen_azure_endpoint`.
* Microsoft Foundry Email Agent id: in my code called `email_agent_id`.
* Google application credentials for Google Sheets API: in my code called `google_app_credentials`.
* Google sheet id: in my code called `google_sheet_id`.

As a reminder, the `dingen` is an abbreviation for dinner generator. A brief comment on lowercase for environment variables: usually they are set in uppercase, but as you will see in the upcoming article on app deployment, I use Azure Vault to store the secrets, and it is easier to keep the naming consistent across local and remote setups. Please see my previous post on [How to build a home for an AI agent]({% post_url 2025-10-15-ai-agents-azure-and-streamlit %}#environment-variables) for instructions on where to find these values in the Microsoft Foundry portal.

In my repository I have provided a `.env.template` that shows how to set up the environment variables for local and deployed environments. More on this in the next article on agentic app deployment. 

{% highlight python linenos %}
# .env.template
# Azure AI Foundry Connection
dingen_azure_endpoint=YOUR_AZURE_ENDPOINT_URL
email_agent_id=YOUR_EMAIL_AGENT_ID

# Google Sheets Connection
# Use file path (local development)
google_app_credentials_json=/path/to/your/credentials.json
# For Azure deployment, set this in Azure App Settings or Key Vault
# google_app_credentials_json=<JSON_CONTENT_OR_BASE64>
google_sheet_id=YOUR_GOOGLE_SHEET_ID

{% endhighlight %}

* * *

# My impression after a deep dive into Azure Python SDK

Here I will share my thoughts after a deep dive into the Azure Python SDK for Microsoft Foundry.

**What worked well:**

- Easy to get started with SDK examples for Python in the documentation.
- A lot of available information and opportunities for versatile agent capabilities.
- Most of the SDK code ran as intended, but I had to be creative and design workarounds.

**Difficulties I ran into:**

- **"All the way with SDK" plan did not work entirely:** The email tool could not be added to the planning agent via the SDK. I had to create a separate email agent in the portal, as in one of my [previous posts]({% post_url 2025-10-15-ai-agents-azure %}#build-an-ai-agent-in-ai-foundry-portal), and establish an A2A connection. On the positive side, I got to test A2A functionality, which works as intended.
- **Lack of direct dynamic data source support for spreadsheets:** I had to implement a workaround with Google Sheets, as an API connection.
- **Incompatibility between model type and available tools:** While working on the code I also discovered that not all models are compatible with all tools. I had to choose GPT-4o for the planning and email agents, as other models did not work with the file search tool. This could be due to subscription limitations. Although, in another unlimited Azure subscription I tested, I experienced a similar situation when trying to use GPT-5 series model with a Grounding Bing Search Tool for web browsing.
- **MCP deployment documentation is still limited:** Instead of connecting to the Google Sheet API I could have developed an MCP server for Google Sheets and probably sped up the data retrieval process significantly. Unfortunately, the documentation I found did not clearly state that MCP tools are supported only in the beta version of the SDK package, and a lot of syntax is different between beta and stable package versions. This made it too cumbersome to switch to beta versions and made me choose the API to dataframe approach for now. Also, in mid-November 2025 Azure AI Foundry was renamed to Microsoft Foundry, with new documentation links and naming conventions, new syntax, and beta version packages. It seems that there is a lot of work done on the MCP standardization, but I will want to wait until MCP capabilities reach stable package versions before investing more time in this.

All in all, I am satisfied with the outcome of this deep dive into the Azure Python SDK for Microsoft Foundry. I was able to build a functional agentic app system that integrates with dynamic data from Google Sheets and can send emails via an email agent. The experience has given me valuable insights into the capabilities and current limitations of the SDK, and I look forward to seeing how it evolves in the future.

I hope you were able to run your own app locally and upskilled your agentic abilities with me.
See you in the next, and last post in this series, where we deploy the agentic app 🩵!  


---

*Transparency note: This article is human-written with AI assistance for proofreading and typo correction. Main image generated with AI.*

---
**[🔝 Back to top 🔝](#top)**

{% include giscus.html %}
