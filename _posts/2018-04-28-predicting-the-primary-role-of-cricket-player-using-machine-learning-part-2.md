---
author: thamizh85
comments: true
date: 2018-04-28 12:00:00+08:00
layout: post
slug: 2018-04-28-predicting-the-playing-role-of-a-cricketer-using-machine-learning-part-2
title: Predicting the playing role of a cricketer using Machine Learning (Part 2)
categories:
- Machine Learning
tags:
- python
- pandas
- pre-processing
- visualization
---
In the previous post we saw how to scrape raw data from a content rich webpage. Let us explore few data preparation and visualization techniques for dealing with the data we scraped. We will use the standard ML toolsets

1. Pandas
2. Numpy
3. Seaborn
4. matplotlib
5. Jupyter 


## Importing data
First let us load the CSV file as pandas data frame and inspect its contents.
**in[0]**
```python
data = pd.read_csv('data/players.csv')
data.dtypes
```
**out[0]**
```
Bat_100                  object
Bat_4s                   object
Bat_50                   object
Bat_6s                   object
Bat_Ave                  object
Bat_BF                   object
Bat_Ct                    int64
Bat_HS                   object
Bat_Inns                 object
Bat_Mat                   int64
Bat_NO                   object
Bat_Runs                 object
Bat_SR                   object
Bat_St                    int64
Bio_Also_known_as        object
Bio_Batting_style        object
Bio_Born                 object
Bio_Bowling_style        object
Bio_Current_age          object
Bio_Died                 object
Bio_Education            object
Bio_Fielding_position    object
Bio_Full_name            object
Bio_Height               object
Bio_In_a_nutshell        object
Bio_Major_teams          object
Bio_Nickname             object
Bio_Other                object
Bio_Playing_role         object
Bio_Relation             object
Bowl_10                  object
Bowl_4w                  object
Bowl_5w                  object
Bowl_Ave                 object
Bowl_BBI                 object
Bowl_BBM                 object
Bowl_Balls               object
Bowl_Econ                object
Bowl_Inns                object
Bowl_Mat                  int64
Bowl_Runs                object
Bowl_SR                  object
Bowl_Wkts                object
dtype: object
```

We  can see that most of the fields are decoded as 'object' data type which is a generic pandas datatype. It gets assigned if our data consists of mixed types such as characters and numerals. There are some obvious numerical fields which are getting detected as string. But before we recast all of them as string, we need to preprocess some of them to extract numeric value out of them. 

For example, let us inspect `Bowl_BBI` and `Bowl_BBM` which stands for best bowling figures in an innings and a match respectively. 

**in[1]**
```data[['Bowl_BBI','Bowl_BBM']].head(n=10)```

**out[1]**
```
   	Bowl_BBI 	Bowl_BBM
0 	- 	-
1 	3/31 	3/31
2 	2/35 	2/42
3 	- 	-
4 	- 	-
5 	- 	-
6 	- 	-
7 	- 	-
8 	6/85 	8/58
9 	- 	-
```

Either fields can be made sense as a combination of two independent variables- Best Bowling Wickets & Best Bowling Runs. Similarly when we cast the field `Bat_HS` as integer, the notout values will be lost since they are suffixed with an asterisk. Let us go ahead to fix these potential issues.

```python
# Best bowling innings wickets
bbi_df = pd.DataFrame(data['Bowl_BBI'].str.replace('-','').str.split('/').tolist(),
                      columns = ['Bowl_BBIW','Bowl_BBIR'])
bbm_df = pd.DataFrame(data['Bowl_BBM'].str.replace('-','').str.split('/').tolist(),
                      columns = ['Bowl_BBMW','Bowl_BBMR'])

data = data.join([bbi_df,bbm_df])

# regex replace * in High scores
data['Bat_HS'] = data['Bat_HS'].replace(r'\*$','',regex=True)
data[numeric_cols] = data[numeric_cols].replace('-',0)
```

**in[2]**
```python
# Identify numeric columns
numeric_cols = ['Bat_100','Bat_4s','Bat_50','Bat_6s','Bat_Ave','Bat_BF',
                'Bat_Ct','Bat_HS','Bat_Inns','Bat_Mat','Bat_NO','Bat_Runs',
                'Bat_SR','Bat_St','Bowl_10','Bowl_4w','Bowl_5w','Bowl_Ave',
                'Bowl_Balls','Bowl_Econ','Bowl_Inns','Bowl_Mat','Bowl_Runs',
                'Bowl_SR', 'Bowl_Wkts','Bowl_BBIW','Bowl_BBIR','Bowl_BBMW','Bowl_BBMR']

# cast HS as numbers
data[numeric_cols] = data[numeric_cols].apply(pd.to_numeric, errors='coerce')
data[numeric_cols] = data[numeric_cols].fillna(0)

# check again
data.dtypes
```
> Be careful when filling NaN with zeroes. Idea is not to introduce false values in to the dataset. In this case, a value of zero is neutral since it represents the same value as absent numbers. But for certain types of data, such as temperature, zero introduces a false value in to the data set since temperature values can be less than zero.

**out[2]**
```
bat_100                    int64
Bat_4s                   float64
Bat_50                     int64
Bat_6s                   float64
Bat_Ave                  float64
Bat_BF                   float64
Bat_Ct                     int64
Bat_HS                     int64
Bat_Inns                   int64
Bat_Mat                    int64
Bat_NO                     int64
Bat_Runs                   int64
Bat_SR                   float64
Bat_St                     int64
Bio_Also_known_as         object
Bio_Batting_style         object
Bio_Born                  object
Bio_Bowling_style         object
Bio_Current_age           object
Bio_Died                  object
Bio_Education             object
Bio_Fielding_position     object
Bio_Full_name             object
Bio_Height                object
Bio_In_a_nutshell         object
Bio_Major_teams           object
Bio_Nickname              object
Bio_Other                 object
Bio_Playing_role          object
Bio_Relation              object
Bowl_10                    int64
Bowl_4w                    int64
Bowl_5w                    int64
Bowl_Ave                 float64
Bowl_BBI                  object
Bowl_BBM                  object
Bowl_Balls                 int64
Bowl_Econ                float64
Bowl_Inns                  int64
Bowl_Mat                   int64
Bowl_Runs                  int64
Bowl_SR                  float64
Bowl_Wkts                  int64
Bowl_BBIW                float64
Bowl_BBIR                float64
Bowl_BBMW                float64
Bowl_BBMR                float64
dtype: object
```

This is much closer to our expectation. 

## Pre-processing 
When using data in our models we have to be careful about the units they represent. For instance, Average & Strike rates are already normalized over the number of matches that a player plays. But other aggregate statistics aren't. Which means it is meaningless to compare run tally of a player who has played only 10 matches with that of another who has played a hundred matches. 

To understand better, let us plot runs scored vs the innings played.

**in[3]**
```python
sns.jointplot(x="Bat_Runs", y="Bat_Inns", data=data)
```
![Bat Inns vs Bat Runs]("/assets/images/2018/04/predicting-the-playing-role-of-a-cricketer-using-machine-learning-part-2/bat-inns-vs-bat-runs.png")

Obviously there is a strong correlation between no. of innings played and no. of runs scored. We can almost plot a linear regression through this data. So let us normalize all such aggregate statistics over the number of innings played.

```python
# select aggregate stats such as no. of hundreds, runs scored etc.,
bat_features_raw = ['Bat_100', 'Bat_4s', 'Bat_50', 'Bat_6s', 
                    'Bat_BF', 'Bat_Ct', 'Bat_NO', 'Bat_Runs','Bat_St']

# column names for scaled features
bat_features_scaled = ['Bat_100_sc', 'Bat_4s_sc', 'Bat_50_sc', 'Bat_6s_sc', 
                    'Bat_BF_sc', 'Bat_Ct_sc', 'Bat_NO_sc', 'Bat_Runs_sc','Bat_St_sc']

# leave aside match and innings count and other aggregate stats such as best bowling figures, strike rate and average
bowl_features_raw = ['Bowl_10', 'Bowl_4w', 'Bowl_5w',  
                     'Bowl_Balls', 'Bowl_Runs','Bowl_Wkts']

# column names for scaled features
bowl_features_scaled = ['Bowl_10_sc', 'Bowl_4w_sc', 'Bowl_5w_sc',  
                     'Bowl_Balls_sc', 'Bowl_Runs_sc','Bowl_Wkts_sc']

# divide by innings count since it is more relevant than match count
data[bat_features_scaled] = data[bat_features_raw].apply(lambda x: x/data['Bat_Inns'])
data[bowl_features_scaled] = data[bowl_features_raw].apply(lambda x: x/data['Bowl_Inns'])

features = ['Bat_Ave','Bat_HS', 'Bat_SR'] + bat_features_scaled + ['Bowl_Ave','Bowl_Econ','Bowl_SR','Bowl_BBIW', 'Bowl_BBIR', 'Bowl_BBMW', 'Bowl_BBMR'] + bowl_features_scaled

# fill numerical features with zero
data[features] = data[features].fillna(0)
``` 
> It can be argued that averaging the runs scored is duplicate with batting average feature. Leaving aside subtle differences in the way in which batting averages are calculated, we would still keep both features to let the ML distributes weights to these features

Now let us plot the scaled runs scored value vs the innings played.


Clearly this is a far better representation of batting capabilities of a player. You can see there is less dependency on the number of innings played.

Let us look at the playing role feature. Remember, this is the feature we are trying to predict but first we need to understand the values it can assume. Let us look at the unique values for the player features

**in[3]**
```python
# Check the unique playing roles to identify mapping function
data['Bio_Playing_role'].unique()
```

**out[3]**
```
array([nan, 'Top-order batsman', 'Bowler', 'Middle-order batsman',
       'Wicketkeeper batsman', 'Allrounder', 'Batsman', 'Opening batsman',
       'Wicketkeeper', 'Bowling allrounder', 'Batting allrounder'], dtype=object)
```

The playing role definiton is too granular. We want fewer variety of roles so that each role gets sufficient sample data points to train the model. Also the role tagging done by Cricinfo is not consistent. For e.g., not all opening batsmen have been tagged with the opening batsman role. So we define a mapping function to group playing roles in to 4 different categories ['Batsman','Bowler','Wicketkeeper','Allrounder']

```python
def get_role(role):
    if  pd.notnull(role):
        if 'keeper' in role:
            return "Wicketkeeper"
        elif 'rounder' in role:
            return "Allrounder"
        elif 'atsman' in role:
            return "Batsman"
        elif 'owler' in role:
            return "Bowler"
        else:
            return ""
    else:
        return ""
    
data['role'] = data['Bio_Playing_role'].apply(get_role)
```

Some fields vary over a larger range compared to the rest. For example, career runs scored can range from 0 to 15000 whereas wickets ticket can range only in few hundres. If we let these datapoints influence our calculation, wickets taken will have negligible influence.   