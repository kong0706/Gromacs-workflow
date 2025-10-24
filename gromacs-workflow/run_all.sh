#!/bin/bash

LOGFILE="run_all.log"
exec > >(tee -a "$LOGFILE") 2>&1   # 所有输出记录到日志

echo "开始运行：$(date)"
set -e   # 一旦有命令出错，脚本立即退出

# 定义错误处理函数
trap 'echo "❌ 出错于第 ${LINENO} 行: ${BASH_COMMAND}"; exit 1' ERR

# ====== 开始执行 ======
echo "进入 input 目录..."
cd input

echo "运行 md_preparation.sh..."
bash ../script/md_preparation.sh

echo "返回上级目录..."
cd ..

echo "运行 run01.sh..."
bash run01.sh

echo "运行 run02.sh..."
bash run02.sh

echo "运行 run03.sh..."
bash run03.sh

echo "返回上级目录..."
cd analysis

echo "运行 analysis01.sh..."
bash analysis01.sh

echo "运行 analysis02.sh.sh..."
bash analysis02.sh

echo "所有步骤都已完成：$(date)"
