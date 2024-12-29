---
layout: post
title: "Building Natural Language Interfaces with LLM Function Calling"
date: 2024-10-27
categories: [Gen AI, Machine Learning]
tags: [LLM, Function Calling, Natural Language Interface]
slug: building-natural-language-interfaces-with-llm-function-calling
---

## Introduction
Large Language Models (LLMs) are good at generating coherent text, but they have few inherent limitations:
1. **Hallucinations**: They learn and generate information in terms of likelihood and  may produce information that is not grounded in facts
2. **Knowledge Cutoff**: LLMs are trained on a fixed dataset and do not have access to real-time information or the ability to perform complex tasks like web browsing or executing code.
3. **Abstraction and Reasoning**: LLMs may struggle with abstract reasoning and complex tasks that require logical steps or mathematical operations. Their output is not precise enough for tasks with fixed rule-sets w/o interfacing with external tools

There are two ways to address these limitations: 
1. Retrieval Augmented Generation (RAG) 
2. Function Calling 

This post focuses on the latter.

## What is Function Calling?

Function Calling enables LLMs to interact with external tools or APIs, thereby supplementing their knowledge and capabilities. This process involves:

1. **Defining Functions**: Specify the functions the model can call, along with their parameters.
2. **Generating Function Calls**: The model generates function calls based on the user's input.
3. **Executing Functions**: The external tools execute these function calls and return the results.
4. **Incorporating Results**: The results are fed back into the model to generate a final response.


![](/images/2024-12-04-function-calling-diagram.png)

This approach helps overcome the limitations of knowledge cutoff and abstract reasoning by allowing LLMs to leverage external knowledge sources or tools.  Although the function specifications can be passed as part of the prompt, it's more effective to use an internalized template known by the model.

## Function Calling As A Natural Language Interface

Function calling is not limited to simple tasks like calculator operations or weather API queries. It can be used to create an alternative, intuitive natural language interfaces for existing applications. This eliminates the need for complex UIs, as users can interact with the application using plain English.

![](/images/27-10-2024-function_calling.excalidraw.png)


### Example: TMDB Movie Explorer 

I have implemented a simple Flask application both with traditional UI and a Natural Language that uses the function calling mechanism. The traditional UI of the application allows users to query movies by cast, genre, or title, whereas the Natural Language Interface allows users to ask in natural language


![TMDB Movie Explorer](/images/2024-12-04-movies-app.gif)

### Chain of Thought Reasoning

To handle user queries, we employ a chain of thought (CoT) reasoning approach. This involves:

1. Analyzing the User's Request: Determine the intent behind the query.
2. Generating a Reasoning Chain: Outline the logical steps required to gather the necessary information.
3. Identifying Relevant Functions: Recognize which functions and the order in which they need to be called to fulfill the request

For example, for the query "List comedy movies with Tom Cruise in it," the reasoning chain might be:
* Search for the person ID of Tom Cruise using the `search_person` function.
* Use the `discover_movie` function to find comedy movies that Tom Cruise has been in.

When a user submits a query, we pass the query to LLM and ask it to generate a reasoning chain that outlines the logical steps required to gather the necessary information. This  involves analyzing the user's request, recognizing relevant functions, and deciding on the order in which these functions should be called. 

```python
def generate_reasoning_chain(user_prompt: str) -> Any:
    messages = [
        {
            "role": "system", 
            "content": "You are a movie search assistant bot who uses TMDB to help users find movies. Think step by step and identify the sequence of reasoning steps that will help to answer the user's query."
        ],
        {"role": "user", "content": user_prompt},
    ]
    return messages
```

### Tool Definitions

Tools are described using JSON Schema and passed to the model in the prompt. Here's an example of tool definitions:

```python
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_movie_details",
            "description": "Get the top level details of a movie by ID",
            "parameters": {
                "type": "object",
                "properties": {
                    "movie_id": {
                        "type": "integer",
                        "description": "The ID of the movie to get details for. Use discover_movie to find the ID of a movie.",
                    },
                },
                "required": ["movie_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "search_person",
            "description": "Search for people in the entertainment industry.",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The search query for the person"
                    },
                },
                "required": ["query"]
            }
        }
    }
]
```

We pass this message structure to the LLM to generate a reasoning chain. Here we are using `llama3-groq-70b-8192-tool-use-preview` model from groq which is 70B parameter model that is fine-tuned for tool use.
```python
# Passing the tools to the function
response = client.chat.completions.create(
    model=MODEL,
    messages=messages,
    tools=tools,
    tool_choice=tool_choice,
    temperature=0,
    max_tokens=4096,
)
```

Here each tool is a python function like below which calls TMDB API to retrieve the data.

```python
def discover_movie(include_adult=False, include_video=False, language="en-US", page=1, sort_by="popularity.desc", **kwargs):
    endpoint = f"{BASE_URL}/discover/movie"
    params = {}

    for key, value in kwargs.items():
        if value is not None:
            params[key] = value
    response = query_tmdb(endpoint, params=params)
    return response
```

Here is an example of the reasoning chain generated for the query "What movies did Tom Hanks star in?"

```python
[
    {
        "role": "system",
        "content": "You are a movie search assistant bot who uses TMDB to help users find movies. Think step by step and identify the sequence of function calls that will help to answer."
    },
    {
        "role": "user",
        "content": "List comedy movies with tom cruise in it"
    },
    {
        "role": "assistant",
        "content": "To find comedy movies with Tom Cruise, I will first need to find the person ID for Tom Cruise using the search_person function. Once I have the person ID, I can use the discover_movie function to find comedy movies that he has been in."
    }
]
```

## Handling Function Calls

The model returns a response containing tool calls. We extract the function name and arguments from the response and execute the function. The function's response is then added to the conversation history.

```python
if response.choices[0].finish_reason == "tool_calls":
    tool_calls = response.choices[0].message.tool_calls
    new_messages = messages.copy()
    for tool_call in tool_calls:
        tool_result = execute_tool(tool_call)
        new_messages.append(
            {
                "tool_call_id": tool_call.id,
                "role": "tool",
                "name": tool_call.function.name,
                "content": str(tool_result),
            }
        )
```

Now the conversation history would be like:

```python
[{'role': 'system',
  'content': 'You are a movie search assistant bot who uses TMDB to help users find movies. Think step by step and identify the sequence of function calls that will help to answer.\n        Do not call multiple functions when they need to be executed in sequence. Only call multiple functions when they can be executed in parallel. Stop with a discover_movie function call that returns a list of movie ids'},
 {'role': 'user', 'content': 'List some movies of Tom hanks'},
 {'role': 'assistant',
  'content': 'To find movies of Tom Hanks, I will first need to find the person ID of Tom Hanks using the search_person function. Once I have the person ID, I can use the discover_movie function to find movies that he has been in.'},
 {'tool_call_id': 'call_p11f',
  'role': 'tool',
  'name': 'search_person',
  'content': ...,
 {'tool_call_id': 'call_0b5m',
  'role': 'tool',
  'name': 'discover_movie',
  'content': ...}]
```

### Recursive Function Calls

We recursively call functions recommended by the LLM until we reach the final function call. The final `discover_movie` call consolidates all the gathered parameters and data into a single request that retrieves the ultimate list of movies relevant to the user's inquiry

```python
def generate_domain_knowledge(messages, count=0):
    response = get_response(client, MODEL, messages, tool_choice="required")
    if response.choices[0].finish_reason == "tool_calls":
        tool_calls = response.choices[0].message.tool_calls
        new_messages = messages.copy()
        for tool_call in tool_calls:
            tool_result = execute_tool(tool_call)
            if tool_call.function.name == "discover_movies":
                return tool_result['results']
            else:
                new_messages.append(
                    {
                        "tool_call_id": tool_call.id,
                        "role": "tool",
                        "name": tool_call.function.name,
                        "content": str(tool_result),
                    }
                )
        if count < 2:
            generate_domain_knowledge(new_messages, count + 1) # stop at 2 recursive calls
```

## Lessons learnt and Caveats

Keep in mind that the limitation and the perks of prompt engineering applies:
- **Simplicity**: Keep the function calls simple and concise. The more complex the function calls, the more likely it is that the model will make mistakes.
- **Parameter Validation**: Function parameter validation is not handled by the model. It is up to the developer to ensure that the parameters are valid.
- **Guardrails**: Establish Guardrails to prevent the model from calling functions that it should not call

Remember that the model is just one component of the system. The effectiveness and safety of the model depend on how it is used and integrated into the broader context. It is the developer's responsibility to tailor safety measures to their specific use case and ensure that the model's outputs are safe and appropriate for the context.

The above code along with a working app is available in [HF Spaces](https://huggingface.co/spaces/tmzh/movies-app).
