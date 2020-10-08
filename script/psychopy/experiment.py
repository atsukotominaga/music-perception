#!usr/bin/env python

"""
This is an experimental programme for Music Perception 2020
"""

# import libraries
from psychopy import core, visual, gui, data, event
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

def trial(expMode, imageFile, midFile, resultsList):
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
    trialClock = core.Clock()
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

# open Max port
os.system("open " + "./midiplayer.maxpat") # open max file
port = mido.open_output("to Max 1")

# participants’s info
expInfo = {"Number": "", "Today": data.getDateStr(), "Expression": ["Articulation", "Dynamics"]}
dlg = gui.DlgFromDict(expInfo, fixed = ["Today"], title = "Music Perception 2020")
if dlg.OK == False:
    print("user cancelled")
    core.quit() # cancel

# programme for Articulation or Dynamics
if expInfo["Expression"] == "Articulation":
    # sheet music
    imageFile = "./image/stim_a.png"
    print(expInfo["Expression"])
elif expInfo["Expression"] == "Dynamics":
    # sheet music
    imageFile = "./image/stim_d.png"
    print(expInfo["Expression"])

# create csv to save data
if not os.path.exists("data"): # make a folder if not exists
    os.makedirs("data")
filename = expInfo["Number"] + expInfo["Today"]
dataFile = open("./data/" + filename + ".csv", "w")
dataFile.write("expMode,trialNumber,midFile,rating,RT1 (manual),RT2 (ratingScale),subjectNumber,date,globalClock\n")

# list to store answers
resultsList = []

# create window and stimuli
win = visual.Window([1920, 1200], monitor = "testMonitor", fullscr = True, color = (-.7, -.7, -.7), units = "pix")
win.mouseVisible = False # hide mouse

# add global clock
globalClock = core.Clock()

### Instruction ###
# display instructions and wait
inst1 = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 60, wrapWidth = 1400, alignText = "left",
    text = "Thank you very much for participating in the pilot study!\n\nIn this experiment, you are going to listen to a number of piano performances and will be asked to judge whether each performance was produced in order to teach a musical technique or not.\n\nPress <Space> to continue")
inst1.draw()
win.flip()
next() # proceed/force quit

## instruction 2
imageSheet = visual.ImageStim(win, image = imageFile, pos = [0, -50], size = [1500, 300])
inst2 = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 60, wrapWidth = 1400,
    text = "You will listen to one piece with one notated musical technique.\n\n\n\n\n\n\n\n\nPress <Space> to continue")
imageSheet.draw()
inst2.draw()
win.flip()
next() # proceed/force quit

## instruction 3
inst3 = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 60, wrapWidth = 1400, text = "Something\n\n\n\n\n\n\n\n\nPress <Space> to continue")
imageSheet.draw()
inst3.draw()
win.flip()
next() # proceed/force quit

### Practice ###
expMode = "practice"
pFileList = os.listdir("practice")
random.shuffle(pFileList) # stimuli randomisation
practice = True
while practice:
    trialCounter = 1
    for file in pFileList:
        midFile = "./practice/" + file
        ratingOrder = random.choice(["articulation", "dynamics"])
        trial(expMode, imageFile, midFile, ratingOrder, resultsList)
        trialCounter += 1
        
    ## instruction practice
    inst_p = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 60, wrapWidth = 1400, alignText = "left",
        text = "Any questions?\n\nIf you want to repeat the practice trials again,\nPress <Return> key.\n\nIf you are ready for experimental trials,\nPress <Space> to start")
    inst_p.draw()
    win.flip()
    resp = None
    while resp == None:
        allKeys = event.getKeys(keyList = ["space", "escape", "return"])
        for resp in allKeys:
            if resp == "space": # proceed
                practice = False
            elif resp == "escape": # force quit
                core.quit()
            elif resp == "return": # practice again
                practice = True

inst8 = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 60, wrapWidth = 1400, alignText = "left",
    text = "In total, there are ?? performance recordings.\n\nAny questions? If not,\n\nPress <Space> to start experimental trials")
inst8.draw()
win.flip()
next() # proceed/force quit

### Experiment ###
expMode = "experiment"
eFileList = os.listdir("mid")
random.shuffle(eFileList) # stimuli randomisation

trialCounter = 1
for file in eFileList:
    midFile = "./mid/" + file
    trial(expMode, imageFile, midFile, resultsList)
    trialCounter += 1

# write results
for item in resultsList:
    dataFile.write('{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}\n'.format(*item))
dataFile.close()

### Thank you ###
thanks = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 100, wrapWidth = 1400,
    text = "Thank you!")
thanks.draw()
win.flip()
core.wait(3)

### Close ###
win.close()
core.quit()