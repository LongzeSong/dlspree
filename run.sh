#!/bin/sh
# 此脚本需要在运行时给一个uid的参数
# 使用当前用户启动sshd服务
echo "111" | sudo -S service ssh restart
# 添加一个用户slz
sudo useradd --no-log-init --create-home -u $1 --shell /bin/bash slz
sudo adduser slz sudo
echo 'slz:111' | sudo -S  chpasswd
# bash保证容器一直在运行
bash