## ----packages, include = FALSE------------------------------
# data manipulation
if (!require("data.table")) {install.packages("data.table"); require("data.table")}
# midi
if (!require("tuneR")) {install.packages("tuneR"); require("tuneR")}
# plot
if (!require("ggpubr")) {install.packages("ggpubr"); require("ggpubr")}
# stats
if (!require("ppcor")) {install.packages("ppcor"); require("ppcor")}
if (!require("performance")) {install.packages("performance"); require("performance")}


## ----read, include = FALSE----------------------------------
# read files and combine them
data_ls <- list.files("data", pattern = "csv")
combined <- lapply(data_ls, function(f){
  fread(paste("data/", f, sep = ""), sep = ",")
})
all_data <- do.call(rbind.data.frame, combined)

# remove irrelevant strings
data <- all_data[expMode == "experiment"]
data$MidFile <- gsub("./mid/", "", data$midFile)
data$MidFile <- gsub(".mid", "", data$MidFile)

# name conditions
data$Condition <- "NA"
data$Skill <- "NA"
data[grepl("_t_", midFile)]$Condition <- "teaching"
data[grepl("_p_", midFile)]$Condition <- "performing"
data[grepl("a_", midFile)]$Skill <- "articulation"
data[grepl("d_", midFile)]$Skill <- "dynamics"


## ----teaching, echo = FALSE---------------------------------
data$Teaching <- 0
data[rating == "Yes"]$Teaching <- 1

# individual
individual <- data[subjectNumber != 9, .(N = .N, Sum = sum(Teaching)), by = .(subjectNumber, Condition, Skill, MidFile)]
individual<- individual[order(subjectNumber)]

# all
all <- individual[, .(N = .N, Mean = mean(Sum), SD = sd(Sum), Mean_Percent = (mean(Sum))*100, SD_Percent = (sd(Sum))*100), by = .(Condition, Skill, MidFile)]
all <- all[order(MidFile)]
all


## ----midi, include = FALSE----------------------------------
# create a list of data file names
lf <- list.files("../experiment/mid/", pattern = "mid")

# combine data
all_data <- data.table()
for (file in lf){
   current <- readMidi(paste("../experiment/mid/", file, sep = ""))
   current$MidFile <- gsub(".mid", "", file)
   all_data <- rbind(all_data, current)
}

data <- all_data[event == "Note On" | event == "Note Off"]
data$NoteNr <- rep(1:134, nrow(data)/134)
data$channel <- NULL
data$parameterMetaSystem <- NULL
data$track <- NULL
data$type <- NULL
data$time2 <- (data$time/960)*1000 # deltatime to time (ms)

# labelling
colnames(data)[c(3,4)] <- c("Pitch", "Velocity") # time event also change
data$Condition <- "NA"
data$Skill <- "NA"
data[grepl("_t_", MidFile)]$Condition <- "teaching"
data[grepl("_p_", MidFile)]$Condition <- "performing"
data[grepl("a_", MidFile)]$Skill <- "articulation"
data[grepl("d_", MidFile)]$Skill <- "dynamics"

# define subcomponents
# For intervals
ls_legato <- list(c(1:7), c(17:23), c(42:48), c(58:64))
ls_staccato <- list(c(9:15), c(25:31), c(34:40), c(50:56))
ls_forte <- list(c(1:7), c(17:23), c(42:48), c(58:64))
ls_piano <- list(c(9:15), c(25:31), c(34:40), c(50:56))

# For each note (velocity only)
ls_legato_2 <- list(c(1:8), c(17:24), c(42:49), c(58:65))
ls_staccato_2 <- list(c(9:16), c(25:32), c(34:41), c(50:57))
ls_forte_2 <- list(c(1:8), c(17:24), c(42:49), c(58:65))
ls_piano_2 <- list(c(9:16), c(25:32), c(34:41), c(50:57))

# Define Skill Change (LtoS, FtoP)
change_1 <- c(8, 24, 49)
# Define Skill Change (StoL, PtoF)
change_2 <- c(16, 41, 57)


## ----ioi, include = FALSE-----------------------------------
data_onset <- data[event == "Note On"]
data_offset <- data[event == "Note Off"]

data_onset$IOI <- diff(c(0, data_onset$time2))
dt_ioi <- data_onset[NoteNr != 1]
dt_ioi$Interval <- rep(1:66, nrow(dt_ioi)/66)

# assign Subcomponents
dt_ioi$Subcomponent <- "NA"
# Legato
for (phrase in 1:length(ls_legato)){
 for (note in 1:length(ls_legato[[phrase]])){
   dt_ioi[Skill == "articulation" & Interval == ls_legato[[phrase]][note]]$Subcomponent <- "Legato"
 }
}
# Staccato
for (phrase in 1:length(ls_staccato)){
 for (note in 1:length(ls_staccato[[phrase]])){
   dt_ioi[Skill == "articulation" & Interval == ls_staccato[[phrase]][note]]$Subcomponent <- "Staccato"
 }
}

# Forte
for (phrase in 1:length(ls_forte)){
 for (note in 1:length(ls_forte[[phrase]])){
   dt_ioi[Skill == "dynamics" & Interval == ls_forte[[phrase]][note]]$Subcomponent <- "Forte"
 }
}
# Piano
for (phrase in 1:length(ls_piano)){
 for (note in 1:length(ls_piano[[phrase]])){
   dt_ioi[Skill == "dynamics" & Interval == ls_piano[[phrase]][note]]$Subcomponent <- "Piano"
 }
}

# assign Subcomponent Change
for (number in change_1){
 dt_ioi[Skill == "articulation" & Interval == number]$Subcomponent <- "LtoS"
 dt_ioi[Skill == "dynamics" & Interval == number]$Subcomponent <- "FtoP"
}
for (number in change_2){
 dt_ioi[Skill == "articulation" & Interval == number]$Subcomponent <- "StoL"
 dt_ioi[Skill == "dynamics" & Interval == number]$Subcomponent <- "PtoF"
}


## ----ioi-all, echo = FALSE----------------------------------
rating <- all # rating data

ioi <- dt_ioi[Subcomponent != "NA", .(N = .N, Mean = mean(IOI), SD = sd(IOI)), by = .(MidFile, Skill)]

# sorted
ioi <- ioi[order(MidFile)]

# plot
ioi$Teaching <- rating$Mean_Percent
ioi$TeachingSD <- rating$SD_Percent

ggscatter(ioi, x = "Mean", y = "Teaching", color = "Skill", add = "reg.line",
          add.params = list(fill = "lightgray"), conf.int = TRUE,
          xlab = "IOIs (ms)", ylab = "Judged as teaching (%)") + ylim(0, 100) + geom_vline(xintercept = 188, linetype="dotted", color = "gray", size = 1)


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(ioi[Skill == "articulation"]$Teaching)
shapiro.test(ioi[Skill == "articulation"]$Mean)

cor_ioi_art <- cor.test(ioi[Skill == "articulation"]$Teaching, ioi[Skill == "articulation"]$Mean)
cor_ioi_art


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(ioi[Skill == "dynamics"]$Teaching)
shapiro.test(ioi[Skill == "dynamics"]$Mean)

cor_ioi_dyn <- cor.test(ioi[Skill == "dynamics"]$Teaching, ioi[Skill == "dynamics"]$Mean)
cor_ioi_dyn

cor_ioi_dyn_spearman <- cor.test(ioi[Skill == "dynamics"]$Teaching, ioi[Skill == "dynamics"]$Mean, method = "spearman")
cor_ioi_dyn_spearman


## ----ioi-tra-all, echo = FALSE------------------------------
ioi_tra <- dt_ioi[Subcomponent == "LtoS" | Subcomponent == "StoL" | Subcomponent == "FtoP" | Subcomponent == "PtoF", .(N = .N, Mean = mean(IOI), SD = sd(IOI)), by = .(MidFile, Skill)]

# sorted
ioi_tra <- ioi_tra[order(MidFile)]

# plot
ioi_tra$Teaching <- rating$Mean_Percent
ioi_tra$TeachingSD <- rating$SD_Percent

ggscatter(ioi_tra, x = "Mean", y = "Teaching", color = "Skill", add = "reg.line",
          add.params = list(fill = "lightgray"), conf.int = TRUE,
          xlab = "IOIs (ms)", ylab = "Judged as teaching (%)") + ylim(0, 100) + geom_vline(xintercept = 188, linetype="dotted", color = "gray", size = 1)


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(ioi_tra[Skill == "articulation"]$Teaching)
shapiro.test(ioi_tra[Skill == "articulation"]$Mean)

cor.test(ioi_tra[Skill == "articulation"]$Teaching, ioi_tra[Skill == "articulation"]$Mean)


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(ioi_tra[Skill == "dynamics"]$Teaching)
shapiro.test(ioi_tra[Skill == "dynamics"]$Mean)

cor.test(ioi_tra[Skill == "dynamics"]$Teaching, ioi_tra[Skill == "dynamics"]$Mean)


## ----cv, echo = FALSE---------------------------------------
cv <- dt_ioi[Subcomponent != "NA", .(N = .N, CV = sd(IOI)/mean(IOI)), by = .(MidFile, Skill)]

# sorted
cv <- cv[order(MidFile)]

# plot
cv$Teaching <- rating$Mean_Percent
cv$TeachingSD <- rating$SD_Percent

ggscatter(cv, x = "CV", y = "Teaching", color = "Skill", add = "reg.line",
          add.params = list(fill = "lightgray"), conf.int = TRUE,
          xlab = "CV", ylab = "Judged as teaching (%)") + ylim(0, 100)


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(cv[Skill == "articulation"]$Teaching)
shapiro.test(cv[Skill == "articulation"]$CV)

cor.test(cv[Skill == "articulation"]$Teaching, cv[Skill == "articulation"]$CV)


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(cv[Skill == "dynamics"]$Teaching)
shapiro.test(cv[Skill == "dynamics"]$CV)

cor.test(cv[Skill == "dynamics"]$Teaching, cv[Skill == "dynamics"]$CV)


## ----kot, include = FALSE-----------------------------------
data_onset$KOT <- 0
for (row in 1:nrow(data_onset)){
   if (row < nrow(data_onset)){
      data_onset$KOT[row+1] <- data_offset$time2[row] - data_onset$time2[row+1] # offset(n) - onset(n+1)
   }
}

dt_kot <- data_onset[NoteNr != 1]
dt_kot$Interval <- rep(1:66, nrow(dt_kot)/66)

# assign Subcomponents
dt_kot$Subcomponent <- "NA"
# Legato
for (phrase in 1:length(ls_legato)){
   for (note in 1:length(ls_legato[[phrase]])){
     dt_kot[Skill == "articulation" & Interval == ls_legato[[phrase]][note]]$Subcomponent <- "Legato"
   }
}
# Staccato
for (phrase in 1:length(ls_staccato)){
   for (note in 1:length(ls_staccato[[phrase]])){
     dt_kot[Skill == "articulation" & Interval == ls_staccato[[phrase]][note]]$Subcomponent <- "Staccato"
   }
}
# Forte
for (phrase in 1:length(ls_forte)){
   for (note in 1:length(ls_forte[[phrase]])){
     dt_kot[Skill == "dynamics" & Interval == ls_forte[[phrase]][note]]$Subcomponent <- "Forte"
   }
}
# Piano
for (phrase in 1:length(ls_piano)){
   for (note in 1:length(ls_piano[[phrase]])){
     dt_kot[Skill == "dynamics" & Interval == ls_piano[[phrase]][note]]$Subcomponent <- "Piano"
   }
}
# assign Subcomponent Change
for (number in change_1){
   dt_kot[Skill == "articulation" & Interval == number]$Subcomponent <- "LtoS"
   dt_kot[Skill == "dynamics" & Interval == number]$Subcomponent <- "FtoP"
}
for (number in change_2){
   dt_kot[Skill == "articulation" & Interval == number]$Subcomponent <- "StoL"
   dt_kot[Skill == "dynamics" & Interval == number]$Subcomponent <- "PtoF"
}


## ----kot-all, echo = FALSE----------------------------------
kot_all <- dt_kot[Subcomponent == "Legato" | Subcomponent == "Staccato" | Subcomponent == "Forte" | Subcomponent == "Piano", .(N = .N, Mean = mean(KOT), SD = sd(KOT)), by = .(MidFile, Skill, Subcomponent)]

# sorted
kot_all <- kot_all[order(MidFile)]

# plot
kot_all$Teaching <- rep(rating$Mean_Percent, each = 2)
kot_all$TeachingSD <- rep(rating$SD_Percent, each = 2)

ggscatter(kot_all, x = "Mean", y = "Teaching", color = "Subcomponent", add = "reg.line", facet.by = "Skill",
          add.params = list(fill = "lightgray"), conf.int = TRUE, cor.coef = FALSE,
          xlab = "KOT (ms)", ylab = "Judged as teaching (%)") + ylim(0, 100)


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(kot_all[Subcomponent == "Legato"]$Teaching)
shapiro.test(kot_all[Subcomponent == "Legato"]$Mean)

cor_kot_leg <- cor.test(kot_all[Subcomponent == "Legato"]$Teaching, kot_all[Subcomponent == "Legato"]$Mean)
cor_kot_leg


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(kot_all[Subcomponent == "Staccato"]$Teaching)
shapiro.test(kot_all[Subcomponent == "Staccato"]$Mean)

cor_kot_sta <- cor.test(kot_all[Subcomponent == "Staccato"]$Teaching, kot_all[Subcomponent == "Staccato"]$Mean)
cor_kot_sta


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(kot_all[Subcomponent == "Forte"]$Teaching)
shapiro.test(kot_all[Subcomponent == "Forte"]$Mean)

cor_kot_for <- cor.test(kot_all[Subcomponent == "Forte"]$Teaching, kot_all[Subcomponent == "Forte"]$Mean)
cor_kot_for

cor_kot_for_spearman <- cor.test(kot_all[Subcomponent == "Forte"]$Teaching, kot_all[Subcomponent == "Forte"]$Mean, method = "spearman")
cor_kot_for_spearman


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(kot_all[Subcomponent == "Piano"]$Teaching)
shapiro.test(kot_all[Subcomponent == "Piano"]$Mean)

cor_kot_pia <- cor.test(kot_all[Subcomponent == "Piano"]$Teaching, kot_all[Subcomponent == "Piano"]$Mean)
cor_kot_pia

cor_kot_pia_spearman <- cor.test(kot_all[Subcomponent == "Piano"]$Teaching, kot_all[Subcomponent == "Piano"]$Mean, method = "spearman")
cor_kot_pia_spearman


## ----vel, include = FALSE-----------------------------------
dt_vel <- data_onset
dt_vel$Note <- rep(1:67, nrow(dt_vel)/67)
# assign Subcomponents
# for each note
dt_vel$Subcomponent <- "NA"
# Legato
for (phrase in 1:length(ls_legato_2)){
   for (note in 1:length(ls_legato_2[[phrase]])){
     dt_vel[Skill == "articulation" & Note == ls_legato_2[[phrase]][note]]$Subcomponent <- "Legato"
   }
}
# Staccato
for (phrase in 1:length(ls_staccato_2)){
   for (note in 1:length(ls_staccato_2[[phrase]])){
     dt_vel[Skill == "articulation" & Note == ls_staccato_2[[phrase]][note]]$Subcomponent <- "Staccato"
   }
}
# Forte
for (phrase in 1:length(ls_forte_2)){
   for (note in 1:length(ls_forte_2[[phrase]])){
     dt_vel[Skill == "dynamics" & Note == ls_forte_2[[phrase]][note]]$Subcomponent <- "Forte"
   }
}
# Piano
for (phrase in 1:length(ls_piano_2)){
   for (note in 1:length(ls_piano_2[[phrase]])){
     dt_vel[Skill == "dynamics" & Note == ls_piano_2[[phrase]][note]]$Subcomponent <- "Piano"
   }
}


## ----vel-all, echo = FALSE----------------------------------
vel_all <- dt_vel[Subcomponent == "Legato" | Subcomponent == "Staccato" | Subcomponent == "Forte" | Subcomponent == "Piano", .(N = .N, Mean = mean(Velocity), SD = sd(Velocity)), by = .(MidFile, Skill, Subcomponent)]

# sorted
vel_all <- vel_all[order(MidFile)]

# plot
vel_all$Teaching <- rep(rating$Mean_Percent, each = 2)
vel_all$TeachingSD <- rep(rating$SD_Percent, each = 2)

ggscatter(vel_all, x = "Mean", y = "Teaching", color = "Subcomponent", add = "reg.line", facet.by = "Skill",
          add.params = list(fill = "lightgray"), conf.int = TRUE, cor.coef = FALSE,
          xlab = "Velocity (0-127)", ylab = "Judged as teaching (%)") + ylim(0, 100)


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(vel_all[Subcomponent == "Forte"]$Teaching)
shapiro.test(vel_all[Subcomponent == "Forte"]$Mean)

cor_vel_for <- cor.test(vel_all[Subcomponent == "Forte"]$Teaching, vel_all[Subcomponent == "Forte"]$Mean)
cor_vel_for


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(vel_all[Subcomponent == "Piano"]$Teaching)
shapiro.test(vel_all[Subcomponent == "Piano"]$Mean)

cor_vel_pia <- cor.test(vel_all[Subcomponent == "Piano"]$Teaching, vel_all[Subcomponent == "Piano"]$Mean)
cor_vel_pia


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(vel_all[Subcomponent == "Legato"]$Teaching)
shapiro.test(vel_all[Subcomponent == "Legato"]$Mean)

cor_vel_leg <- cor.test(vel_all[Subcomponent == "Legato"]$Teaching, vel_all[Subcomponent == "Legato"]$Mean)
cor_vel_leg

cor_vel_leg_spearman <- cor.test(vel_all[Subcomponent == "Legato"]$Teaching, vel_all[Subcomponent == "Legato"]$Mean, method = "spearman")
cor_vel_leg_spearman


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(vel_all[Subcomponent == "Staccato"]$Teaching)
shapiro.test(vel_all[Subcomponent == "Staccato"]$Mean)

cor_vel_sta <- cor.test(vel_all[Subcomponent == "Staccato"]$Teaching, vel_all[Subcomponent == "Staccato"]$Mean)
cor_vel_sta


## ----vel-diff, include = FALSE------------------------------
data_onset$Diff <- diff(c(0, data_onset$Velocity))
dt_vel_diff <- data_onset[NoteNr != 1]
# assign Interval
dt_vel_diff$Interval <- rep(1:66, nrow(dt_vel_diff)/66)

# for intervals
dt_vel_diff$Subcomponent <- "NA"
# Legato
for (phrase in 1:length(ls_legato)){
for (note in 1:length(ls_legato[[phrase]])){
  dt_vel_diff[Skill == "articulation" & Interval == ls_legato[[phrase]][note]]$Subcomponent <- "Legato"
}
}
# Staccato
for (phrase in 1:length(ls_staccato)){
for (note in 1:length(ls_staccato[[phrase]])){
  dt_vel_diff[Skill == "articulation" & Interval == ls_staccato[[phrase]][note]]$Subcomponent <- "Staccato"
}
}
# Forte
for (phrase in 1:length(ls_forte)){
for (note in 1:length(ls_forte[[phrase]])){
  dt_vel_diff$Subcomponent[dt_vel_diff$Skill == "dynamics" & dt_vel_diff$Interval == ls_forte[[phrase]][note]] <- "Forte"
}
}
# Piano
for (phrase in 1:length(ls_piano)){
for (note in 1:length(ls_piano[[phrase]])){
  dt_vel_diff[Skill == "dynamics" & Interval == ls_piano[[phrase]][note]]$Subcomponent <- "Piano"
}
}
# Assign Skill Change
for (i in change_1){
dt_vel_diff[Skill == "articulation" & Interval == i]$Subcomponent <- "LtoS"
dt_vel_diff[Skill == "dynamics" & Interval == i]$Subcomponent <- "FtoP"
}
for (i in change_2){
dt_vel_diff[Skill == "articulation" & Interval == i]$Subcomponent <- "StoL"
dt_vel_diff[Skill == "dynamics" & Interval == i]$Subcomponent <- "PtoF"
}


## ----vel-diff-all, echo = FALSE-----------------------------
vel_diff_all <- dt_vel_diff[Subcomponent == "FtoP" | Subcomponent == "PtoF" | Subcomponent == "LtoS" | Subcomponent == "StoL", .(N = .N, Mean = mean(Diff), SD = sd(Diff)), by = .(MidFile, Skill, Subcomponent)]

# sorted
vel_diff_all <- vel_diff_all[order(MidFile)]

# plot
vel_diff_all$Teaching <- rep(rating$Mean_Percent, each = 2)
vel_diff_all$TeachingSD <- rep(rating$SD_Percent, each = 2)

ggscatter(vel_diff_all, x = "Mean", y = "Teaching", color = "Subcomponent", add = "reg.line", facet.by = "Skill",
          add.params = list(fill = "lightgray"), conf.int = TRUE, cor.coef = FALSE,
          xlab = "Velocity Difference (-127-127)", ylab = "Judged as teaching (%)") + ylim(0, 100)


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(vel_diff_all[Subcomponent == "FtoP"]$Teaching)
shapiro.test(vel_diff_all[Subcomponent == "FtoP"]$Mean)

cor_vel_diff_ftop <- cor.test(vel_diff_all[Subcomponent == "FtoP"]$Teaching, vel_diff_all[Subcomponent == "FtoP"]$Mean)
cor_vel_diff_ftop


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(vel_diff_all[Subcomponent == "PtoF"]$Teaching)
shapiro.test(vel_diff_all[Subcomponent == "PtoF"]$Mean)

cor_vel_diff_ptof <- cor.test(vel_diff_all[Subcomponent == "PtoF"]$Teaching, vel_diff_all[Subcomponent == "PtoF"]$Mean)
cor_vel_diff_ptof


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(vel_diff_all[Subcomponent == "LtoS"]$Teaching)
shapiro.test(vel_diff_all[Subcomponent == "LtoS"]$Mean)

cor_vel_diff_ltos <- cor.test(vel_diff_all[Subcomponent == "LtoS"]$Teaching, vel_diff_all[Subcomponent == "LtoS"]$Mean)
cor_vel_diff_ltos

cor_vel_diff_ltos_spearman <- cor.test(vel_diff_all[Subcomponent == "LtoS"]$Teaching, vel_diff_all[Subcomponent == "LtoS"]$Mean, method = "spearman")
cor_vel_diff_ltos_spearman


## ---- echo = FALSE------------------------------------------
# normality check
shapiro.test(vel_diff_all[Subcomponent == "StoL"]$Teaching)
shapiro.test(vel_diff_all[Subcomponent == "StoL"]$Mean)

cor_vel_diff_stol <- cor.test(vel_diff_all[Subcomponent == "StoL"]$Teaching, vel_diff_all[Subcomponent == "StoL"]$Mean)
cor_vel_diff_stol


## ----partial, include = FALSE-------------------------------
partial <- dt_ioi[Subcomponent != "NA", .(N = .N, IOI = mean(IOI), IOISD = sd(IOI)), by = .(MidFile, Skill)]
partial <- rbind(partial, partial)
partial <- partial[order(MidFile)]

partial$Subcomponent <- kot_all$Subcomponent
partial$KOT <- kot_all$Mean
partial$KOTSD <- kot_all$SD
partial$KV <- vel_all$Mean
partial$KVSD <- vel_all$SD
partial$Subcomponent2 <- vel_diff_all$Subcomponent
partial$KVDiff <- vel_diff_all$Mean
partial$KVDiffSD <- vel_diff_all$SD

partial$Teaching <- rep(rating$Mean_Percent, each = 2)
partial$TeachingSD <- rep(rating$SD_Percent, each = 2)


## ----kot-partial-leg, echo = TRUE---------------------------
pcor.test(partial[Subcomponent == "Legato"]$KOT, partial[Subcomponent == "Legato"]$Teaching, partial[Subcomponent == "Legato", c("IOI", "KV", "KVDiff")])


## ----kot-partial-sta, echo = TRUE---------------------------
pcor.test(partial[Subcomponent == "Staccato"]$KOT, partial[Subcomponent == "Staccato"]$Teaching, partial[Subcomponent == "Staccato", c("IOI", "KV", "KVDiff")])


## ----vel-partial-for, echo = TRUE---------------------------
pcor.test(partial[Subcomponent == "Forte"]$KV, partial[Subcomponent == "Forte"]$Teaching, partial[Subcomponent == "Forte", c("IOI", "KOT", "KVDiff")])


## ----vel-partial-pia, echo = TRUE---------------------------
pcor.test(partial[Subcomponent == "Piano"]$KV, partial[Subcomponent == "Piano"]$Teaching, partial[Subcomponent == "Piano", c("IOI", "KOT", "KVDiff")])


## ----vel-diff-partial-ftop, echo = TRUE---------------------
pcor.test(partial[Subcomponent2 == "FtoP"]$KVDiff, partial[Subcomponent2 == "FtoP"]$Teaching, partial[Subcomponent2 == "FtoP", c("IOI", "KOT", "KV")])


## ----vel-diff-partial-ptof, echo = TRUE---------------------
pcor.test(partial[Subcomponent2 == "PtoF"]$KVDiff, partial[Subcomponent2 == "PtoF"]$Teaching, partial[Subcomponent2 == "PtoF", c("IOI", "KOT", "KV")])


## ---- echo = TRUE-------------------------------------------
m1 <- lm(Teaching ~ IOI + KOT + KV + KVDiff, data = partial[Subcomponent == "Legato"])
summary(m1)
check_model(m1)


## ---- echo = TRUE-------------------------------------------
m2 <- lm(Teaching ~ IOI + KOT + KV + KVDiff, data = partial[Subcomponent == "Staccato"])
summary(m2)
check_model(m2)


## ---- echo = TRUE-------------------------------------------
m3 <- lm(Teaching ~ IOI + KOT + KV + KVDiff, data = partial[Subcomponent == "Forte"])
summary(m3)
check_model(m3)


## ---- echo = TRUE-------------------------------------------
m4 <- lm(Teaching ~ IOI + KOT + KV + KVDiff, data = partial[Subcomponent == "Piano"])
summary(m4)
check_model(m4)

## ----export, include = FALSE--------------------------------
knitr::purl("analysis.Rmd")

