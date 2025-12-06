# helm-big-data-platform
A helm deployment method of hadoop + hive


这是我的第一个Helm Chart发布体验！

## 这是什么？
这是一个测试用的Helm Chart，用于学习和体验Helm Chart发布流程。

## 注意
⚠️ **这是测试版本**，不建议在生产环境使用！

## 安装
```bash
helm repo add vwvm-test https://vwvm.github.io/helm-big-data-platform
helm install my-bigdata vwvm-test/big-data-platform
```

## 组件
- hadoop hdfs
- hive

## 目的
体验Helm Chart发布到Artifact Hub的完整流程。
