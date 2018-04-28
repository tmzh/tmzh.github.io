---
author: thamizh85
comments: true
date: 2018-04-23 12:00:00+08:00
layout: post
slug: 2018-04-23-predicting-the-playing-role-of-a-cricketer-using-machine-learning-part-1
title: Predicting the playing role of a cricketer using Machine Learning
categories:
- Machine Learning
tags:
- python
- Scrapy
- web-scraping
---

In this project, we will apply Machine Learning techniques to predict whether a particular cricket player is a batsman or bowler based on his career stats. First we will use Deep Neural Networks (DNN) model and later compare the results with a simpler classifier algorithm such as Random Forest Classifier.

For the sake of consistency, we will consider only test players. Apart from being a puritan choice, the playing role of a player may differ from format to format and so we can't expect a consistent prediction. The cricinfo player bio page has this `playing role` information, but that covers only around 20% of the test players. For vast majority of players we only have numerical stats but no description whether the player is a batsman or a bowler. 

This is a perfect problem for ML to assist. We have a decent amount of training data (600+ players) and good amount of features (statistics) to base our prediction on. It would also be interesting to observe which features are relevant to our consideration of a player as batsman or bowler.

This is by no means a comprehensive tutorial for ML. The goal of this post is to serve as gentle introduction and wet the appetite for newcomers. So in the process, I would cover the following areas:

1. Data collection
2. Data cleaning
3. Data visualization
4. Machine Learning


## Data Collection 
Most ML examples work with pre-processed data but in reality data is seldom available prepackaged. For this problem, we will have to scrape the data off cricinfo website. We will use Scrapy for getting this info off cricinfo website.

The Scrapy tool is well-documented and has some nice tutorials to get started. However I will attempt my own brief introduction. 

To start we create a project as follows:

    scrapy startproject <project_name>

This will create the necessary folder structure. It will also create some boilerplate code which we can customize to our will later on.

> The default folder structure creates a parent folder and child folder with the same name. Do not get confused. All Scrapy commands are executed in the parent folder (where )

Ultimately our objective is to perform a web scraping using `scrapy crawl` command which looks like the one below:

    cd <project_name>
    Scrapy crawl <spider_name> -o <file_name>.csv

In this command, the `spider_name` is the name attribute of a spider class. This spider class file should be located under the spiders directory (<project_name>/<project_name>/spiders/*.py). The `file_name` is the output file name, csv being our chosen export format. Let us see the steps involved in reaching to this stage.

### Spider class
Start with the skeleton code required for scraping. Here is the skeleton spider class file we will use:

```python
import Scrapy

class CricinfoSpider(Scrapy.Spider):
    name = "players"

    start_urls = [ # list of starting urls
        ]

    def parse(self, response):
        # do some fancy web scraping
        pass
```

> The file name of this python class is arbitrary

> The spiders directory can contain multiple python file each implementing its own spider logic. The spider name attribute should be unique across all these files.

A Spider class should contain the following:
1. name attribute to be called from the Scrapy command line
2. start_urls is a list holding the URLS which act as the starting pages of our scraping.
3. parse function which performs the grunt of scraping the data. The parse function can also recursively call itself to scrape more pages or it can also have a callback function which can be further customized.

The starting page for our scraping should be the one containing links to all player profile pages. In cricinfo, there is no such global directory. However there is a page for players who represented a country. The URL is like this 

    http://www.espncricinfo.com/ci/content/player/caps.html?country=1;class=1

Notice the [parameters](http://www.ronstauffer.com/blog/understanding-a-url/) in the URL which we can manipulate to enumerate all test playing nations. The class parameter represents the game type- for test matches it is 1. Since the list of test playing nations is only a handful, I manually determined that the country code for test playing nations are 1 to 10 and 25 (25 is for Bangladesh, the latest addition to test playing nations). Armed with this info, we can define our start_urls as follows:

```python
start_urls = ['http://www.espncricinfo.com/ci/content/player/caps.html?country={0};class=1'.format(str(x)) for x in list(range(1,10))+[25]]
```

During a scraping process, Scrapy will issue a GET request to each one of these start_urls. If we get a valid HTTP 200 response, the response body will be passed on to parse function. 

### Parse function:
The parse function receives the response object and extracts useful info from it. Our starting page doesn't have the data that we need but contains the links to the player stats page which is what we want. So we will extract the links to player stats page and define another parse function to extract the statistics. 

To extract the links, we will use CSS selectors. Looking at the source code of the page, we can see that all links to player stats has a class name of `ColumnistSmry`. But that is not enough to uniquely identify player links since match links also has the same class name. We can further filter by matching the target URL which is expected to contain the string "player". So our CSS selector for extracting relevant URLs would be:

    response.css('a.ColumnistSmry[href*="player"]::attr(href)') 

Once we extract the link, Scrapy provides a handy `response.follow` function which navigates to the extracted link and can execute a callback function. This callback function will handle all our stats extraction since it will work directly with the player stats page. At this point, rest of the code is just a matter of studying the source code and extracting features using css selectors.


```python
def parse(self,response):
    #follow player links
    for href in response.css('a.ColumnistSmry[href*="player"]::attr(href)'):
        yield response.follow(href, self.parse_player)

def parse_player(self, response):
    player = PlayerItem()
    d = {}
    info = response.css(".ciPlayerinformationtxt")
    tables = response.css('.engineTable')

    values = [i.css('span::text').extract() for i in info]
    keys = [i.css('b::text').extract() for i in info]

    batting = tables[0]
    batting_keys = batting.css('th::text').extract()
    batting_values = batting.css('tr.data1')[0].css('td::text').extract()[-len(batting_keys):]

    bowling = tables[1]
    bowling_keys = bowling.css('th::text').extract()
    bowling_values = bowling.css('tr.data1')[0].css('td::text').extract()[-len(bowling_keys):]

    for item in zip(keys, values):
        key = 'Bio_' + self.title_clean(item[0][0])
        player[key] = self.clean(item[1])

    for item in zip(batting_keys, batting_values):
        key = 'Bat_' + self.title_clean(item[0])
        player[key] = self.clean(item[1])

    for item in zip(bowling_keys, bowling_values):
        key = 'Bowl_' + self.title_clean(item[0])
        player[key] = self.clean(item[1])

    return player
```


> If you find it difficult to define appropriate CSS selector for any element, you can always use inspector tool from Developer tools in Chrome or firefox. You can right click on the interesting code block and copy CSS selector or Xpath (Xpath is also supported in Scrapy) 

### Items Class:
In the parse function, you can note that I am updating the parsed information in to a class called `PlayerItem()`. It is an instance of Scrapy.Item class and its attributes are defined in items.py file. Here is a brief snippet of my `items.py` file.

```python
from Scrapy import Item, Field

class PlayerItem(Item):
    # define the fields for your item here like:
    Bio_Full_name = Field()
    Bio_Born = Field()
    Bio_Current_age = Field()
    Bio_Major_teams = Field()
    Bio_Playing_role = Field()
```

You don't have to always use a Item class. One can simply yield the values from parse function and it will output to CSV just fine. However without an Item class, the fields of the CSV file is determined by the fields in the first record processed. Any new field that may appear in subsequent scraped records will be silently dropped. For that reason, it is preferrable to define the structure of our parsed data ahead using an Item class.

## Conclusion
Finally we can save the result of our hardwork to a precocious CSV file and guard it (Just kidding... If you lose or corrupt the file, just delete it and scrape again! ).

    scrapy crawl players -o players.csv

In the next post we will look at pre-processing this data for our machine learning work. To learn more about Scrapy, do head to its official site. The documentation is excellent and once you grasp hold of the structure, rest falls in to place quite easily. 