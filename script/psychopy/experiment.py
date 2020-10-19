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
    stimuli = visual.ImageStim(win, image = imageFile, size = [1500, 300])
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
    ratingScale = visual.RatingScale(win, pos = (0, -300), choices = ["Yes", "No"], lineColor = (-.7, -.7, -.7), tickHeight = 0.0, markerStart = 0.5, markerColor = "Orange", textFont = "Avenir", size = 1.5, noMouse = True, acceptKeys = "return", showAccept = False, acceptPreText =  "Select your response", acceptSize = 1.8, skipKeys = None)
    question = visual.TextStim(win, pos=[0, 0], font = "Avenir", height = 60, wrapWidth = 1400,
    text = "Teaching?\nYes: <Left>    No: <Right>\n\nPress <Return> to confirm\n\n\n\n")
    trialClock = core.Clock()
    while ratingScale.noResponse:
        question.draw()
        ratingScale.draw()
        win.flip()
        if len(ratingScale.getHistory()) == 2: # if accidentally hit return, ignore
            ratingScale.noResponse = True
        elif len(ratingScale.getHistory()) > 2 and ratingScale.getHistory()[-1] == ratingScale.getHistory()[-2]: # if there is no response, ignore (i.e., keep on pressing return)
            ratingScale.noResponse = True

    # store responses1
    resultsList.append([
        expMode, # practice/experiment
        trialCounter, # trial number
        midFile, # mid file
        ratingScale.getRating(), # final answer
        trialClock.getTime(), # RT1
        ratingScale.getRT(), # RT2
        #ratingScale.getHistory(), # history
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

# participants's info
expInfo = {"Number": "", "Today": data.getDateStr(), "Expression": ["Articulation", "Dynamics"]}
dlg = gui.DlgFromDict(expInfo, fixed = ["Today"], title = "Music Perception 2020")
if dlg.OK == False:
    print("user cancelled")
    core.quit() # cancel

# programme for Articulation or Dynamics
if expInfo["Expression"] == "Articulation":
    # sheet music
    imageFile = "./image/stim_a.png"
    text_3 = "Musical Technique: [ Articulation ]\nthe smoothness of sound\nslurs: legato, dots: staccato\n\n\n\n\n\n\nPress <Space> to continue"
    pFileList = [f for f in os.listdir("practice/") if f.startswith("a_")]
    eFileList = [f for f in os.listdir("mid/") if f.startswith("a_")]
    
elif expInfo["Expression"] == "Dynamics":
    # sheet music
    imageFile = "./image/stim_d.png"
    text_3 = "Musical Technique: [ Dynamics ]\nthe loudness of sound\nf: forte, p: piano\n\n\n\n\n\n\nPress <Space> to continue"
    pFileList = [f for f in os.listdir("practice/") if f.startswith("d_")]
    eFileList = [f for f in os.listdir("mid/") if f.startswith("d_")]

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
    text = "Thank you very much for participating in our study!\n\nIn this experiment, you are going to listen to a number of piano performances and be asked to judge whether each performance was produced in order to teach a musical technique or not.\n\nPress <Space> to continue")
inst1.draw()
win.flip()
next() # proceed/force quit

## instruction 2
imageSheet = visual.ImageStim(win, image = imageFile, pos = [0, -50], size = [1500, 300])
inst2 = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 60, wrapWidth = 1400,
    text = "You will listen to one piece with one notated musical technique.\n\n\n\n\n\n\nPress <Space> to continue")
imageSheet.draw()
inst2.draw()
win.flip()
next() # proceed/force quit

## instruction 3
inst3 = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 60, wrapWidth = 1400, text = text_3)
imageSheet.draw()
inst3.draw()
win.flip()
next() # proceed/force quit

## instruction 4
inst4 = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 60, wrapWidth = 1400, alignText = "left",
    text = "Each performance was produced in order to either\n\n1) teach the musical technique (as a teacher) \n\nor\n\n2) perform their best (as a performer)\n\nPress <Space> to continue")
inst4.draw()
win.flip()
next() # proceed/force quit

## instruction 5
inst5 = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 60, wrapWidth = 1400, alignText = "left",
    text = "You will be asked to judge whether each performer had the intention to teach or not by pressing the 'Yes' <Left> or 'No' <Right> key.\n\nPress <Space> to continue")
inst5.draw()
win.flip()
next() # proceed/force quit

## instruction 6
inst6 = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 60, wrapWidth = 1400, alignText = "left",
    text = "Any questions? If not, we will start practice trials to make sure you understand the procedure.\n\nPress <Space> to start practice trials")
inst6.draw()
win.flip()
next() # proceed/force quit

### Practice ###
expMode = "practice"
random.shuffle(pFileList) # stimuli randomisation
practice = True
while practice:
    trialCounter = 1
    for file in pFileList:
        midFile = "./practice/" + file
        trial(expMode, imageFile, midFile, resultsList)
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
    text = "You will listen to 48 performances (trials). You can take a break between each trial whenever you want.\n\nAny questions? If not,\n\nPress <Space> to start experimental trials")
inst8.draw()
win.flip()
next() # proceed/force quit

### Experiment ###
expMode = "experiment"
random.shuffle(eFileList) # stimuli randomisation

trialCounter = 1
for file in eFileList:
    midFile = "./mid/" + file
    trial(expMode, imageFile, midFile, resultsList)
    trialCounter += 1

# write results
for item in resultsList:
    dataFile.write('{0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}\n'.format(*item))
dataFile.close()

### Thank you ###
thanks = visual.TextStim(win, pos = [0, 0], font = "Avenir", height = 70, wrapWidth = 1400,
    text = "This is the end of the experiment.\n\nThank you!")
thanks.draw()
win.flip()
core.wait(3)

### Close ###
win.close()
core.quit()
