# Experiment 2

# experiment
- Environment: Mac OS X 10.15.6, Max MSP 8.1.7, Python 3.8.2
- [Python Environment](https://gist.github.com/atsukotominaga/3414c38eb5add5110d39c4f74723743c)
- `experiment.py`: for the experiment
- `midiplayer.maxpat`: to make midi sound from `experiment.py`
- `image`: experimental stimuli (sheet music)
- `mid`: experimental stimuli (performance data)
- `practice`: stimuli for practice trials

# analysis
## analysis summary
- [Analysis](https://rpubs.com/atsukotominaga/956103)

- `analysis.Rmd`: analysis script >> output: `analysis.nb.html`
- `questionnaire.Rmd`: demographics info >> output: `questionnaire.nb.html`
- `prereg_analysis`: preregistered analysis (see details: [OSF preregistration](https://osf.io/z3j69))

# data
raw performance data

# material
## instruction
- `instruction.md`: instruction sheet for an experimenter >> output: pdf file
- `png files`: figures used in the instruction sheet

## sheetmusic
- `ly files`: sheet music compiled by lilypond >> output: pdf files

## expstimuli
### selection

1. get performances without pitch error and randomly select stimuli
    - *Excluded SubNr 3 due to insufficient motor skills and performances whose IOIs are outside 2SD*
- `stimuli.Rmd`: stimuli selection and profiles for selected stimuli >> output: `stimuli.nb.html` & `1614096852-230221` folder
- `function.R:` to detect pitch errors in a performance
- `ideal.txt`: the ideal sequence of the piece. used for filtering
- `raw_data`: original performance data

### export
2. export above as mid files
- `mid_export.py`: to export txt files in the filtered folder as mid files >> output: `mid` and `practice` folders

## etc
- `checklist.xlsx`: a list to check each procedure during testing (for an experimenter)