---
author: tmzh
categories:
- Artificial Intelligence
comments: true
date: "2023-03-15T12:00:00Z"
image: /images/2020-09-26-meta-learning.png
slug: 2023-03-15-gpt-4-stable-diffusion-and-beyond
tags:
- chatGPT
- philosophy
title: "GPT-4, Stable Diffusion, and Beyond: How Generative AI Will Shape Human Society"
---
In 2021, I wrote about GPT-3 model. About a year later, OpenAI released ChatGPT which was based on GPT-3 but trained using Reinforcement Learning from Human Feedback (RLHF). Now that GPT-4 has only been out for a day, it is already seeing incredible applications being built with it such as [turning sketches](https://twitter.com/blader/status/1635792905628712960) into functional apps, creating [personal tutors](https://www.youtube.com/watch?v=yEgHrxvLsz0), turning wikipedia articles into [tome](https://twitter.com/keithpeiris/status/1635744012081729536) and [more](https://twitter.com/rowancheung/status/1636017917136367617).

And not just GPT based models, StableDiffusion and Dall-E are also pushing the boundaries of art, creating stunning visuals from mere textual descriptions. Professional ad agencies, too, are exploring how to use AI, as seen in this [Coca Cola ad](https://youtu.be/951q69P0La) and this [Crocs ad](https://twitter.com/nonmayorpete/status/163516240862815846) which apparently took only 28 minutes to create from scratch.

<figure>
    <img src="/images/2023-03-15-gpt-4-performance.png"
         alt="GPT-4 performance"
         width="80%">
    <figcaption><i>The newly released GPT-4 exhibits human-level performance on a variety of common and professional academic exams. Source: <a href="https://cdn.openai.com/papers/gpt-4.pdf">OpenAI GPT-4 Technical Report</a></i></figcaption>
</figure>

Suddenly the pace of advancements in AI has shifted from a slow trickle to a deluge. And some may even say out of control. A staple fear about hyper intelligence has been that a recursively self-improving AI would have no discernible limit to the extent of intelligence it could attain. However, I think these are speculations given how little we understand about the inner-workings of AI (more on this later). We tend to project our apprehensions and anthropocentric tendencies onto AI and assume that it would act as a sentient being would. Rather than worrying about future possibilities with superhuman intelligence, the immediate concern should be that AI models are already good enough to disrupt human society.

## Impact on Society
Human society has always evolved in a dynamic equilibrium with technology it posseses. Every major technological revolution has been accompanied by a sociological inflection point, as society adjusts adjusts not just to the novelty of new inventions but revises its implicit assumptions and mechanisms for functioning. 

The cognitive revolution (language & arts) that laid the foundation for civilization by bringing people together, also gave us myths, hero worship and kings. It took us millennia for society at large to loosen the shackles of such institutions. Similarly, the invention of the printing press brought about a new era of mass communication, but also led to the spread of propaganda and the manipulation of public opinion. With the rise of radio and television came new forms of propaganda and disinformation. With the internet and social media, we still haven't figured out coping mechanisms for fake news and large scale manipulation of public opinion.

## Homogeneous models brings outsized risks
Generative AI brings with it all of the above risks, but on a scale and reach never imagined before. Almost all large scale models are derived from very few foundational models, further centralizing the risks and power. When I wrote about GPT-3, three things caught my attention:

* Effectiveness of scale
* Languages can be a model of physical world 
* Emergent behaviors leading to Zero to few shot learning

However I only thought of GPT-3 as a precursor for things to come. But recent products like ChatGPT that are built on GPT-3 has shown that GPT-3 and similar Large Language Models (LLM) are already good enough. 

> "In place of a circumspect, potentially biased human, we will have an infallible, impartial arbitrator telling us what is true"

And good enough models are easy to use, so their adoption will only continue to grow. As people become more familiar with these tools, they will begin to trust its judgment automatically. In place of a circumspect, potentially biased human, we will have an infallible, impartial arbitrator telling us what is true. But how can we know how it made its decision? 

## Why we can never truly understand AI
The performance of a LLM model comes from their emergent behaviors rather than explicit instruction. In the [past](https://arxiv.org/pdf/2108.07258.pdf#subsection.1.3) researchers have warned that, "Despite their deployment into real world, these models are very much research prototypes that are poorly understood". Not much has changed since then. Furthermore the resources required for training such large scale models keeps it out of reach for many; commercial incentives lend very few reasons for companies to make their models transparent or to attend to any of these social externalities arising from their obscurity. 

## Impact on Culture 
Large scale models are largely homogeneous, derived from very few foundation models; training data is lopsided and only represents a tiny percentage of languages. The embedded social and political factors in these models leads to entrenchment of pre-dominant value system and undermines plurality. Anyone who has ever tried to translate across language trees can attest to loss of meaning outside certain cultural context. Prevalence of homogeneous LLMs in society can lead to a cultural conformity where individual expression and differences are lost on all levels from the individual to society.

## What does it mean for job market?
There is always a concern that the AI systems will replace human workers in a variety of industries, leading to job losses and economic disruption. Fears of job losses due to technology changes is not new. In the early 19th century, textile workers in England formed the Luddite movement to protest against the introduction of new textile technologies that threatened their jobs. Their paranoia turned out to be misguided as new technologies led to industry growth, creating new jobs and increasing productivity. However, it is also important to acknowledge that while new technologies can bring in new avenues of employment there will be displacements in existing employment patterns. It is important for us as individuals and society to be prepared for these changes and adapt accordingly.

## Death of art or reincarnation of art?
For AI generative art, the main concern is regarding the risk of plagiarism. This is kind of a Ship of theseus problem- at what point of does the art becomes something else? How do you distinguish between contribution that are uniquely yours? Irrespective of how we address the plagiarism problem, I don't see AI generated art diminishing the need or impact of artists. Art in its purest meaning, is a counterpoint to the current current society. If everyone is outputting StableDiffusion artwork, certain predictable patterns begins to emerge and it can quickly feel soulless. Same can be said of ChatGPT or any AI derived work. Folks have already [noted](https://twitter.com/bildoperationen/status/1633082030178050048) that in StableDiffusion "the default mode of these images is to shine and sparkle, as if illuminated from within". On the other hand, a mainstream art that mimics status quo will be under threat. Pop artists may be replaced by prompt engineers or there may be new generation of hybrid artists who would wield AI tools as a paintbrush to produce unique forms of artwork.

<figure>
    <img src="/images/2023-03-15-surrealist-art-stable-diffusion.png"
         witdth="50%"
         alt="Surrealist art by Stable Diffusion">
    <figcaption>Surrealist art by Stable Diffusion</figcaption>
</figure>


## What do we need to do?
In order to tackle the potential hazards of AI, we have to channel our innate ability to adapt. As much as we'd like to think we're in charge of the progress of AI, we can't possibly anticipate all the potential consequences and risks that come with AI and expect to control it with a set of rules and regulations. Therefore, it is imperative that we approach the development and integration of AI with humility, acknowledging the complexity and unpredictability of the technology, and actively seeking to examine, understand and manage its potential impact on society and individual lives.
