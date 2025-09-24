# 三螺旋束 Binder 的设计方法  
以 **TNFR1-S1B2** 与 **SzM-binder3** 为例

---

## Step 1：Binder–靶蛋白复合物的分子动力学模拟与结合自由能计算

### 1.1 模拟体系构建  
- **力场与溶剂模型**  
  - 蛋白力场：`AMBER14SB_parmbsc1`  
  - 水分子模型：`TIP3P`  
- **溶剂盒子**  
  - 使用长方体水盒，蛋白质位于盒子中心  
  - 距离盒子边界：1.2 nm  
- **平衡步骤**  
  - NVT 与 NPT 平衡，均采用三维周期性边界条件  
  - 对蛋白施加位置约束，避免初始剧烈运动  
  - 积分器：`leap-frog`，时间 100 ps  
  - 约束算法：`LINCS`，对氢键约束  
  - 邻居列表：`Verlet` + `Grid`  
  - 静电与范德华相互作用截断距离：1.2 nm  
  - 长程静电：`PME`，插值阶数 = 4  
  - 温度耦合：`V-rescale`，蛋白与非蛋白部分分组  
  - 压力耦合：`Parrinello-Rahman`  
  - 初始速度：310 K，随机数种子来自系统  

- **生产模拟**  
  - 时间：300 ns  
  - 积分器：`leap-frog`  
  - 温控：`V-rescale`，目标温度 310 K  
  - 压控：`Parrinello-Rahman`，目标压力 1 bar  
  - 静电：`PME`  
  - 范德华：截断 + 力平滑切换  
  - 氢键：全约束  

### 1.2 结合自由能计算  
- 使用 **gmx_MMPBSA** 工具  
- 输入：MD 稳定阶段的 `.xtc` 轨迹  
- 参数：  
  - 力场：`leaprc.ff99SB`  
  - 温度：310 K  
  - 能量分解：分析 6 Å 结合界面范围内的残基  
- 目的：确定对结合贡献最大的关键氨基酸  

---

## Step 2：螺旋束的提取与组装
- 将 binder 拆分为单独的螺旋束  
- 根据 **Step 1** 的能量分解结果与关键氨基酸残基贡献对螺旋束排序  
- 选择方式：  
  - TNFR1 Binder 中排名前二的螺旋束  
  - SzM Binder 中排名第一的螺旋束  
- 使用 **PyMOL** 调整三根螺旋束的相对空间位置，确保结合界面暴露在表面  

---

## Step 3：RFdiffusion 设计三螺旋束之间的 Linker
- Linker 长度：4–7 个氨基酸  
- 随机设计 100 种 linker 组合  
- 筛选：人工检查长度与空间适配性  

命令示例：
```bash
Path_to_RFdiffusion/scripts/run_inference.py \
  inference.output_prefix=example_outputs/design_motifscaffolding \
  inference.input_pdb=input/szmtnfr.pdb \
  'contigmap.contigs=[A1-19/4-7/B1-17/4-7/C1-19]' \
  inference.num_designs=100
```

## Step 4：ProteinMPNN 进行序列填充与优化

- **目标**：
  - 为 linker 填充序列
  - 对三螺旋内部可能存在的斥力进行氨基酸优化
- MPNN模型：`HyperMPNN (v48_020_epoch300_hyper)`
- 脚本示例：`mpnn_fixed_design.sh`

------

## Step 5：ColabFold 预测序列填充后的结构

- 使用 `colabfold_batch` 预测填充序列后的结构
- 结构筛选：
  - **目视检查**：三螺旋是否完整折叠
  - **脚本分析**：
    - `pLDDT.py` 评估模型可信度
    - `RMSD_calculate.py` 比较 Cα RMSD，越小表示结构保持更一致

命令示例：

```
colabfold_batch input.fasta colab_out_dir
```

------

## Step 6：ProteinMPNN + FastRelax 进行界面优化

- 构建 **SzM–binder–TNFR1 三元复合物**
- 使用 `dl_interface_design.py` 进行结合界面序列优化
- 参考仓库：[dl_binder_design](https://github.com/nrbennet/dl_binder_design)

命令示例：

```
dl_interface_design.py -pdbdir path/to/pdbdir -outpdbdir ./mpnnfr_out
```

------

## Step 7：ColabFold 筛选双靶标结合的 Binder

- 分别预测：
  - binder–SzM 复合物
  - binder–TNFR1 复合物
- 筛选指标：
  - pLDDT、pTM 得分排序
  - 可视化验证三螺旋束是否符合预期功能：
    - 螺旋束 1 → 特异性结合 SzM
    - 螺旋束 2 → 同时结合 SzM 和 TNFR1
    - 螺旋束 3 → 特异性结合 TNFR1

------

## Step 8：Binder–靶标复合物 MD 模拟与结合亲和力评估

- 与 **Step 1** 相同的模拟与能量计算参数
- 目的：筛选出最优 binder 候选，进入实验验证