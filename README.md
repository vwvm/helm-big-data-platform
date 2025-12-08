# helm-big-data-platform
A helm deployment method of hadoop + hive
一个hadoop+hive

## 基础条件
- kube 1.32.2
- helm version 4.0.1
- helmfile version 1.2.2

## 插件
```shell
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.18.2/cert-manager.yaml
# helm tiff
helm plugin install https://github.com/databus23/helm-diff --verify=false
```

## 这是什么？
一个基本的hadoop平台
A basic hadoop platform

## 注意
**这是测试版本**，
不建议在生产环境使用！
**this is the test version**, 
not recommended for use in the production environment!

## 安装
```bash
helm repo add vwvm-test https://vwvm.github.io/helm-big-data-platform
helm install my-bigdata vwvm-test/big-data-platform
```

## 组件
- hdfs
- yarn
- hive

## 目的
一键部署
One-click deployment

## 查看
多使用下面的命令查看问题
```shell
kubectl describe
kubectl logs
```
