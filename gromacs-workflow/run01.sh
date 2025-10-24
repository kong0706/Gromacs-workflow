#!/bin/bash
start=`date +%s`

gmx_mpi editconf -f ./input/complex.gro -o newbox.gro -bt cubic -d 1.0 -c

gmx_mpi solvate -cp newbox.gro -cs spc216.gro -p ./input/topol.top -o solv.gro

gmx_mpi grompp -f ./mdp/ions.mdp -c solv.gro -p ./input/topol.top -o ions.tpr -maxwarn 1

echo -e "15" | gmx_mpi genion -s ions.tpr -o solv_ions.gro -p ./input/topol.top -pname NA -nname CL -neutral

end=`date +%s`
runtime=$((end-start))
printf "\n"
echo "run01 done, Script ran in $runtime seconds"
