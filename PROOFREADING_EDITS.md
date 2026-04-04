# Proofreading and Consistency Edits Summary

This document summarizes all the edits made during the proofreading and consistency review of the blog posts on the `redesign` branch.

---

## 1. Spelling Corrections

| File | Original | Correction |
|------|----------|------------|
| `2018-04-23-predicting-the-primary-role-of-cricket-player-using-machine-learning-part-1.md` | tne | the |
| `2018-04-23-predicting-the-primary-role-of-cricket-player-using-machine-learning-part-1.md` | wetting the appetite | whetting the appetite |
| `2018-04-23-predicting-the-primary-role-of-cricket-player-using-machine-learning-part-1.md` | Preferrable | Preferable |
| `2018-04-28-predicting-the-primary-role-of-cricket-player-using-machine-learning-part-2.md` | definiton | definition |
| `2018-04-28-predicting-the-primary-role-of-cricket-player-using-machine-learning-part-2.md` | Confusin Matrix | Confusion Matrix |
| `2018-04-28-predicting-the-primary-role-of-cricket-player-using-machine-learning-part-2.md` | succesfully | successfully |
| `2018-05-20-book-review-security-automation-with-ansible-2.md` | infrastructue | infrastructure |
| `2019-03-02-using-object-detection-with-python-and-opencv-to-keep-kids-away-from-tv.md` | minimzing | minimizing |
| `2019-03-02-using-object-detection-with-python-and-opencv-to-keep-kids-away-from-tv.md` | without much adieu | without much ado |
| `2019-03-02-using-object-detection-with-python-and-opencv-to-keep-kids-away-from-tv.md` | learned stay away | learned to stay away |
| `2021-02-02-testing-terraform-code-bdd-style-using-terratest.md` | succesful | successful |
| `2023-03-15-gpt-4-stable-diffusion-and-beyond.md` | definately | definitely |
| `2017-10-29-emulating-angryip-scanner-with-nmap-nse-a-lua-scripting-primer.md` | arguements (×2) | arguments |
| `2017-10-29-emulating-angryip-scanner-with-nmap-nse-a-lua-scripting-primer.md` | arguement | argument |
| `2022-03-07-solvers-for-the-wordle-game-evaluation-of-different-strategies.md` | took ong to solve | took long to solve |
| `2017-12-09-solving-ancient-chinese-puzzle-with-constraint-programming-using-or-tools.md` | arguemnt | argument |
| `2018-03-22-introduction-to-openstack-networking-for-network-engineers.md` | tet us | let us |

**Total spelling corrections: 19**

---

## 2. Grammar and Phrasing Fixes

| File | Issue | Fix |
|------|-------|-----|
| `2017-07-19-dynamic-registration-of-dns...` | applies only for the clients | applies only to the clients |
| `2017-07-19-dynamic-registration-of-dns...` | it can be configured to ask | it can be configured to be asked |
| `2017-10-29-emulating-angryip-scanner...` | Such details are available | Additional details are available |
| `2017-10-29-emulating-angryip-scanner...` | carry out much of the grunt | carry out much of the grunt work |
| `2018-04-28-predicting-the-primary-role...` | at a lower cost (ambiguous) | at a lower computational cost |
| `2018-05-20-book-review-security-automation...` | tools such Elasticsearch, AWS Lambda are | tools such as Elasticsearch and AWS Lambda are |
| `2021-03-26-previewing-command-line-json...` | AWS Lambda are already built | AWS Lambda is already built |
| `2023-06-24-llm-powered-faq-chat-bot.md` | be as helpfully as possible (×5) | be as helpful as possible |
| `2023-03-15-gpt-4-stable-diffusion...` | fine-tuning their ability (incomplete) | fine-tuning sacrifices their ability |
| `2024-10-27-llm-function-calling.md` | w/o interfacing | without interfacing |
| `2024-06-20-codenames-ai-assistant.md` | expedited the generation of usable outcomes | expedited the process of generating usable outcomes |
| `2017-12-09-solving-ancient-chinese-puzzle...` | Run-on sentence | Added proper punctuation |

**Total grammar/phrasing fixes: 12**

---

## 3. Frontmatter Standardization

### 3.1 Layout Field
- **Removed** `layout: post` from `2024-10-27-function-calling.md` (inconsistent with other posts)

### 3.2 Image Field Standardization
| File | Before | After |
|------|--------|-------|
| `2024-01-22-running-deep-floyd...` | `images:` (array) | `image:` (string) |
| `2024-06-20-codenames...` | `images:` (array) | `image:` (string) |
| `2022-03-07-wordle...` | External URL | Local path |
| `2021-09-16-huggingface...` | External URL | Local path |
| `2021-03-26-firefox...` | External URL | Removed |
| `2021-02-02-terratest...` | External URL | Removed |
| `2020-09-20-gpt-3...` | Wrong image file | Correct image file |
| `2023-03-15-gpt-4...` | Old image | Updated to new image |

### 3.3 Slug Field Standardization
| File | Before | After |
|------|--------|-------|
| `2024-01-22-running-deep-floyd...` | Array format | String format |
| `2024-06-20-codenames...` | Array format | String format |
| `2024-10-27-function-calling...` | No date prefix | Added date prefix |

### 3.4 Date Format Standardization
- Standardized all dates to ISO format with quotes: `"YYYY-MM-DDTHH:MM:SSZ"`
- Fixed `2024-10-27-function-calling.md` to include time component

### 3.5 Removed Inconsistent Fields
- `autoCollapseToc: true` (removed from 2 posts)
- `mathjaxEnableSingleDollar: true` (removed from 1 post)

### 3.6 Added Missing Fields
- `comments: true` added to 4 posts that were missing it
- `author: tmzh` added to 1 post that was missing it

**Total frontmatter changes: 25+**

---

## 4. Image Format Standardization

### 4.1 Converted HTML `<figure>` to Markdown
| File | Change |
|------|--------|
| `2023-03-15-gpt-4-stable-diffusion...` | Converted 2 `<figure>` blocks to Markdown |
| `2023-06-24-llm-powered-faq-chat-bot.md` | Converted 2 `<figure>` blocks to Markdown |
| `2024-01-22-running-deep-floyd...` | Converted 1 `<figure>` block to Markdown |
| `2024-10-27-function-calling...` | Converted 1 `<figure>` block to Markdown |

### 4.2 HTML Cleanup
| File | Before | After |
|------|--------|-------|
| `2018-04-28-cricket-ml-part-2` | `<p align='center'>` (deprecated) | `<figcaption style="text-align: center;">` |

**Total image format changes: 6**

---

## 5. Category Standardization (Lowercase + Hyphenated)

| Old Category | New Category | Files Affected |
|--------------|--------------|----------------|
| Machine Learning | machine-learning | 3 |
| Generative AI | generative-ai | 5 |
| Artificial Intelligence | artificial-intelligence | 2 |
| Cloud Computing | cloud-computing | 1 |
| Big Data | big-data | 1 |
| Image recognition | image-recognition | 1 |
| SysAdmin | sysadmin | 1 |
| Notes | notes | 1 |
| Scripting | scripting | 1 |
| Modelling | modelling | 1 |
| Networking | networking | 1 |
| Security | security | 1 |
| solver | solver | 2 |
| tips | tools | 1 |

**Total category standardizations: 20**

---

## 6. Tag Standardization (Lowercase + Hyphenated)

| Tag Changes | Count |
|-------------|-------|
| `LLM` → `llm` | 2 |
| `Function Calling` → `function-calling` | 1 |
| `Natural Language Interface` → `natural-language-interface` | 1 |
| `chatGPT` → `chatgpt` | 1 |
| `machine learning` (removed from tags, kept in categories) | 2 |
| `generative_ai` → `generative-ai` | 3 |
| `deep_floyd` → `deep-floyd` | 1 |

**Total tag standardizations: 10**

---

## 7. Fixed Links

| File | Issue | Fix |
|------|-------|-----|
| `2023-03-15-gpt-4-stable-diffusion...` | YouTube URL truncated | Added missing character |
| `2023-03-15-gpt-4-stable-diffusion...` | Twitter URL truncated | Added missing character |

**Total link fixes: 2**

---

## 8. Edit Statistics

### By Type
| Category | Count |
|----------|-------|
| Spelling corrections | 19 |
| Grammar/phrasing fixes | 12 |
| Frontmatter changes | 25+ |
| Image format standardization | 6 |
| Category standardization | 20 |
| Tag standardization | 10 |
| Link fixes | 2 |
| **Total** | **94+** |

### By File
| File | Edit Count |
|------|------------|
| `2023-06-24-llm-powered-faq-chat-bot.md` | 10+ |
| `2024-10-27-function-calling.md` | 8 |
| `2023-03-15-gpt-4-stable-diffusion.md` | 7 |
| `2024-01-22-running-deep-floyd.md` | 7 |
| `2024-06-20-codenames.md` | 6 |
| `2018-04-28-cricket-ml-part-2.md` | 6 |
| `2018-04-23-cricket-ml-part-1.md` | 4 |
| `2019-03-02-opencv-kids.md` | 4 |
| `2017-10-29-nmap-lua.md` | 4 |
| Other files (13) | 1-3 each |

### Files Modified: 22
### Total Lines Changed: ~200+ (89 insertions, 123 deletions)

---

*Generated on: 2024*
*Branch: redesign*
