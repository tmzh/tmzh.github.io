---
layout: post
title: "LLM Function Calling"
date: 2024-10-27
categories: [AI, Machine Learning]
tags: [LLM, Function Calling]
slug: 
---

## Introduction
Large Language Models are good in generating coherent text but they have two inherent limitations:
1. **Hallucinations**: They may produce information that is not supported by the training data, leading to inaccurate or misleading responses.
2. **Knowledge Cutoff**: LLMs are trained on a fixed dataset and do not have access to real-time information or the ability to perform complex tasks like web browsing or executing code.
3. **Abstraction and Reasoning**: LLMs may struggle with abstract reasoning and complex tasks that require logical steps or mathematical operations.

There are two ways to address these limitations: **Retrieval Augmented Generation (RAG)** and **Function Calling**. This post focuses on the latter.

## Function Calling
Function Calling is a technique that allows LLMs to interact with external tools or APIs to perform specific tasks. 

Function Calling serves as a method for LLMs to interact with external tools or APIs, allowing them to supplement their knowledge and capabilities. This technique helps to overcome the limitations of knowledge cut-off and abstract reasoning, such as when performing mathematical operations. By integrating with calculator functions or other specialized tools, LLMs can access real-time data, perform calculations, or execute code, thereby enhancing their capabilities and reducing the occurrence of hallucinations.



### How Function Calling Works

Function calling in Large Language Models (LLMs) enhances how applications interact with these models. Here's a brief overview of the process:

1. **Initiation**: Your application sends a prompt to the LLM, outlining the functions available for it to call.
2. **Decision Making**: The LLM analyzes the prompt to determine if it should respond directly or invoke one or more functions.
3. **API Response**: Based on its analysis, the LLM instructs your application about which function to call and provides the necessary arguments.
4. **Function Execution**: Your application then executes the specified function using the provided arguments.
5. **Final Output**: Finally, your application sends the results of the function execution back to the LLM, along with the original prompt for context.


## Function Calling As A Natural Language Interface
Calculator functions and weather APIs are common examples of tools that can be provided to LLMs to enhance their capabilities. By integrating with tools such as a calculator for mathematical operations or weather APIs for real-time data, LLMs can respond accurately and efficiently to user queries. This provides them with access to structured, specific, relevant, and up-to-date information that can help a lot in making them into genuinely helpful partners .

However, a more powerful use of this technique is implementing LLMs as a natural language interface for existing applications. When a user inputs a query in natural language, the LLM can analyze the query, discern the user's intent, and then translate it into the relevant function call with appropriate arguments. 

This enhances the interaction experience with the application, freeing users from the necessity to navigate through intricate user interfaces or memorize specific commands. Given the infinite possibilities of user interactions, it's unrealistic for developers to design a UI for every potential scenario. Function Calling significantly improves the user experience and accessibility of applications, making them more approachable for a diverse range of users.

## Example: TMDB Movie Explorer 
I've created a simple example to demonstrate how Function Calling can be used to create a natural language interface for a movie explorer application. The application uses the TMDB API to retrieve movie information. The application has traditional UI to list movies by Title, cast name and genre but it also has a chatbot interface that uses Function Calling to interact with the TMDB API.

The LLM is prompted with a user query and decides whether to call the TMDB API to retrieve movie information or respond directly. The LLM then generates a function call with the appropriate arguments based on the user's query. The application executes the function call and sends the results back to the LLM, which generates a response based on the results. The response is then sent back to the user. The code for the example can be found [here](https://github.com/joseph-mccarthy/llm-function-calling-example).


### Generate Chain of Thought Reasoning

To handle user queries, we employ a chain of thought (CoT) reasoning approach. This method breaks down the user’s intent into smaller steps, determining the necessary API calls to meet the request.

When a user submits a query, the application generates a reasoning chain that outlines the logical steps required to gather the necessary information. This process involves analyzing the user's request, recognizing relevant functions, and deciding on the order in which these functions should be called. For example, if a user asks for movies starring a particular actor, the reasoning chain will outline steps such as first searching for the actor's ID and then retrieving a list of movies associated with that ID. By breaking down the process in this manner, the application can identify the sequence of API calls needed to fulfill the user's request.

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
## How Tools are Formatted and Passed as Input

Once the reasoning chain identifies the information required, we can pass those instructions to LLM to come up with the appropriate function calls. I like to change the original system prompt so that the model will now know that it should expect tool definintions and that it should use them to generate function calls.

```python
    messages = generate_reasoning_chain(user_prompt)
    messages[0]["content"] = (
            "You are a movie search assistant bot that utilizes TMDB to help users find movies. "
            "Approach each query step by step, determining the sequence of function calls needed to gather the necessary information. "
            "Execute functions sequentially, using the output from one function to inform the next function call when required. "
            "Only call multiple functions simultaneously when they can run independently of each other. "
            "Once you have identified all the required parameters from previous calls, "
            "finalize your process with a discover_movie function call that returns a list of movie IDs. "
            "Ensure that this call includes all necessary parameters to accurately filter the movies."
        )
    ]

```

To pass the tool definitons to the LLM, we use the `tools` parameter of the `ChatCompletion.create` method. The `tools` parameter expects a list of dictionaries, where each dictionary represents a tool. The format of a tool is as follows:


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

## Handling Function Calls

Once the LLM generates a output, we need to check if it contains a function call. If it does, we need to extract the function name and arguments, call the function, and add the result to the conversation history.

Once the API calls are executed, the responses must be assimilated back into the conversation flow. The application collects the output from each tool call and formats it into a coherent message that can be appended to the ongoing dialogue. Two messages to be added to the chat history. The first message is the assistant initiating the tool call with the specific movie title or genre as the argument. The second message is the tool's response, which is the output of the called function - for example, the search results for the requested cast or genre.

Both the tool call and the tool response are crucial. The model, which only operates based on the information it has in the chat history, may not be able to make sense of a tool response without understanding the call it made and the arguments it used to retrieve that response. A tool response of "28" on its own isn't very informative, but it's extremely beneficial if the model can also see the call that it made earlier to search for  the genre"comedy". Understanding this can greatly enhance the user's experience by providing more accurate and relevant results.


```python
if response.choices[0].finish_reason == "tool_calls":
    tool_calls = response.choices[0].message.tool_calls
    tool_call = tool_calls[0]
    tool_output = execute_tool(tool_call)
    messages.append({
            "tool_call_id": tool_call.id,
            "role": "tool",
            "name": tool_call.function.name,
            "content": str(tool_output),
        })

     messages.append(
         {"role": "function", "content": function_response, "name": function_name}
     )
```





## How API Call Responses are Assimilated Back into a Prompt



## How the LLM is Prompted to Return the Final `discover_movies` API Call

After processing the necessary tools and responses, the application prompts the language model (LLM) to execute the final `discover_movies` API call. This call consolidates all the gathered parameters and data into a single request that retrieves the ultimate list of movies relevant to the user's inquiry.

The LLM is guided to generate this final call based on the accumulated information from earlier steps. It incorporates all relevant parameters, ensuring that the request is as specific and accurate as possible. Once the `discover_movies` call is executed, the results are returned to the front end, where they can be displayed to the user. This final step highlights the synergy between the reasoning process and API interactions, enabling the application to deliver precise and tailored movie recommendations efficiently.
