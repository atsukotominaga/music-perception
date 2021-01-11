#!/usr/local/bin/R
#rm(list=ls(all=T)) # clear all

####################################
#  Documentation
####################################
# Created: 12/10/2020
# This script organises raw data and randomly select performances which do not contain any pitch errors (IOIs within 3SD).
# GitHub repo (private): https://github.com/atsukotominaga/perception-v1.0/tree/master/material/stimuli

# create folders if not exists
if (!file.exists("3sd/")){
  dir.create("3sd")
  dir.create("3sd/practice/")
}

if (!file.exists("3sd/art_teaching")){
  dir.create("3sd/art_teaching")
  dir.create("3sd/practice/art_teaching")
}

if (!file.exists("3sd/dyn_teaching")){
  dir.create("3sd/dyn_teaching")
  dir.create("3sd/practice/dyn_teaching")
}

if (!file.exists("3sd/art_performing")){
  dir.create("3sd/art_performing")
  dir.create("3sd/practice/art_performing")
}

if (!file.exists("3sd/dyn_performing")){
  dir.create("3sd/dyn_performing")
  dir.create("3sd/practice/dyn_performing")
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

# correct labelling (due to a labelling error of the original study)
# articulation
dt_a <- raw_data[grepl("stim_a", Image)]
# correct wrong labelling
dt_a$Skill <- "articulation"

# dynamics
dt_d <- raw_data[grepl("stim_d", Image)]
# correct wrong labelling
dt_d$Skill <- "dynamics"

# bind data frames for articulation and dynamics
dt_all <- rbind(dt_a, dt_d)

# raw_data without metronome
dt_all <- dt_all[Pitch != 31 & Pitch != 34]

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

# exclude IOIs +/- 3SD
dt_ioi <- dt_include[Key_OnOff == 1]
dt_ioi$IOI <- diff(c(0, dt_ioi$TimeStamp))
dt_ioi <- dt_ioi[NoteNr != 17] # remove irrelevant notes
dt_ioi$Interval <- rep(1:66, nrow(dt_ioi)/66)
ioi <- dt_ioi[Interval != 32 & Interval != 33 & Interval != 65 & Interval != 66, .(N = .N, Mean = mean(IOI), SD = sd(IOI)), by = .(SubNr, BlockNr, TrialNr)]
mean_ioi <- mean(ioi$Mean)
sd_ioi <- sd(ioi$Mean)
ioi_include <- ioi[Mean < mean_ioi+2*sd_ioi & Mean > mean_ioi-2*sd_ioi]

dt_include_updated <- data.table()
for (row in 1:nrow(ioi_include)){
  subnr = ioi_include$SubNr[row]
  block = ioi_include$BlockNr[row]
  trial = ioi_include$TrialNr[row]
  
  current <- dt_include[SubNr == subnr & BlockNr == block & TrialNr == trial]
  dt_include_updated <- rbind(dt_include_updated, current)
}

# create a list for included performances
list_include <- dt_include_updated[, .N, by = .(SubNr, BlockNr, TrialNr, Condition, Skill)]
list_overall <- list_include[, .N, by = .(Condition, Skill)]

# assign random nubmers for performances in each category
list_include$RandNr <- 0
for (cond in c("teaching", "performing")){
  for (skill in c("articulation", "dynamics")){
    list_include[Condition == cond & Skill == skill]$RandNr <- sample(nrow(list_include[Condition == cond & Skill == skill]), replace = FALSE)
  }
}
list_include <- list_include[order(RandNr),]

# stimuli for experimental trials
for (i in 1:96){ # 24 stimuli for each category
  subject = list_include$SubNr[i]
  block = list_include$BlockNr[i]
  trial = list_include$TrialNr[i]
  cond = list_include$Condition[i]
  skill = list_include$Skill[i]
  current <- dt_include[SubNr == subject & BlockNr == block & TrialNr == trial]
  firstTimestamp = current$TimeStamp[1]
  current$TimeStamp <- current$TimeStamp - firstTimestamp # start with time 0
  
  if (cond == "teaching" & skill == "articulation"){
    filename = paste("./3sd/art_teaching/", subject, block, trial, ".txt", sep = "")
  } else if (cond == "teaching" & skill == "dynamics"){
    filename = paste("./3sd/dyn_teaching/", subject, block, trial, ".txt", sep = "")
  } else if (cond == "performing" & skill == "articulation"){
    filename = paste("./3sd/art_performing/", subject, block, trial, ".txt", sep = "")
  } else if (cond == "performing" & skill == "dynamics"){
    filename = paste("./3sd/dyn_performing/", subject, block, trial, ".txt", sep = "")
  }
  fwrite(current, file = filename)
}

print("Experimental stimuli - Done! :)")

# stimuli for practice trials
for (i in 97:104){ # 4 stimuli for each category
  subject = list_include$SubNr[i]
  block = list_include$BlockNr[i]
  trial = list_include$TrialNr[i]
  cond = list_include$Condition[i]
  skill = list_include$Skill[i]
  current <- dt_include[SubNr == subject & BlockNr == block & TrialNr == trial]
  firstTimestamp = current$TimeStamp[1]
  current$TimeStamp <- current$TimeStamp - firstTimestamp # start with time 0
  
  if (cond == "teaching" & skill == "articulation"){
    filename = paste("./3sd/practice/art_teaching/", subject, block, trial, ".txt", sep = "")
  } else if (cond == "teaching" & skill == "dynamics"){
    filename = paste("./3sd/practice/dyn_teaching/", subject, block, trial, ".txt", sep = "")
  } else if (cond == "performing" & skill == "articulation"){
    filename = paste("./3sd/practice/art_performing/", subject, block, trial, ".txt", sep = "")
  } else if (cond == "performing" & skill == "dynamics"){
    filename = paste("./3sd/practice/dyn_performing/", subject, block, trial, ".txt", sep = "")
  }
  fwrite(current, file = filename)
}

print("Practice stimuli - Done! :)")
