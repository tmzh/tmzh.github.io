---
author: tmzh
categories:
- Generative AI 
comments: true
date: "2023-05-16T12:00:00Z"
image: /images/2023-05-16-stable-diffusion-art.png
slug: 2023-05-16-paint-like-bob-ross-using-stable-diffusion
tags:
- stable-diffusion
- art
title: "Creating a Bob Ross painting from rough sketch using Stable diffusion"
---

## Introduction
When it comes to creating artwork, there are many Generative AI tools, but my favorite is [Stable Diffusion](https://github.com/CompVis/stable-diffusion). Since it is open source, a variety of tools and usecases have been built around Stable diffusion. It can train your own model, finetune existing models, or use countless other models trained and hosted by others. And it can run on most consumer hardware with atleast 8 GB VRAM. 

One of my favorite use case is to render rough sketches into much prettier artwork. In this post we will see how to setup realtime rendering so that we have an interactive drawing experience. See below to see how quickly we can come up with a decent painting. 

<video width=80% autoplay="true" loop="true" src="/images/2023-05-16-stable-diffusion-art.mp4"> </video>

All this was done in 2 minutes, with a bit more skill and persistence it is possible to extract a more beautiful artwork as per your want. 

![Mountain](/images/2023-05-16-stable-diffusion-art.png)

What I like about this approach is that it is interactive - you don't go in with a pre-conceived notion. You take your artwork to where the canvas (Stable Diffusion in this case) leads you. 

## Instructions
For this, I made use of the excellent [Stable Diffusion web UI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) project by AUTOMATIC1111. 

### Setup

1. Install Stable Diffusion Web UI by following the [instructions](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs#windows-method-1) in the project page. If you are on Windows, for least hassle I would suggest running this project directly on Windows rather than on WSL2. Navigating CUDA runtime dependencies across Windows + linux is not something I would wish upon anyone.
2. We would also need Jupyter notebook to call Stable Diffusion Web UI API. Add the `notebook` package to the bottom of `requirements.txt` present at the project root. 
3. Next we need to [enable](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/API) API support. For example, if you're using Windows, edit the `webui-user.bat` file and add --api --api-log to the COMMANDLINE_ARGS line:
```bat
Rem Run jupyter notebook
start jupyter notebook --no-browser

Rem Stable diffusion webui
call webui.bat
```
4. Run the modified execution script. For example, on Windows, run `webui-user.bat`. It should launch two CMD windows, one to launch Stable diffusion web UI and one to launch Jupyter notebook
5. Verify that Stable Diffusion Web UI is running by visiting http://localhost:7860/ in your browser.
6. When you are done, remember to close both the CMD windows.

### Drawing

Remember to save the mspaint file periodically. If you are using 
