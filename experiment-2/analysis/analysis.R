## ----setup, include = FALSE---------------------------------------------------
options(knitr.duplicate.label = "allow")

# data manipulation
if (!require("data.table")) {install.packages("data.table"); require("data.table")}
# midi
if (!require("tuneR")) {install.packages("tuneR"); require("tuneR")}
# plot
if (!require("ggpubr")) {install.packages("ggpubr"); require("ggpubr")}
if (!require("corrplot")) {install.packages("corrplot"); require("corrplot")}
# stats
if (!require("ppcor")) {install.packages("ppcor"); require("ppcor")}
if (!require("performance")) {install.packages("performance"); require("performance")}


## ----read, include = FALSE----------------------------------------------------
# read files and combine them
data_lf <- list.files("../data", pattern = "csv")
combined <- lapply(data_lf, function(f){
  fread(paste("../data/", f, sep = ""), sep = ",")
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


## ----teaching, echo = FALSE---------------------------------------------------
data$Teaching <- 0
data[rating == "Yes"]$Teaching <- 1

# individual
individual <- data[subjectNumber != 4, .(N = .N, Sum = sum(Teaching)), by = .(subjectNumber, Condition, Skill, MidFile)]
individual<- individual[order(subjectNumber)]

# all
all <- individual[, .(N = .N, Mean = mean(Sum), SD = sd(Sum), Mean_Percent = (mean(Sum))*100, SD_Percent = (sd(Sum))*100), by = .(Condition, Skill, MidFile)]
all <- all[order(MidFile)]
all


## ----midi, include = FALSE----------------------------------------------------
# create a list of data file names
midi_lf <- list.files("../experiment/mid/", pattern = "mid")

# combine data
all_midi <- data.table()
for (file in midi_lf){
   current <- readMidi(paste("../experiment/mid/", file, sep = ""))
   current$MidFile <- gsub(".mid", "", file)
   all_midi <- rbind(all_midi, current)
}

midi <- all_midi[event == "Note On" | event == "Note Off"]
midi$NoteNr <- rep(1:144, nrow(midi)/144)
midi$channel <- NULL
midi$parameterMetaSystem <- NULL
midi$track <- NULL
midi$type <- NULL
midi$time2 <- (midi$time/960)*1000 # deltatime to time (ms)

# labelling
colnames(midi)[c(3,4)] <- c("Pitch", "Velocity") # time event also change
midi$Condition <- "NA"
midi$Skill <- "NA"
midi[grepl("_t_", MidFile)]$Condition <- "teaching"
midi[grepl("_p_", MidFile)]$Condition <- "performing"
midi[grepl("a_", MidFile)]$Skill <- "articulation"
midi[grepl("d_", MidFile)]$Skill <- "dynamics"

# define subcomponents
# for intervals
ls_legato <- list(c(1:4), c(9:16), c(21:24), c(40:46))
ls_staccato <- list(c(6:7), c(18:19), c(29:31), c(36:38), c(48:50), c(53:55), c(58:64))
ls_forte <- list(c(1:4), c(9:16), c(21:24), c(40:46))
ls_piano <- list(c(6:7), c(18:19), c(29:31), c(36:38), c(48:50), c(53:55), c(58:64))

# for each note (velocity)
ls_legato_2 <- list(c(1:5), c(9:17), c(21:26), c(40:47))
ls_staccato_2 <- list(c(6:8), c(18:20), c(29:32), c(36:39), c(48:51), c(53:56), c(58:65))
ls_forte_2 <- list(c(1:5), c(9:17), c(21:26), c(40:47))
ls_piano_2 <- list(c(6:8), c(18:20), c(29:32), c(36:39), c(48:51), c(53:56), c(58:65))

# define Component Change (LtoS, FtoP)
change_1 <- c(5, 17, 47)
# define Component Change (StoL, PtoF)
change_2 <- c(8, 20, 39)


## ----ioi, include = FALSE-----------------------------------------------------
data_onset <- midi[event == "Note On"]
data_offset <- midi[event == "Note Off"]

data_onset$IOI <- diff(c(0, data_onset$time2))
dt_ioi <- data_onset[NoteNr != 1]
dt_ioi$Interval <- rep(1:71, nrow(dt_ioi)/71)

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


## ----ioi-all, echo = FALSE----------------------------------------------------
rating <- all # rating data

ioi <- dt_ioi[Subcomponent != "NA", .(N = .N, Mean = mean(IOI), SD = sd(IOI)), by = .(MidFile, Skill)]

# sorted
ioi <- ioi[order(MidFile)]

# plot
ioi$Teaching <- rating$Mean_Percent
ioi$TeachingSD <- rating$SD_Percent

ggscatter(ioi, x = "Mean", y = "Teaching", color = "Skill", add = "reg.line",
          add.params = list(fill = "lightgray"), conf.int = TRUE,
          xlab = "IOIs (ms)", ylab = "Judged as teaching (%)") + scale_x_continuous(breaks = seq(240, 332, 20)) + coord_cartesian(xlim = c(240, 332), ylim = c(0, 100)) + theme(aspect.ratio = 1)


## ---- echo = FALSE------------------------------------------------------------
# normality check
ioi_art_norm_teaching <- shapiro.test(ioi[Skill == "articulation"]$Teaching)
ioi_art_norm_performance <- shapiro.test(ioi[Skill == "articulation"]$Mean)

# qqnorm(ioi[Skill == "articulation"]$Teaching)
# qqline(ioi[Skill == "articulation"]$Teaching)
# ioi_art_norm_teaching
# 
# qqnorm(ioi[Skill == "articulation"]$Mean)
# qqline(ioi[Skill == "articulation"]$Mean)
# ioi_art_norm_performance

cor_ioi_art <- cor.test(ioi[Skill == "articulation"]$Teaching, ioi[Skill == "articulation"]$Mean)
cor_ioi_art


## ---- echo = FALSE------------------------------------------------------------
# normality check
ioi_dyn_norm_teaching <- shapiro.test(ioi[Skill == "dynamics"]$Teaching)
ioi_dyn_norm_performance <- shapiro.test(ioi[Skill == "dynamics"]$Mean)

# qqnorm(ioi[Skill == "dynamics"]$Teaching)
# qqline(ioi[Skill == "dynamics"]$Teaching)
# ioi_dyn_norm_teaching
# 
# qqnorm(ioi[Skill == "dynamics"]$Mean)
# qqline(ioi[Skill == "dynamics"]$Mean)
# ioi_dyn_norm_performance

cor_ioi_dyn <- cor.test(ioi[Skill == "dynamics"]$Teaching, ioi[Skill == "dynamics"]$Mean)
cor_ioi_dyn

cor_ioi_dyn_spearman <- cor.test(ioi[Skill == "dynamics"]$Teaching, ioi[Skill == "dynamics"]$Mean, method = "spearman", exact = FALSE)
cor_ioi_dyn_spearman


## ---- echo = FALSE------------------------------------------------------------
mean = mean(ioi[Skill == "dynamics"]$Mean)
sd = sd(ioi[Skill == "dynamics"]$Mean)

# normality check
shapiro.test(ioi[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
shapiro.test(ioi[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

# qqnorm(ioi[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# qqline(ioi[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# 
# qqnorm(ioi[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)
# qqline(ioi[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

cor.test(ioi[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching, ioi[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)


## ----ioi-tra-all, echo = FALSE------------------------------------------------
ioi_tra <- dt_ioi[Subcomponent == "LtoS" | Subcomponent == "StoL" | Subcomponent == "FtoP" | Subcomponent == "PtoF", .(N = .N, Mean = mean(IOI), SD = sd(IOI)), by = .(MidFile, Skill)]

# sorted
ioi_tra <- ioi_tra[order(MidFile)]

# plot
ioi_tra$Teaching <- rating$Mean_Percent
ioi_tra$TeachingSD <- rating$SD_Percent

ggscatter(ioi_tra, x = "Mean", y = "Teaching", color = "Skill", add = "reg.line",
          add.params = list(fill = "lightgray"), conf.int = TRUE,
          xlab = "IOIs (ms)", ylab = "Judged as teaching (%)") + ylim(0, 100) + theme(aspect.ratio = 1)


## ---- echo = FALSE------------------------------------------------------------
# normality check
ioi_art_tra_norm_teaching <- shapiro.test(ioi_tra[Skill == "articulation"]$Teaching)
ioi_art_tra_norm_performance <- shapiro.test(ioi_tra[Skill == "articulation"]$Mean)

# qqnorm(ioi_tra[Skill == "articulation"]$Teaching)
# qqline(ioi_tra[Skill == "articulation"]$Teaching)
# ioi_art_tra_norm_teaching
# 
# qqnorm(ioi_tra[Skill == "articulation"]$Mean)
# qqline(ioi_tra[Skill == "articulation"]$Mean)
# ioi_art_tra_norm_performance

cor.test(ioi_tra[Skill == "articulation"]$Teaching, ioi_tra[Skill == "articulation"]$Mean)

cor.test(ioi_tra[Skill == "articulation"]$Teaching, ioi_tra[Skill == "articulation"]$Mean, method = "spearman", exact = FALSE)


## ---- echo = FALSE------------------------------------------------------------
# normality check
ioi_dyn_tra_norm_teaching <- shapiro.test(ioi_tra[Skill == "dynamics"]$Teaching)
ioi_dyn_tra_norm_performance <- shapiro.test(ioi_tra[Skill == "dynamics"]$Mean)

# qqnorm(ioi_tra[Skill == "dynamics"]$Teaching)
# qqline(ioi_tra[Skill == "dynamics"]$Teaching)
# ioi_dyn_tra_norm_teaching
# 
# qqnorm(ioi_tra[Skill == "dynamics"]$Mean)
# qqline(ioi_tra[Skill == "dynamics"]$Mean)
# ioi_dyn_tra_norm_performance

cor.test(ioi_tra[Skill == "dynamics"]$Teaching, ioi_tra[Skill == "dynamics"]$Mean)

cor.test(ioi_tra[Skill == "dynamics"]$Teaching, ioi_tra[Skill == "dynamics"]$Mean, method = "spearman", exact = FALSE)


## ---- echo = FALSE------------------------------------------------------------
mean = mean(ioi_tra[Skill == "dynamics"]$Mean)
sd = sd(ioi_tra[Skill == "dynamics"]$Mean)

# normality check
shapiro.test(ioi_tra[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
shapiro.test(ioi_tra[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

# qqnorm(ioi_tra[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# qqline(ioi_tra[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# 
# qqnorm(ioi_tra[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)
# qqline(ioi_tra[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

cor.test(ioi_tra[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching, ioi_tra[Skill == "dynamics" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)


## ----cv, echo = FALSE---------------------------------------------------------
cv <- dt_ioi[Subcomponent != "NA", .(N = .N, CV = sd(IOI)/mean(IOI)), by = .(MidFile, Skill)]

# sorted
cv <- cv[order(MidFile)]

# plot
cv$Teaching <- rating$Mean_Percent
cv$TeachingSD <- rating$SD_Percent

ggscatter(cv, x = "CV", y = "Teaching", color = "Skill", add = "reg.line",
          add.params = list(fill = "lightgray"), conf.int = TRUE,
          xlab = "CV", ylab = "Judged as teaching (%)") + ylim(0, 100) + theme(aspect.ratio = 1)


## ---- echo = FALSE------------------------------------------------------------
# normality check
cv_art_norm_teaching <- shapiro.test(cv[Skill == "articulation"]$Teaching)
cv_art_norm_performance <- shapiro.test(cv[Skill == "articulation"]$CV)

# qqnorm(cv[Skill == "articulation"]$Teaching)
# qqline(cv[Skill == "articulation"]$Teaching)
# cv_art_norm_teaching
# 
# qqnorm(cv[Skill == "articulation"]$CV)
# qqline(cv[Skill == "articulation"]$CV)
# cv_art_norm_performance

cor.test(cv[Skill == "articulation"]$Teaching, cv[Skill == "articulation"]$CV)

cor.test(cv[Skill == "articulation"]$Teaching, cv[Skill == "articulation"]$CV, method = "spearman", exact = FALSE)


## ---- echo = FALSE------------------------------------------------------------
mean = mean(cv[Skill == "articulation"]$CV)
sd = sd(cv[Skill == "articulation"]$CV)

# normality check
shapiro.test(cv[Skill == "articulation" & CV > mean-2*sd & CV < mean+2*sd]$Teaching)
shapiro.test(cv[Skill == "articulation" & CV > mean-2*sd & CV < mean+2*sd]$CV)

# qqnorm(cv[Skill == "articulation" & CV > mean-2*sd & CV < mean+2*sd]$Teaching)
# qqline(cv[Skill == "articulation" & CV > mean-2*sd & CV < mean+2*sd]$Teaching)
# 
# qqnorm(cv[Skill == "articulation" & CV > mean-2*sd & CV < mean+2*sd]$CV)
# qqline(cv[Skill == "articulation" & CV > mean-2*sd & CV < mean+2*sd]$CV)

cor.test(cv[Skill == "articulation" & CV > mean-2*sd & CV < mean+2*sd]$Teaching, cv[Skill == "articulation" & CV > mean-2*sd & CV < mean+2*sd]$CV)


## ---- echo = FALSE------------------------------------------------------------
# normality check
cv_dyn_norm_teaching <- shapiro.test(cv[Skill == "dynamics"]$Teaching)
cv_dyn_norm_performance <- shapiro.test(cv[Skill == "dynamics"]$CV)

# qqnorm(cv[Skill == "dynamics"]$Teaching)
# qqline(cv[Skill == "dynamics"]$Teaching)
# cv_dyn_norm_teaching
# 
# qqnorm(cv[Skill == "dynamics"]$CV)
# qqline(cv[Skill == "dynamics"]$CV)
# cv_dyn_norm_performance

cor.test(cv[Skill == "dynamics"]$Teaching, cv[Skill == "dynamics"]$CV)

cor.test(cv[Skill == "dynamics"]$Teaching, cv[Skill == "dynamics"]$CV, method = "spearman", exact = FALSE)


## ---- echo = FALSE------------------------------------------------------------
mean = mean(cv[Skill == "dynamics"]$CV)
sd = sd(cv[Skill == "dynamics"]$CV)

# normality check
shapiro.test(cv[Skill == "dynamics" & CV > mean-2*sd & CV < mean+2*sd]$Teaching)
shapiro.test(cv[Skill == "dynamics" & CV > mean-2*sd & CV < mean+2*sd]$CV)

# qqnorm(cv[Skill == "dynamics" & CV > mean-2*sd & CV < mean+2*sd]$Teaching)
# qqline(cv[Skill == "dynamics" & CV > mean-2*sd & CV < mean+2*sd]$Teaching)
# 
# qqnorm(cv[Skill == "dynamics" & CV > mean-2*sd & CV < mean+2*sd]$CV)
# qqline(cv[Skill == "dynamics" & CV > mean-2*sd & CV < mean+2*sd]$CV)

cor.test(cv[Skill == "dynamics" & CV > mean-2*sd & CV < mean+2*sd]$Teaching, cv[Skill == "dynamics" & CV > mean-2*sd & CV < mean+2*sd]$CV)


## ----kot, include = FALSE-----------------------------------------------------
data_onset$KOT <- 0
for (row in 1:nrow(data_onset)){
   if (row < nrow(data_onset)){
      data_onset$KOT[row+1] <- data_offset$time2[row] - data_onset$time2[row+1] # offset(n) - onset(n+1)
   }
}

dt_kot <- data_onset[NoteNr != 1]
dt_kot$Interval <- rep(1:71, nrow(dt_kot)/71)

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


## ----kot-all, echo = FALSE----------------------------------------------------
kot_all <- dt_kot[Subcomponent == "Legato" | Subcomponent == "Staccato" | Subcomponent == "Forte" | Subcomponent == "Piano", .(N = .N, Mean = mean(KOT), SD = sd(KOT)), by = .(MidFile, Skill, Subcomponent)]

# sorted
kot_all <- kot_all[order(MidFile)]

# plot
kot_all$Teaching <- rep(rating$Mean_Percent, each = 2)
kot_all$TeachingSD <- rep(rating$SD_Percent, each = 2)

ggscatter(kot_all, x = "Mean", y = "Teaching", color = "Subcomponent", add = "reg.line", facet.by = "Skill",
          add.params = list(fill = "lightgray"), conf.int = TRUE, cor.coef = FALSE,
          xlab = "KOT (ms)", ylab = "Judged as teaching (%)") + 
scale_x_continuous(breaks = seq(-300, 150, 100)) + coord_cartesian(xlim = c(-300, 150), ylim = c(0, 100)) + theme(aspect.ratio = 1)


## ---- echo = FALSE------------------------------------------------------------
# normality check
kot_leg_norm_teaching <- shapiro.test(kot_all[Subcomponent == "Legato"]$Teaching)
kot_leg_norm_performance <- shapiro.test(kot_all[Subcomponent == "Legato"]$Mean)

# qqnorm(kot_all[Subcomponent == "Legato"]$Teaching)
# qqline(kot_all[Subcomponent == "Legato"]$Teaching)
# kot_leg_norm_teaching
# 
# qqnorm(kot_all[Subcomponent == "Legato"]$Mean)
# qqline(kot_all[Subcomponent == "Legato"]$Mean)
# kot_leg_norm_performance

cor_kot_leg <- cor.test(kot_all[Subcomponent == "Legato"]$Teaching, kot_all[Subcomponent == "Legato"]$Mean)
cor_kot_leg


## ---- echo = FALSE------------------------------------------------------------
# normality check
kot_sta_norm_teaching <- shapiro.test(kot_all[Subcomponent == "Staccato"]$Teaching)
kot_sta_norm_performance <- shapiro.test(kot_all[Subcomponent == "Staccato"]$Mean)

# qqnorm(kot_all[Subcomponent == "Staccato"]$Teaching)
# qqline(kot_all[Subcomponent == "Staccato"]$Teaching)
# kot_sta_norm_teaching
# 
# qqnorm(kot_all[Subcomponent == "Staccato"]$Mean)
# qqline(kot_all[Subcomponent == "Staccato"]$Mean)
# kot_sta_norm_performance

cor_kot_sta <- cor.test(kot_all[Subcomponent == "Staccato"]$Teaching, kot_all[Subcomponent == "Staccato"]$Mean)
cor_kot_sta


## ---- echo = FALSE------------------------------------------------------------
# normality check
kot_for_norm_teaching <- shapiro.test(kot_all[Subcomponent == "Forte"]$Teaching)
kot_for_norm_performance <- shapiro.test(kot_all[Subcomponent == "Forte"]$Mean)

# qqnorm(kot_all[Subcomponent == "Forte"]$Teaching)
# qqline(kot_all[Subcomponent == "Forte"]$Teaching)
# kot_for_norm_teaching
# 
# qqnorm(kot_all[Subcomponent == "Forte"]$Mean)
# qqline(kot_all[Subcomponent == "Forte"]$Mean)
# kot_for_norm_performance

cor_kot_for <- cor.test(kot_all[Subcomponent == "Forte"]$Teaching, kot_all[Subcomponent == "Forte"]$Mean)
cor_kot_for

cor_kot_for_spearman <- cor.test(kot_all[Subcomponent == "Forte"]$Teaching, kot_all[Subcomponent == "Forte"]$Mean, method = "spearman", exact = FALSE)
cor_kot_for_spearman


## ---- echo = FALSE------------------------------------------------------------
mean = mean(kot_all[Subcomponent == "Forte"]$Mean)
sd = sd(kot_all[Subcomponent == "Forte"]$Mean)

# normality check
shapiro.test(kot_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
shapiro.test(kot_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

# qqnorm(kot_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# qqline(kot_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# 
# qqnorm(kot_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)
# qqline(kot_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

cor.test(kot_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching, kot_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)


## ---- echo = FALSE------------------------------------------------------------
# normality check
kot_pia_norm_teaching <- shapiro.test(kot_all[Subcomponent == "Piano"]$Teaching)
kot_pia_norm_performance <- shapiro.test(kot_all[Subcomponent == "Piano"]$Mean)

# qqnorm(kot_all[Subcomponent == "Piano"]$Teaching)
# qqline(kot_all[Subcomponent == "Piano"]$Teaching)
# kot_pia_norm_teaching
# 
# qqnorm(kot_all[Subcomponent == "Piano"]$Mean)
# qqline(kot_all[Subcomponent == "Piano"]$Mean)
# kot_pia_norm_performance

cor_kot_pia <- cor.test(kot_all[Subcomponent == "Piano"]$Teaching, kot_all[Subcomponent == "Piano"]$Mean)
cor_kot_pia

cor_kot_pia_spearman <- cor.test(kot_all[Subcomponent == "Piano"]$Teaching, kot_all[Subcomponent == "Piano"]$Mean, method = "spearman", exact = FALSE)
cor_kot_pia_spearman


## ---- echo = FALSE------------------------------------------------------------
mean = mean(kot_all[Subcomponent == "Piano"]$Mean)
sd = sd(kot_all[Subcomponent == "Piano"]$Mean)

# normality check
shapiro.test(kot_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
shapiro.test(kot_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

# qqnorm(kot_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# qqline(kot_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# 
# qqnorm(kot_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)
# qqline(kot_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

cor.test(kot_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching, kot_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)


## ----vel, include = FALSE-----------------------------------------------------
dt_vel <- data_onset
dt_vel$Note <- rep(1:72, nrow(dt_vel)/72)
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


## ----vel-all, echo = FALSE----------------------------------------------------
vel_all <- dt_vel[Subcomponent == "Legato" | Subcomponent == "Staccato" | Subcomponent == "Forte" | Subcomponent == "Piano", .(N = .N, Mean = mean(Velocity), SD = sd(Velocity)), by = .(MidFile, Skill, Subcomponent)]

# sorted
vel_all <- vel_all[order(MidFile)]

# plot
vel_all$Teaching <- rep(rating$Mean_Percent, each = 2)
vel_all$TeachingSD <- rep(rating$SD_Percent, each = 2)

ggscatter(vel_all, x = "Mean", y = "Teaching", color = "Subcomponent", add = "reg.line", facet.by = "Skill",
          add.params = list(fill = "lightgray"), conf.int = TRUE, cor.coef = FALSE,
          xlab = "Velocity (0-127)", ylab = "Judged as teaching (%)") + scale_x_continuous(breaks = seq(40, 100, 10)) + coord_cartesian(xlim = c(40, 100), ylim = c(0, 100)) + theme(aspect.ratio = 1)


## ---- echo = FALSE------------------------------------------------------------
# normality check
vel_for_norm_teaching <- shapiro.test(vel_all[Subcomponent == "Forte"]$Teaching)
vel_for_norm_performance <- shapiro.test(vel_all[Subcomponent == "Forte"]$Mean)

# qqnorm(vel_all[Subcomponent == "Forte"]$Teaching)
# qqline(vel_all[Subcomponent == "Forte"]$Teaching)
# vel_for_norm_teaching
# 
# qqnorm(vel_all[Subcomponent == "Forte"]$Mean)
# qqline(vel_all[Subcomponent == "Forte"]$Mean)
# vel_for_norm_performance

cor_vel_for <- cor.test(vel_all[Subcomponent == "Forte"]$Teaching, vel_all[Subcomponent == "Forte"]$Mean)
cor_vel_for

cor_vel_for_spearman <- cor.test(vel_all[Subcomponent == "Forte"]$Teaching, vel_all[Subcomponent == "Forte"]$Mean, method = "spearman", exact = FALSE)
cor_vel_for_spearman


## ---- echo = FALSE------------------------------------------------------------
mean = mean(vel_all[Subcomponent == "Forte"]$Mean)
sd = sd(vel_all[Subcomponent == "Forte"]$Mean)

# normality check
shapiro.test(vel_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
shapiro.test(vel_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

# qqnorm(vel_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# qqline(vel_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# 
# qqnorm(vel_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)
# qqline(vel_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

cor.test(vel_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching, vel_all[Subcomponent == "Forte" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)


## ---- echo = FALSE------------------------------------------------------------
# normality check
vel_pia_norm_teaching <- shapiro.test(vel_all[Subcomponent == "Piano"]$Teaching)
vel_pia_norm_performance <- shapiro.test(vel_all[Subcomponent == "Piano"]$Mean)

# qqnorm(vel_all[Subcomponent == "Piano"]$Teaching)
# qqline(vel_all[Subcomponent == "Piano"]$Teaching)
# vel_pia_norm_teaching
# 
# qqnorm(vel_all[Subcomponent == "Piano"]$Mean)
# qqline(vel_all[Subcomponent == "Piano"]$Mean)
# vel_pia_norm_performance

cor_vel_pia <- cor.test(vel_all[Subcomponent == "Piano"]$Teaching, vel_all[Subcomponent == "Piano"]$Mean)
cor_vel_pia

cor_vel_pia_spearman <- cor.test(vel_all[Subcomponent == "Piano"]$Teaching, vel_all[Subcomponent == "Piano"]$Mean, method = "spearman", exact = FALSE)
cor_vel_pia_spearman


## ---- echo = FALSE------------------------------------------------------------
mean = mean(vel_all[Subcomponent == "Piano"]$Mean)
sd = sd(vel_all[Subcomponent == "Piano"]$Mean)

# normality check
shapiro.test(vel_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
shapiro.test(vel_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

# qqnorm(vel_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# qqline(vel_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# 
# qqnorm(vel_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)
# qqline(vel_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

cor.test(vel_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching, vel_all[Subcomponent == "Piano" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)


## ---- echo = FALSE------------------------------------------------------------
# normality check
vel_leg_norm_teaching <- shapiro.test(vel_all[Subcomponent == "Legato"]$Teaching)
vel_leg_norm_performance <- shapiro.test(vel_all[Subcomponent == "Legato"]$Mean)

# qqnorm(vel_all[Subcomponent == "Legato"]$Teaching)
# qqline(vel_all[Subcomponent == "Legato"]$Teaching)
# vel_leg_norm_teaching
# 
# qqnorm(vel_all[Subcomponent == "Legato"]$Mean)
# qqline(vel_all[Subcomponent == "Legato"]$Mean)
# vel_leg_norm_performance

cor_vel_leg <- cor.test(vel_all[Subcomponent == "Legato"]$Teaching, vel_all[Subcomponent == "Legato"]$Mean)
cor_vel_leg


## ---- echo = FALSE------------------------------------------------------------
# normality check
vel_sta_norm_teaching <- shapiro.test(vel_all[Subcomponent == "Staccato"]$Teaching)
vel_sta_norm_performance <- shapiro.test(vel_all[Subcomponent == "Staccato"]$Mean)

# qqnorm(vel_all[Subcomponent == "Staccato"]$Teaching)
# qqline(vel_all[Subcomponent == "Staccato"]$Teaching)
# vel_sta_norm_teaching
# 
# qqnorm(vel_all[Subcomponent == "Staccato"]$Mean)
# qqline(vel_all[Subcomponent == "Staccato"]$Mean)
# vel_sta_norm_performance

cor_vel_sta <- cor.test(vel_all[Subcomponent == "Staccato"]$Teaching, vel_all[Subcomponent == "Staccato"]$Mean)
cor_vel_sta


## ----vel-diff, include = FALSE------------------------------------------------
data_onset$Diff <- diff(c(0, data_onset$Velocity))
dt_vel_diff <- data_onset[NoteNr != 1]
dt_vel_diff$Interval <- rep(1:71, nrow(dt_vel_diff)/71)

# assign Subcomponents
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

# assign Subcomponent Change
for (i in change_1){
  dt_vel_diff[Skill == "articulation" & Interval == i]$Subcomponent <- "LtoS"
  dt_vel_diff[Skill == "dynamics" & Interval == i]$Subcomponent <- "FtoP"
}
for (i in change_2){
  dt_vel_diff[Skill == "articulation" & Interval == i]$Subcomponent <- "StoL"
  dt_vel_diff[Skill == "dynamics" & Interval == i]$Subcomponent <- "PtoF"
}


## ----vel-diff-all, echo = FALSE-----------------------------------------------
vel_diff_all <- dt_vel_diff[Subcomponent == "FtoP" | Subcomponent == "PtoF" | Subcomponent == "LtoS" | Subcomponent == "StoL", .(N = .N, Mean = mean(Diff), SD = sd(Diff)), by = .(MidFile, Skill, Subcomponent)]

# sorted
vel_diff_all <- vel_diff_all[order(MidFile)]

# plot
vel_diff_all$Teaching <- rep(rating$Mean_Percent, each = 2)
vel_diff_all$TeachingSD <- rep(rating$SD_Percent, each = 2)

ggscatter(vel_diff_all, x = "Mean", y = "Teaching", color = "Subcomponent", add = "reg.line", facet.by = "Skill",
          add.params = list(fill = "lightgray"), conf.int = TRUE, cor.coef = FALSE,
          xlab = "Velocity Difference (-127-127)", ylab = "Judged as teaching (%)") + scale_x_continuous(breaks = seq(-40, 55, 20)) + coord_cartesian(xlim = c(-40, 55), ylim = c(0, 100)) + theme(aspect.ratio = 1)


## ---- echo = FALSE------------------------------------------------------------
# normality check
vel_diff_ftop_norm_teaching <- shapiro.test(vel_diff_all[Subcomponent == "FtoP"]$Teaching)
vel_diff_ftop_norm_performance <- shapiro.test(vel_diff_all[Subcomponent == "FtoP"]$Mean)

# qqnorm(vel_diff_all[Subcomponent == "FtoP"]$Teaching)
# qqline(vel_diff_all[Subcomponent == "FtoP"]$Teaching)
# vel_diff_ftop_norm_teaching
# 
# qqnorm(vel_diff_all[Subcomponent == "FtoP"]$Mean)
# qqline(vel_diff_all[Subcomponent == "FtoP"]$Mean)
# vel_diff_ftop_norm_performance

cor_vel_diff_ftop <- cor.test(vel_diff_all[Subcomponent == "FtoP"]$Teaching, vel_diff_all[Subcomponent == "FtoP"]$Mean)
cor_vel_diff_ftop

cor_vel_diff_ftop_spearman <- cor.test(vel_diff_all[Subcomponent == "FtoP"]$Teaching, vel_diff_all[Subcomponent == "FtoP"]$Mean, method = "spearman", exact = FALSE)
cor_vel_diff_ftop_spearman


## ---- echo = FALSE------------------------------------------------------------
mean = mean(vel_diff_all[Subcomponent == "FtoP"]$Mean)
sd = sd(vel_diff_all[Subcomponent == "FtoP"]$Mean)

# normality check
shapiro.test(vel_diff_all[Subcomponent == "FtoP" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
shapiro.test(vel_diff_all[Subcomponent == "FtoP" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

# qqnorm(vel_diff_all[Subcomponent == "FtoP" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# qqline(vel_diff_all[Subcomponent == "FtoP" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# 
# qqnorm(vel_diff_all[Subcomponent == "FtoP" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)
# qqline(vel_diff_all[Subcomponent == "FtoP" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

cor.test(vel_diff_all[Subcomponent == "FtoP" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching, vel_diff_all[Subcomponent == "FtoP" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)


## ---- echo = FALSE------------------------------------------------------------
# normality check
vel_diff_ptof_norm_teaching <- shapiro.test(vel_diff_all[Subcomponent == "PtoF"]$Teaching)
vel_diff_ptof_norm_performance <- shapiro.test(vel_diff_all[Subcomponent == "PtoF"]$Mean)

# qqnorm(vel_diff_all[Subcomponent == "PtoF"]$Teaching)
# qqline(vel_diff_all[Subcomponent == "PtoF"]$Teaching)
# vel_diff_ptof_norm_teaching
# 
# qqnorm(vel_diff_all[Subcomponent == "PtoF"]$Mean)
# qqline(vel_diff_all[Subcomponent == "PtoF"]$Mean)
# vel_diff_ptof_norm_performance

cor_vel_diff_ptof <- cor.test(vel_diff_all[Subcomponent == "PtoF"]$Teaching, vel_diff_all[Subcomponent == "PtoF"]$Mean)
cor_vel_diff_ptof

cor_vel_diff_ptof_spearman <- cor.test(vel_diff_all[Subcomponent == "PtoF"]$Teaching, vel_diff_all[Subcomponent == "PtoF"]$Mean, method = "spearman", exact = FALSE)
cor_vel_diff_ptof_spearman


## ---- echo = FALSE------------------------------------------------------------
mean = mean(vel_diff_all[Subcomponent == "PtoF"]$Mean)
sd = sd(vel_diff_all[Subcomponent == "PtoF"]$Mean)

# normality check
shapiro.test(vel_diff_all[Subcomponent == "PtoF" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
shapiro.test(vel_diff_all[Subcomponent == "PtoF" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

# qqnorm(vel_diff_all[Subcomponent == "PtoF" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# qqline(vel_diff_all[Subcomponent == "PtoF" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching)
# 
# qqnorm(vel_diff_all[Subcomponent == "PtoF" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)
# qqline(vel_diff_all[Subcomponent == "PtoF" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)

cor.test(vel_diff_all[Subcomponent == "PtoF" & Mean > mean-2*sd & Mean < mean+2*sd]$Teaching, vel_diff_all[Subcomponent == "PtoF" & Mean > mean-2*sd & Mean < mean+2*sd]$Mean)


## ---- echo = FALSE------------------------------------------------------------
# normality check
vel_diff_ltos_norm_teaching <- shapiro.test(vel_diff_all[Subcomponent == "LtoS"]$Teaching)
vel_diff_ltos_norm_performance <- shapiro.test(vel_diff_all[Subcomponent == "LtoS"]$Mean)

# qqnorm(vel_diff_all[Subcomponent == "LtoS"]$Teaching)
# qqline(vel_diff_all[Subcomponent == "LtoS"]$Teaching)
# vel_diff_ltos_norm_teaching
# 
# qqnorm(vel_diff_all[Subcomponent == "LtoS"]$Mean)
# qqline(vel_diff_all[Subcomponent == "LtoS"]$Mean)
# vel_diff_ltos_norm_performance

cor_vel_diff_ltos <- cor.test(vel_diff_all[Subcomponent == "LtoS"]$Teaching, vel_diff_all[Subcomponent == "LtoS"]$Mean)
cor_vel_diff_ltos


## ---- echo = FALSE------------------------------------------------------------
# normality check
vel_diff_stol_norm_teaching <- shapiro.test(vel_diff_all[Subcomponent == "StoL"]$Teaching)
vel_diff_stol_norm_performance <- shapiro.test(vel_diff_all[Subcomponent == "StoL"]$Mean)

# qqnorm(vel_diff_all[Subcomponent == "StoL"]$Teaching)
# qqline(vel_diff_all[Subcomponent == "StoL"]$Teaching)
# vel_diff_stol_norm_teaching
# 
# qqnorm(vel_diff_all[Subcomponent == "StoL"]$Mean)
# qqline(vel_diff_all[Subcomponent == "StoL"]$Mean)
# vel_diff_stol_norm_performance

cor_vel_diff_stol <- cor.test(vel_diff_all[Subcomponent == "StoL"]$Teaching, vel_diff_all[Subcomponent == "StoL"]$Mean)
cor_vel_diff_stol


## ----partial, include = FALSE-------------------------------------------------
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


## ----partial-plot-leg, echo = FALSE-------------------------------------------
# plot
corrplot.mixed(pcor(partial[Subcomponent == "Legato", c("Teaching", "IOI", "KOT", "KV", "KVDiff")])$estimate, diag = c("n"))


## ----kot-partial-leg, echo = TRUE---------------------------------------------
pcor.test(partial[Subcomponent == "Legato"]$KOT, partial[Subcomponent == "Legato"]$Teaching, partial[Subcomponent == "Legato", c("IOI", "KV", "KVDiff")])


## ----partial-plot-sta, echo = FALSE-------------------------------------------
# plot
corrplot.mixed(pcor(partial[Subcomponent == "Staccato", c("Teaching", "IOI", "KOT", "KV", "KVDiff")])$estimate, diag = c("n"))


## ----kot-partial-sta, echo = TRUE---------------------------------------------
pcor.test(partial[Subcomponent == "Staccato"]$KOT, partial[Subcomponent == "Staccato"]$Teaching, partial[Subcomponent == "Staccato", c("IOI", "KV", "KVDiff")])


## ----partial-plot-for, echo = FALSE-------------------------------------------
# plot
corrplot.mixed(pcor(partial[Subcomponent == "Forte", c("Teaching", "IOI", "KOT", "KV", "KVDiff")])$estimate, diag = c("n"))


## ----vel-partial-for, echo = TRUE---------------------------------------------
pcor.test(partial[Subcomponent == "Forte"]$KV, partial[Subcomponent == "Forte"]$Teaching, partial[Subcomponent == "Forte", c("IOI", "KOT", "KVDiff")])


## ----partial-plot-pia, echo = FALSE-------------------------------------------
# plot
corrplot.mixed(pcor(partial[Subcomponent == "Piano", c("Teaching", "IOI", "KOT", "KV", "KVDiff")])$estimate, diag = c("n"))


## ----vel-partial-pia, echo = TRUE---------------------------------------------
pcor.test(partial[Subcomponent == "Piano"]$KV, partial[Subcomponent == "Piano"]$Teaching, partial[Subcomponent == "Piano", c("IOI", "KOT", "KVDiff")])


## ----partial-plot-ftop, echo = FALSE------------------------------------------
# plot
corrplot.mixed(pcor(partial[Subcomponent2 == "FtoP", c("Teaching", "IOI", "KOT", "KV", "KVDiff")])$estimate, diag = c("n"))


## ----vel-diff-partial-ftop, echo = TRUE---------------------------------------
pcor.test(partial[Subcomponent2 == "FtoP"]$KVDiff, partial[Subcomponent2 == "FtoP"]$Teaching, partial[Subcomponent2 == "FtoP", c("IOI", "KOT", "KV")])


## ----partial-plot-ptof, echo = FALSE------------------------------------------
# plot
corrplot.mixed(pcor(partial[Subcomponent2 == "PtoF", c("Teaching", "IOI", "KOT", "KV", "KVDiff")])$estimate, diag = c("n"))


## ----vel-diff-partial-ptof, echo = TRUE---------------------------------------
pcor.test(partial[Subcomponent2 == "PtoF"]$KVDiff, partial[Subcomponent2 == "PtoF"]$Teaching, partial[Subcomponent2 == "PtoF", c("IOI", "KOT", "KV")])


## ---- echo = FALSE, fig.height = 4--------------------------------------------
m1 <- lm(Teaching ~ IOI + KOT + KV + KVDiff, data = partial[Subcomponent == "Legato"])
summary(m1)
check_model(m1)


## ---- echo = FALSE------------------------------------------------------------
check_collinearity(m1)


## ---- echo = FALSE------------------------------------------------------------
check_heteroscedasticity(m1)


## ---- echo = FALSE------------------------------------------------------------
check_normality(m1)


## ---- echo = FALSE, fig.height = 4--------------------------------------------
m2 <- lm(Teaching ~ IOI + KOT + KV + KVDiff, data = partial[Subcomponent == "Staccato"])
summary(m2)
check_model(m2)


## ---- echo = FALSE------------------------------------------------------------
check_collinearity(m2)


## ---- echo = FALSE------------------------------------------------------------
check_heteroscedasticity(m2)


## ---- echo = FALSE------------------------------------------------------------
check_normality(m2)


## ---- echo = FALSE, fig.height = 4--------------------------------------------
m3 <- lm(Teaching ~ IOI + KOT + KV + KVDiff, data = partial[Subcomponent == "Forte"])
summary(m3)
check_model(m3)


## ---- echo = FALSE------------------------------------------------------------
check_collinearity(m3)


## ---- echo = FALSE------------------------------------------------------------
check_heteroscedasticity(m3)


## ---- echo = FALSE------------------------------------------------------------
check_normality(m3)


## ---- echo = FALSE, fig.height = 4--------------------------------------------
m4 <- lm(Teaching ~ IOI + KOT + KV + KVDiff, data = partial[Subcomponent == "Piano"])
summary(m4)
check_model(m4)


## ---- echo = FALSE------------------------------------------------------------
check_collinearity(m4)


## ---- echo = FALSE------------------------------------------------------------
check_heteroscedasticity(m4)


## ---- echo = FALSE------------------------------------------------------------
check_normality(m4)


## ----export, include = FALSE--------------------------------------------------
knitr::purl("analysis.Rmd")

