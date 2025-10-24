#!/bin/bash
start=`date +%s`

# --- RMSD ---
# Select group 4 ('Backbone') 13 ('MOL') for both fitting and calculation.
echo -e "4 4" | gmx_mpi rms -s ../md_out.tpr -f md_out_fit.xtc -tu ns -o pro_rmsd.xvg
echo -e "4 13" | gmx_mpi rms -s ../md_out.tpr -f md_out_fit.xtc -tu ns -o lig_rmsd.xvg

# --- RMSF ---
# Select group 4 ('Backbone') for calculation.
echo -e "4" | gmx_mpi rmsf -s ../md_out.tpr -f md_out_fit.xtc -o rmsf.xvg -ox avg.pdb -res

# --- Radius of Gyration ---
# Select group 4 ('Backbone').
echo -e "4" | gmx_mpi gyrate -s ../md_out.tpr -f md_out_fit.xtc -o gyrate.xvg

# --- Gibbs Free Energy Landscape ---
#提取低能构象：shamlog.log中找到能量最低的index，然后去bindex.ndx中找到index，
#查看到这个索引对应的时间帧，然后利用trjconv命令把对应的帧抽提出来，就可以得到蛋白质能量最低构象的pdb文件了
sed -i '/^[#@]/d' gyrate.xvg pro_rmsd.xvg
awk 'NR==FNR{a[NR]=$2; next} {print $0, a[FNR]}' gyrate.xvg pro_rmsd.xvg > merged.xvg
gmx_mpi sham -f merged.xvg -nlevels 50 -ls gibbs.xpm 
python ../script/xpm2txt.py -f gibbs.xpm -o gibbs.txt #gibbs.txt用于作图

sed -i 's/x-label: "PC1"/x-label: "RMSD(nm)"/' gibbs.xpm
sed -i 's/y-label: "PC2"/y-label: "ROG(nm)"/' gibbs.xpm
python ../script/xpm2png.py -f gibbs.xpm -o gibbs.png -ip yes -show no

#sort -k3,3n gibbs.txt > gibbs_sort.txt
#gmx_mpi xpm2ps -f gibbs.xpm -o gibbs.eps -rainbow red

# --- Extracting PDB structures at various time points --- 
#echo "20" | gmx_mpi trjconv -s ../md_out.tpr -f md_out_fit.xtc -o 10ns.pdb -dump 10000 -n ../index.ndx

# --- cluster ---
#echo -e "20 20" | gmx_mpi cluster -s ../md_out.tpr -f md_out_fit.xtc -cutoff 0.15 -method gromos -o clusters.xpm -g cluster.log -cl cluster.pdb -n ../index.ndx 

# --- Hydrogen Bonds ---
#echo -e "1 13" | gmx_mpi hbond -s ../md_out.tpr -f md_out_fit.xtc -n ../index.ndx -tu ns -num -hbn -hbm
#python ../script/plot_xpm.py hbmap.xpm

# --- Analysis of Water Molecules near a Binding Site ---
# # 1. Extract proteins, ligands, and 5 angstrom small molecules around ligands at a certain time point.
# echo 'group "Protein" or group "MOL" or (group "SOL" and within 0.5 of group "MOL")' | gmx_mpi select -s ../md_out.tpr -f md_out_fit.xtc -n ../index.ndx -on water_5A.ndx -b 10000 -e 10000 -pdbatoms selected -ofpdb



end=`date +%s`
runtime=$((end-start))
printf "\n"
echo "analysis01 done, Script ran in $runtime seconds"
