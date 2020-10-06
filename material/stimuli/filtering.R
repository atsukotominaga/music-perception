#!/usr/local/bin/R
#rm(list=ls(all=T)) # clear all

####################################
#  Documentation
####################################
# Created: 06/10/2020
# This script organises raw data and select performances which do not contain any pitch errors.
# GitHub repo (private): https://github.com/atsukotominaga/perception-v1.0/tree/master/material/stimuli

# create a folder if not exists
if (!file.exists("filtered")){
  dir.create("filtered")
}

# read functions
source("./function.R")

# read a text file for ideal performance
dt_ideal <- read.table("./ideal.txt")
colnames(dt_ideal) <- "Pitch"
dt_ideal$RowNr <- 1:nrow(dt_ideal)
setcolorder(dt_ideal, c(2, 1))

# create a list of data file names
lf <- list.files("./raw_data", pattern = "txt")

# create raw_data - merge all data files into one
raw_data <- data.table()
for (i in 1:length(lf)){
  data_i <- fread(file.path("./raw_data", lf[i]), header = F, sep = " ", dec = ".")
  raw_data <- rbind(raw_data, data_i)
}

# add column namesls
colnames(raw_data) <- c("NoteNr", "TimeStamp", "Pitch", "Velocity", "Key_OnOff", "Device", "SubNr", "BlockNr", "TrialNr", "Skill", "Condition", "Image")

# clean raw_data
raw_data$NoteNr <- as.numeric(gsub(",", "", raw_data$NoteNr))
raw_data$Image <- gsub(";", "", raw_data$Image)

# sort by SubNr, BlockNr, TrialNr
raw_data <- raw_data[order(raw_data$SubNr, raw_data$BlockNr, raw_data$TrialNr),]

# raw_data without metronome
dt_all <- raw_data[Pitch != 31 & Pitch != 34]

# onset and offset
dt_onset <- dt_all[Key_OnOff == 1]
dt_offset <- dt_all[Key_OnOff == 0]

# 1. Detect error trials
dt_error_onset <- checker(dt_onset, dt_ideal)
dt_error_offset <- checker(dt_offset, dt_ideal)

# combine onset/offset
dt_error <- rbind(dt_error_onset, dt_error_offset)
dt_error$Duplicate <- duplicated(dt_error)

# exclude these performances
dt_exclude <- dt_error[Duplicate == FALSE]

# mark imperfect performances
dt_all$Error <- 0
for (error in 1:nrow(dt_exclude)){
  dt_all[SubNr == dt_exclude$SubNr[error] & BlockNr == dt_exclude$BlockNr[error] & TrialNr == dt_exclude$TrialNr[error]]$Error <- 1
}
dt_include <- dt_all[Error == 0]

# exclude SubNr 16 due to a deviated tempo
dt_include <- dt_include[SubNr != 16]

# export as a separate txt for each performance
for (subject in unique(dt_include$SubNr)){
  for (block in unique(dt_include[SubNr == subject]$BlockNr)){
    for (trial in unique(dt_include[SubNr == subject & BlockNr == block]$TrialNr)){
      current <- dt_include[SubNr == subject & BlockNr == block & TrialNr == trial]
      firstTimestamp = current$TimeStamp[1]
      current$TimeStamp <- current$TimeStamp - firstTimestamp # start with time 0
      # export as txt
      filename = paste("./filtered/", subject, block, trial, ".txt", sep = "")
      fwrite(current, file = filename)
    }
  }
}
