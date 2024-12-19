---
layout: post
title: "LLM Function Calling"
date: 2024-10-27
categories: [AI, Machine Learning]
tags: [LLM, Function Calling]
slug: 
---

## Introduction
Large Language Models (LLMs) are good at generating coherent text, but they have few inherent limitations:
1. **Hallucinations**: They learn and generate information in terms of likelihood and  may produce information that is not grounded in facts
2. **Knowledge Cutoff**: LLMs are trained on a fixed dataset and do not have access to real-time information or the ability to perform complex tasks like web browsing or executing code.
3. **Abstraction and Reasoning**: LLMs may struggle with abstract reasoning and complex tasks that require logical steps or mathematical operations. Their output is not precise enough for tasks with fixed rule-sets w/o interfacing with external tools

There are two ways to address these limitations: **Retrieval Augmented Generation (RAG)** and **Function Calling**. This post focuses on the latter.

## What is Function Calling?

Function Calling establishes common protocols for LLMs to interact with external tools or APIs, allowing them to supplement their knowledge and capabilities. The below diagam illustrates the process:

![](/images/2024-12-04-function-calling-diagram.png)

This technique helps to overcome the limitations of knowledge cut-off and abstract reasoning, by allowing LLM to plug in to external knowledge sources or tools capable of performing complex tasks.

It may seem that there are many ways to pass function specifications as part of the prompt, but the key is to use an internalized template known by the model.

## Function Calling As A Natural Language Interface

Function calling isn't just for using calculators or calling weather APIs. It can also be used to call backend APIs creating a powerful way to create intuitive natural language interfaces for existing applications. Natural language interfaces are particularly more useful since it allows users to interact with the applications in more than one way. Given the infinite possibilities of user interactions, it's unrealistic for developers to design a UI for every potential scenario. It also eliminates the need for complex UIs, since users can simply ask questions in plain English. 


![](/images/27-10-2024-function_calling.excalidraw.png)


## Example: TMDB Movie Explorer 

I have implemented a simple Flask application both with traditional UI and a Natural Language that uses the function calling mechanism 
This example demonstrates how Function Calling can be used to create a natural language interface for a movie explorer application. 

Scenario: The application is a movie explorer that allows users to query by the cast, the genre, or the title.  But we would like the user to be able to ask in natural language and have the application use the LLM to translate the query into a function call with the necessary arguments. The application should be able to handle all of these queries and return the appropriate information.


![TMDB Movie Explorer](/images/2024-12-04-movies-app.gif)

### Generate Chain of Thought Reasoning

To handle user queries, we employ a chain of thought (CoT) reasoning approach. This method breaks down the user’s intent into smaller steps, determining the necessary API calls to meet the request.

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
For example, if a user asks for movies starring a particular actor, here is the message structure to be used:

```python
[{'role': 'system',
  'content': 'You are a movie search assistant bot who uses TMDB to help users find movies. Think step by step and identify the sequence of function calls that will help to answer.'},
 {'role': 'user', 'content': 'List comedy movies with tom cruise in it'}]
```

To generate the reasoning chain, the LLM also needs to know the list of tools that it has access to. To pass the tool definitions to the LLM, we use the `tools` parameter of the `ChatCompletion.create` method. The tools should be described using JSON Schema and the messages should contain as much available information as possible. Here is an example of tool definition.

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

The chat method returns a generator of list, each of which may contain multiple messages. Since we passed the tools in the prompt, we should get a list of `tool_calls` in the response:

```python
ChatCompletion(
    id='chatcmpl-e3be35d4-c1e6-4368-b38f-ee556f19a620',
        Choice(
            finish_reason='tool_calls',
            index=0,
            logprobs=None,
            message=ChatCompletionMessage(
                content=None,
                role='assistant',
                function_call=None,
                tool_calls=[
                    ChatCompletionMessageToolCall(
                        id='call_p11f',
                        function=Function(
                            arguments='{"query": "Tom Hanks"}',
                            name='search_person'
                        ),
                        type='function'
                    )
                ]
            )
        )
    ],
    created=1733275334,
    model='llama3-groq-70b-8192-tool-use-preview',
    object='chat.completion',
    system_fingerprint='fp_ee4b521143',
    usage=CompletionUsage(
        completion_tokens=26,
        prompt_tokens=901,
        total_tokens=927,
        completion_time=0.080189063,
        prompt_time=0.059023546,
        queue_time=0.0008997029999999948,
        total_time=0.139212609
    ),
    x_groq={'id': 'req_01je7m5dnae2h9xtnxcf36bbc2'}
)
```

The details related to tool calls are placed in the `function` field of the messages:
* **name**: a string representing the function to call
* **arguments**: a JSON-formatted string representing the arguments the function should be called with

For example in the above response, the function name to call is `search_person` and the arguments are `{"query": "Tom Hanks"}`.

We can extract the function name and arguments from the response and call the function. The function's response is then added to the conversation history.

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

Including both the function call and its response is crucial. The LLM relies solely on the conversation history; without context, a standalone response (like "28") is meaningless. However, paired with the preceding call ("Search for genre: comedy"), the response becomes informative and improves the user experience.

Now the message would be like:

```python
[{'role': 'system',
  'content': 'You are a movie search assistant bot who uses TMDB to help users find movies. Think step by step and identify the sequence of function calls that will help to answer.\n        Do not call multiple functions when they need to be executed in sequence. Only call multiple functions when they can be executed in parallel. Stop with a discover_movie function call that returns a list of movie ids'},
 {'role': 'user', 'content': 'List some movies of Tom hanks'},
 {'role': 'assistant',
  'content': 'To find movies of Tom Hanks, I will first need to find the person ID of Tom Hanks using the search_person function. Once I have the person ID, I can use the discover_movie function to find movies that he has been in.'},
 {'tool_call_id': 'call_p11f',
  'role': 'tool',
  'name': 'search_person',
  'content': '{\'page\': 1, \'results\': [{\'adult\': False, \'gender\': 2, \'id\': 31, \'known_for_department\': \'Acting\', \'name\': \'Tom Hanks\', \'original_name\': \'Tom Hanks\', \'popularity\': 77.857, \'profile_path\': \'/eKF1sGJRrZJbfBG1KirPt1cfNd3.jpg\', \'known_for\': [{\'backdrop_path\': \'/ghgfzbEV7kbpbi1O8eIILKVXEA8.jpg\', \'id\': 13, \'title\': \'Forrest Gump\', \'original_title\': \'Forrest Gump\', \'overview\': \'A man with a low IQ has accomplished great things in his life and been present during significant historic events—in each case, far exceeding what anyone imagined he could do. But despite all he has achieved, his one true love eludes him.\', \'poster_path\': \'/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg\', \'media_type\': \'movie\', \'adult\': False, \'original_language\': \'en\', \'genre_ids\': [35, 18, 10749], \'popularity\': 95.507, \'release_date\': \'1994-06-23\', \'video\': False, \'vote_average\': 8.47, \'vote_count\': 27471}, {\'backdrop_path\': \'/lxD5ak7BOoinRNehOCA85CQ8ubr.jpg\', \'id\': 862, \'title\': \'Toy Story\', \'original_title\': \'Toy Story\', \'overview\': "Led by Woody, Andy\'s toys live happily in his room until Andy\'s birthday brings Buzz Lightyear onto the scene. Afraid of losing his place in Andy\'s heart, Woody plots against Buzz. But when circumstances separate Buzz and Woody from their owner, the duo eventually learns to put aside their differences.", \'poster_path\': \'/uXDfjJbdP4ijW5hWSBrPrlKpxab.jpg\', \'media_type\': \'movie\', \'adult\': False, \'original_language\': \'en\', \'genre_ids\': [16, 12, 10751, 35], \'popularity\': 110.308, \'release_date\': \'1995-10-30\', \'video\': False, \'vote_average\': 8.0, \'vote_count\': 18372}, {\'backdrop_path\': \'/vxJ08SvwomfKbpboCWynC3uqUg4.jpg\', \'id\': 497, \'title\': \'The Green Mile\', \'original_title\': \'The Green Mile\', \'overview\': "A supernatural tale set on death row in a Southern prison, where gentle giant John Coffey possesses the mysterious power to heal people\'s ailments. When the cell block\'s head guard, Paul Edgecomb, recognizes Coffey\'s miraculous gift, he tries desperately to help stave off the condemned man\'s execution.", \'poster_path\': \'/8VG8fDNiy50H4FedGwdSVUPoaJe.jpg\', \'media_type\': \'movie\', \'adult\': False, \'original_language\': \'en\', \'genre_ids\': [14, 18, 80], \'popularity\': 80.478, \'release_date\': \'1999-12-10\', \'video\': False, \'vote_average\': 8.506, \'vote_count\': 17461}]}, {\'adult\': False, \'gender\': 0, \'id\': 1156014, \'known_for_department\': \'Directing\', \'name\': \'Tom Hankins\', \'original_name\': \'Tom Hankins\', \'popularity\': 0.001, \'profile_path\': None, \'known_for\': [{\'backdrop_path\': None, \'id\': 173251, \'title\': "Mac \'n Cheese", \'original_title\': "Mac \'n Cheese", \'overview\': "When you find yourself running scared and running out of energy, there\'s only a few options left to outrun your opponent through the southern desert. Stopping at nothing, watch these two guys wear each other out and rip through boundaries hitherto unbroken. Enjoy the ride.", \'poster_path\': None, \'media_type\': \'movie\', \'adult\': False, \'original_language\': \'xx\', \'genre_ids\': [16, 28], \'popularity\': 0.426, \'release_date\': \'2011-08-08\', \'video\': False, \'vote_average\': 5.3, \'vote_count\': 6}, {\'backdrop_path\': None, \'id\': 207000, \'title\': "Mac \'n\' Cheese: Supermarket", \'original_title\': "Mac \'n\' Cheese: Supermarket", \'overview\': "Mac \'n Cheese try to realize their dream vacation by working in a local supermarket. Things go awry when new opportunities arise to make a buck. This short was shown theatrically before World War Z in the Netherlands.", \'poster_path\': None, \'media_type\': \'movie\', \'adult\': False, \'original_language\': \'xx\', \'genre_ids\': [16, 28], \'popularity\': 0.172, \'release_date\': \'2013-06-20\', \'video\': False, \'vote_average\': 5.5, \'vote_count\': 2}]}], \'total_pages\': 1, \'total_results\': 2}'},
 {'tool_call_id': 'call_0b5m',
  'role': 'tool',
  'name': 'discover_movie',
  'content': '{\'page\': 1, \'results\': [{\'adult\': False, \'backdrop_path\': \'/rXYejcyn762o3cjp9OYfyVR3QpY.jpg\', \'genre_ids\': [18], \'id\': 940139, \'original_language\': \'en\', \'original_title\': \'Here\', \'overview\': \'An odyssey through time and memory, centered around a place in New England where—from wilderness, and then, later, from a home—love, loss, struggle, hope and legacy play out between couples and families over generations.\', \'popularity\': 285.048, \'poster_path\': \'/79euHUJJtfgeGU63ef38KtNjXEn.jpg\', \'release_date\': \'2024-10-30\', \'title\': \'Here\', \'video\': False, \'vote_average\': 6.5, \'vote_count\': 68}, {\'adult\': False, \'backdrop_path\': \'/xxH7s4o2ED9qrGxADOp627Txq7o.jpg\', \'genre_ids\': [16, 12, 10751, 14], \'id\': 5255, \'original_language\': \'en\', \'original_title\': \'The Polar Express\', \'overview\': \'When a doubting young boy takes an extraordinary train ride to the North Pole, he embarks on a journey of self-discovery that shows him that the wonder of life never fades for those who believe.\', \'popularity\': 140.636, \'poster_path\': \'/eOoCzH0MqeGr2taUZO4SwG416PF.jpg\', \'release_date\': \'2004-11-10\', \'title\': \'The Polar Express\', \'video\': False, \'vote_average\': 6.721, \'vote_count\': 6264}, {\'adult\': False, \'backdrop_path\': \'/lxD5ak7BOoinRNehOCA85CQ8ubr.jpg\', \'genre_ids\': [16, 12, 10751, 35], \'id\': 862, \'original_language\': \'en\', \'original_title\': \'Toy Story\', \'overview\': "Led by Woody, Andy\'s toys live happily in his room until Andy\'s birthday brings Buzz Lightyear onto the scene. Afraid of losing his place in Andy\'s heart, Woody plots against Buzz. But when circumstances separate Buzz and Woody from their owner, the duo eventually learns to put aside their differences.", \'popularity\': 109.546, \'poster_path\': \'/uXDfjJbdP4ijW5hWSBrPrlKpxab.jpg\', \'release_date\': \'1995-10-30\', \'title\': \'Toy Story\', \'video\': False, \'vote_average\': 8.0, \'vote_count\': 18372}, {\'adult\': False, \'backdrop_path\': \'/ghgfzbEV7kbpbi1O8eIILKVXEA8.jpg\', \'genre_ids\': [35, 18, 10749], \'id\': 13, \'original_language\': \'en\', \'original_title\': \'Forrest Gump\', \'overview\': \'A man with a low IQ has accomplished great things in his life and been present during significant historic events—in each case, far exceeding what anyone imagined he could do. But despite all he has achieved, his one true love eludes him.\', \'popularity\': 103.826, \'poster_path\': \'/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg\', \'release_date\': \'1994-06-23\', \'title\': \'Forrest Gump\', \'video\': False, \'vote_average\': 8.47, \'vote_count\': 27471}, {\'adult\': False, \'backdrop_path\': \'/7iUDfakacY1HpajP1DtHrCuDB95.jpg\', \'genre_ids\': [16, 35, 10751], \'id\': 863, \'original_language\': \'en\', \'original_title\': \'Toy Story 2\', \'overview\': "Andy heads off to Cowboy Camp, leaving his toys to their own devices. Things shift into high gear when an obsessive toy collector named Al McWhiggen, owner of Al\'s Toy Barn kidnaps Woody. Andy\'s toys mount a daring rescue mission, Buzz Lightyear meets his match and Woody has to decide where he and his heart truly belong.", \'popularity\': 87.692, \'poster_path\': \'/W6iWzam7nxiA0FpZkqUbh8JLUK.jpg\', \'release_date\': \'1999-10-30\', \'title\': \'Toy Story 2\', \'video\': False, \'vote_average\': 7.6, \'vote_count\': 13817}, {\'adult\': False, \'backdrop_path\': \'/vxJ08SvwomfKbpboCWynC3uqUg4.jpg\', \'genre_ids\': [14, 18, 80], \'id\': 497, \'original_language\': \'en\', \'original_title\': \'The Green Mile\', \'overview\': "A supernatural tale set on death row in a Southern prison, where gentle giant John Coffey possesses the mysterious power to heal people\'s ailments. When the cell block\'s head guard, Paul Edgecomb, recognizes Coffey\'s miraculous gift, he tries desperately to help stave off the condemned man\'s execution.", \'popularity\': 79.573, \'poster_path\': \'/8VG8fDNiy50H4FedGwdSVUPoaJe.jpg\', \'release_date\': \'1999-12-10\', \'title\': \'The Green Mile\', \'video\': False, \'vote_average\': 8.506, \'vote_count\': 17462}, {\'adult\': False, \'backdrop_path\': \'/42QKmIdogK82MwmR27AF4buZNNR.jpg\', \'genre_ids\': [16, 10751, 35], \'id\': 10193, \'original_language\': \'en\', \'original_title\': \'Toy Story 3\', \'overview\': "Woody, Buzz, and the rest of Andy\'s toys haven\'t been played with in years. With Andy about to go to college, the gang find themselves accidentally left at a nefarious day care center. The toys must band together to escape and return home to Andy.", \'popularity\': 64.665, \'poster_path\': \'/AbbXspMOwdvwWZgVN0nabZq03Ec.jpg\', \'release_date\': \'2010-06-16\', \'title\': \'Toy Story 3\', \'video\': False, \'vote_average\': 7.8, \'vote_count\': 14637}, {\'adult\': False, \'backdrop_path\': \'/rW2xRFlJRbTnBJlQTSjQmjevIwb.jpg\', \'genre_ids\': [18, 36, 10752], \'id\': 857, \'original_language\': \'en\', \'original_title\': \'Saving Private Ryan\', \'overview\': \'As U.S. troops storm the beaches of Normandy, three brothers lie dead on the battlefield, with a fourth trapped behind enemy lines. Ranger captain John Miller and seven men are tasked with penetrating German-held territory and bringing the boy home.\', \'popularity\': 74.754, \'poster_path\': \'/AdpcyHDrwxUuBi6OCSvNbAmRLKK.jpg\', \'release_date\': \'1998-07-24\', \'title\': \'Saving Private Ryan\', \'video\': False, \'vote_average\': 8.2, \'vote_count\': 15825}, {\'adult\': False, \'backdrop_path\': \'/Ag6qhzsJd3k1NKuNrG9RmhZDMh7.jpg\', \'genre_ids\': [18, 80], \'id\': 640, \'original_language\': \'en\', \'original_title\': \'Catch Me If You Can\', \'overview\': \'A true story about Frank Abagnale Jr. who, before his 19th birthday, successfully conned millions of dollars worth of checks as a Pan Am pilot, doctor, and legal prosecutor. An FBI agent makes it his mission to put him behind bars. But Frank not only eludes capture, he revels in the pursuit.\', \'popularity\': 64.487, \'poster_path\': \'/ctjEj2xM32OvBXCq8zAdK3ZrsAj.jpg\', \'release_date\': \'2002-12-16\', \'title\': \'Catch Me If You Can\', \'video\': False, \'vote_average\': 8.0, \'vote_count\': 15611}, {\'adult\': False, \'backdrop_path\': \'/8ln5VUVk7gnNGIb2VNgw8nICDVt.jpg\', \'genre_ids\': [16, 35, 10751], \'id\': 35, \'original_language\': \'en\', \'original_title\': \'The Simpsons Movie\', \'overview\': "After Homer accidentally pollutes the town\'s water supply, Springfield is encased in a gigantic dome by the EPA and the Simpsons are declared fugitives.", \'popularity\': 55.202, \'poster_path\': \'/waWXo6lv77EwKxX50MadlXrwtE4.jpg\', \'release_date\': \'2007-07-25\', \'title\': \'The Simpsons Movie\', \'video\': False, \'vote_average\': 7.0, \'vote_count\': 7963}, {\'adult\': False, \'backdrop_path\': \'/q62bpQ67qaXY0u6b2wFEnQYIbPd.jpg\', \'genre_ids\': [10751, 12, 16, 35, 14], \'id\': 301528, \'original_language\': \'en\', \'original_title\': \'Toy Story 4\', \'overview\': \'Woody has always been confident about his place in the world and that his priority is taking care of his kid, whether that\\\'s Andy or Bonnie. But when Bonnie adds a reluctant new toy called "Forky" to her room, a road trip adventure alongside old and new friends will show Woody how big the world can be for a toy.\', \'popularity\': 63.982, \'poster_path\': \'/w9kR8qbmQ01HwnvK4alvnQ2ca0L.jpg\', \'release_date\': \'2019-06-19\', \'title\': \'Toy Story 4\', \'video\': False, \'vote_average\': 7.487, \'vote_count\': 9751}, {\'adult\': False, \'backdrop_path\': \'/v2LilmCylr3bL9TCZSj6syjowZh.jpg\', \'genre_ids\': [35, 18], \'id\': 937278, \'original_language\': \'en\', \'original_title\': \'A Man Called Otto\', \'overview\': \'When a lively young family moves in next door, grumpy widower Otto Anderson meets his match in a quick-witted, pregnant woman named Marisol, leading to an unlikely friendship that turns his world upside down.\', \'popularity\': 57.033, \'poster_path\': \'/130H1gap9lFfiTF9iDrqNIkFvC9.jpg\', \'release_date\': \'2022-12-28\', \'title\': \'A Man Called Otto\', \'video\': False, \'vote_average\': 7.763, \'vote_count\': 2756}, {\'adult\': False, \'backdrop_path\': \'/phWZP5FESItyhQcqk6sWz35nUtP.jpg\', \'genre_ids\': [18, 36], \'id\': 363676, \'original_language\': \'en\', \'original_title\': \'Sully\', \'overview\': "On 15 January 2009, the world witnessed the \'Miracle on the Hudson\' when Captain \'Sully\' Sullenberger glided his disabled plane onto the Hudson River, saving the lives of all 155 souls aboard. However, even as Sully was being heralded by the public and the media for his unprecedented feat of aviation skill, an investigation was unfolding that threatened to destroy his reputation and career.", \'popularity\': 55.734, \'poster_path\': \'/r09ivJ1GGh5WArqRViRYDQLrTVG.jpg\', \'release_date\': \'2016-09-07\', \'title\': \'Sully\', \'video\': False, \'vote_average\': 7.2, \'vote_count\': 7147}, {\'adult\': False, \'backdrop_path\': \'/sd4xN5xi8tKRPrJOWwNiZEile7f.jpg\', \'genre_ids\': [16, 12, 35, 10751], \'id\': 920, \'original_language\': \'en\', \'original_title\': \'Cars\', \'overview\': "Lightning McQueen, a hotshot rookie race car driven to succeed, discovers that life is about the journey, not the finish line, when he finds himself unexpectedly detoured in the sleepy Route 66 town of Radiator Springs. On route across the country to the big Piston Cup Championship in California to compete against two seasoned pros, McQueen gets to know the town\'s offbeat characters.", \'popularity\': 49.94, \'poster_path\': \'/abW5AzHDaIK1n9C36VdAeOwORRA.jpg\', \'release_date\': \'2006-06-08\', \'title\': \'Cars\', \'video\': False, \'vote_average\': 7.0, \'vote_count\': 13919}, {\'adult\': False, \'backdrop_path\': \'/rLo9T9jEg67UZPq3midjLnTUYYi.jpg\', \'genre_ids\': [18, 10402, 36], \'id\': 614934, \'original_language\': \'en\', \'original_title\': \'Elvis\', \'overview\': \'The life story of Elvis Presley as seen through the complicated relationship with his enigmatic manager, Colonel Tom Parker.\', \'popularity\': 45.177, \'poster_path\': \'/qBOKWqAFbveZ4ryjJJwbie6tXkQ.jpg\', \'release_date\': \'2022-06-22\', \'title\': \'Elvis\', \'video\': False, \'vote_average\': 7.514, \'vote_count\': 3402}, {\'adult\': False, \'backdrop_path\': \'/oE6bhqqVFyIECtBzqIuvh6JdaB5.jpg\', \'genre_ids\': [878, 18, 12], \'id\': 522402, \'original_language\': \'en\', \'original_title\': \'Finch\', \'overview\': "On a post-apocalyptic Earth, a robot, built to protect the life of his dying creator\'s beloved dog, learns about life, love, friendship, and what it means to be human.", \'popularity\': 40.76, \'poster_path\': \'/jKuDyqx7jrjiR9cDzB5pxzhJAdv.jpg\', \'release_date\': \'2021-11-04\', \'title\': \'Finch\', \'video\': False, \'vote_average\': 7.874, \'vote_count\': 3492}, {\'adult\': False, \'backdrop_path\': \'/ioqaIhJSkwa9DGRHGtOOUTiGRs2.jpg\', \'genre_ids\': [12, 18], \'id\': 8358, \'original_language\': \'en\', \'original_title\': \'Cast Away\', \'overview\': "Chuck Nolan, a top international manager for FedEx, and Kelly, a Ph.D. student, are in love and heading towards marriage. Then Chuck\'s plane to Malaysia crashes at sea during a terrible storm. He\'s the only survivor, and finds himself marooned on a desolate island. With no way to escape, Chuck must find ways to survive in his new home.", \'popularity\': 36.774, \'poster_path\': \'/7lLJgKnAicAcR5UEuo8xhSMj18w.jpg\', \'release_date\': \'2000-12-22\', \'title\': \'Cast Away\', \'video\': False, \'vote_average\': 7.7, \'vote_count\': 11346}, {\'adult\': False, \'backdrop_path\': \'/cj0VkGBTywa7WTIPPW9xgqmUVWl.jpg\', \'genre_ids\': [53, 9648], \'id\': 13448, \'original_language\': \'en\', \'original_title\': \'Angels & Demons\', \'overview\': \'Harvard symbologist Robert Langdon is recruited by the Vatican to investigate the apparent return of the Illuminati - a secret, underground organization - after four cardinals are kidnapped on the night of the papal conclave.\', \'popularity\': 33.235, \'poster_path\': \'/tFZQAuulEOtFTp0gHbVdEXwGrYe.jpg\', \'release_date\': \'2009-04-23\', \'title\': \'Angels & Demons\', \'video\': False, \'vote_average\': 6.718, \'vote_count\': 6763}, {\'adult\': False, \'backdrop_path\': \'/66oSbVOmD4W7S6ILRPssYt51ab4.jpg\', \'genre_ids\': [53, 9648], \'id\': 591, \'original_language\': \'en\', \'original_title\': \'The Da Vinci Code\', \'overview\': \'A murder in Paris’ Louvre Museum and cryptic clues in some of Leonardo da Vinci’s most famous paintings lead to the discovery of a religious mystery. For 2,000 years a secret society closely guards information that — should it come to light — could rock the very foundations of Christianity.\', \'popularity\': 33.175, \'poster_path\': \'/9ejKfNk0LBhSI9AahH4f9NJNZNM.jpg\', \'release_date\': \'2006-05-17\', \'title\': \'The Da Vinci Code\', \'video\': False, \'vote_average\': 6.727, \'vote_count\': 9266}, {\'adult\': False, \'backdrop_path\': \'/xXBnM6uSTk6qqCf0SRZKXcga9Ba.jpg\', \'genre_ids\': [10752, 28, 18], \'id\': 516486, \'original_language\': \'en\', \'original_title\': \'Greyhound\', \'overview\': \'A first-time captain leads a convoy of allied ships carrying thousands of soldiers across the treacherous waters of the "Black Pit" to the front lines of WWII. With no air cover protection for 5 days, the captain and his convoy must battle the surrounding enemy Nazi U-boats in order to give the allies a chance to win the war.\', \'popularity\': 35.477, \'poster_path\': \'/kjMbDciooTbJPofVXgAoFjfX8Of.jpg\', \'release_date\': \'2020-07-09\', \'title\': \'Greyhound\', \'video\': False, \'vote_average\': 7.404, \'vote_count\': 2880}], \'total_pages\': 8, \'total_results\': 154}'}]
```

We recursively call functions recommended by the language model until we reach the `discover_movies` function. At each iteration we execute those calls and assimilate the responses back into the prompt. The final `discover_movies` call consolidates all the gathered parameters and data into a single request that retrieves the ultimate list of movies relevant to the user's inquiry.

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
The above code along with a working app is available in [HF Spaces](https://huggingface.co/spaces/tmzh/movies-app).

## Lessons learnt and Caveats

Keep in mind that the limitation and the perks of prompt engineering applies:
- Keep the function calls simple and concise. The more complex the function calls, the more likely it is that the model will make mistakes.
- Function parameter validation is not handled by the model. It is up to the developer to ensure that the parameters are valid.
- Establish Guardrails to prevent the model from calling functions that it should not call

Remember that the model is just one component of the system. Its effectiveness and safety depend on how it's used and integrated into the broader context. It's the responsibility of the developer to tailor safety measures to their specific use case and to ensure that the model's outputs are safe and appropriate for the context.
