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
data_ls <- list.files("../../data", pattern = "csv")
combined <- lapply(data_ls, function(f){
  fread(paste("../../data/", f, sep = ""), sep = ",")
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

# check correct or incorrect
data$Correct <- 0
data[Condition == "teaching" & rating == "Yes"]$Correct <- 1
data[Condition == "performing" & rating == "No"]$Correct <- 1

all <- data[expMode == "experiment", .(N = .N, Sum = sum(Correct), Percent = (sum(Correct)/.N)*100), by = .(subjectNumber, Condition, Skill)]
all[order(subjectNumber, Condition, Skill)]


## ----acc, echo = FALSE--------------------------------------
# individual
ind_data <- data[subjectNumber != 4, .(N = .N, Sum = sum(Correct), Percent = (sum(Correct)/.N)*100), by = .(subjectNumber)]
ind_data <- ind_data[order(subjectNumber)]

# all
subset <- ind_data[, .(N = .N, Mean = mean(Sum), SD = sd(Sum), Mean_Percent = (mean(Sum)/72)*100, SD_Percent = (sd(Sum)/72)*100)]
subset


## ----plot, echo = FALSE-------------------------------------
ggboxplot(ind_data, x = "N", y = "Percent", add = "dotplot", xlab = FALSE) + ylab("Correct %") + theme(axis.text.x = element_blank())


## ----t-test, echo = FALSE-----------------------------------
# normality check
shapiro.test(ind_data$Percent)

t.test(ind_data$Percent, mu = 50, alternative = "two.sided")


## ----plot2, echo = FALSE------------------------------------
ind_data_ad <- data[subjectNumber != 4, .(N = .N, Sum = sum(Correct), Percent = (sum(Correct)/.N)*100), by = .(subjectNumber, Skill)]
ind_data_ad <- ind_data_ad[order(subjectNumber, Skill)]

subset_ad <- ind_data_ad[, .(N = .N, Mean = mean(Sum), SD = sd(Sum), Mean_Percent = (mean(Sum)/36)*100, SD_Percent = (sd(Sum)/36)*100), by = .(Skill)]
subset_ad

data_box <- data.table(subjectNumber = ind_data_ad[Skill == "articulation"]$subjectNumber, articulation = ind_data_ad[Skill == "articulation"]$Percent, dynamics = ind_data_ad[Skill == "dynamics"]$Percent)
box <- ggpaired(data_box, cond1 = "articulation", cond2 = "dynamics", line.color = "gray", line.size = 0.4, ylab = "Correct %")
box


## ----t-test-a, echo = FALSE---------------------------------
# normality check
shapiro.test(ind_data_ad[Skill == "articulation"]$Percent)

t.test(ind_data_ad[Skill == "articulation"]$Percent, mu = 50, alternative = "two.sided")


## ----t-test-d, echo = FALSE---------------------------------
# normality check
shapiro.test(ind_data_ad[Skill == "dynamics"]$Percent)

t.test(ind_data_ad[Skill == "dynamics"]$Percent, mu = 50, alternative = "two.sided")


## ----p-t-test, echo = FALSE---------------------------------
# normality check
shapiro.test(ind_data_ad[Skill == "dynamics"]$Percent-ind_data_ad[Skill == "articulation"]$Percent)

t.test(ind_data_ad[Skill == "articulation"]$Percent, ind_data_ad[Skill == "dynamics"]$Percent, paired = TRUE)


## ----export, include = FALSE--------------------------------
knitr::purl("prereg_analysis.Rmd")

