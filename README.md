# helm-big-data-platform
A helm deployment method of hadoop + hive
这是我的第一个Helm Chart发布体验！

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
- hadoop hdfs
- hive

## 目的
一键部署
One-click deployment
