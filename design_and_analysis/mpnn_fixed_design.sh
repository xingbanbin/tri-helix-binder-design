#!/bin/bash
#SBATCH -p 3080
#SBATCH --mem=32g
#SBATCH -G 1
#SBATCH -c 3
#SBATCH -A weizg

source /home/weizg/weizg/softwares/miniconda3/bin/activate proteinMPNN
folder_with_pdbs="/home/weizg/weizg/xingbb/rfdiffusion/szm_tnfr1/mpnn/example_outputs/design_motifscaffolding_0"

output_dir="/home/weizg/weizg/xingbb/rfdiffusion/szm_tnfr1/mpnn/example_outputs/design_motifscaffolding_0/output"


if [ ! -d $output_dir ]
then
    mkdir -p $output_dir
fi


path_for_parsed_chains=$output_dir"/parsed_pdbs.jsonl"
path_for_assigned_chains=$output_dir"/assigned_pdbs.jsonl"
path_for_fixed_positions=$output_dir"/fixed_pdbs.jsonl"
chains_to_design="A"
#The first amino acid in the chain corresponds to 1 and not PDB residues index for now.
fixed_positions="residue index on the surface of proteins"


python  /home/weizg/weizg/softwares/ProteinMPNN-main/helper_scripts/parse_multiple_chains.py --input_path=$folder_with_pdbs --output_path=$path_for_parsed_chains

python  /home/weizg/weizg/softwares/ProteinMPNN-main/helper_scripts/assign_fixed_chains.py --input_path=$path_for_parsed_chains --output_path=$path_for_assigned_chains --chain_list "$chains_to_design"

python  /home/weizg/weizg/softwares/ProteinMPNN-main/helper_scripts/make_fixed_positions_dict.py --input_path=$path_for_parsed_chains --output_path=$path_for_fixed_positions --chain_list "$chains_to_design" --position_list "$fixed_positions"

python  /home/weizg/weizg/softwares/ProteinMPNN-main/protein_mpnn_run.py \
        --jsonl_path $path_for_parsed_chains \
        --chain_id_jsonl $path_for_assigned_chains \
        --fixed_positions_jsonl $path_for_fixed_positions \
        --out_folder $output_dir \
        --num_seq_per_target 1 \
        --sampling_temp "0.001" \
        --seed 37 \
        --batch_size 1 \
	    --model_name v48_020_epoch300_hyper \
        --path_to_model_weights /home/weizg/weizg/softwares/ProteinMPNN-main/hypermpnn_model_weights