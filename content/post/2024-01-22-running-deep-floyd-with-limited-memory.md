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
Recently I came across a very interesting project called Visual Anagrams. In it, the authors proposes a very clever approach to generate multi-view optical illusions by utilizing text-to-image diffusion models that changes appearance under various transformations such as flips, rotations, and pixel permutations. 

Optical illusions such as images that show different subjects under different orientation, ambigrams, etc., Naturally I was quite excited to come across a project called `Visual Anagrams` that can generate illusions using generative AI. The project introduces a clever method for generating multi-view optical illusions using text-to-image diffusion models. The generated images changes in appearance under different transformations such as flips, rotations, and pixel permutations.

It uses a generative model called DeepFloyd IF. IF is a pixel-based text-to-image generation model and was released in late April 2023 by DeepFloyd. This takes a different approach to Stable diffusion, by operating in pixel space rather than performing denoising in a latent space. This approach allows IF to generate images with high-frequency details, as well as things like generating legible text, where Stable Diffusion struggles.

However, these advantages come at the cost of a significantly higher number of parameters. The text encoder, IF's text-to-image UNet, and IF's upscaler UNet have 4.5 billion, 4.3 billion, and 1.2 billion parameters, respectively. In contrast, Stable Diffusion 2.1 has only 400 million parameters for the text encoder and 900 million parameters for the UNet. Running this model in full float32 precision would require at least 37GB memory. 

T5-XXL Text Encoder: 19GB
Stage 1 UNet: 17.2 GB
Stage 2 UNet: 4.97 GB


<figure>
    <img src="/images/2024-01-28-deep-floyd-if-scheme.jpg"
         alt="DeepFloyd-IF model card"
         width="80%">
    <figcaption><i>source: <a href="https://huggingface.co/DeepFloyd/IF-I-XL-v1.0">DeepFloyd-IF model card</a>
</i></figcaption>
</figure>

Fortunately, it is possible to run this model on consumer hardware or even on Google Colab for free. The Diffusers API from HuggingFace allows us to load individual components modularly, reducing the memory requirements by loading components selectively.

# Inference process

## Import and setup what we need


## Load TextEncoder Model
The TextEncoder model used in DeepFloyd-IF is `T5`. To begin, we load this `T5` model in half-precision (fp16) and utilize the `device_map` flag to enable transformers to offload model layers to either CPU or disk. This reduces the memory requirements by more than half. For more information on device_map, refer to the transformers [documentation](https://huggingface.co/docs/accelerate/usage_guides/big_modeling#designing-a-device-map).

```python
from transformers import T5EncoderModel

text_encoder = T5EncoderModel.from_pretrained(
    "DeepFloyd/IF-I-L-v1.0",
    subfolder="text_encoder",
    device_map="auto",
    variant="fp16",
    torch_dtype=torch.float16,
)
```

### Addendum
To further reduce memory utilization, we can also load the same `T5` model using 8-bit quantization. Transformers directly supports bitsandbytes through the load_in_8bit flag. Set the variant="8bit" flag to download pre-quantized weights. This allows loading the text encoders in as little as 8GB of memory.

## Create text embeddings
Next, we need to generate embeddings for the two prompts that describe the visual illusions. DiffusionPipeline from HuggingFace Diffusers library contains methods to load models necessary for running diffusion networks. We can override the individual models used by changing the keyword arguments to `from_pretrained`. In this case, we pass the previously instantiated `text_encoder` for the text_encoder argument and `None` for the unet argument to avoid loading the UNet into memory, enabling us to load only the necessary models to run the text embedding portion of the diffusion process.

```python
from diffusers import DiffusionPipeline

pipe = DiffusionPipeline.from_pretrained(
    "DeepFloyd/IF-I-L-v1.0",
    text_encoder=text_encoder, # pass the previously instantiated text encoder
    unet=None
)
```
We can now use this pipeline to encode the two prompts. The prompts need to be concatenated for the illusion.

```python
# Feel free to change me:
prompts = [
      'an oil painting of a deer',
      'an oil painting of a waterfall',
    ]

# Embed prompts using the T5 model
prompt_embeds = [pipe.encode_prompt(prompt) for prompt in prompts]
prompt_embeds, negative_prompt_embeds = zip(*prompt_embeds)
prompt_embeds = torch.cat(prompt_embeds)
negative_prompt_embeds = torch.cat(negative_prompt_embeds)  # These are just null embeds
``` 

Flush to free memory for the next stages.

```python
import gc

def flush():
    gc.collect()
    torch.cuda.empty_cache()

del text_encoder
del pipe
flush()
```

## Main Diffusion Process
With the available GPU memory, we can reload the DiffusionPipeline using only the UNet to execute the main diffusion process. Note that once again we are loading the weights in 16-bit floating point format using the variant and torch_dtype keyword arguments.

```python
from diffusers import DiffusionPipeline

stage_1 = DiffusionPipeline.from_pretrained(
    "DeepFloyd/IF-I-L-v1.0",
    text_encoder=None,
    variant="fp16",
    torch_dtype=torch.float16,
)

stage_1.enable_model_cpu_offload()
stage_1.to('cuda')
```

```python
stage_2 = DiffusionPipeline.from_pretrained(
                "DeepFloyd/IF-II-L-v1.0",
                text_encoder=None,
                variant="fp16",
                torch_dtype=torch.float16,
              )
stage_2.enable_model_cpu_offload()
stage_2.to('cuda')
```

## Generate Image
Choose one of the view transformations supported by the Visual Anagrams repository.

```python
# UNCOMMENT ONE OF THESE

# views = get_views(['identity', 'rotate_180'])
# views = get_views(['identity', 'rotate_cw'])
# views = get_views(['identity', 'flip'])
# views = get_views(['identity', 'jigsaw'])
views = get_views(['identity', 'negate'])
# views = get_views(['identity', 'skew'])
# views = get_views(['identity', 'patch_permute'])
# views = get_views(['identity', 'pixel_permute'])
# views = get_views(['identity', 'inner_circle'])
```


## Results
Now, we can generate illusions by denoising all views simultaneously. The `sample_stage_1` function accomplishes this and produces a $64 \times 64$ image. The `sample_stage_2` function upsamples the resulting image while denoising all views, generating a $256 \times 256$ image. 

```python
image_64 = sample_stage_1(stage_1,
                          prompt_embeds,
                          negative_prompt_embeds,
                          views,
                          num_inference_steps=40,
                          guidance_scale=10.0,
                          reduction='mean',
                          generator=None)
mp.show_images([im_to_np(view.view(image_64[0])) for view in views])
```


```python
image = sample_stage_2(stage_2,
                       image_64,
                       prompt_embeds,
                       negative_prompt_embeds,
                       views,
                       num_inference_steps=30,
                       guidance_scale=10.0,
                       reduction='mean',
                       noise_level=50,
                       generator=None)
mp.show_images([im_to_np(view.view(image[0])) for view in views])
```
````

# Conclusion

![animation](/images/2024-01-28-waterfall.deer.mp4-output.gif)


# References
https://colab.research.google.com/github/huggingface/notebooks/blob/main/diffusers/deepfloyd_if_free_tier_google_colab.ipynb#scrollTo=YVmG9-a8-XyI