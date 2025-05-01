# Linux Scripts
This directory contains shell scripts developed for Linux machines. The intent is for these scripts
to be able to run on any Linux computer (Internet often required), with no dependencies on Python,
or any other external packages. Most perform set-up operations, but other applications will
naturally arise (TODO!).


### README to Script
There are cases when it's valuable to have a README that documents a procedure (or many procedures)
that consists primary of terminal commands be converted into a script that can execute all steps
with a single command to run the script. Documenting steps in a README makes it easier for a human
to understand why steps are being executed, something that can also be done with comments in the
shell scripts themselves.

- Read through headers in README, determines which are procedures (maybe "Procure :" prefix?)
- Extract shell commands from between ```
- For lines to be written to files, get file name/path from verbal instruction, and text to insert
  from between ```.
