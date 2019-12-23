FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

ENV HADOOP_VERSION=2.7.2
LABEL HADOOP_VERSION=2.7.2

RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get -y update && \
    apt-get -y install python \
        python-pip \
        python-dev \
        python3 \
        python3-pip \
        python3-dev \
        python-yaml \
        python-six \
        build-essential \
        wget \
        curl \
        unzip \
        automake \
        openjdk-8-jdk \
        openssh-server \
        openssh-client \
        lsof \
        libcupti-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget -qO- http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | \
    tar xz -C /usr/local && \
    mv /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    HADOOP_INSTALL=/usr/local/hadoop \
    NVIDIA_VISIBLE_DEVICES=all

ENV HADOOP_PREFIX=${HADOOP_INSTALL} \
    HADOOP_BIN_DIR=${HADOOP_INSTALL}/bin \
    HADOOP_SBIN_DIR=${HADOOP_INSTALL}/sbin \
    HADOOP_HDFS_HOME=${HADOOP_INSTALL} \
    HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_INSTALL}/lib/native \
    HADOOP_OPTS="-Djava.library.path=${HADOOP_INSTALL}/lib/native"

ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${HADOOP_BIN_DIR}:${HADOOP_SBIN_DIR} \
    LD_LIBRARY_PATH=/usr/local/cuda/extras/CUPTI/lib:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda/lib64:/usr/local/cuda/targets/x86_64-linux/lib/stubs:${JAVA_HOME}/jre/lib/amd64/server


# 设置环境变量
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# Anaconda的环境变量
ENV PATH /opt/conda/bin:$PATH 

# torch1.3-cuda10
ENV TF_VERSION=1.14 \
ANACONDA_VERSION="Anaconda3-2019.07-Linux-x86_64" \
TORCH_URL="torch" \
TORCH_VRISION_URL="torchvision" \
TENSORBOARDX_VERSION=1.9 \
NNI_VERSION=1.2

# 下载依赖的软件包
# wget下载Anaconda用， 后两个ssh用
RUN buildDeps='openssh-server net-tools sudo vim ' \ 
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

# RUN  groupadd  anaconda \
# && mkdir /opt/anaconda3 \
# &&  chgrp -R anaconda /opt/anaconda3\

# && chmod 777 -R /opt/anaconda3
#　安装Anaconda
# COPY anaconda.sh /
# 下载 安装anaconda并配置环境变量

RUN wget --quiet https://repo.anaconda.com/archive/$ANACONDA_VERSION.sh -O ~/anaconda.sh \
# 安装anaconda
&& /bin/bash ~/anaconda.sh -b -p /opt/conda \
# 删除安装包
&& rm ~/anaconda.sh \
&& ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh  \
&& echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc  

# 从清华源安装最新稳定版tensorflow-gpu 以及 keras
RUN pip install --no-cache-dir  --upgrade tensorflow-gpu==$TF_VERSION \
&& pip install --no-cache-dir --upgrade keras

# 安装pytorch-GPU 安装命令从官网获取也可以使用清华源
RUN pip install --no-cache-dir $TORCH_URL \
&& pip install --no-cache-dir $TORCH_VRISION_URL

# 安装 PyTorch Geometric PyTorch图神经网络库PyG
RUN pip install --no-cache-dir torch-scatter \
&& pip install --no-cache-dir torch-sparse \
&& pip install --no-cache-dir torch-cluster \
&& pip install  --no-cache-dir torch-spline-conv \
&& pip install torch-geometric

# 安装常用的python包以及NNI
# 从清华源安装代码格式化工具
RUN pip install --no-cache-dir autopep8 \
# 从清华源安装torchsnooper pytroch代码调试工具，安装时会自动安装python代码调试工具 pysnooper
&& pip install --no-cache-dir torchsnooper \
# 安装pyecharts
&& pip install --no-cache-dir pyecharts \
# 安装最新NNI
&& python3 -m pip --no-cache-dir install  --upgrade nni==$NNI_VERSION \
&& pip install tensorboardX==$TENSORBOARDX_VERSION \
# 安装XGBoost
&& pip install xgboost



# 添加jupyter插件的配置文件
COPY ["notebook.json", "run.sh", "/tmp/"]
# 安装jupyter插件
RUN pip install jupyter_contrib_nbextensions \
&& jupyter contrib nbextension install --system \
&& pip install jupyter_nbextensions_configurator \
&& jupyter nbextensions_configurator enable --system \
# 更改Jupyter插件的配置，使其打开时就勾选了一些常用的应用，这里因为考虑到每次都打开容器时都是-u指定不存在的用户
# 所以将配置文件放在了/.jupyter/nbconfig中，正常的应该为其用户目录下的这个文件,也可以在打开容器时进行挂载
&& mkdir /.jupyter \
&& mkdir /.jupyter/nbconfig/ \
&& mv /tmp/notebook.json /.jupyter/nbconfig/ \
# 开放/.local的权限保证所有用户皆可使用jupyter
&& mkdir /.local \
&& chmod 777 /.local

# 设定工作目录
# WORKDIR /home/SongLongze
# 创建工作目录并开放所有权限
RUN mkdir /workdir \
&& chmod 777 /workdir
WORKDIR /workdir