This repo contains scripts and materials for a musical perception study with musicians.

<!-- Open Science Framework: [https://osf.io/8nbjh/](https://osf.io/8nbjh/) (Raw data are available here) -->

# Overview
- [Script](#script)
- [Material](#material)

# Script
## Environment
All of the programme scripts were written and tested in the following environment.

- ProductName:	Mac OS X
- ProductVersion:	10.15.6

## Psychopy3
- [experiment.py]()

### Others
- image: contains sheet music
- mid: contains mid files (performance data)

# Material
<!-- ## Instruction
- instruction.Rmd: a instruction sheet for an experimenter >> output: html file.
- image: figures used in the instruction sheet
- psd files: images used in the instruction >> output: png files
 -->
## Lilypond
- ly files: sheet music compiled by lilypond >> output: pdf files

## Stimuli
### 1. Get performances without pitch error (R)
- filtering.R: to get correct performances and export each as an individual txt file >> output: filtered folder
- function.R: to detect pitch errors in a performance
- ideal.txt: the ideal sequence of the piece. used for filtering

### 2. Export 1. as mid files (python)
- mid_export.py: to export txt files in the filtered folder as mid files
