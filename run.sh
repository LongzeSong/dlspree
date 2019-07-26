#!/bin/sh
# 此脚本需要用root运行，并在运行时给一个uid的参数
# 使用当前用户启动sshd服务
service ssh restart
# 添加一个用户slz
useradd --no-log-init -u $1 --shell /bin/bash slz
echo 'slz:111' | chpasswd