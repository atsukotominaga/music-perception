#!usr/bin/env python

"""
This is an experimental programme for Music Perception 2020
"""

# import libraries
from psychopy import core, visual, gui, data, event
from psychopy.tools.filetools import fromFile, toFile
import os, random, mido

### function ###
def next():
    resp = None
    while resp == None:
        allKeys = event.getKeys(keyList = ["space", "escape"])
        for resp in allKeys:
            if resp == "space": # proceed
                break
            elif resp == "escape": # force quit
                for item in resultsList: # save data so far
                    dataFile.write('{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}\n'.format(*item))
                dataFile.close()
                core.quit()
    return

def trial(expMode, imageFile, midFile, ratingOrder, resultsList):
    # stimuli presentation
    ## 1. sheet music
    stimuli = visual.ImageStim(win, image = imageFile, size = [1500, 535])
    stimuli.draw()

    ## 2. midi play
    playing = True
    while playing:
        win.flip() # sheet music
        mid = mido.MidiFile(midFile)
        for msg in mid.play():
            port.send(msg)
        event.clearEvents() # clear if any keypress
        core.wait(1)
        playing = False
    
    # get response (yes/no answer)
    ratingScale = visual.RatingScale(win, choices = ["Yes", "No"], markerStart = 0.5, markerColor = "Orange", textFont = "Avenir", size = 1.5, noMouse = True, acceptKeys = "return", showAccept = False, skipKeys = None)
    question = visual.TextStim(win, pos=[0, 0], font = "Avenir", height = 60, wrapWidth = 1400,
    text = "Teaching?")
    trialClock - core.clock()
    while ratingScale.noResponse:
        question.draw()
        ratingScale.draw()
        win.flip()
    
    # store responses1
    resultsList.append([
        expMode, # practice/experiment
        trialCounter, # trial number
        midFile, # mid file
        ratingScale.getRating(), # final answer
        trialClock.getTime(), # RT1
        ratingScale.getRT(), # RT2
        expInfo["Number"], # subject number
        expInfo["Today"], # date
        globalClock.getTime()
    ])
    print(resultsList)
    event.clearEvents()

    inst = visual.TextStim(win, pos=[0, 0], font = "Avenir", height = 60, wrapWidth = 1400, alignText = "left",
    text = "Press <Space> to continue")
    inst.draw()
    win.flip()
    next() # proceed/force quit
    event.clearEvents()
    return
    

"""
   ("-.  ) (`-.       _ (`-.    ("-.  _  .-")          _   .-")       ("-.       .-") _  .-") _    
 _(  OO)  ( OO ).    ( (OO  ) _(  OO)( \( -O )        ( ".( OO )_   _(  OO)     ( OO ) )(  OO) )   
(,------.(_/.  \_)-._.`     \(,------.,------.  ,-.-") ,--.   ,--.)(,------.,--./ ,--," /     "._  
 |  .---" \  `."  /(__...--"" |  .---"|   /`. " |  |OO)|   `."   |  |  .---"|   \ |  |\ |"--...__) 
 |  |      \     /\ |  /  | | |  |    |  /  | | |  |  \|         |  |  |    |    \|  | )"--.  .--" 
(|  "--.    \   \ | |  |_." |(|  "--. |  |_." | |  |(_/|  |"."|  | (|  "--. |  .     |/    |  |    
 |  .--"   ."    \_)|  .___." |  .--" |  .  ".",|  |_."|  |   |  |  |  .--" |  |\    |     |  |    
 |  `---. /  .".  \ |  |      |  `---.|  |\  \(_|  |   |  |   |  |  |  `---.|  | \   |     |  |    
 `------""--"   "--"`--"      `------"`--" "--" `--"   `--"   `--"  `------"`--"  `--"     `--"    
"""
