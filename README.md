# What makes musicians infer teaching intentions?


<p align="center">
  <img height="300" src="https://media.giphy.com/media/VJxNm7zrm3K4E/giphy.gif">
</p>

Open Science Framework: [https://osf.io/f6nr2/](https://osf.io/f6nr2/)  
Preregistration: [https://osf.io/z3j69](https://osf.io/z3j69)

This repo contains scripts and materials for a musical perception study with musicians.

# experiment
- Environment: Mac OS X 10.15.6, Max MSP 8
- [Python Environment](https://gist.github.com/atsukotominaga/3414c38eb5add5110d39c4f74723743c)

## psychopy3
- `experiment.py`: for the experiment
- `midiplayer.maxpat`: to make midi sound from `experiment.py`

## others
- `image`: experimental stimuli (sheet music)
- `mid`: experimental stimuli (performance data)
- `practice`: stimuli for practice trials

# analysis
- `analysis.Rmd`: analysis script >> output: `analysis.nb.html`
- `data`: raw performance data


# material
## instruction
- `instruction.md`: instruction sheet for an experimenter >> output: pdf file
- `png files`: figures used in the instruction sheet

## sheetmusic
- `ly files`: sheet music compiled by lilypond >> output: pdf files

## expstimuli
### selection

1. get performances without pitch error
    - *Excluded SubNr 16 due to a deviated tempo and performances whose IOIs are outside 2SD*
- `filtering.R`: to get correct performances and export each as an individual txt file >> output: filtered folder
- `function.R:` to detect pitch errors in a performance
- `ideal.txt`: the ideal sequence of the piece. used for filtering

### export
2. export above as mid files
- `mid_export.py`: to export txt files in the filtered folder as mid files >> output: mid files

## etc
- `checklist.xlsx`: a list to check each procedure during testing (for an experimenter)