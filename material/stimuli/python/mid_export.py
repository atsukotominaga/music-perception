#!/usr/local/bin/python
####################
# Created: 20/04/2020
# This script converts txt files to mid files.

#%% import packages
import os, csv, mido

#%% create mid folder if not existed
if not os.path.exists("mid"):
    os.mkdir("mid")

#%% folder names
folder_a_t = "../R/3sd/art_teaching/"
folder_d_t = "../R/3sd/dyn_teaching/"
folder_a_p = "../R/3sd/art_performing/"
folder_d_p = "../R/3sd/dyn_performing/"
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
            if folder == "../R/3sd/art_teaching/":
                midname = "./mid/a_t_" + str(instance+1) + ".mid"
            elif folder == "../R/3sd/dyn_teaching/":
                midname = "./mid/d_t_" + str(instance+1) + ".mid"
            elif folder == "../R/3sd/art_performing/":
                midname = "./mid/a_p_" + str(instance+1) + ".mid"
            elif folder == "../R/3sd/dyn_performing/":
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

print("Done :D")
# %%