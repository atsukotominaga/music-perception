# install and load required packages
if (!require("data.table")) {install.packages("data.table"); require("data.table")}
if (!require("tibble")) {install.packages("tibble"); require("tibble")}
if (!require("editData")) {install.packages("editData"); require("editData")}
if (!require("ggplot2")) {install.packages("ggplot2"); require("ggplot2")}

### check whether a trial contains pitch errors
# data: data of the current trial
# ideal: dt_ideal
checker <- function(data, ideal){
  dt_errors <- data.table() # return data of erroneous trials - SubNr/BlockNr/TrialNr/Reason
  for (subject in unique(data$SubNr)){
    for(block in c(1:4)){
      for (trial in c(1:8)){
        current <- data[SubNr == subject & BlockNr == block & TrialNr == trial]
        if (nrow(current) != 0){ # current data not empty
          if (nrow(current) != nrow(ideal)){ # extra/missing note
            if (nrow(current) > nrow(ideal)){
              dt_errors <- rbind(dt_errors, data.table(subject, block, trial, "Extra Notes")) 
            } else if (nrow(current) < nrow(ideal)){
              dt_errors <- rbind(dt_errors, data.table(subject, block, trial, "Missing Notes")) 
            }
          } else if (nrow(current) == nrow(ideal)){ # substituted note
            for (note in 1:nrow(ideal)){
              if (current$Pitch[note] != ideal$Pitch[note]){
                dt_errors <- rbind(dt_errors, data.table(subject, block, trial, paste("Substituted Notes - RowNr ", as.character(note), sep = "")))
                break
              }
            }
          }
        } else if (nrow(current) == 0){ # current data empty
          dt_errors <- rbind(dt_errors, data.table(subject, block, trial, paste("Missing Trial")))
        }
      }
    }
  }
  colnames(dt_errors) <- c("SubNr", "BlockNr", "TrialNr", "Reason")
  return(dt_errors)
}
