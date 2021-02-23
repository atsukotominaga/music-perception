#!/usr/local/bin/python
####################
# Created: 23/02/2020
# This script converts txt files to mid files.

#%% import packages
import os, csv, mido

#%% create mid folder if not existed
if not os.path.exists("mid"):
    os.mkdir("mid")
if not os.path.exists("practice"):
    os.mkdir("practice")

#%% folder names
folder_a_t = "./1614096852-230221/art_teaching/"
folder_d_t = "./1614096852-230221/dyn_teaching/"
folder_a_p = "./1614096852-230221/art_performing/"
folder_d_p = "./1614096852-230221/dyn_performing/"
folders = [folder_a_t, folder_d_t, folder_a_p, folder_d_p]

#%% mid export
for folder in folders:
    files = [f for f in os.listdir(folder) if os.path.isfile(os.path.join(folder, f))]
    for instance in range(0, len(files)):
        filename = folder + files[instance]
        with open(filename) as csvfile:
            # create mid file
            mid = mido.MidiFile()
            track = mido.MidiTrack()
            mid.tracks.append(track)
            track.append(mido.Message('program_change', program=0, time=0)) # program 0 = Acoustic Grand Piano
            # name for mid file
            if folder == "./1614096852-230221/art_teaching/":
                midname = "./mid/a_t_" + str(instance+1) + ".mid"
            elif folder == "./1614096852-230221/dyn_teaching/":
                midname = "./mid/d_t_" + str(instance+1) + ".mid"
            elif folder == "./1614096852-230221/art_performing/":
                midname = "./mid/a_p_" + str(instance+1) + ".mid"
            elif folder == "./1614096852-230221/dyn_performing/":
                midname = "./mid/d_p_" + str(instance+1) + ".mid"
            # read current track data (txt file)   
            current = csv.reader(csvfile, delimiter = ",")
            next(current) # skip first row
            counter = 0
            for row in current:
                if counter == 0:
                    previousTime = 0
                    counter += 1
                else:
                    previousTime = currentTime
                if int(row[6]) == 100:
                    currentTime = int(mido.second2tick(int(row[1])*0.001+3, 480, 500000))
                elif int(row[6]) == 110:
                    currentTime = int(mido.second2tick(int(row[1])*0.001+3, 480, 462000))
                elif int(row[6]) == 120:
                    currentTime = int(mido.second2tick(int(row[1])*0.001+3, 480, 429000))
                currentPitch = int(row[2])
                currentVelocity = int(row[3])
                currentOnOff = int(row[4])
                # assign midi values
                if currentOnOff == 1:
                    track.append(mido.Message('note_on', note=currentPitch, velocity=currentVelocity, time=currentTime-previousTime))
                elif currentOnOff == 0:
                    track.append(mido.Message('note_off', note=currentPitch, velocity=currentVelocity, time=currentTime-previousTime))
            mid.save(midname) # save track

print("Experimental stimuli - Done :D")

#%%
folder_a_t_p = "./1614096852-230221/practice/art_teaching/"
folder_d_t_p = "./1614096852-230221/practice/dyn_teaching/"
folder_a_p_p = "./1614096852-230221/practice/art_performing/"
folder_d_p_p = "./1614096852-230221/practice/dyn_performing/"
folders_p = [folder_a_t_p, folder_d_t_p, folder_a_p_p, folder_d_p_p]

#%% mid export
for folder in folders_p:
    files = [f for f in os.listdir(folder) if os.path.isfile(os.path.join(folder, f))]
    for instance in range(0, len(files)):
        filename = folder + files[instance]
        with open(filename) as csvfile:
            # create mid file
            mid = mido.MidiFile()
            track = mido.MidiTrack()
            mid.tracks.append(track)
            track.append(mido.Message('program_change', program=0, time=0)) # program 0 = Acoustic Grand Piano
            # name for mid file
            if folder == "./1614096852-230221/practice/art_teaching/":
                midname = "./practice/a_t_" + str(instance+1) + ".mid"
            elif folder == "./1614096852-230221/practice/dyn_teaching/":
                midname = "./practice/d_t_" + str(instance+1) + ".mid"
            elif folder == "./1614096852-230221/practice/art_performing/":
                midname = "./practice/a_p_" + str(instance+1) + ".mid"
            elif folder == "./1614096852-230221/practice/dyn_performing/":
                midname = "./practice/d_p_" + str(instance+1) + ".mid"
            # read current track data (txt file)   
            current = csv.reader(csvfile, delimiter = ",")
            next(current) # skip first row
            counter = 0
            for row in current:
                if counter == 0:
                    previousTime = 0
                    counter += 1
                else:
                    previousTime = currentTime
                currentTime = int(mido.second2tick(int(row[1])*0.001+3, 480, 500000))
                currentPitch = int(row[2])
                currentVelocity = int(row[3])
                currentOnOff = int(row[4])
                # assign midi values
                if currentOnOff == 1:
                    track.append(mido.Message('note_on', note=currentPitch, velocity=currentVelocity, time=currentTime-previousTime))
                elif currentOnOff == 0:
                    track.append(mido.Message('note_off', note=currentPitch, velocity=currentVelocity, time=currentTime-previousTime))
            mid.save(midname) # save track

print("Practice stimuli - Done :D")