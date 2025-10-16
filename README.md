# Foamflow

Foamflow is a pipeline manager to populate and orchestrate openfoam case
files. It requires you to define case template (with all the files you need for the case) - `case.template`,
and configurable values in `Flowfile`, the `flow` pipeline will do the rest.

Using this pipeline, you can easily create multiple case directories from a template, substitute configurable parameters, run the simulation, and extract results in CSV format (depends how you define post processing stage).

Useful for generating single experiment with variable cases.

> [!important]
> This pipeline assumes you are comfortable with `OpenFOAM` and `bash` scripting.
> Using this pipeline manager out-of-the box is **NOT** recommended!
> Case template is created *specifically* for my needs, adapt it as you need.

## Flow subcommands

flow new <case>: Create a new case directory structure and populate all necessary OpenFOAM dictionary files from case.template (with placeholder variables in place).

flow pre <case>: Pre-process the case by substituting placeholders with values from Flowfile (mesh generation, boundary setup, solver settings). This step also runs mesh generation (e.g. blockMesh) and any other required preprocessing utilities.

flow run <case>: Run the simulation for the specified case. By default this uses an Allrun script (included in the case) to execute the solver and any intermediate steps.

flow post <case>: Post-process results to compute and export key data (e.g. average phase volume fractions) to a CSV file named <case>_result.csv in the case directory.

flow <case> (no subcommand): Convenience option to run all of the above steps in sequence (new → pre → run → post) for the given case name.

## How to use


```bash
git clone https://github.com/merv1n34k/foamflow.git
cd foamflow
./flow [-D KEY=VALUE] [new|pre|run|post] <case.name>
```

## Requirements

1. Openfoam must be installed on your system, for best experience
follow Openfoam [installation guide](https://openfoam.org/download/).

2. OpenSCAD, if you plan to generate mesh procedurally

## License

Distributed under the MIT License. See `LICENSE` for more information.
