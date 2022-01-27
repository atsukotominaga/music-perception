## ----setup, include = FALSE---------------------------------------------------
# packages
# data manipulation
if (!require("data.table")) {install.packages("data.table"); require("data.table")}
# plot
if (!require("ggpubr")) {install.packages("ggpubr"); require("ggpubr")}


## ----read, echo = FALSE-------------------------------------------------------
dt <- fread("questionnaire.csv", header = T, sep = ",", dec = ".", na.string = "NA")

# change some colnames
colnames(dt)[2] <- "SubNr"
colnames(dt)[3] <- "Age"
colnames(dt)[4] <- "Gender"
colnames(dt)[7] <- "Handedness"

# extract the total number of years of training for the longest instrument (input manually based on the original csv file)
dt$Training <- c(7, 7, 10, 6, 7, 6, 6, 20, 12, 7, 7, 11, 9, 16, 20, 15, 19, 14, 24, 12, 14)

# exclude participants
dt_included <- dt[SubNr != 9]

print(dt_included)


## ----1, echo = FALSE----------------------------------------------------------
data.table("Answer" = dt_included$`Have you noticed anything special regarding the tasks in the experiment? If any, please describe below.`)


## ----export, include = FALSE--------------------------------------------------
knitr::purl("questionnaire.Rmd")

