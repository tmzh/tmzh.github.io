---
author: thamizh85
comments: true
date: 2019-03-02 12:00:00+08:00
layout: post
slug: 2019-03-02-using-opencv-object-detection-to-keep-kids-away-from-tv
title: Using OpenCV object detection to keep kids away from TV
categories:
- Image recognition
tags:
- python
- opencv
---
## Introduction

>Give me a dozen healthy infants, well formed, and my own specified world to bring them up in and I’ll guarantee to take any one at random and train him to become any type of specialist I might select—doctor, lawyer, artist, merchant-chief and yes, even beggar-man thief, regardless of his talents, penchants, tendencies, abilities, vocations, and race of his ancestors.

This was John Watson, one of the founders of [Behaviorism](https://www.wikiwand.com/en/Behaviorism), writing around 1925. He believed that human behavior is completely malleable and that it can be shaped into anything given the right environment. While I don't harbor any grand objectives or sinister experiments like Watson did, I do hope to be able to teach my kids good habits using controlled environments. For instance, my two year old kids started developing the habit of getting too close to the TV. I don't want to use force or impose restrictions on them, so I thought I could use technology to discourage them from getting too close to TV.

## Problem statement

I play YouTube rhymes on my HTPC which is connected to our living room TV. While watching they sometimes get down from the couch and walk to the TV. When they do, I want to turn off the video automatically to let them know that they have gone too close and not resume the playback until they get back to the couch. For my setup, that means pausing youtube player and minimzing the browser. 

Fortunately this is easy to do with a camera and [OpenCV](https://github.com/opencv/opencv). Let us see how.

![Open CV](https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/OpenCV_Logo_with_text_svg_version.svg/195px-OpenCV_Logo_with_text_svg_version.svg.png)

## Tools and solutions

Object detection is among the fundamental features of OpenCV and there are a few ways to do it. I explored three of them: 

1. *Using HAAR Cascades*:
This is a popular object detection method in OpenCV. It uses models that are trained on a lot of positive and negative images and extracting features from those images. The training step is optional here as there are lot of pre-trained models available to detect face and human bodies. However for my case, those models didn't do well due to the awkward angle at which my camera was placed. Training my own model based on an image corpus is also not an option since asking two year olds to hold postures for model training is a non-trivial endeavour.

2. *Background Subtraction*:
Among all the methods this is the one which impressed me! All we need is a single call to `opencv2.createBackgroundSubtractorMOG()` to identify moving objects in the foreground and to eliminate static background. The method works by subtracting pixels from subsequent frames of a video and extracting those that change. However this method left a relatively larger footprint on the CPU (still not significant). I was also put off by the false shadow objects created under changing light conditions. But the biggest problem for me was that initial state of the frame was out of my control, so a person moving out of the frame would trigger object detection in the same way as a new person moving in. Asking my family to stay still as the computer boots up is a tricky request... even by my standards.

3. *Contour detection*:
This is among the cheaper method in terms of computational requirements and it was just the method I needed for my simple requirement. It works by identifying contours in a picture. If the picture is black and white, the contour detection works better. Fortunately, since I only needed to detect a head in the visual frame and the hair in the head helped to distinguish the contours clearly. So this seemed to be the best fit for my requirement and I went with it. 

## Using Contour detection
With the default OpenCV video capture drivers, my camera returned a frame with resolution 640 x 480 pixels. Here you can see my son lost in the colorful world of baby rhymes, hoping to dive into the TV to enjoy the rhymes in full splendor. 

![Naughty kid](/assets/images/2019/03/using-opencv-object-detection-to-keep-kids-away-from-tv/naughty-kid.png)

First I cropped the image to focus only on the area that I want to monitor- a small rectange close to TV. Blurring was done to smoothen the contours.

```python
cropped = frame[100:300, 0:630]

# Blur the image
blurred = cv2.blur(cropped, (3, 3))
```

![Cropped image](/assets/images/2019/03/using-opencv-object-detection-to-keep-kids-away-from-tv/cropped.png)

Next I needed to do convert some color channels. Contour detection is not efficient when the color intensities are in 3 dimensions (RGB). The job is greatly simplified if we can restict the colors to a single dimension. And it works even better with binary images where the pixels are either pure black or white (even for us black and white are easier to tell apart than a million shades of other colors in between). 

So we apply a threshold using `cv2.inRange` function  which converts the image to black and white (not grey scale). This is done by specifying a range of interesting colors and every  pixel that fall in the range will be converted to white and rest to black. Now it is easy to find contours with `cv2.findContours` method.

```python
# Convert to HSV color space
hsv = cv2.cvtColor(blurred, cv2.COLOR_BGR2HSV)

# define range of blue color in HSV
lower_black = np.array([0,0,0])
upper_black = np.array([180, 255, 50])

# Create a binary image with where the head will be white while the rest is black
thresh = cv2.inRange(hsv, lower_black, upper_black)
```

![Thresholded image](/assets/images/2019/03/using-opencv-object-detection-to-keep-kids-away-from-tv/filtered.png)

Finally we turn to the `cv2.findContours` method. The `cv2.findContours` method returns an array of contours. I looked for the largest contour by area and triggered helper methods when the area was bigger than a threshold. We can even plot the contours to see how our object detection works, as I have done in the picture below.

```python
_, contours, hierarchy = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
if contours:
    area = max([cv2.contourArea(c) for c in contours])
    if area > 1500:
        cv2.drawContours(cropped, contours, -1 , (0,255,0), 3)
        # Object detected. Do something
cv2.drawContours(cropped, contours, -1, (0,255,0), 3)
```
![Contour detection](/assets/images/2019/03/using-opencv-object-detection-to-keep-kids-away-from-tv/contour-detection.png)

And there you go! The naughty infiltrator is caught.

## Controlling the playback

For controlling the playback, I used a combination of pyautogui and win32con libraries. Since I didn't want to interrupt playbacks on normal times, the object detection is activated only when Youtube is one among the foreground windows. 

Now without much adieu, here is the full code. 

```python
#!C:\Python
import time

import numpy as np
from win32con import SW_RESTORE, SW_SHOW

import cv2
import pyautogui
import win32gui

TRIGGER_THRESHOLD = 30
COOLDOWN_THRESHOLD = 5

def get_windows_placement(window_id):
    return win32gui.GetWindowPlacement(window_id)[1]

def set_active_window(window_id):
    if get_windows_placement(window_id) == 2:
        win32gui.ShowWindow(window_id, SW_RESTORE)
    else:
        win32gui.ShowWindow(window_id, SW_SHOW)
    win32gui.SetForegroundWindow(window_id)
    win32gui.SetActiveWindow(window_id)

def search_and_restore_youtube(window_id, hwnd):
    if "YouTube" in win32gui.GetWindowText(window_id):
        set_active_window(window_id)

def check_for_youtube(window_id, hwnd):
    if "YouTube" in win32gui.GetWindowText(window_id):
        hwnd.append(window_id)
    return True 

class FrameCounter():
    def __init__(self):
        self.counter = 0
        self.minimized = False
        self.state = "nf_max"
        
    def __str__(self):
        return("Current count: {}", self.counter)
    
    def found(self):
        if self.state == "nf_max":
            self.counter += 1
            self.state = "f_max"
        elif self.state == "f_max":
            if self.counter > TRIGGER_THRESHOLD:
                self.minimize_all_windows()
                self.state = "f_min"
            else:
                self.counter += 1
        else:
            next
    
    def not_found(self):
        if self.state == "f_min":
            self.counter -= 1
            self.state = "nf_min"
        elif (self.state == "nf_min"):
            if self.counter < (TRIGGER_THRESHOLD - COOLDOWN_THRESHOLD):
                self.restore_firefox()
                self.state = "nf_max"
                self.counter = 0 #forget and forgive
            else:
                self.counter -= 1
        elif (self.state =="f_max"):
            self.counter = max(0, self.counter - 1)
        else: 
            next 
            
    def minimize_all_windows(self):
        print("Minimizing firefox at {0}".format(self.counter))
        pyautogui.hotkey('k')
        pyautogui.hotkey('win', 'd')
        self.minimized = True

    def restore_firefox(self):
        print("Restoring firefox at {0}".format(self.counter))
        win32gui.EnumWindows(search_and_restore_youtube, None)
        pyautogui.hotkey('k')
        self.minimized = False

    
def find_kids(frame, frame_counter):
    cropped = frame[100:300, 0:630]
    
    # Blur the image
    blur = cv2.blur(cropped, (3, 3))

    # Convert to HSV color space
    hsv = cv2.cvtColor(blur, cv2.COLOR_BGR2HSV)

    # define range of blue color in HSV
    lower_black = np.array([0,0,0])
    upper_black = np.array([180, 255, 50])

    # Create a binary image with where the head will be white while the rest is black
    thresh = cv2.inRange(hsv, lower_black, upper_black)
    _, contours, hierarchy = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    if contours:
        area = max([cv2.contourArea(c) for c in contours])
        if area > 1500:
            cv2.drawContours(cropped, contours, -1 , (0,255,0), 3)
            frame_counter.found()
        else:
            frame_counter.not_found()
    else:
        frame_counter.not_found()
    cv2.imshow('filtered',cropped)
    

if __name__ == '__main__':
    cap = cv2.VideoCapture(0)
    cap.set(cv2.CAP_PROP_POS_MSEC,1000)
    frame_counter = FrameCounter()
    hwnd=[]
    while(cap.isOpened()):
        # Run only when Youtube is one of the running window titles
        win32gui.EnumWindows(check_for_youtube, hwnd)
        if (hwnd):
            ret, frame = cap.read()
            find_kids(frame,frame_counter)
        k = cv2.waitKey(500) & 0xff
        if k == 27:
            break
    cap.release()
    cv2.destroyAllWindows()

```
  
## Results
Overall, I would say that the whole exercise was quite effective. The kids have learnt stay away from TV... most of the times. Sometimes they do succumb to the temptation and get closer. And when the playback stops, they move away from the TV and wait for the playback to automatically resume. It seems they have figured out their environment on their own. 

But the kids cognition process is not without its faults though, there were some unexpected results. For instance, my son developed a superstition that everytime the playback stops he needs to run all the way to kitchen for it to resume (exactly the time taken for the resume timer to cooldown) and so far he hasn't observed any counter-examples to break the correlation between trip to kitchen and resumption of youtube videos. But I expect that over the next few days he will refine his model of environment. My daughter has developed no such belief, she climbs back in to the couch and waits for the playback to resume. 

Now, I think I have solved my initial problem satisfactorily using technology, further strengthening my conviction that technology can be a solution when used properly. Now all I need to do is find some technical solutions to get rid of those earworm rhymes that I keep humming awkwardly in public.
