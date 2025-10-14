# Foamflow

Foamflow is a simple pipeline manager to populate and orchestrate openfoam case
files. For it to work you only need to define case temple - `case.template`,
actual pipeline - `do_*` in `flow` script and `Flowfile` for configurable
values.

Using this pipeline, you can easily create a new case directory from a template, substitute configurable parameters, run the simulation, and extract results in CSV format.

Useful for generating single experiment with variable cases.

# Flow subcommands

flow new <case>: Create a new case directory structure and populate all necessary OpenFOAM dictionary files from case.template (with placeholder variables in place).

flow pre <case>: Pre-process the case by substituting placeholders with values from Flowfile (mesh generation, boundary setup, solver settings). This step also runs mesh generation (e.g. blockMesh) and any other required preprocessing utilities.

flow run <case>: Run the simulation for the specified case. By default this uses an Allrun script (included in the case) to execute the solver and any intermediate steps.

flow post <case>: Post-process results to compute and export key data (e.g. average phase volume fractions) to a CSV file named <case>_result.csv in the case directory.

flow <case> (no subcommand): Convenience option to run all of the above steps in sequence (new → pre → run → post) for the given case name.

## How to use

If you have `nix` one can simply do:

```bash
git clone https://github.com/merv1n34k/foamflow.git
cd foamflow
nix develop
```

In other cases, Openfoam must be installed on your system, for best experience
follow Openfoam [installation guide](https://openfoam.org/download/).

## License

Distributed under the MIT License. See `LICENSE` for more information.
