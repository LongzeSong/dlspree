From nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

MAINTAINER by songlongze

# 设置环境变量
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# Anaconda的环境变量
ENV PATH /opt/conda/bin:$PATH


# 更新apt-get， 一般不进行update。，因为许多基础镜像中的「必须」包不会在一个非特权容器中升级。
# 如果基础镜像中的某个包过时了，你应该联系它的维护者。
# 如果你确定某个特定的包，比如 foo，需要升级，使用 apt-get install -y foo 就行，该指令会自动升级 foo 包。
# update操作需要和install放在统一个RUN避免出现问题


# 下载依赖的软件包
# wget下载Anaconda用， 后两个ssh用
RUN buildDeps='wget openssh-server net-tools ' \ 
&& apt-get update \
&& apt-get install -y $buildDeps \
# 清除apt缓存
&& rm -rf /var/lib/apt/lists/*


# 安装 ssh 服务

# 手动创建目录
RUN mkdir -p /var/run/sshd \
# 允许root用户登陆
&& echo  PermitRootLogin yes >> /etc/ssh/sshd_config \
# 修改密码为111
&& echo root:111 | chpasswd


#　安装Anaconda

# 下载 安装anaconda并配置环境变量
RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-2019.03-Linux-x86_64.sh -O ~/anaconda.sh \
# 安装anaconda
&& /bin/bash ~/anaconda.sh -b -p /opt/conda \
# 删除安装包
&& rm ~/anaconda.sh \
# 添加环境变量
&& echo "export PATH=/opt/conda/bin:$PATH" >> ~/.bashrc \
# RUN source ~/.bashrc
# 上面这种会报错 要用 bash运行 不知道起不起作用
&& /bin/bash -c "source ~/.bashrc" 


# 从清华源安装最新稳定版tensorflow-gpu 以及 keras
RUN pip install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple/ --upgrade tensorflow-gpu \
&& pip install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple/ --upgrade keras

# 安装pytorch-GPU 安装命令从官网获取也可以使用清华源
RUN pip install --no-cache-dir https://download.pytorch.org/whl/cu100/torch-1.1.0-cp37-cp37m-linux_x86_64.whl \
&& pip install --no-cache-dir https://download.pytorch.org/whl/cu100/torchvision-0.3.0-cp37-cp37m-linux_x86_64.whl

# 安装常用的python包
# 从清华源安装代码格式化工具
RUN pip install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple/ autopep8 \
# 从清华源安装torchsnooper pytroch代码调试工具，安装时会自动安装python代码调试工具 pysnooper
&& pip install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple/ torchsnooper


# 添加jupyter插件的配置文件
ADD notebook.json  /tmp/
# 安装jupyter插件
RUN pip install jupyter_contrib_nbextensions -i https://pypi.mirrors.ustc.edu.cn/simple \
&& jupyter contrib nbextension install --user \
&& pip install --user jupyter_nbextensions_configurator \
&& jupyter nbextensions_configurator enable --user \
# 更改Jupyter插件的配置，使其打开时就勾选了一些常用的应用
&& mv /tmp/notebook.json /root/.jupyter/nbconfig/
# 创建一个普通用户，暂时没啥用，使用时容易出现权限问题
# 添加一个普通用户，赋予sudo权限、设置密码为111，将目录所有者设定为SongLongze
RUN useradd --create-home --no-log-init --shell /bin/bash SongLongze \
&& adduser SongLongze sudo \
&& echo 'SongLongze:111' | chpasswd \
&& chown -R SongLongze /home/SongLongze 
# 默认使用SongLongze用户打开容器
USER SongLongze
# 设定工作目录
WORKDIR /home/SongLongze
# 开放端口 分别为ssh端口22 jupyter默认端口8888 tensorboard默认端口6006
EXPOSE 22 8888 6006 

# 设置自启动命令
#CMD /usr/sbin/sshd -D &
#CMD service ssh restart &
#CMD [ "/bin/bash" ]