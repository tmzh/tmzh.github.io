---
author: tmzh
categories:
- Generative AI 
comments: true
date: "2023-06-24T12:00:00Z"
slug: 2023-06-24-llm-powered-faq-chat-bot
tags:
- llama
- langchain

title: "Exploring Retrieval-Augmentated Generation with Open Source Large Language Models"

mathjax: true
autoCollapseToc: true
---

# Introduction
In today's digital landscape, chatbots have become a familiar presence, seamlessly integrating into various applications and platforms, from customer service to virtual assistants. However, as widespread as they may be, these traditional conversational agents still face certain limitations. While they are excellent in generating conditioned responses, they struggle with out-of-distribution queries. For example, if the user asks an unexpected question or uses unusual patterns, they either revert to a standard response or fail to respond.

This is where large language models (LLMs) can help, offering a promising solution to enhance chatbot performance. LLMs handle out-of-distribution data better, so they perform better in situations where simple syntax parsing, pattern matching and database lookup are not adequate. And unlike traditional Chatbots, LLMs offer a more human-like interaction by understanding context, generating personalized responses. 

Conversely, Chatbots are also an excellent use case for LLMs where the strengths of an LLM shines. For examples, LLMs have a common weakness known as "hallucination," wherein they generate inaccurate or irrelevant responses. When in used in Chatbots, we can reduce LLM "hallucination" by  incorporating knowledge retrieval, and restricting the responses to authoritative information sourced from knowledge base. 

Finally, for knowledge-intensive tasks like chatbots, the ability of LLMs to make predictions based on both input contexts and domain-specific knowledge, such as a company's documentation, proves invaluable. This integration enables chatbots to provide more informed and accurate responses, enhancing their overall performance as conversational agents.


<figure>
    <img src="/images/2023-06-25-decision-flow-for-chosing-llm.png"
         alt="Decision Flow for choosing LLM"
         width="80%">
    <figcaption><i>Source: Harnessing the Power of LLMs in Practice: A Survey on ChatGPT and Beyond 
(<a href="https://arxiv.org/pdf/2304.13712.pdf">arXiv:2304.13712</a>)
</i></figcaption>
</figure>

### Advantages of RAG over LLM-based question answering
1. RAG can answer based on facts not learned during the LLM training, without the need for fine-tuning. This is more relevant for specific knowledge domains such as internal company docs or for data outside the cut-off used for LLM training
2. RAG can provide traceability to its answers, enabling users to identify the sources of information
3. When passing source documents as prompts, LLMs are limited by context length. Even with newer models that supports longer contexts it is not performant to pass the entire knowledge base into the prompt 

### Advantages of RAG over traditional chatbots
1. LLMs handle out-of-distribution data better, so they perform better in situations where simple syntax parsing, pattern matching and database lookup are not adequate. And unlike traditional Chatbots, LLMs offer a more human-like interaction by understanding context, generating personalized responses.
2. If the users query doesn't exactly match the question in our knowledge base, the response quality greatly suffers

## How Retrieval Augmented Generation works
Retrieval augmented generation (RAG) works by combining two main components: a retrieval model and a generation model. 

The retrieval model searches and retrieves relevant information from a database or collection of documents. It typically uses semantic similarity, representing words or documents as numerical embeddings and calculating the similarity between query embeddings and document embeddings to identify the most relevant information.

Once the retrieval model has retrieved the relevant content, it serves as a knowledge base or reference for the generation model. The generation model is typically a large language model (LLM) that takes the retrieved information as input and generates new text based on it. The generation model uses the retrieved information to guide the text generation process. 

![Retrieval Augmented Generation](/images/2023-06-25-retrieval-qa.svg)

The combination of the retrieval model and the generation model allows for a more targeted and accurate generation of text. The retrieval model ensures that the generated text is grounded in relevant and reliable information, while the generation model adds creativity and fluency to the text. While it is possible to use a large language model (LLM) for both embedding and text generation, processing long documents through an LLM for populating vector store can be computationally expensive. Embedding models, unlike LLMs, are not encumbered with extraneous details required for next token prediction. Overall, separating the retrieval and generation tasks improves efficiency and precision.


In this blog post, we will develop a retrieval augmented generation (RAG) based LLM application from scratch. We will be building a chatbot that answers questions based on a knowledge base. For the knowledge base, we will use [E-commerce FAQ dataset](https://www.kaggle.com/datasets/saadmakhdoom/ecommerce-faq-chatbot-dataset).

## Implementation

### Load documents

The chat dataset used for this project, is in a JSON format as an array of key-value pairs. We will split it into chunks of `n` characters but to retain the information within each chunk, we will ensure that each QnA pair is loaded as an individual chunk. 

```python
import json
from pathlib import Path
import uuid

file_path='./data/faq_dataset.json'
data = json.loads(Path(file_path).read_text())

documents = [json.dumps(q) for q in data['questions']] # encode QnA as json strings for generating embeddings
metadatas = data['questions'] # retain QnA as dict in metadata
ids = [str(uuid.uuid1()) for _ in documents] # unique identifier for the vectors
```

###  Generate and store embeddings
Next we will use an embedding model to generate vector representations of the chunks. Here we are using `BAAI/bge-small-en-v1.5` model.  This is a tiny model, less than 150 MB in size and uses 384 dimensions to store semantic information, but it is sufficient for retrieval. Since embedding model needs to process a lot more tokens than answering model which only needs to process the prompt, it is better to keep it lightweight. If we have enough memory, we can use a larger model to generate embeddings.

```python

import chromadb
from chromadb.utils import embedding_functions

client = chromadb.Client()
emb_fn = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="BAAI/bge-small-en-v1.5")

collection = client.create_collection(
    name="retrieval_qa",
    embedding_function=emb_fn,
    metadata={"hnsw:space": "cosine"} # l2 is the default
)
```


Since our FAQ dataset is very small, and we have a light embedding model, it is quite inexpensive to calculate the embeddings. So we will use in-memory non-persistent Chroma client as a Vector store. Vector stores is a data structure or database that specialize in storing and retrieving embeddings. They also provide methods for performing similarity search and Nearest neighbour search. Note that in ChromaDB, the default index type is [Hierarchical Navigable Small Worlds](https://zilliz.com/learn/hierarchical-navigable-small-worlds-HNSW) (`hnsw`) and distance function is `l2`. However other distance functions are also available:

| Distance          | Parameter | Equation                                                                                                                |
|-------------------|-----------|-------------------------------------------------------------------------------------------------------------------------|
| Squared L2        | `l2`      | $$ d = \sum\left(A_i-B_i\right)^2 $$                                                                                    |
| Inner product     | `ip`      | $$d = 1.0 - \sum\left(A_i \times B_i\right) $$                                                                          |
| Cosine Similarity | `cosine`  | $$d = 1.0 - \frac{\sum\left(A_i \times B_i\right)}{\sqrt{\sum\left(A_i^2\right)} \cdot \sqrt{\sum\left(B_i^2\right)}}$$ |

For more expensive embedding operations involving larger dataset or embedding model, we can use persistent store such one offered by ChromaDB itself or other options such as `pgVector`, `Pinecone` or `Weaviate`

### Querying Index
We can now retrieve a documents closest to query:

```python
query = "How can I open an account?"
docs = collection.query(query_texts=[query], 
                        n_results=3)
```
	{'ids': [['d9b8bc80-7093-11ee-a189-00155d07b3f4',
	   'd9b8bee2-7093-11ee-a189-00155d07b3f4',
	   'd9b8bece-7093-11ee-a189-00155d07b3f4']],
	 'embeddings': None,
	 'documents': [['{"question": "How can I create an account?", "answer": "To create an account, click on the \'Sign Up\' button on the top right corner of our website and follow the instructions to complete the registration process."}',
	   '{"question": "Can I order without creating an account?", "answer": "Yes, you can place an order as a guest without creating an account. However, creating an account offers benefits such as order tracking and easier future purchases."}',
	   '{"question": "Do you have a loyalty program?", "answer": "Yes, we have a loyalty program where you can earn points for every purchase. These points can be redeemed for discounts on future orders. Please visit our website to learn more and join the program."}']],
	 'metadatas': [[{'question': 'How can I create an account?',
		'answer': "To create an account, click on the 'Sign Up' button on the top right corner of our website and follow the instructions to complete the registration process."},
	   {'question': 'Can I order without creating an account?',
		'answer': 'Yes, you can place an order as a guest without creating an account. However, creating an account offers benefits such as order tracking and easier future purchases.'},
	   {'question': 'Do you have a loyalty program?',
		'answer': 'Yes, we have a loyalty program where you can earn points for every purchase. These points can be redeemed for discounts on future orders. Please visit our website to learn more and join the program.'}]],
	 'distances': [[0.19405025243759155, 0.3536655902862549, 0.3666747808456421]]}

For simple and straightforward user queries, it may be sufficient to return the top match. But consider a question like below:

```python
query = "What are the conditions for requesting a refund? Do I need to keep the receipt?"
docs = collection.query(query_texts=[query],
                        n_results=3)

```
The top 3 responses are:

	[[{'question': "Can I return a product without a receipt?",
	   'answer':  "A receipt or proof of purchase is usually required for returns. Please refer to our return policy or contact our customer support team for assistance."},
	  {'question': "Can I return a product if I no longer have the original receipt?",
	   'answer':  "While a receipt is preferred for returns, we may be able to assist you without it. Please contact our customer support team for further guidance."},
	  {'question': "What is your return policy?",
	   'answer':  "Our return policy allows you to return products within 30 days of purchase for a full refund, provided they are in their original condition and packaging. Please refer to our Returns page for detailed instructions."}
	  ]]

Clearly just returning answer for the closest matched question will be incomplete and unsatisfactory for the user. The ideal answer need to incorporate all facts from the relevant document chunks. This is where generation model can help.


**Loading a generative model**

LLMs are often trained and released as unaligned base models initially which simply take in text and predict next token. Bloom, Llama2, Mistral are examples of such base models. But for practical use we often require models that are further fine-tuned for the task. For RAG and generally speaking for chat agents we need `Instruct models` that are further fine-tuned on instruction-response pairs. 

For this demonstration I used an instruction fine-tuned model [`Mistral-7B-Instruct-v0.1`](https://docs.mistral.ai/llm/mistral-instruct-v0.1) from Mistral. The Mistral model is in particular impressive for the quality of its text generation given the relatively small model size (7B). This leads to quite performant prompt evaluation and response generation. I used `GPTQ` quantized version which further reduces the model size and improves the prompt evaluation and token generation throughput significantly.

> GPTQ models are quantized versions that reduces memory requirements with a slight [tradeoff](https://github.com/ggerganov/llama.cpp/pull/1684) of intelligence. Hugging Face transformers supports loading of GPTQ models since version `4.32.0` using AutoGPTQ library. You can learn more about this [here](https://huggingface.co/blog/gptq-integration)


```python
import torch
import transformers
from transformers import AutoModelForCausalLM, AutoTokenizer

models = {
    "wizardLM-7B-HF" : "TheBloke/wizardLM-7B-HF",
    "wizard-vicuna-13B-GPTQ" : "TheBloke/wizard-vicuna-13B-GPTQ",
    "WizardLM-13B" : "TheBloke/WizardLM-13B-V1.0-Uncensored-GPTQ",
    "Llama-2-7B" : "TheBloke/Llama-2-7b-Chat-GPTQ",
    "Vicuna-13B" : "TheBloke/vicuna-13B-v1.5-GPTQ",
    "WizardLM-13B-V1.2" : "TheBloke/WizardLM-13B-V1.2-GPTQ", 
    "Mistral-7B" : "TheBloke/Mistral-7B-Instruct-v0.1-GPTQ"
}

model_name = "Mistral-7B"
tokenizer = AutoTokenizer.from_pretrained(models[model_name])
model = AutoModelForCausalLM.from_pretrained(models[model_name], 
                                             torch_dtype=torch.float16, 
                                             device_map="auto")
```

Alternately you can use any of the other instruct models. I have had good results with `WizardLM-13B` as well. Note that the models we choose must fit the VRAM of your GPU. Often you can find the memory requirements of a model in their HuggingFace model card such as [here](https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.1-GPTQ).



**Building a prompt**

Every instruct model works best when we provide it with prompts as per a specific template which it was trained on. Since this template can vary between models, to reliably apply model specific chat template, we can use [Transformers chat template](https://huggingface.co/docs/transformers/main/chat_templating), which allows us to format a list of messages as per model specific chat template.

```python
chat = [
    {"role": "user", "content": "Hello, how are you?"},
    {"role": "assistant", "content": "I'm doing great. How can I help you today?"},
    {"role": "user", "content": "I'd like to show off how chat templating works!"},
]

tokenizer.use_default_system_prompt = True
tokenizer.apply_chat_template(chat, tokenize=False)
```
`<s>[INST] <<SYS>>\nYou are a helpful, respectful and honest support executive. Always answer as helpfully as possible, while being safe. While answering, use the information provided in the earlier conversations only. If the information is not present in the prior conversation, or If you don't know the answer to a question, please don't share false information. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. \n<</SYS>>\n\nHello, how are you? [/INST] I'm doing great. How can I help you today? </s><s>[INST] I'd like to show off how chat templating works! [/INST]`

In our case, we want to customize the system prompt to pass the retrieved document chunks as a context for QnA. 
This is done by disabling the default system prompt and configuring the tokenizer to use `default_chat_template`. This allows us to override the message for system role. 

```python
chat = []
system_message = "You are a helpful, respectful and honest support executive. Always be as helpfully as possible, while being correct. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. Use the following piece of context to answer the questions. If the information is not present in the provided context, answer that you don't know. Please don't share false information."

for d in docs['metadatas'][0]:
    # append context to system message
    system_message += f"\n Question: {d['question']} \n Answer: {d['answer']}"
    
chat.append({"role": "system", "content": system_message})
chat.append({"role": "user", "content": query})

prompt = tokenizer.apply_chat_template(chat, tokenize=False)
```
For our example the constructed prompt looks like this:

    <s>[INST] <<SYS>>
    You are a helpful, respectful and honest support executive. Always be as helpfully as possible, while being correct. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. Use the following piece of context to answer the questions. If the information is not present in the provided context, answer that you don't know. Please don't share false information.
    Question: How can I create an account?
    Answer: To create an account, click on the 'Sign Up' button on the top right corner of our website and follow the instructions to complete the registration process.
    Question: Can I order without creating an account?
    Answer: Yes, you can place an order as a guest without creating an account. However, creating an account offers benefits such as order tracking and easier future purchases.
    Question: Do you have a loyalty program?
    Answer: Yes, we have a loyalty program where you can earn points for every purchase. These points can be redeemed for discounts on future orders. Please visit our website to learn more and join the program.
    <</SYS>>

    How can I open an account? [/INST]

**Generating a response**

Now we have everything needed to generate a user-friendly response from LLM. 

```python
encodeds = tokenizer.apply_chat_template(chat, return_tensors="pt")

model_inputs = encodeds.to(model.device)
model.to(model.device)

generated_ids = model.generate(model_inputs, max_new_tokens=100, do_sample=True)
answer = tokenizer.batch_decode(generated_ids[:, model_inputs.shape[1]:])[0]
```
    <s>[INST] <<SYS>>
    You are a helpful, respectful and honest support executive. Always be as helpfully as possible, while being correct. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. Use the following piece of context to answer the questions. If the information is not present in the provided context, answer that you don't know. Please don't share false information.
    Question: How can I create an account?
    Answer: To create an account, click on the 'Sign Up' button on the top right corner of our website and follow the instructions to complete the registration process.
    Question: Can I order without creating an account?
    Answer: Yes, you can place an order as a guest without creating an account. However, creating an account offers benefits such as order tracking and easier future purchases.
    Question: Do you have a loyalty program?
    Answer: Yes, we have a loyalty program where you can earn points for every purchase. These points can be redeemed for discounts on future orders. Please visit our website to learn more and join the program.
    <</SYS>>

    How can I open an account? [/INST] To open an account, click on the 'Sign Up' button on the top right corner of our website and follow the instructions to complete the registration process.</s>

Everything after the last token `[/INST]` is the response we seek. Keep in mind that, from an LLM perspective generating responses is merely continuing the text prompt that we passed to it. To retrieve the generated response we need to index from the input prompt length.

```python
answer = tokenizer.batch_decode(generated_ids[:, model_inputs.shape[1]:])[0]
```


**Building a Chat UI**

Now we have all the necessary ingredients to build a chatbot. Gradio library offers several ready-made components which simplifies the process of building a Chat UI. We need to wrap our token generation process as below:

```python
import gradio as gr

with gr.Blocks() as chatbot:
    with gr.Row():
        answer_block = gr.Textbox(label="Answers", lines=2)
        question = gr.Textbox(label="Question")
        generate = gr.Button(value="Ask")
        generate.click(respond, inputs=question, outputs=[answer_block, global_state, exampleso])

chatbot.launch()
```
Along with generating a response, we can also give a list of references to let the user know the source of truth for responses. We can also suggest other relevant questions that the users can click to follow. With these additions, the code for chat component is as follows:

```python
import gradio as gr
import random

samples = [
    ["How can I return a product?"],
    ["What is the return policy?"],
    ["How can I contact customer support?"],
]


def update_examples():
    global samples
    samples = get_new_examples()
    return gr.Dataset.update(samples=samples)


def respond(query):
    global samples
    docs = collection.query(query_texts=[query], n_results=3)
    chat = []
    related_questions = []
    references = "## References\n"

    system_message = "You are a helpful, respectful and honest support executive. Always be as helpfully as possible, while being correct. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. Use the following piece of context to answer the questions. If the information is not present in the provided context, answer that you don't know. Please don't share false information."

    for d in docs['metadatas'][0]:
        # prepare chat template
        system_message += f"\n Question: {d['question']} \n Answer: {d['answer']}"

        # Update references
        references += f"**{d['question']}**\n\n"
        references += f"> {d['answer']}\n\n"

        # Update related questions
        related_questions.append([d['question']])

    chat.append({"role": "system", "content": system_message})
    chat.append({"role": "user", "content": query})

    prompt = tokenizer.apply_chat_template(chat, tokenize=False)

    encodeds = tokenizer.apply_chat_template(chat, return_tensors="pt")

    model_inputs = encodeds.to(model.device)
    model.to(model.device)

    generated_ids = model.generate(model_inputs, max_new_tokens=100, do_sample=True)
    answer = tokenizer.batch_decode(generated_ids[:, model_inputs.shape[1]:])[0]
    answer = answer.replace('</s>', '')

    related = gr.Dataset.update(samples=related_questions)

    return [answer, references, related]


def load_example(example_id):
    global samples
    return samples[example_id][0]


with gr.Blocks() as chatbot:
    with gr.Row():
        with gr.Column():
            answer_block = gr.Textbox(label="Answers", lines=2)
            question = gr.Textbox(label="Question")
            examples = gr.Dataset(samples=samples, components=[question], label="Similar questions", type="index")
            generate = gr.Button(value="Ask")
        with gr.Column():
            references_block = gr.Markdown("## References\n", label="global variable")

        examples.click(load_example, inputs=[examples], outputs=[question])
        generate.click(respond, inputs=question, outputs=[answer_block, references_block, examples])

chatbot.launch()
```


# Reference
* https://arxiv.org/abs/2005.11401
* https://jxnl.github.io/instructor/blog/2023/09/17/rag-is-more-than-just-embedding-search/
* https://docs.aws.amazon.com/sagemaker/latest/dg/jumpstart-foundation-models-customize-rag.html
* https://scriv.ai/guides/retrieval-augmented-generation-overview/?utm_source=pocket_saves
* https://github.com/aws-samples/amazon-bedrock-workshop/blob/main/03_QuestionAnswering/01_qa_w_rag_claude.ipynb
* https://research.ibm.com/blog/retrieval-augmented-generation-RAG