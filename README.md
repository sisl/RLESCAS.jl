# Reinforcement Learning Encounter Simulator (RLES) for Collision Avoidance Systems #
Author: Ritchie Lee (ritchie.lee@sv.cmu.edu)

RLESCAS is a Julia package for applying Monte Carlo tree search (MCTS) to check collision avoidance systems.

## Installation ##

The software requires Julia v0.3 and above.  It is currently untested on v0.4.

Substitute your bitbucket username in places marked [username]

* In Julia, run Pkg.clone("https://[username]@bitbucket.org/rcnlee/rlescas.git", "RLESCAS")
* In Julia, run Pkg.clone("https://[username]@bitbucket.org/rcnlee/rlesmdp.jl.git", "RLESMDPs")
* In Julia, run Pkg.clone("https://[username]@bitbucket.org/rcnlee/sisles.jl.git", "SISLES")
* In Julia, run Pkg.clone("https://[username]@bitbucket.org/rcnlee/ccas.jl.git", "CCAS")
* In Julia, run Pkg.clone("https://[username]@bitbucket.org/rcnlee/runcases.git", "RunCases")
* In Julia, run Pkg.clone("https://[username]@bitbucket.org/rcnlee/obj2dict.git", "Obj2Dict")
* In Julia, run Pkg.checkout("PGFPlots", "master")
* In Julia, run Pkg.checkout("TikzPictures", "master")
* To be able to generate PDFs, you'll need lualatex and also aircraftshapes.sty.  For the latter, get aircraftshapes.sty from https://github.com/sisl/aircraftshapes and include it into your tex system.  For Windows (for MikTex2.9), put the aircraftshapes.sty file into "C:\Program Files\MiKTeX 2.9\tex\latex\aircraftshapes" folder.

## Usage ##

###Method 1: Command-Line###

At a command prompt, navigate to $PKGDIR/RLESCAS/test and run julia ../src/mcts.jl config_2ac.ini.  The output will be under ./results.

This command can be run from anywhere as long as the relative paths to the files are correct.  First argument is the mcts.jl file that is the main entry for command-line access.  Second argument is the configuration file.  See below for more details on the config file.  Output directory is specified in config.

RLESCAS is able to parallelize computations.  (This is the recommended way to run RLESCAS.) To use multiple processors, use the -p Julia option.  e.g., To specify 4 cores, run julia -p 4 ../src/mcts.jl config_2ac.ini

###Method 2: Advanced###

The full RLESCAS environment is available for advanced users/developers.  Navigate to $PKGDIR/src, start Julia, and run include("RLESCAS.jl").

## Config File ##


```
#!text

; This is a comment
number_of_aircraft = 2  ; Number of aicraft can be 2 or 3.  Pairwise uses LLCEM.  Multithreat uses Star model
initial = ../encounters/initial.txt  ; Encounter initial conditions file (for 2 aircraft only)
transition = ../encounters/transition.txt  ; Encounter transitions file (for 2 aircraft only)
encounters = 1-2,5-6  ; Encounters numbers to run.  Uses dashes to denote ranges, and commas to separate ranges.
mcts_iterations = 10  ; Number of inner-loop iterations for MCTS.  Default 4000.  For testing, use 10.
libcas = ../../CCAS/libcas0.8.6/lib/libcas.dll  ; libcas library
libcas_config = ../../CCAS/libcas0.8.6/parameters/0.8.5.standard.r13.xa.config.txt  ; libcas config file
output_filters = nmacs_only  ; If nmacs_only is specified, formats listed in "outputs" field are outputted only for nmac encounters.  Leave blank to output all formats for all encounters.
outputs = tex, pdf, scripted, waypoints, label270_text, csv, summary  ; Output formats.  See description below
output_dir = ./results  ; output directory
```


### Output Formats ###

**pdf**  Visualization of the encounter in PDF format.

**tex**  Same as pdf option, but in TEX format.

**scripted**  Scripted encounter file (.dat) compatible with CSIM.

**waypoints**  Waypoints encounter file (.dat) compatiable with CSIM.

**label270_text** Text file containing time and label 270 of RAs issued in the encounter.

**csv**  Simulation log of all states in comma-separated values format.

**summary**  Text file containing high-level info about the encounter, including reward, hmd, vmd, and whether an NMAC occurred.