#!/bin/bash
start=`date +%s`

gmx_mpi grompp -f ./mdp/minim.mdp -c solv_ions.gro -p ./input/topol.top -o em.tpr -maxwarn 2

gmx_mpi mdrun -v -deffnm em

echo -e "10 0" | gmx_mpi energy -f em.edr -o potential.xvg

echo -e "1 | 13\nq" | gmx_mpi make_ndx -f em.gro -o index.ndx

gmx_mpi grompp -f ./mdp/nvt.mdp -c em.gro -r em.gro -p ./input/topol.top -n index.ndx -o nvt.tpr -maxwarn 1

gmx_mpi mdrun -v -deffnm nvt

echo -e "16 0" | gmx_mpi energy -f nvt.edr -o temperature.xvg

gmx_mpi grompp -f ./mdp/npt.mdp -c nvt.gro -t nvt.cpt -r nvt.gro -p ./input/topol.top -n index.ndx -o npt.tpr -maxwarn 1

gmx_mpi mdrun -v -deffnm npt

echo -e "18 0" | gmx_mpi energy -f npt.edr -o pressure.xvg

echo -e "24 0" | gmx_mpi energy -f npt.edr -o density.xvg

end=`date +%s`
runtime=$((end-start))
printf "\n"
echo "run02 done, Script ran in $runtime seconds"
