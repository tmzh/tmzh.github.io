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

Last year OpenAI released the Generative Pre-trained Transformer 2 (GPT-2) model. GPT-2 was a language model with 1.5 billion parameters, trained on 8 million web pages. It generated quite a buzz as it could generate coherent text, comprehend paragraphs, answer questions, and summarize text- all without task-specific learning. OpenAI even deemed the model too dangerous to release but eventually ended up releasing them.

In May 2020, OpenAI released their follow-up GPT-3 model which took the game several notches higher. It was trained with 175 billion parameters, using close to half-a-trillion tokens. The model and its weights alone would take up 300GB VRAM. This is a drastic increase in scale and complexity, anyway you look at it. So what did we get in return?

![GPT-3 Training Size](/images/2020-09-26-gpt-3-training-size.png)

<!--more-->

GPT-3 can already create poetry, mimic [the writing style of personalities](https://www.gwern.net/GPT-3#literary-parodies), do better than an average college applicant in [SAT analogy problems](https://arxiv.org/pdf/2005.14165.pdf#page=25), generate [cohesive stories](https://medium.com/@aidungeon/ai-dungeon-dragon-model-upgrade-7e8ea579abfe). You can even ask it to do system admin jobs in natural language and it will come up with shell commands and execute them, like a seasoned sysadmin. 

![Natural Language Shell](/images/2020-09-26-nlsh.png)


## Learning how to learn
One of the amazing aspects of the GPT-3 model is that it doesn't need any task-specific fine-tuning and yet achieves decent results on many of the Natural Language Processing (NLP) benchmarks and tasks. OpenAI's claim is that if an NLP model is sufficiently complex and trained on large volume of data, it can learn to do a new task only by looking at few examples prompts i.e, the model is capable of learning new tasks on the go and it has learned to [learn](https://www.gwern.net/newsletter/2020/05#meta-learning). In the chart below, you can see how well the GPT-3 175B curve is propped up, just by inputting a few examples.

![Meta-learning](/images/2020-09-26-meta-learning.png)

The ability to learn is one of the defining characteristics of Artificial General Intelligence (AGI) and now you can understand why GPT-3 is generating the buzz.

## The unreasonable effectiveness of data
In 2009, Google's Peter Norvig wrote a [paper](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/35179.pdf) about the unreasonable effectiveness of data. GPT-3 seems to be the latest example of that. GPT-3 has no direct exposure to reality, except via a large corpus of text. Yet the knowledge imparted from this large volume of text allows GPT-3 to reason about the physical world as seen in the [example](https://www.lesswrong.com/posts/L5JSMZQvkBAx9MD5A/to-what-extent-is-gpt-3-capable-of-reasoning) below 

![Reasoning about the physical world](/images/2020-09-26-reasoning.png)

In fact, GPT-3 has also demonstrated surprising ability outside the traditional NLP domain. It can do certain non-linguistic tasks like simple arithmetics. This begs the question, whether language alone is sufficient to form an understanding of reality? We use language to describe our world. So a relation between words should correspond to a relation between the real world entities represented by those words. Some [reason](https://deponysum.com/2020/01/16/recent-advances-in-natural-language-processing-some-woolly-speculations/) that ML models are transitive (i.e, if X models Y and Y models Z, then X models Z) and since language itself is an approximate model of the world, a language model should be an approximate representation of the world. 

## The unreasonable effectiveness of Scale
Another surprising outcome of GPT-3 is that the performance has not tapered as the model got more complex. When GPT-2 got released most people speculated that we will have diminishing returns on further scaling up the model. But that hasn't happened with GPT-3. With a more complex model, GPT-3 has shown big improvements in its performance and seems to get better at learning new tasks (see the widening gap between zero-shot and few-shot benchmarks).

As recently as last year, training a model with 175B seemed far off into the future. The Human brain is estimated to contain around 100 trillion neurons, how long before we reach that figure and what would AI look like as it approaches the figure? 

![Scaling hypothesis](/images/2020-09-26-scaling-hypothesis.png)

Now I agree that I am playing to the gallery here and being sensational. We cannot compare ML neurons with biological neurons despite the fact that historically the former was inspired by the latter. They are fundamentally quite different. A CNN model can do object detection (in fact better than us) but it doesn't need to have the same structure as our brain to do so.

And not everyone buys the scaling hypothesis. Detractors like Marcus claim that just because we know how to stack ladders doesn't mean that we can build ladders to the moon. The argument is fundamentally flawed. In the case of ladders to the moon, we know the governing rules and the limits of possibility. But we don't know enough about intelligence to confidently say that such an impervious chasm exists between a statistical model and causal reasoning. 


## What do the critics say?
### It is not as good as SOTA
To be correct, GPT-3 is not the best model out there. On most NLP tasks & benchmarks, SOTA performs better than GPT-3 (i.e SuperGLUE, CoQA, Winograd, to name a few). But there are other tasks in which it beats fine-tuned SOTA (i.e PhysicalQA, LAMBADA, Penn Tree Bank). But that doesn't matter.

1. Most of the SOTA algorithms are fine-tuned for specific tasks, requiring task-specific datasets and fine-tuning. GPT-3 can do these tasks without large supervised datasets, similar to how humans learn language tasks (hence the suggestions of general intelligence). 
2. Beating SOTA is not the hallmark of general intelligence. As it is, SOTA already performs better than humans on many specific tasks like object recognition, mastering games like Chess and Go. But we don’t let that belittle our intelligence just on that count. In a sense, General intelligence always has to underfit to have wider applicability. 
	
### It is just an autocomplete
Some critics say that GPT-3 is just a sophisticated text prediction engine[1]. It doesn't understand what those words mean. But I think we don't know enough to confidently define what it means to understand something[5]. Generations of philosophers have toiled at this task and not come to a conclusion.

Let us say our brain is a sophisticated lookup dictionary populated by past experiences and culturally accumulated knowledge. Suppose a non-human entity possesses a similar dictionary but populated in a different route (by training on text corpus or other means). Can it claim to have an understanding? This was the crux of the argument laid down by Searle in his Chinese room thought experiment[4]. Searle claims that looking up a dictionary doesn't represent understanding, but there are many who don't agree. 

When even philosophers aren't in agreement in terms of what constitutes understanding, it is premature to claim that the model hasn't understood anything. Our intuitions about intelligence, understanding, and meaning are too imprecise to make any such claims. 

### It has already seen the data it is predicting on
GPT-3 has also a more serious allegation of being a pattern matcher regurgitating the texts fed into it. For example, Yannic Kilcher in his video[2] suspects that it can do arithmetic predictions because the model is likely to have seen the same data in the training dataset. OpenAI team claims to have done sufficient deduplication to remove the testing dataset from the training data[6]. But since their input data is too huge, the deduplication is optimistic.

A few days back I came across an implementation of GPT by Karpathy and his mini model was trained exclusively on synthetic data. And it was able to do 2 digit arithmetic with a clear separation between the training set and validation set. So it is possible for a language model to learn the mechanics of arithmetics, albeit limited to 2 digits. Thus it is conceivable that this can be expanded upon in the future.


## Conclusion
The whole point of the article is not to make the grand claim that GPT-3 model is an AGI or that it conclusively proves that AGI is possible. However, there are a few noteworthy conclusions to draw from this:
1. NLP models can be a shortcut to AGI as they have the ability to indirectly model the physical world
2. We haven't hit the wall in terms of diminishing returns from a more complex model. It will be interesting to explore whether such walls exist.
3. At higher model complexities, interesting behaviors seem to emerge such as the ability to learn new tasks

The year 2018 has been called the [ImageNet moment](https://thegradient.pub/nlp-imagenet/) for NLP and we can see why. The amount of progress made in NLP during the last couple of years and the continued investments in the domain is staggering. For millennia philosophers used to construct thought experiments and argue about consciousness, the nature of knowledge, innateness vs blank slate etc., Now technology is advancing this discourse at a pace never seen before. Whichever side of the fence one sits on, the world waits with bated breath as the story unfolds.
