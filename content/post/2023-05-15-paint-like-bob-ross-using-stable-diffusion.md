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
title: "Create beautiful paintings from rough sketches using Stable diffusion"
---

## Introduction
When it comes to creating artwork, there are many Generative AI tools, but my favorite is [Stable Diffusion](https://github.com/CompVis/stable-diffusion). Since it is open source, a variety of tools and usecases have been built around Stable diffusion. With it, you can train your own model, fine-tune existing models, or use countless other models trained and hosted by others. 

But one of my favorite use case is to render rough sketches into much prettier artwork. In this post we will see how to setup real-time rendering so that we have an interactive drawing experience. See below to see how quickly we can come up with a decent painting. 

<video width=80% autoplay="true" loop="true" src="/images/2023-05-16-stable-diffusion-art.mp4"> </video>

This was just a rough  draft done in 2 minutes, with a bit more skill and persistence it is possible to extract a more beautiful artwork as per your want. 

![Mountain](/images/2023-05-16-stable-diffusion-art.png)

What I like about this approach is that it is interactive - you don't go in with a pre-conceived notion. You take your artwork to where the canvas (Stable Diffusion in this case) leads you. Next we will seehow to set it up on your own.

## Instructions
For this, I made use of the excellent [Stable Diffusion web UI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) project by AUTOMATIC1111. The Web UI also supports an API mode which we will use to generate images using `img2img`  of Stable Diffusion. `img2img` uses the weights from Stable Diffusion to generate new images from an input image using [StableDiffusionImg2ImgPipeline](https://replicate.com/stability-ai/stable-diffusion-img2img) from diffusers. 

### Setup
1. Install Stable Diffusion Web UI by following the [instructions](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs#windows-method-1) in the project page. If you are on Windows, I would recommend running this directly on Windows rather than on WSL2. Navigating CUDA runtime dependencies across Windows + linux is not worth the time.
2. We would also need Jupyter notebook and webuiapi packages to call Stable Diffusion Web UI API. At launch, AUTOMATIC1111 always sets up a VirtualEnv and pip installs the packages from `requirements.txt`. So add the packages `notebook` and `webuiapi` to the bottom of `requirements.txt` present at the project root. Jupyter notebook package will get installed at the next launch. 
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
1. Open a new notebook and add the following code:
```python
import webuiapi  
from IPython.display import clear_output
import os
import time
from pathlib import Path
from PIL import Image

# create API client
api = webuiapi.WebUIApi(sampler='Euler a', steps=20)

file_base = "base.png"
file_prompt = "prompt.txt"
f_base_new = 0
f_prompt_new = 0 
```

2. Add your desired prompt text to the file `prompt.txt`. In my example above, I used a very generic prompt like below:
```
an oil painting of a scenery by bob ross
```


3. Create a PNG file called `base.png` using MS Paint or any of your favorite image editing tool and save it at the  base path.

4. Run this code from a new cell block in your notebook. It will monitor you files for changes periodically andcall Stable Diffusion web UI API to generate new images based on your updated drawings.

```python
while True:
    f_base = os.path.getmtime(file_base)
    f_prompt = os.path.getmtime(file_prompt)
    if f_base == f_base_new and f_prompt==f_prompt_new:
        time.sleep(0.5)
    else:
        f_base_new = f_base
        f_prompt_new = f_prompt
        prompt_txt = Path(file_prompt).read_text()
        with Image.open(file_base) as im:
            result2 = api.img2img(
                images=[im], 
                prompt=prompt_txt, 
                negative_prompt = "poorly drawn, photorealistic, watermark, logo, text, bad anatomy, missing fingers,missing body part,mangled hands",
                steps=40,
                seed=-1,
                styles=[],
                cfg_scale=7, 
                width=512,
                height=724,
                denoising_strength=0.6)
            clear_output(wait=True)
            display(result2.image)
```
5. If you are using a tool like Photoshop, turn on the autosave. If not remember to save your file periodically.
