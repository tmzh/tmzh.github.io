---
author: thamizh85
comments: true
date: 2017-12-09 12:00:00+08:00
layout: post
slug: 2017-12-09-using-constraint-programming-to-solve-an-ancient-chinese-math-puzzle
title: Using Constraint Programming Tools to solve an ancient Chinese math puzzle
categories:
- Modelling
tags:
- or-tools
- python
- puzzle
- operations research
- constraint programming
---
[Constraint programming (CP)](https://www.wikiwand.com/en/Constraint_programming) is a subset of Operations Research (OR) where our task is to identify all feasible solutions to a given problem that satisfies a set of constraints. This is different from an optimization problem, where an objective function is defined and we arrive at solutions that either maximizes or minimizes an objective function. 

CP is mostly well suited for solving logic puzzles, since most logic puzzles are based on constraints and enumerating feasible solutions. But apart from recreational maths, CP also has a lot of practical applications in Scheduling, Resource allocation, Manufacturing etc.,

<!--more-->

Recently I came across [or-tools](https://developers.google.com/optimization/) from Google github repo. It is a suite of libraries for solving Operations Research problems. I wanted to give it a try by solving a simple logic puzzle. The puzzle I chose is called [Hundred Fowls Problem](https://www.wikiwand.com/en/Hundred_Fowls_Problem). Let us see how it goes. 

## Hundred Fowls problem
This puzzle found in the sixth-century work of mathematician Chang Chiu-chen called the "hundred fowls" problem asks:

>If a rooster is worth five coins, a hen three coins, and three chickens together are worth one coin, how many roosters, hens, and chicks totalling 100 can be bought for 100 coins?

This translates to solving a set of 2 algebraic equations with 3 variables. In real numbers, there are infinite solutions to this puzzle since we are short by one non-equivalent equation to bind values to 3 variables. However, buying non-integer number of fowls can get tricky, so we can safely assume that we are dealing with 3 integer valued variables here. This reduces the solution space to a finite count, but still there are more than one feasible solution. This is a perfect candidate for constraint programming since we need to identify all feasible solutions and not maximize/minimize an objective function.

### Components of an OR model
A model for an optimization problem can be thought to have 3 components:
* Decision variables
* Constraints
* Objectives

Decision variables are the answer an OR problem tries to solve. In our case, it is the valid number of fowls of each type that we can buy. Constraints are the limits imposed on the problem. Here we have total cost and total bird count imposed as limits. An objective is the goal of an OR problem such as maximize profit or minimize project time etc., Most often in Constraint Programming, we don't need to work with objectives and we don't have one for our problem as well.

### Setting up the code
Let us first import the necessary modules and create a Solver and define our parameters. 
```python
from ortools.constraint_solver import pywrapcp

solver = pywrapcp.Solver("hundred_fowls")

ROOSTER_COST = 5
HEN_COST     = 3
THREE_CHICK_COST   = 1

total_cost = 100
total_fowls = 100
```

#### Decision Variables
Let us first try to define the limits our decision variables can take i.e., the maximum number of roosters, hens or chicks that we need to consider. One can enumerate each fowl type up to the total count (100) but this increases the search domain unnecessarily. For e.g, we cannot buy more than 20 roosters since we would exceed 100 coins nor can we buy 300 chicks for 100 coins. So, we try to establish the upper limit for each of our decision variables as below:
```python
from math import floor

max_rooster = min(total_fowls, floor(total_cost/ROOSTER_COST))
max_hen = min(total_fowls, floor(total_cost/HEN_COST))
max_chick_set = min(total_fowls, floor(total_cost/THREE_CHICK_COST)) # a set of 3 chickens 
```
Notice that for chick count, we are grouping them in sets of three. This is because the unit cost of a chick is a fraction (1/3) and the solver doesn't allow us to multiply float numbers with IntVar object (which we will come to know later). This is perfectly acceptable for our scenario since chick count always needs to be a multiple of 3 or else the total cost will never be an integer (100 in this case). Besides, this also reduces the search space for chick count by a factor of 3, eliminating obvious non-solutions.

We now have to spec out our decision variables. OR-Tools supports different types of decision variables such as Integers, Intervals etc., In our current challenge the decision variable is an integer so we assign it by using IntVar method. The first two values gives the lower and upper bounds for the variables. The last value is an arbitrary string handle for output representation. I am not sure under which scenarios the last variable will come to use, but likely it is an object name required for the underlying C++ code. The python module we use for or-tools is actually a wrapper for the core C++ code.

For our problem the decision variables can be defined as below:
```python
# since the puzzle requires us to buy atleast one fowl 
# of each type we will start enumerating from one
rooster_count = solver.IntVar(1, max_rooster, "Rooster")
hen_count     = solver.IntVar(1, max_hen, "Hen")
chick_set_count    = solver.IntVar(1, max_chick_set, "Chick")
```
#### Constraints
Next we add the constraints for our model. It is done using the "Add" method of Solver object.

```python
solver.Add(rooster_count + 
           hen_count + 
           chick_set_count*3 == total_fowls)

solver.Add(rooster_count*ROOSTER_COST + 
           hen_count*HEN_COST + 
           chick_set_count*THREE_CHICK_COST == total_cost)
```
#### Navigating the search space
Next we create a decision builder which specifies how to iterate through all possible values for our problems. It is done using the Phase method. The first arguemnt is an array of our decision variables. Second argument is how we choose the next value to try for our decision variable. Last argument is how we start assigning value to our variable (from minimum or maximum). We will go with the defauls although for larger problems, we could use some sort of heuristics to search only interesting portions of a search space. You can refer to [or-tools documentation](http://www.lia.disi.unibo.it/Staff/MicheleLombardi/or-tools-doc/reference_manual/or-tools/src/constraint_solver/classoperations__research_1_1Solver.html#8bda7ed6e7e533cca4c44eba6efffc8b) for other search strategies.

```python
db = solver.Phase([rooster_count, hen_count, chick_set_count], 
                  solver.CHOOSE_FIRST_UNBOUND, 
                  solver.ASSIGN_MIN_VALUE)
```

### Solving the model
Finally we solve our model and iterate through our solutions.

```python
solver.Solve(db)
count = 0

while solver.NextSolution():
    count += 1
    print("{0} Roosters, {1} Hen and {2} Chicks".format(rooster_count, hen_count, chick_set_count.Value()*3))
print("Number of unique solutions found - {0}".format(count))
```
This produces 3 solutions to the puzzle.  
```
Rooster(4) Roosters, Hen(18) Hen and 78 Chicks
Rooster(8) Roosters, Hen(11) Hen and 81 Chicks
Rooster(12) Roosters, Hen(4) Hen and 84 Chicks
Number of unique solutions found - 3
```

## Further Reading

or-tools manual on [Constraint Programming](https://acrogenesis.com/or-tools/documentation/user_manual/manual/introduction/what_is_cp.html) is quite comprehensive. As always, best way to learn is to study existing code and implementations. In this regards, the [example scripts](https://github.com/google/or-tools/tree/master/examples) from or-tools public repo is quite indispensable for learning. There is a good amount of example scripts for some of the most popular OR challenges. 