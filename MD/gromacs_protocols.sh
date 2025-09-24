##创建文件夹
for i in $(ls);do mkdir ${i%.pdb};mv $i ${i%.pdb};done

##搭建模型+能量最小化
for i in $(ls);do cd $i; (echo 2; echo 1) |  gmx pdb2gmx -f ${i}.pdb -o protein.gro -ignh ;cd ..;done
for i in $(ls);do cd $i;gmx editconf -f protein.gro -o box.gro -d 1.2;cd ..;done
for i in $(ls);do cd $i;gmx solvate -cp box.gro -p topol.top -o solv.gro;cd ..;done
for i in $(ls);do cd $i;gmx grompp -f /home/weizg/weizg/xingbb/gromacs/protein_mdp/em.mdp -p topol.top -c solv.gro -o ions.tpr -maxwarn 2;cd ..;done
for i in $(ls);do cd $i;echo 13 | gmx genion -s ions.tpr -p topol.top -o system.gro -neutral -conc 0.15;cd ..;done
for i in $(ls);do cd $i;gmx grompp -f /home/weizg/weizg/xingbb/gromacs/protein_mdp/em.mdp -p topol.top -c system.gro -o em.tpr -maxwarn 2;cd ..;done
for i in $(ls);do cd $i;sbatch -p V100 -G 1 -n 3 -A weizg --mem 30G -J em --wrap "gmx mdrun -v -deffnm em -ntmpi 1 -ntomp 5";sleep 2s;cd ..;done

##体系平衡NVT
for i in $(ls);do cd $i;gmx grompp -f /home/weizg/weizg/xingbb/gromacs/protein_mdp/nvt.mdp -p topol.top -c em.gro -r em.gro -o nvt.tpr -maxwarn 2;cd ..;done
for i in $(ls);do cd $i;sbatch -p V100 -G 1 -n 3 -A weizg --mem 30G -J nvt --wrap "gmx mdrun -deffnm nvt -ntmpi 1 -ntomp 3";sleep 2s;cd ..;done

##体系平衡NPT
for i in $(ls);do cd $i;gmx grompp -f /home/weizg/weizg/xingbb/gromacs/protein_mdp/pr.mdp -p topol.top -c nvt.gro -r nvt.gro -o pr.tpr -maxwarn 2;cd ..;done
for i in $(ls);do cd $i;sbatch -p V100 -G 1 -n 3 -A weizg --mem 30G -J npt --wrap "gmx mdrun -deffnm pr -ntmpi 1 -ntomp 3";sleep 2s;cd ..;done

##正式模拟,解除限制的NPT模拟
for i in $(ls);do cd $i;gmx grompp -f /home/weizg/weizg/xingbb/gromacs/protein_mdp/md.mdp -p topol.top -c pr.gro -o md.tpr -maxwarn 3;cd ..;done
for i in $(ls);do cd $i;sbatch -p V100 -G 1 -n 1 -c 8 -A weizg --mem 30G -J md --wrap "gmx mdrun -deffnm md -ntmpi 1 -ntomp 8";sleep 2s;cd ..;done
