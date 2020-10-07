---
author: tmzh
comments: true
date: 2020-09-20 12:00:00+08:00
layout: post
slug: 2020-09-20-gpt-3-and-the-status-of-artificial-general-intelligence
title: GPT-3 and the status of Artificial General Intelligence 
categories:
- Artificial Intelligence 
tags:
- gpt-3
- philosophy 
---

Last year OpenAI released Generative Pre-trained Transformer 2 (GPT-2) model. GPT-2 was a language model with 1.5 billion parameters, trained on 8 million web pages. It generated quite a buzz as it could generate coherent text, comprehend paragraphs, answer questions and summarize text- all without task-specific learning. OpenAI even deemed the model too dangerous to release but  ended up releasing them eventually.

In May 2020, OpenAI released their follow-up GPT-3 model which took the game several notches higher. It was trained with 175 billion parameters, using close to half-a-trillion tokens. The model and its weights alone would take up 300GB VRAM. This is a drastic increase in complexity, anyway you look at it. So what do we get in return?

![GPT-3 Training Size](/images/2020-09-26-gpt-3-training-size.png)

<!--more-->

GPT-3 can already create poetry, mimic [writing style of personalities](https://www.gwern.net/GPT-3#literary-parodies), do better than average college applicants in  [SAT analogy problems](https://arxiv.org/pdf/2005.14165.pdf#page=25), generate [cohesive stories](https://medium.com/@aidungeon/ai-dungeon-dragon-model-upgrade-7e8ea579abfe). You can even talk to it and ask to do system admin jobs and it will come up with shell commands and execute them, like a seasoned sysadmin. 

![Natural Language Shell](/images/2020-09-26-nlsh.png)


## Meta-learning
The model approaches decent results on many NLP tasks and benchmarks without fine-tuning. OpenAI claims that if a NLP model is sufficiently complex and trained on large volume of data, it can learn to do a new task just by looking at few examples prompts i.e, the model is capable of learning new task on the go and it has learnt to learn[2]. This is one of the reasons why GPT-3 is generating quite a buzz. 

## Unreasonable effectiveness of data
In 2009, Google's Peter Norvig wrote a [paper](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/35179.pdf) about unreasonable effectiveness of data. GPT-3 seems to be the latest example of that. GPT-3 has no direct exposure to reality, except via large corpus of text. Yet the knowledge imparted from this large volume of text allows GPT-3 to reason about the physical world as seen in the [example](https://www.lesswrong.com/posts/L5JSMZQvkBAx9MD5A/to-what-extent-is-gpt-3-capable-of-reasoning) below 

![Reasoning about physical world](/images/2020-09-26-reasoning.png)

In fact, GPT-3 has also demonstrated surprising ability outside the traditional NLP domain. It can do certain non-linguistic tasks like simple arithmetics. This begs the question, whether language alone is sufficient to form an understanding of reality? We use language to describe our world. So a relation between words should correspond to a relation between the real world entities represented by those word. Some [reason](https://deponysum.com/2020/01/16/recent-advances-in-natural-language-processing-some-woolly-speculations/) that ML models are transitive (i.e, if X models Y and Y models Z, then X models Z) and as language itself is an approximate model of the world, then a language model should be an approximate representation of the world. 

## Unreasonable effectiveness of Scale
Another surprising outcome of GPT-3 is that the performance has not tapered as the model got more complex. As the model got more complicated, instead of hitting a wall the performance keeps on getting better. We are 
As recently as last year, training a model with 175B seemed far off in to the future. Human brain is estimated to contain around 100 trillion neurons, how long before we reach that figure and what would AI look like as it approaches the figure? 

![Scaling hypothesis](/images/2020-09-26-scaling-hypothesis.png)

We need to be careful about drawing parallels here as biological neurons are functionally very different from ML model neurons. But the neuron count is a proxy for model complexity and it would be curious to see whether a sufficiently complex model resemble general intelligence.
Detractors like Marcus claim that just because we know how to stack ladders doesn't meant that we can build ladders to the moon. To them, there is an unbreachable chasm between a statistical model and causal reasoning. But I think we don't know enough about the building blocks of our intelligence to confidently say that such a chasm exists. 

## What do the critics say?
### It is not as good as SOTA
To be correct, on most NLP tasks & benchmarks SOTA performs better than GPT-3 (i.e SuperGLUE, CoQA, Winograd, to name a few). But there are other tasks in which it beats fine-tuned SOTA (i.e PhysicalQA, LAMBADA, Penn Tree Bank). We should not hold this hastily against GPT-3:

1. Most of the SOTA algorithms are fine-tuned for specific tasks, requiring task-specific datasets and fine-tuning. GPT-3 can do these tasks without large supervised datasets, similar to how humans learn language tasks (hence the suggestions of general intelligence). 
2. Beating SOTA is not the hallmark of general intelligence. As it is, SOTA already performs better than humans on many specific tasks like object recognition, mastering games like Chess and Go but we don’t belittle our general intelligence on that count. In a sense, General intelligence always has to underfit to have a wider applicability. 
	
### It is just auto complete
Some critics say that GPT-3 is just a sophisticated text prediction engine[1]. It doesn't understand what those words mean. But I think we don't know enough to confidently define what it means to understand something[5]. 

Let us say our brain is a sophisticated lookup dictionary populated by past experiences and culturally accumulated knowledge. Suppose a non-human entity possesses a similar dictionary but populated in a different route (by training on text corpus or other means). Can it claim to have understanding? This was the crux of the argument laid down by Searle in his Chinese room thought experiment[4]. Searle claims that looking up a dictionary doesn't represent understanding, but there are many who don't agree. 

When even philosophers aren't in agreement in terms of what constitutes understanding, it is premature to claim that the model hasn't understood anything. Our intuitions about intelligence, understanding and meaning are not a reliable foundation for any argument. 

### It has already seen the data it is predicting on
GPT-3 has also a more serious allegation of being a pattern matcher regurgitating the texts fed into it. For example, Yannic Kilcher in his video[2] suspects that it can do arithmetic predictions because the model is likely to have seen the same data in training dataset. OpenAI team claims to have done sufficient deduplication to remove testing dataset from training data[6]. But since their input data is too huge, the deduplication is optimistic.

Few days back I came across an implementation of GPT by Karpathy and his mini model was trained exclusively on synthetic data. And it was able to do 2 digit arithmetic with a clear separation between training set and validation set. So it is possible for a language model to learn mechanics of arithmetics, albeit limited to 2 digits. Therefore it is conceivable that this can be expanded upon in future.


