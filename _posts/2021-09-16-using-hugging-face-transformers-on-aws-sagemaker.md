---
author: tmzh
comments: true
date: 2021-09-16 12:00:00+08:00
layout: post
slug: 2021-09-16-using-hugging-face-transformers-on-aws-sagemaker
title: Using Hugging Face Transformers on AWS Sagemaker
categories:
- Machine Learning
tags:
- aws 
- huggingface
- transformers
image: https://huggingface.co/blog/assets/17_the_partnership_amazon_sagemaker_and_hugging_face/cover.png 
---

In July 2021, AWS and Hugging Face announced collaboration to make Hugging Face a first party framework within SageMaker. Earlier, you had to use PyTorch container and install packages manually to do this. With the new Hugging Face Deep Learning Containers (DLC) availabe in Amazon SageMaker, the process of training and deploying models is greatly simplified.

In this post, we will go through a high level overview of Hugging Face Transformers library before looking at how to use the newly announced Hugging Face DLCs within Sagemaker.

<!--more-->

# Introduction to Hugging Face Transformers
The Hugging Face Transformers is a library that makes it easy to use NLP models. It allows developers to leverage hundreds of pretrained models for Natural Language Understanding (NLU) tasks as well as making it simple to train new transformer models. The API of this library is based around 3 broad classes:

1. **Model** - PyTorch or Keras models that we can use in training loop or for prediction
2. **Configuration** - Stores all the configuration required to build a model
3. **Tokenizer** - Stores the vocabulary and methods for encoding and decoding between strings and tokens

The transformers library offers a simple abstraction over the above 3 models using the `pipeline` method. This is the simplest way to get started using the pre-trained models from model hub.

```python
classifier = pipeline('sentiment-analysis', model="distilbert-base-uncased-finetuned-sst-2-english")
classifier('We are very happy to show you the 🤗 Transformers library.')
```

The first argument is a Hugging Face NLP task, in this case it is `sentiment analysis`. Some of the supported tasks are:
* Sequence Classification
* Sentiment Analysis
* Question Answering
* Language Modelling
* Text Generation
* Named Entity Recognition (NER)
* Summarization
* Translation

See [here](https://huggingface.co/transformers/task_summary.html#) for an overview of the tasks supported by the library.

Under the hood, calling the pipeline method roughly covers the following steps:

```python
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from torch import nn

# download the model and tokenizer
model_name = "distilbert-base-uncased-finetuned-sst-2-english"
model = AutoModelForSequenceClassification.from_pretrained(model_name)
tokenizer = AutoTokenizer.from_pretrained(model_name)

# tokenize the input
batch = tokenizer(["The Hugging Face Transformers library is amazing"], 
                  padding=True, truncation=True, max_length=512, 
                  return_tensors="pt")

# run predictions
outputs = model(**batch) # returns logits for classification task

# get predictions
predictions = nn.functional.softmax(outputs.logits, dim=-1)
print(predictions)
```

The downloaded models are stored in `~/.cache/huggingface/transformers`. 

Here is the process:

* Instantiate `AutoTokenizer` to download the tokenizer associated to the model we picked and instantiate it. 
* Use `AutoModelForSequenceClassification` to download the model itself. 
* Build a sequence from the input sentence, using the correct model-specific separators token type ids and attention masks 
* Pass this sequence through the model to get the logits
* Compute the softmax of the result to get probabilities over the classes

## Tokenizer

Tokenizer's job is to preprocess your text into tokens suitable for training or inference. Tokens can be a word (`predict`) or a subword (`##ly`). For example, a tokenizer may split the word `Transformers` into (`transform`, `##ers`) so that the model's vocabulary doesn't explode. The tokenizer can also take care of other pre-processing tasks such as normalizing cases and punctuations.

The tokenization logic is tied to the model we use. That is why in our example we derived the model and tokenizer from the same model name. The `AutoTokenizer` and `AutoModelForxxx` classes ensures that the tokenizers and models are paired correctly.

When we apply a tokenizer to an input text, it returns a dictionary containing `ids` of the tokens and `attention mask`. `ids` are the numerical representation of tokens. To learn about attention mask and other details related to Tokenizers refer [here](https://huggingface.co/transformers/tokenizer_summary.html).

```python
>>> tokenizer("We are very happy to show you the 🤗 Transformers library.")
{'input_ids': [101, 2057, 2024, 2200, 3407, 2000, 2265, 2017, 1996, 100, 19081, 3075, 1012, 102], 'attention_mask': [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]}
```

Note that the tokens also consists of some special tokens which encodes special meaning in the sentences. They differ from model to model. In our model, they are:

```python
>>> tokenizer.special_tokens_map
{'cls_token': '[CLS]',
 'mask_token': '[MASK]',
 'pad_token': '[PAD]',
 'sep_token': '[SEP]',
 'unk_token': '[UNK]'}
 ```

 ## Hugging Face Model
 Once the input text has been  preprocessed by the tokenizer, we can pass it directly to the model

 ```python
 outputs = model(**batch)
 ```

The contents of the model output depends on the task. For [SequenceClassification](https://huggingface.co/transformers/main_classes/output.html#transformers.modeling_outputs.SequenceClassifierOutput) we get back `logit`, an optional `loss`, `hidden_states` and `attentions` attributes
The `model` class can also be used to do transfer learning for custom NLP tasks. The Transformers library provides a `Trainer` API that takes this model as input, extracts the pre-trained weights and fine tunes it.

The `model` class can also be used to do transfer learning for custom NLP tasks. The Transformers library provides a `Trainer` API that takes this model as input, extracts the pre-trained weights and fine tunes it.

```python
from transformers import Trainer

# Build the trainer class
trainer = Trainer(
    model=model, 
    args=training_args, 
    train_dataset=small_train_dataset, 
    eval_dataset=small_eval_dataset
)

# Fine-tune the model
trainer.train()
```

This covers a high level overview of the Hugging Face Transformers library. Next we will see how to use the library along with Sagemaker.

# Using Hugging Face on Sagemaker
Hugging Face in collaboration with AWS released Sagemaker Hugging Face Deep Learning Containers (DLCs) that makes it easy to train and deploy Hugging Face models using AWS platform. 

## Running a Training job

### Preparing a training script
First we need to prepare the training script. This would be similar to any Transformers training script. A minimal training script would look like this:

```python
%%writefile train.py
from transformers import AutoModelForSequenceClassification, Trainer, TrainingArguments, AutoTokenizer
from sklearn.metrics import accuracy_score, precision_recall_fscore_support
from datasets import load_from_disk
import random
import logging
import sys
import argparse
import os
import torch

if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    # Data, model, and output directories
    parser.add_argument("--model_dir", type=str, default=os.environ["SM_MODEL_DIR"])
    parser.add_argument("--training_dir", type=str, default=os.environ["SM_CHANNEL_TRAIN"])
    parser.add_argument("--test_dir", type=str, default=os.environ["SM_CHANNEL_TEST"])

    # load datasets
    train_dataset = load_from_disk(args.training_dir)
    test_dataset = load_from_disk(args.test_dir)

    # download model from model hub
    model_name = "distilbert-base-uncased-finetuned-sst-2-english"
    model = AutoModelForSequenceClassification.from_pretrained(model_name)
    tokenizer = AutoTokenizer.from_pretrained(model_name)

    # define training args
    training_args = TrainingArguments(
        output_dir=args.model_dir
    )

    # create Trainer instance
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=test_dataset,
        tokenizer=tokenizer,
    )

    # train model
    trainer.train()
    
    # save the model
    trainer.save_model(args.model_dir)
```

For a more complete version of the script covering model evaluation, logging and additional training arguments, refer to this [sample script](https://github.com/huggingface/notebooks/blob/9664c8b62e38083952b849da8912af13a35312b0/sagemaker/01_getting_started_pytorch/scripts/train.py).

As with any Sagemaker training job, we need to ensure that this script reads data from DLC's data input directory and saves the model to model directory. The following lines of codes takes care of this.

```python
# loading datasets
parser.add_argument("--training_dir", type=str, default=os.environ["SM_CHANNEL_TRAIN"])
parser.add_argument("--test_dir", type=str, default=os.environ["SM_CHANNEL_TEST"])

train_dataset = load_from_disk(args.training_dir)
test_dataset = load_from_disk(args.test_dir)

# storing models
trainer.save_model(args.model_dir)
```

### Run training using Hugging Face estimator

First we create a Hugging Face estimator which exposes methods similar to other Sagemaker Estimator. Note that the `entry_point` attribute matches the file name of our training script.

```python
from sagemaker.huggingface import HuggingFace


# hyperparameters, which are passed into the training job
hyperparameters={'epochs': 1,
                 'per_device_train_batch_size': 32,
                 'model_name_or_path': 'distilbert-base-uncased'
                 }

# create the Estimator
huggingface_estimator = HuggingFace(
        entry_point='train.py',
        instance_type='ml.p3.2xlarge',
        instance_count=1,
        role=role,
        transformers_version='4.4',
        pytorch_version='1.6',
        py_version='py36',
        hyperparameters = hyperparameters
)
```

Training is invoked by calling the `fit` method on `Hugging Face` Estimator.

```python
huggingface_estimator.fit(
  {'train': 's3://sagemaker-us-east-1-558105141721/samples/datasets/imdb/train',
   'test': 's3://sagemaker-us-east-1-558105141721/samples/datasets/imdb/test'}
)
```

The trained model is a tarball with all the resources needed for inference.

```
model.tar.gz/
|- pytroch_model.bin
|- vocab.txt
|- tokenizer_config.json
|- config.json
|- special_tokens_map.json
```

## Deploying the model for inference

Once the training is completed, we can deploy a `Hugging Face` model directly from the `Estimator` object. 

```python
# deploy model to SageMaker Inference
predictor = huggingface_estimator.deploy(initial_instance_count=1, instance_type="ml.m5.xlarge")
```

Alternatively, if we already have a completed training job, we can used its output model to deploy a new `Hugging Face` model and deploy it.

```python
from sagemaker.huggingface.model import HuggingFaceModel

# create Hugging Face Model Class
huggingface_model = HuggingFaceModel(
   model_data="s3://models/my-bert-model/model.tar.gz",  # path to your trained sagemaker model
   role=role, # iam role with permissions to create an Endpoint
   transformers_version="4.6", # transformers version used
   pytorch_version="1.7", # pytorch version used
   py_version='py36', # python version used
)

# deploy model to SageMaker Inference
predictor = huggingface_model.deploy(
   initial_instance_count=1,
   instance_type="ml.m5.xlarge"
)
```

We can use this deployed model to make predictions on input text. The default inference script in Hugging Face DLC expects a dictionary with `inputs` as key. For details on default input formats for various tasks refer to [this](https://huggingface.co/docs/sagemaker/inference#inference-toolkit---api-description).

```python
# example request. 
data = {
   "inputs": "Sagemaker SDK is easy to use"
}
# request
predictor.predict(data)
```

The above method makes use of Sagemaker SDK to invoke the model. Often in a production ML application, invocation is handled by calling [InvokeEndpoint API](https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_runtime_InvokeEndpoint.html) via boto3 or other SDK. A sample boto3 based invocation would look like below:

```python
import os
import io
import boto3
import json
import csv

# grab environment variables
ENDPOINT_NAME = os.environ['ENDPOINT_NAME']
runtime= boto3.client('runtime.sagemaker')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))
    
    data = json.loads(json.dumps(event))
    payload = data['data']
    print(payload)

data = {
   "inputs": "Sagemaker SDK is easy to use"
}

payload = json.dumps(data).encode('utf-8')
    
response = runtime.invoke_endpoint(EndpointName=ENDPOINT_NAME,
                                    ContentType='application/json',
                                    Body=payload)
```

Remember to delete the endpoint at the end of experiments.

```python
# delete endpoint
predictor.delete_endpoint()
```

### Advanced features of the Inference toolkit
We can also pass additional environment variables to the inference model that simplifies deployment.

```python
hub = {
  'HF_MODEL_ID':'distilbert-base-uncased-distilled-squad',
  'HF_TASK':'question-answering'
}
# create Hugging Face Model Class
huggingface_model = HuggingFaceModel(
    transformers_version='4.6',
    pytorch_version='1.7',
    py_version='py36',
    env=hub,
    
```

Here, `HF_TASK` variable defines the task for the Transformers pipeline and `HF_MODEL_ID` defines the model id to load from [huggingface.co/models](https://huggingface.co/models). For the full list of supported environment variables refer to [here](https://github.com/aws/sagemaker-huggingface-inference-toolkit#%EF%B8%8F-environment-variables).

### Customizing Inference script

When creating an inference model, we can specify use defined code/modules that allows us to customize the inference process. 

For example, here is a barebones inference script which we will call `inference.py`:

```python
from sagemaker_huggingface_inference_toolkit.transformers_utils import (
    _is_gpu_available,
    get_pipeline,
)
from sagemaker_huggingface_inference_toolkit import decoder_encoder


if _is_gpu_available():
  device = int(self.context.system_properties.get("gpu_id"))
else:
  device = -1

def load_fn(model_dir):
  # gets pipeline from task tag
  hf_pipeline = get_pipeline(task='sentiment-analysis', 
                             model_dir=model_dir, 
                             device=device)
  return hf_pipeline

def transform_fn(self, model, input_data, content_type, accept):
  processed_data = decoder_encoder.decode(input_data, content_type)
  predictions = model(processed_data['my_custom_input']) # Our custom input format
  response = decoder_encoder.encode(predictions, accept)
  return response
```

To use this script, we need to place it under a source directory along with any additional files required.

```
|- source/
  |- inference.py
  |- requirements.txt 
```

Next when we create the `Hugging FaceModel` we need to set the `source_dir` and `entry_point` attribute. These attributes are derived from the [Sagemaker Estimator Framework](https://sagemaker.readthedocs.io/en/stable/api/training/estimators.html#sagemaker.estimator.Framework) so they are available under all Frameworks.

```python
huggingface_model = HuggingFaceModel(
   model_data="s3://models/my-bert-model/model.tar.gz", 
   source_dir='source',  #relative path to current directory of calling script
   entry_point='inference.py' #name of the inference script under the source dir
   role=role, 
   transformers_version="4.6", 
   pytorch_version="1.7", 
   py_version='py36', 
)
```

This has the effect of setting the environment variables `SAGEMAKER_SUBMIT_DIRECTORY` to `source` and `SAGEMAKER_PROGRAM` to `inference.py` on the inference model. The inference model also has the files packaged with the following directory structure:

```
model.tar.gz/
|- pytroch_model.bin
|- ....
|- code/
  |- inference.py
  |- requirements.txt 
```

Now when we deploy the model, we can pass custom inputs to it.

```python
# deploy model to SageMaker Inference
predictor = huggingface_model.deploy(
   initial_instance_count=1,
   instance_type="ml.m5.xlarge"
)

# example request. 
data = {
   "my_custom_input": "The Hugging Face Transformers library is amazing"
}

# request
predictor.predict(data)
```

For further instructions on how to customize inference, refer to [this](https://github.com/aws/sagemaker-huggingface-inference-toolkit#%EF%B8%8F-environment-variables)

# Additional resources

To learn more, you can refer to:
* [Philosophy of Hugging Face transformers library](https://huggingface.co/transformers/philosophy.html)
* [Sample Hugging Face Transformers Notebooks](https://huggingface.co/transformers/notebooks.html)
* [Hugging Face on Amazon Sagemaker](https://huggingface.co/docs/sagemaker/main)
