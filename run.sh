#!/bin/sh
# 此脚本需要用root运行，并在运行时给一个uid的参数
# 使用当前用户启动sshd服务
service ssh restart
# 添加一个用户slz
useradd --create-home -u $1  --no-log-init --shell /bin/bash slz
adduser slz sudo
echo 'slz:111' | chpasswd
# bash保证容器一直在运行
bash