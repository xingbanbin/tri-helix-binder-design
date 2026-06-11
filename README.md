# Design Method for Three-Helix Bundle Binders
Using **TNFR1-S1B2** and **SzM-binder3** as Examples

---

## Step 1: Molecular Dynamics Simulation and Binding Free Energy Calculation of Binder–Target Complexes

### 1.1 Simulation System Setup
- **Force Field and Solvent Model**
  - Protein force field: `AMBER14SB_parmbsc1`
  - Water model: `TIP3P`
- **Solvent Box**
  - Use a rectangular water box with the protein centered
  - Distance from box boundary: 1.2 nm
- **Equilibration Steps**
  - NVT and NPT equilibration, both with three-dimensional periodic boundary conditions
  - Apply position restraints on the protein to avoid initial violent motion
  - Integrator: `leap-frog`, duration 100 ps
  - Constraint algorithm: `LINCS`, constraining hydrogen bonds
  - Neighbor list: `Verlet` + `Grid`
  - Cutoff distance for electrostatic and van der Waals interactions: 1.2 nm
  - Long-range electrostatics: `PME`, interpolation order = 4
  - Temperature coupling: `V-rescale`, with separate groups for protein and non-protein parts
  - Pressure coupling: `Parrinello-Rahman`
  - Initial velocities: 310 K, random seed from the system

- **Production Simulation**
  - Duration: 300 ns
  - Integrator: `leap-frog`
  - Temperature control: `V-rescale`, target temperature 310 K
  - Pressure control: `Parrinello-Rahman`, target pressure 1 bar
  - Electrostatics: `PME`
  - van der Waals: cutoff + force-switch smoothing
  - Hydrogen bonds: fully constrained

### 1.2 Binding Free Energy Calculation
- Using the **gmx_MMPBSA** tool
- Input: `.xtc` trajectory from the stable MD production phase
- Parameters:
  - Force field: `leaprc.ff99SB`
  - Temperature: 310 K
  - Energy decomposition: analyze residues within a 6 Å binding interface
- Purpose: identify key amino acids that contribute most to binding

---

## Step 2: Extraction and Assembly of Helix Bundles
- Split the binder into individual helices
- Rank the helices based on the energy decomposition results from Step 1 and the contribution of key amino acid residues
- Selection criteria:
  - Top two helices from the TNFR1 Binder
  - Top one helix from the SzM Binder
- Use **PyMOL** to adjust the relative spatial positions of the three helices to ensure the binding interfaces are exposed on the surface

---

## Step 3: RFdiffusion Design of Linkers Between Three-Helix Bundles
- Linker length: 4–7 amino acids
- Randomly design 100 linker combinations
- Screening: manual inspection of length and spatial compatibility

Example command:
```bash
Path_to_RFdiffusion/scripts/run_inference.py \
  inference.output_prefix=example_outputs/design_motifscaffolding \
  inference.input_pdb=input/szmtnfr.pdb \
  'contigmap.contigs=[A1-19/4-7/B1-17/4-7/C1-19]' \
  inference.num_designs=100
```

## Step 4: ProteinMPNN Sequence Inpainting and Optimization

- **Objectives**:
  - Fill sequences for the linkers
  - Optimize amino acids to resolve potential steric clashes within the three-helix bundle
- MPNN model: `HyperMPNN (v48_020_epoch300_hyper)`
- Example script: `mpnn_fixed_design.sh`

------

## Step 5: ColabFold Structure Prediction of Inpainted Sequences

- Use `colabfold_batch` to predict the structure after sequence inpainting
- Structure screening:
  - **Visual inspection**: whether the three-helix bundle is fully folded
  - **Script analysis**:
    - `pLDDT.py` to evaluate model confidence
    - `RMSD_calculate.py` to compare Cα RMSD; smaller values indicate more consistent structure maintenance

Example command:

```
colabfold_batch input.fasta colab_out_dir
```

------

## Step 6: ProteinMPNN + FastRelax Interface Optimization

- Construct the **SzM–binder–TNFR1 ternary complex**
- Use `dl_interface_design.py` for binding interface sequence optimization
- Reference repository: [dl_binder_design](https://github.com/nrbennet/dl_binder_design)

Example command:

```
dl_interface_design.py -pdbdir path/to/pdbdir -outpdbdir ./mpnnfr_out
```

------

## Step 7: ColabFold Screening of Dual-Target Binding Binders

- Predict separately:
  - binder–SzM complex
  - binder–TNFR1 complex
- Screening metrics:
  - Rank by pLDDT and pTM scores
  - Visually validate whether the three-helix bundle conforms to the expected function:
    - Helix 1 → Specifically binds SzM
    - Helix 2 → Simultaneously binds SzM and TNFR1
    - Helix 3 → Specifically binds TNFR1

------

## Step 8: MD Simulation and Binding Affinity Evaluation of Binder–Target Complexes

- Same simulation and energy calculation parameters as in Step 1
- Purpose: screen for the optimal binder candidate for experimental validation
