#!/bin/bash
start=`date +%s`

echo -e "0" | gmx_mpi trjconv -s ../md_out.tpr -f ../md_out.xtc -o md_out_nojump.xtc -pbc nojump

echo -e "20 0" | gmx_mpi trjconv -s ../md_out.tpr -f md_out_nojump.xtc -o md_out_center.xtc -center -pbc mol -ur compact -n ../index.ndx

echo -e "20 0" | gmx_mpi trjconv -s ../md_out.tpr -f md_out_center.xtc -o md_out_fit.xtc -fit rot+trans -n ../index.ndx

end=`date +%s`
runtime=$((end-start))
printf "\n"
echo "analysis01 done, Script ran in $runtime seconds"
