import os
import json
import argparse

def calculate_average_plddt(json_file):
    with open(json_file, 'r') as f:
        data = json.load(f)
    plddt_scores = data['plddt']
    total_plddt = sum(plddt_scores)
    average_plddt = total_plddt / len(plddt_scores)
    return average_plddt

def process_json_files(folder_path, output_file):
    with open(output_file, 'w') as out_file:
        for filename in os.listdir(folder_path):
            if filename.endswith('.json'):
                json_file = os.path.join(folder_path, filename)
                average_plddt = calculate_average_plddt(json_file)
                output_line = f'{filename}: pLDDT = {average_plddt}\n'
                out_file.write(output_line)

def main():
    parser = argparse.ArgumentParser(description='Calculate average pLDDT from JSON files in a folder.')
    parser.add_argument('--folder_path', required=True, help='Path to the folder containing JSON files.')
    args = parser.parse_args()

    output_file = 'outputs_plddt.txt'
    process_json_files(args.folder_path, output_file)

if __name__ == "__main__":
    main()