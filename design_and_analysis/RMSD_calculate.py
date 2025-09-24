from pyrosetta import *
from pyrosetta.toolbox import cleanATOM
from pyrosetta.teaching import CA_rmsd
import os

# 初始化 PyRosetta（可静音）
init("-mute all")

# 加载 native 结构
native_pose = pose_from_pdb("s1b2.pdb")

# 待比对的结构所在目录
pdb_dir = "./pdbs"  # ← 替换为你的目录路径
pdb_files = sorted([f for f in os.listdir(pdb_dir) if f.endswith(".pdb")])

# 输出结果保存路径
output_file = "rmsd_results.txt"
with open(output_file, "w") as f:
    f.write(f"{'PDB file':40s}\tCA_RMSD\n")
    for pdb in pdb_files:
        pose_path = os.path.join(pdb_dir, pdb)
        try:
            pose = pose_from_pdb(pose_path)
            rmsd = CA_rmsd(native_pose, pose)
            f.write(f"{pdb:40s}\t{rmsd:.3f}\n")
        except Exception as e:
            f.write(f"{pdb:40s}\tERROR: {e}\n")

print(f"✅ RMSD 结果已保存到 {output_file}")