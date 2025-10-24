#!/bin/bash
start=`date +%s`

gmx_mpi grompp -f ./mdp/md.mdp -c npt.gro -t npt.cpt -p ./input/topol.top -n index.ndx -o md_out.tpr -maxwarn 1

gmx_mpi mdrun -deffnm md_out -update gpu -v


end=`date +%s`
runtime=$((end-start))
printf "\n"
echo "run03 done, Script ran in $runtime seconds"
