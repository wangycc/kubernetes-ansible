### Kubernetes Cluster 

#### 1. Pre installation

##### 系统环境

- Linux内核:4.11
- Linux发行版: Centos7.3
- Docker data FS: XFS
- Docker: 17.3
- Docker storage driver: overlay2
- kubernetes: 1.9.1
- flannel: 0.9.1
- etcd: 3.1.10
- TLS: True
- RBAC: True

**1. 下载依赖包到本地**

   部署前deploy-local.sh 下载包及解压,kubernetes及etcd版本可通过inventory/group_vars/all.yaml# downloads修改
   
~**2. 部署配置AWS 基础环境**~~

   ~~修改inventory/group_vars/all.yaml配置文件，#AWS VPC config为aws 基础配置，roles/vpc/defaults/main.yml为vps子网配置及master和node实例配置。~~
   ~~导入AWS AWS_ACCESS_KEY 和AWS_SECRET_ACCESS_KEY 环境变量 ~~
   ```shell
    export AWS KEY
   ```
~- 创建AWS Keypair(默认使用meiqia-sa,如果不存在需要提前创建)~~
~- 修改vpc role 配置文件({role_path}/defaults/main.yml及group_vars/all.yml)~~

> **由于我们是复用common VPC，部署配置AWS基础环境skip。**

#### 2. 部署k8s基础环境

1 ~~无VPC的情况下，需要创建HA VPC，master，node机器,ELB,role,安全组 deploy-vpc.sh~~
   
   ~~修改inventory/group_vars/all.yaml文件,添加aws环境配置,修改role/vpc/default/main.yml文件,定义vpc、子网、机器配置。~~
   ~~之后执行scripts/deploy-aws.sh脚本~~
   ~~基础环境创建完成之后，修改inventory/inventory主机IP列表.~~
   
2 生成集群TLS证书

   aws console控制台或者脚本收集master、node的IP地址以及ELB的dns名称配置在inventory/group_vars/all.yaml文件SSL项中
   执行scripts/deploy-ssl.sh,会生成集群SSL文件存放在.ssl目录中.用于kubernetes以及etc大集群TLS认证通信.
   ```shell
   # kubernetes.io/role/node or kubernetes.io/role/master
   aws --profile=pro ec2 describe-instances --filters "Name=tag:KubernetesCluster,Values=kubernetes-production"  --query "Reservations[*].Instances[*].{role:Tags[?Key=='kubernetes.io/role/node'],Ip:PrivateIpAddress}"
   ```

3 部署ETCD集群

   目前是etcd和maste节点混部。scripts/deploy-etd.sh脚本即可部署。此过程会安装etcd集群、同步TLS证书及etcd配置文件。。
   
4 部署master

   scripts/deploy-master.sh 脚本部署master.此过程会安装flanneld、master相关组件。会同步TLS证书、master配置文件.部署完之后观察ELB后台实例是否健康检查成功
   
5 部署node

   scripts/deploy-node.sh 脚本部署node节点.此过程会安装依赖、docker、flanneld、kubelet、kube-proxy.
   
6 部署flannel

   由于master和node节点都依赖flannel。所以在master和node role中已经添加在dependency中.

部署完毕


#### 3. 添加1个Node机器

由于复用的common VPC，就没有做VPC的playbook管理了，手动添加机器吧。

1. AWS console工作台创建一台机器，
    -. 选择ami-8b1bc6e6 AMI，
    -. 创建在common-vpc中，子网选择kubernetes-production-private-1[a|b]，启动终止保护.
    -. 添加标签KubernetesCluster=kubernetes-production,kubernetes.io/role/(master|node)=空.
    -. 配置安全组:kubernetes-production-node-sg
    -. 启动即可
2. 将新添加的机器IP更新到 inventory文件nodes group中，开始部署。

    ```shell
    bash deploy-node.sh
    ```
3. 完毕


#### 4. 下架一台机器

1. 将服务器调度状态变更为不可调度，避免在驱逐pod过程中，新的pod被调度进来

    ```shell
    kubectl cordon node $node
    ```
2. 驱逐当前Node节点上面运行的pod到其他节点

    ```shell
    kubectl drain $node [--ignore-daemonsets=true|--delete-local-data=true|--force=|true]
    ```
3. 从集群中移除
    ```shell
    kubectl delete node $node
    ```
    
    


