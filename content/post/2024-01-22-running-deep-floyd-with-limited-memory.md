---
author: tmzh
categories:
- Generative AI 
comments: true
date: "2024-01-22T12:00:00Z"
slug: 2024-01-22-generating-visual-illusions-using-generative-ai-in-memory-constrained-hardware
tags:
- deep_floyd
- generative_ai

title: "Generating Visual Illusions Using Generative AI"

mathjax: true
autoCollapseToc: true
---

# Introduction
Recently I came across a very interesting project called Visual Anagrams. In it, the authors proposes a very clever approach to generate multi-view optical illusions by utilizing text-to-image diffusion models. The image changes appearance under various transformations such as flips, rotations, and pixel permutations. 

It uses a generative model called DeepFloyd IF. IF is a pixel-based text-to-image generation model and was released in late April 2023 by DeepFloyd. This takes a different approach to Stable diffusion, by operating in pixel space rather than performing denoising in a latent space. This approach allows IF to generate images with high-frequency details, as well as things like generating legible text, where Stable Diffusion struggles.

However, these advantages come at the cost of a significantly higher number of parameters. The text encoder, IF's text-to-image UNet, and IF's upscaler UNet have 4.5 billion, 4.3 billion, and 1.2 billion parameters, respectively. In contrast, Stable Diffusion 2.1 has only 400 million parameters for the text encoder and 900 million parameters for the UNet. The official demo for this repo, recommends to use A100 GPU.

Fortunately, it is possible to run this on consumer hardware or even Google colab free. This is made possible by the fact that In this blog post, I will discuss methods to run this in a consumer grade GPU or Google colab free


# References
https://colab.research.google.com/github/huggingface/notebooks/blob/main/diffusers/deepfloyd_if_free_tier_google_colab.ipynb#scrollTo=YVmG9-a8-XyI