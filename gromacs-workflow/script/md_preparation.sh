#!/bin/bash

# 受体制备
gmx_mpi pdb2gmx -f pro.pdb -o protein.gro -water tip3p -ignh <<< 1 #自行选择力场编号

# 配体制备
#将配体名称改为MOL，不需要再改mdp文件了
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

antechamber -i lig.mol2 -fi mol2 -o ligand_bcc.mol2 -fo mol2 -at gaff -c bcc -nc 0 -pf y || { echo "Failed to run command  at line ${LINENO} in ${BASH_SOURCE}" && exit 1; } #根据净电荷自行修改-nc参数
parmchk2 -i ligand_bcc.mol2 -f mol2 -o ligand.frcmod || { echo "Failed to run command  at line ${LINENO} in ${BASH_SOURCE}" && exit 1; }
tleap -f ../script/tleap_ligand.in || { echo "Failed to run command  at line ${LINENO} in ${BASH_SOURCE}" && exit 1; }
python3 ../script/pmed_amb2gmx.py -p ligand.prmtop -x ligand.inpcrd -o ligand || { echo "Failed to run command  at line ${LINENO} in ${BASH_SOURCE}" && exit 1; }

cp ligand.top ligand.itp
sed -i '/system/,+2 d' ligand.itp
sed -i '/molecules/,+2 d' ligand.itp
sed -i '/defaults/,+2 d' ligand.itp

# 限制
gmx_mpi make_ndx -f ligand.gro -o index.ndx << INPUT
2 & ! a H*
q
INPUT
gmx_mpi genrestr -f ligand.gro -o posre_ligand.itp -n index.ndx -fc 1000 1000 1000 <<< 3 || { echo "Failed to run command  at line ${LINENO} in ${BASH_SOURCE}" && exit 1; }

# 复合物制备
#合并gro文件
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


