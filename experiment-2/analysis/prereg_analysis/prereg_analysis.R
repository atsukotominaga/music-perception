## ----packages, include = FALSE-----------------------------
# data manipulation
if (!require("data.table")) {install.packages("data.table"); require("data.table")}
# midi
if (!require("tuneR")) {install.packages("tuneR"); require("tuneR")}
# plot
if (!require("ggpubr")) {install.packages("ggpubr"); require("ggpubr")}
# stats
if (!require("afex")) {install.packages("afex"); require("afex")}


## ----read, include = FALSE---------------------------------
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


## ----acc, echo = FALSE-------------------------------------
# individual
ind_data <- data[subjectNumber != 4, .(N = .N, Sum = sum(Correct), Percent = (sum(Correct)/.N)*100), by = .(subjectNumber)]
ind_data <- ind_data[order(subjectNumber)]

# all
subset <- ind_data[, .(N = .N, Mean_Percent = mean(Percent), SD_Percent = sd(Percent))]
subset


## ----plot, echo = FALSE------------------------------------
ggboxplot(ind_data, x = "N", y = "Percent", add = "dotplot", xlab = FALSE) + ylab("Correct %") + theme(axis.text.x = element_blank()) + geom_hline(yintercept = 50, linetype = "dashed")


## ----t-test, echo = FALSE----------------------------------
# normality check
shapiro.test(ind_data$Percent)

t.test(ind_data$Percent, mu = 50, alternative = "two.sided")


## ----plot2, echo = FALSE-----------------------------------
ind_data_ad <- data[subjectNumber != 4, .(N = .N, Sum = sum(Correct), Percent = (sum(Correct)/.N)*100), by = .(subjectNumber, Skill)]
ind_data_ad <- ind_data_ad[order(subjectNumber, Skill)]

subset_ad <- ind_data_ad[, .(N = .N, Mean_Percent = mean(Percent), SD_Percent = sd(Percent)), by = .(Skill)]
subset_ad

data_box <- data.table(subjectNumber = ind_data_ad[Skill == "articulation"]$subjectNumber, articulation = ind_data_ad[Skill == "articulation"]$Percent, dynamics = ind_data_ad[Skill == "dynamics"]$Percent)

# plot with jitter
n <- length(data_box$articulation)
d <- data.frame(y = c(data_box$articulation, data_box$dynamics), 
                x = rep(c(1,2), each = n),
                id = factor(rep(1:n,2)))

set.seed(321)    
d$xj <- jitter(d$x, amount = .05)
ggplot(data = d, aes(y=y)) +
  geom_boxplot(aes(x=x, group = x), width = 0.5, outlier.shape = NA) +
  geom_point(aes(x = xj)) +
  geom_line(aes(x = xj, group = id), color = "gray", size = .4) + labs(x = "Skill", y = "Correct %") +
  scale_x_continuous(breaks = c(1, 2), labels = c("articulation", "dynamics"), limits = c(0.5, 2.5)) + geom_hline(yintercept = 50, linetype = "dashed") + theme_pubr()

# plot without jitter
# ggpaired(data_box, cond1 = "articulation", cond2 = "dynamics", line.color = "gray", line.size = 0.4, xlab = "Skill", ylab = "Correct %") + geom_hline(yintercept = 50, linetype = "dashed")


## ----t-test-a, echo = FALSE--------------------------------
# normality check
shapiro.test(ind_data_ad[Skill == "articulation"]$Percent)

t.test(ind_data_ad[Skill == "articulation"]$Percent, mu = 50, alternative = "two.sided")


## ----t-test-d, echo = FALSE--------------------------------
# normality check
shapiro.test(ind_data_ad[Skill == "dynamics"]$Percent)

t.test(ind_data_ad[Skill == "dynamics"]$Percent, mu = 50, alternative = "two.sided")


## ----p-t-test, echo = FALSE--------------------------------
# normality check
shapiro.test(ind_data_ad[Skill == "dynamics"]$Percent-ind_data_ad[Skill == "articulation"]$Percent)

t.test(ind_data_ad[Skill == "articulation"]$Percent, ind_data_ad[Skill == "dynamics"]$Percent, paired = TRUE)


## ----plot3, echo = FALSE-----------------------------------
ind_data_tp_ad <- data[subjectNumber != 4, .(N = .N, Sum = sum(Correct), Percent = (sum(Correct)/.N)*100), by = .(subjectNumber, Condition, Skill)]
ind_data_tp_ad <- ind_data_tp_ad[order(subjectNumber, Condition, Skill)]

ggboxplot(ind_data_tp_ad, "Skill", "Percent", color = "Condition") + geom_hline(yintercept = 50, linetype = "dashed")


## ---- echo = FALSE-----------------------------------------
anova <- aov_ez("subjectNumber", "Percent",
                data = ind_data_tp_ad, within = c("Condition", "Skill"))
anova


## ----export, include = FALSE-------------------------------
knitr::purl("prereg_analysis.Rmd")

