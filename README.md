# Reinforcement Learning Encounter Simulator (RLES) for Collision Avoidance Systems #
Author: Ritchie Lee (ritchie.lee@sv.cmu.edu)

RLESCAS is a Julia package for applying Monte Carlo tree search (MCTS) to check collision avoidance systems.

## Installation ##

The software requires Julia v0.3 and above.  It is currently untested on v0.4.  Requires 64-bit Julia.

* In Julia, run Pkg.clone("https://github.com/sisl/rlescas.jl.git", "RLESCAS")
* In Julia, run Pkg.clone("https://github.com/sisl/adaptivestresstesting.jl.git", "AdaptiveStressTesting")
* In Julia, run Pkg.clone("https://github.com/sisl/rles-sisles.jl.git", "SISLES")
* In Julia, run Pkg.clone("https://github.com/sisl/casinterface.jl.git", "CASInterface")
* In Julia, run Pkg.clone("https://github.com/sisl/ccas.jl.git", "CCAS").  Follow the instructions on the CCAS wiki to configure.
* In Julia, run Pkg.clone("https://github.com/sisl/rlesutils.jl.git", "RLESUtils")
* In Julia, run Pkg.checkout("PGFPlots", "master").  PGFPlots requires some additional configuration.  Follow the installation instructions on the package documentation https://github.com/sisl/PGFPlots.jl.  Note: if you use the config file method to execute, and do not require pdf and tex outputs, then you can skip installation of the visualization tools.
* In Julia, run Pkg.checkout("TikzPictures", "master")
* To be able to generate PDFs, you'll need lualatex and also aircraftshapes.sty.  For the latter, get aircraftshapes.sty from https://github.com/sisl/aircraftshapes and include it into your tex system.  For Windows (for MikTex2.9), put the aircraftshapes.sty file into "C:\Program Files\MiKTeX 2.9\tex\latex\aircraftshapes" folder.  Lualatex is included in MikTex distribution.

## Usage ##

###Method 1: Command-Line###

At a command prompt, navigate to $PKGDIR/RLESCAS/test and run julia ../src/mcts.jl config_2ac.ini.  The output will be under ./results.

This command can be run from anywhere as long as the relative paths to the files are correct.  First argument is the mcts.jl file that is the main entry for command-line access.  Second argument is the configuration file.  See below for more details on the config file.  Output directory is specified in config.

RLESCAS is able to parallelize computations.  (This is the recommended way to run RLESCAS.) To use multiple processors, use the -p Julia option.  e.g., To specify 4 cores, run julia -p 4 ../src/mcts.jl config_2ac.ini

Sometimes it is useful to be able to execute from within Julia (e.g., better error messages when debugging).  You can emulate the above command line call by navigating to $PKGDIR/RLESCAS/test and from within Julia run include("runtests.jl").  Edit runtests.jl with the desired config file.

###Method 2: Advanced###

The full RLESCAS environment is available for advanced users/developers.  Navigate to $PKGDIR/RLESCAS/src, start Julia, and run include("RLESCAS.jl").

The full environment includes visualization tools, so you will need to have PGFPlots properly configured.

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

### JSON format ###

The JSON output file contains all the information from the run.  All other file formats can be generated from the JSON .  To save space, RLESCAS uses GZip to compress the JSON file to json.gz.  RLESCAS can read and write either file type.     Since JSON is in ASCII human-readable format, you could simply open it in a text editor to view or edit the contents.

The recommended method to interact with the JSON file is to use the advanced mode in RLESCAS.

Start Julia in $PKGDIR/RLESCAS/src and run:

```
#!julia

include("rlescas.jl").
d=trajLoad("trajSaveMCTS_ACASX_EvE_1.json.gz") #substitute your json.gz filename

```

**run_type** indicates the type of study: "MCTS", "MCBEST" or "ENC"

**sim_params** contains the simulation parameters (e.g., number of aircraft, encounter file, libcas path, etc.) in Obj2Dict format.  To recover the object, use:

```
#!julia

sim_params = Obj2Dict.to_obj(d["sim_params"])
```

**mdp_params** contains the mdp parameters (e.g., action_counter) in Obj2Dict format.  To recover the object, use:

```
#!julia

mdp_params = Obj2Dict.to_obj(d["mdp_params"])
```

**dpw_params** contains the MCTS DPW parameters (e.g., iterations, k, alpha, etc.) in Obj2Dict format.  To recover the object, use:

```
#!julia

dpw_params = Obj2Dict.to_obj(d["dpw_params"])
```

**compute_info** contains the compute details of the run (e.g., start time, compute time, machine name, etc.) in Obj2Dict format.  To recover the object, use:

```
#!julia

compute_info = Obj2Dict.to_obj(d["compute_info"])
```

**sim_log**

From here, you can browse the Dict directly, or the recommended way to interact, is by using the helpers in RLESCAS/src/helpers/save_helpers.jl.  See Save Helpers section below.

sim_log contains all the simulation logs (those defined in define_log.jl)

* "var_names" contains the variable names of each field.
* "var_units" contains the units of the variables of each field (parallels var_names)
* "run_info" gives information about the sim outcome
* "CAS_info" logs the output string of libcas
* "initial" gives the initial state of the aircraft
* "action_seq" logs the action seeds of the final trajectory in Obj2Dict format. i.e.,

```
#!julia

action_seq = Obj2Dict.to_obj(d["sim_log"]["action_seq"])
```

Each of the following fields is a dictionary organized first by field, then by aircraft (if applicable) then by time.  e.g., d["sim_log"]["ra"]["aircraft"]["1"]["time"]["5"], where in this example "ra" is the field, 1 is the aircraft number, and 5 is the time step.

* "command" contains the pilot commands
* "sensor" contains the sensor logs
* "ra" contains the collision avoidance system info (simple)
* "ra_detailed" contains the collision avoidance system info (detailed)
* "wm" contains the world model states (e.g., time, positions, velocities)
* "adm" contains the aircraft dynamic states
* "response" contains the pilot response output

Tip: Use the json_to_csv converter to output all the fields and variables to a comma-separated file, and use summarize() to output a compact summary to a text file.  trajPlot is useful for visualization of the output trajectory (with RAs and responses overlayed) and summary information is embedded in the caption.

# Save Helpers #

The recommended way to access sim_log variables is through save_helpers.jl instead of directly through the Dict.  This allows the underlying Dict structure to be modified without impacting dependent functions.

* sv_reward(d) to get the final reward
* sv_nmac(d) to get whether an nmac occurred
* sv_hmd(d) to get the horizontal miss distance
* etc...

* To lookup field names, use sv_simlog_names(...)
* To lookup field units, use sv_simlog_units(...)
* To get non-timestamped data, use sv_simlog_data(...)
* To get time-stamped data, use sv_simlog_tdata(...)
* The _vid versions lookup a specific variable (vid can be a variable name or the index into the array)
* The _vid_f versions return variables converted to floats where possible (e.g., useful for passing to PGFPlots)
