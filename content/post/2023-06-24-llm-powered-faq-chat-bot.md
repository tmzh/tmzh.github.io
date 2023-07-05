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
title: "Using Retrieval Augmentation to fix hallucination in a local LLM powered chat-bot for QA on FAQ"
---

# Introduction

Among the many potential applications of Large Language Models (LLMs), question answering (or chatbot) is one of the more suitable use case. LLMs handle out-of-distribution data better, so they perform better in situations where syntax parsing and pattern matching are not sufficient. And unlike traditional chatbots, LLMs offer a more human-like interaction by understanding context, generating personalized responses.

<figure>
    <img src="/images/2023-06-25-decision-flow-for-chosing-llm.png"
         alt="Decision Flow for choosing LLM"
         width="80%">
    <figcaption><i>Source: Harnessing the Power of LLMs in Practice: A Survey on ChatGPT and Beyond 
(<a href="https://arxiv.org/pdf/2304.13712.pdf">arXiv:2304.13712</a>)
</i></figcaption>
</figure>

But adoption of LLM in a business context have certain practical challenges. These include:
1. The ability to run the models locally as some organizations do not prefer sharing data with a third party such as OpenAI
2. Hallucination is a common weakness of LLMs where they generate inaccurate or irrelevant responses. 
3. Knowledge intensive tasks such as chatbot needs the model to make predictions based on both the input contexts and domain specific knowledge such as company's documentation. 

In this blog post, we will look at ways to run a LLM locally and also overcome hallucination by retrieving relevant responses from a pre-defined database and presenting them to the user, ensuring accurate and relevant information is provided.


# Setup

![Retrieval QA](/images/2023-06-25-retrieval-qa.svg)

- **Vector Store** - Chroma
- **LangChain** - LangChain is a library which helps you build applications with LLMs through composable chains of inputs/outputs. 
- **LLM Model** -  In this setup, I have used



# Question answering over documents

Question answering in this context refers to question answering over your document data.
For question answering over other types of data, please see other sources documentation like [SQL database Question Answering](/docs/use_cases/tabular.html) or [Interacting with APIs](/docs/use_cases/apis.html).

For question answering over many documents, you almost always want to create an index over the data.
This can be used to smartly access the most relevant documents for a given question, allowing you to avoid having to pass all the documents to the LLM (saving you time and money).

**Load Your Documents**

```python
from langchain.document_loaders import TextLoader
loader = TextLoader('../../modules/state_of_the_union.txt')
```

See [here](/docs/modules/data_connection/document_loaders/) for more information on how to get started with document loading.

**Create Your Index**

```python
from langchain.indexes import VectorstoreIndexCreator
index = VectorstoreIndexCreator().from_loaders([loader])
```

The best and most popular index by far at the moment is the VectorStore index.

**Query Your Index**

```python
query = "What did the president say about Ketanji Brown Jackson"
index.query(query)
```

Alternatively, use `query_with_sources` to also get back the sources involved

```python
query = "What did the president say about Ketanji Brown Jackson"
index.query_with_sources(query)
```

Again, these high level interfaces obfuscate a lot of what is going on under the hood, so please see [this notebook](/docs/modules/data_connection/) for a more thorough introduction to data modules.

## Document Question Answering

Question answering involves fetching multiple documents, and then asking a question of them.
The LLM response will contain the answer to your question, based on the content of the documents.

The recommended way to get started using a question answering chain is:

```python
from langchain.chains.question_answering import load_qa_chain
chain = load_qa_chain(llm, chain_type="stuff")
chain.run(input_documents=docs, question=query)
```

The following resources exist:

- [Question Answering Notebook](/docs/modules/chains/additional/question_answering.html): A notebook walking through how to accomplish this task.
- [VectorDB Question Answering Notebook](/docs/modules/chains/popular/vector_db_qa.html): A notebook walking through how to do question answering over a vector database. This can often be useful for when you have a LOT of documents, and you don't want to pass them all to the LLM, but rather first want to do some semantic search over embeddings.

## Adding in sources

There is also a variant of this, where in addition to responding with the answer the language model will also cite its sources (eg which of the documents passed in it used).

The recommended way to get started using a question answering with sources chain is:

```python
from langchain.chains.qa_with_sources import load_qa_with_sources_chain
chain = load_qa_with_sources_chain(llm, chain_type="stuff")
chain({"input_documents": docs, "question": query}, return_only_outputs=True)
```

# Conclusion
The other ways of doing this are:
1. Similarity search
2. fine tuning


