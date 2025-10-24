#!/bin/bash

# 受体制备
gmx_mpi pdb2gmx -f pro.pdb -o protein.gro -water tip3p -ignh <<< 1 #自行选择力场编号，AMBER14SB是我后来新增的力场，不包括在gromacs自带的力场文件中。

# 配体制备
# md.mdp文件将受体和配体定义为一个组，配体的命名为MOL，在配体制备前期先将配体名称改为MOL，后续就不需要再改md.mdp文件了。
awk '
BEGIN { in_atom=0 }
/@<TRIPOS>ATOM/ { in_atom=1; print; next }
/@<TRIPOS>BOND/ { in_atom=0; print; next }
{
    if (in_atom) {
        $ (NF-1) = "MOL"   # 倒数第二列改为 MOL
    }
    print
}
' lig.mol2 > tmp.mol2 && mv tmp.mol2 lig.mol2

# 4个步骤分别是拟合电荷、生成Amber力场参数文件、构建Amber拓扑与坐标文件、转换为 GROMACS 格式文件
antechamber -i lig.mol2 -fi mol2 -o ligand_bcc.mol2 -fo mol2 -at gaff -c bcc -nc 0 -pf y || { echo "Failed to run command  at line ${LINENO} in ${BASH_SOURCE}" && exit 1; } #根据原子电荷自行修改-nc参数
parmchk2 -i ligand_bcc.mol2 -f mol2 -o ligand.frcmod || { echo "Failed to run command  at line ${LINENO} in ${BASH_SOURCE}" && exit 1; }
tleap -f ../script/tleap_ligand.in || { echo "Failed to run command  at line ${LINENO} in ${BASH_SOURCE}" && exit 1; }
python3 ../script/pmed_amb2gmx.py -p ligand.prmtop -x ligand.inpcrd -o ligand || { echo "Failed to run command  at line ${LINENO} in ${BASH_SOURCE}" && exit 1; }

#删除system、molecules以及defaults行及其后面的两行内容
cp ligand.top ligand.itp
sed -i '/system/,+2 d' ligand.itp
sed -i '/molecules/,+2 d' ligand.itp
sed -i '/defaults/,+2 d' ligand.itp

# 给配体加上位置限制势能
gmx_mpi make_ndx -f ligand.gro -o index.ndx << INPUT
2 & ! a H*
q
INPUT
gmx_mpi genrestr -f ligand.gro -o posre_ligand.itp -n index.ndx -fc 1000 1000 1000 <<< 3 || { echo "Failed to run command  at line ${LINENO} in ${BASH_SOURCE}" && exit 1; }

# 复合物制备
# merge_gro.py脚本可实现合并gro文件，并自动修改原子数
python ../script/merge_gro.py

# 检查 ligand.itp 文件末尾是否已经有 #include "posre_ligand.itp"
if ! tail -n 3 ligand.itp | grep -q '#include "posre_ligand.itp"'; then
    cat << 'EOF' >> ligand.itp
#ifdef POSRES
#include "posre_ligand.itp"
#endif
EOF
fi

#检查topol.top文件中是否有#include "ligand.itp"
if ! grep -q '#include "ligand.itp"' topol.top; then
    sed -i '/; Include forcefield parameters/ { 
        n
        n
        i\
; Include ligand topology\
#include "ligand.itp"
    }' topol.top
fi

# 检查最后一行是否已经是 MOL 1，如果不是才追加
if ! tail -n 1 topol.top | grep -q '^MOL 1$'; then
    echo -e "MOL 1\n" >> topol.top
fi

echo "=== 所有制备工作已完成 ==="


