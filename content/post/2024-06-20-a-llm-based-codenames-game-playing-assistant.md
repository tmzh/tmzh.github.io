---
author: tmzh
categories:
- Generative AI 
- Games
date: 2024-06-20T12:00:00Z
images: 
- /images/2024-06-20-game-clues.png
slug: 
- 2024-06-20-llm-based-codenames-game-playing-assistant
tags:
- llm
- generative_ai

title: "Building a Codenames AI Assistant with Multi-Modal LLMs"
---

# Introduction

Codenames is a word association game where two teams guess secret words based on one-word clues. The game involves a 25-word grid, with each team identifying their words while avoiding the opposing team's words and the "assassin" word. 

I knew that word embeddings could be used to group words based on their semantic similarity. This seemed like a good way to cluster words on the board and generate clues. I was largely successful in getting this to work along with few surprises and learnings along the way. 

![Game play](/images/2024-06-20-game-clues.png)

I have published a demo of this Gradio app along with its code in [HF Spaces](https://huggingface.co/spaces/tmzh/codenames-phi3).

# Initial attempts

My initial experiments with sentence embedding models did not yield satisfactory results. These models required a more context beyond individual words to deliver precise outcomes. Transitioning to word embedding models proved to be more effective; however, I still encountered challenges in filtering out undesired outputs such as foreign language terms and compound words. Additionally, employing similarity search techniques like kNN and Cosine similarity did not yield optimal results.

I switched to word embedding models, which were better, but I still had to filter out unwanted outputs like foreign language words and compound words. Similarity search methods like kNN and Cosine similarity also didn't give me the best results. 

Extracting the game words using OpenCV also turned out to be more involved than I expected. I had to deal with shadows, uneven exposure, grid detection, and draw bounding boxes. The upside-down clue words also caused problems for the character recognition model.

# Multi-Modal LLM Solution

This is when I decided to try a small local Large Language Model (LLM) for this. I used [microsoft/Phi-3-Mini-4K-Instruct](https://huggingface.co/microsoft/Phi-3-mini-4k-instruct) which is a 3.8B parameters, lightweight LLM by Microsoft. Surprisingly this model consistently produced high-quality results with minimal effort. I split the task into 3 sections:
1. Identifying words in the game using OCR
2. Grouping of words
3. Generating clues for each groups

## OCR for text extraction
The Phi-3 model family also has a multimodal version called [microsoft/Phi-3-vision-128k-instruct](https://huggingface.co/microsoft/Phi-3-vision-128k-instruct) with a focus on very high-quality, reasoning dense data both on text and vision. I used this model for OCR. It worked like a charm, eliminating the need for complex image processing techniques. Unfortunately the structured output generation library I used (Outlines, explained later) doesn't yet support Vision models so I couldn't use this as a single model for both OCR and text generation.  So I leveraged Nvidia hosted LLM service (NIM) to perform the OCR task.

```python
def process_image(img):
    # Resize the image
    max_size = (1024, 1024)
    img.thumbnail(max_size)

    image_byte_array = jpeg_with_target_size(img, 180_000)
    image_b64 = base64.b64encode(image_byte_array).decode()

    invoke_url = "https://ai.api.nvidia.com/v1/vlm/microsoft/phi-3-vision-128k-instruct"
    stream = False

    if os.environ.get("NVIDIA_API_KEY", "").startswith("nvapi-"):
        print("Valid NVIDIA_API_KEY already in the environment. Delete to reset")

    headers = {
        "Authorization": f"Bearer {os.environ.get('NVIDIA_API_KEY', '')}",
        "Accept": "text/event-stream" if stream else "application/json"
    }

    payload = {
        "messages": [
            {
                "role": "user",
                "content": f'Identify the words in this game of Codenames. Provide only a list of words. Provide the '
                           f'words in capital letters only. <img src="data:image/png;base64,{image_b64}" />'
            }
        ],
        "max_tokens": 512,
        "temperature": 0.1,
        "top_p": 0.70,
        "stream": stream
    }

    response = requests.post(invoke_url, headers=headers, json=payload)
    if response.ok:
        print(response.json())
        # Define the pattern to match uppercase words separated by commas
        pattern = r'[A-Z]+(?:\s+[A-Z]+)?'
        words = re.findall(pattern, response.json()['choices'][0]['message']['content'])

        return gr.update(choices=words, value=words)
```

## Grouping of words
I employed few-shot prompting technique along with a custom system prompt to cluster words that share common characteristics. I observed that when we instruct the Language Model (LLM) to group words, the resulting clusters are often random, regardless of the initial instructions. However, prompting the LLM to group words and then explain the rationale behind the grouping led to more coherent and meaningful word groupings.

```python
# Grouping the words
def group_words(words):
    @outlines.prompt
    def chat_group_template(system_prompt, query, history=[]):
        '''<s><|system|>
        {{ system_prompt }}
        {% for example in history %}
        <|user|>
        {{ example[0] }}<|end|>
        <|assistant|>
        {{ example[1] }}<|end|>
        {% endfor %}
        <|user|>
        {{ query }}<|end|>
        <|assistant|>
        '''

    grouping_system_prompt = ("You are an assistant for the game Codenames. Your task is to help players by grouping a "
                              "given group of secrets into 3 to 4 groups. Each group should consist of secrets that "
                              "share a common theme or other word connections such as homonym, hypernyms or synonyms")
    prompt = chat_group_template(grouping_system_prompt, words, example_groupings)
    
    # Greedy sampling is sufficient since the objective is to generate grouping of existing words rather than 
    # generating interesting new tokens
    sampler = samplers.greedy()
    generator = generate.json(model, Groups, sampler)

    print("Grouping words:", words)
    generations = generator(
        prompt,
        max_tokens=500
    )
    print("Got groupings: ", generations)
    return [group.words for group in generations.groups]
```

## Generation of Clues
I split the clue generation logic separately even though LLMs could generate them at the time of grouping the words together. This is because I wanted to be able to regenerate better clues for individual groups without having to regroup the entire word list every time.

```python
def generate_clues(group):
    template = '''
    {% for example in history %}
    INPUT:
    {{ example[0] }}
    OUTPUT:
    { 'clue':{{ example[1] }}, 'explanation':{{ example[2] }} }
    {% endfor %}
    INPUT:
    {{ query }}
    OUTPUT:


    {{ system }}

    Clue = {'clue': str, 'explanation': str}
    Return: Clue
    '''

    clue_system_prompt = ("You are a codenames game companion. Your task is to give a single word clue related to "
                          "a given group of words. You will only respond with a single word clue. The clue can be a common theme or other word connections such as homonym, hypernyms or synonyms. Avoid clues that are not too generic or not unique enough to be guessed easily")

    prompt = render_jinja2_template(template, clue_system_prompt, example_clues, group)

    raw_response = model.generate_content(
        prompt,
        generation_config={'top_k': 3, 'temperature': 1.1})
    response = json.loads(raw_response.text)

    print("Generating clues for: ", group)

    print("Got clue: ", json.dumps(response, indent=4))
    return response
```

## Outlines
One reason why I tried other options before LLMs because LLMs generations are stochastic and I needed parsable output for my web page i.e, I need guarantee that the output text will have a certain format. That's when I came across the Outlines library which is one among the many popular guided generations libraries. It helped me generate structured text consistently, making it easy to integrate with my app's interface.

The basic idea of Outlines is simple: in each state, it gets a list of symbols that correspond to completions that partially match the regular expression. It masks the other symbols in the logits returned by a large language model, so we derive a new FSM whose alphabet is the model's vocabulary. We can do this in only one pass over the vocabulary.

```python
# Load LLM model using Outlines library 
model = models.transformers("microsoft/Phi-3-mini-4k-instruct",
                            model_kwargs={'device_map': "cuda", 'torch_dtype': "auto",
                                          'trust_remote_code': True,
                                          'attn_implementation': "flash_attention_2"})

# Generating structured output using Outlines
class Clue(BaseModel):
    word: str
    explanation: str

clue_system_prompt = ("You are a codenames game companion. Your task is to give a single word clue related to "
                      "a given group of words. You will only respond with a single word clue. Compound words are "
                      "allowed. Do not include the word 'Clue'. Do not provide explanations or notes.")

prompt = chat_clue_template(clue_system_prompt, group, example_clues)
generator = generate.json(model, Clue)
generator(prompt, max_tokens=100)
```

# Reflections and the Road Ahead
Initially, I underestimated the LLM approach, considering it excessive for what seemed like a straightforward issue. However, I was mistaken. Leveraging LLM significantly expedited the generation of usable outcomes, saving considerable time. Over time, despite its substantial size and computational demands, this ease of use aspect will boost its acceptance. As momentum builds, further research and optimization will ensue, resulting in more compact, effective, and intelligent models. Although optimized algorithms and specialized models will retain significance in particular domains, LLMs are positioned to transform numerous sectors with their adaptability and potency.