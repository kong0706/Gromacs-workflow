1. 将小分子mol2文件和蛋白PDB文件放入input文件夹中，然后进行系统制备：

cd input
bash ../script/md_preparation.sh

2. 返回上一级目录，然后进行能量最小化升温平衡：

cd ..
bash run_all.sh

3.MMGBSA
script文件夹中的mmpbsa.in中包含了使用方法，记得先要激活gmxMMPBSA虚拟环境。
