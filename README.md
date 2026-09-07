# Домашнее задание по теме "Хранение в K8s" Ячмень Марк Викторович

## Задание 1. Volume: обмен данными между контейнерами в поде

Создать Deployment приложения, состоящего из двух контейнеров, обменивающихся данными.

## Решение 1

Подготовим окружение.

Для выполнения домашнего задания будем использовать виртуальную машину `k8s-lab` с MicroK8s, подготовленную в рамках предыдущей домашней работы.

После запуска виртуальной машины проверено состояние кластера:

```
microk8s status
kubectl get nodes -o wide
kubectl get pods -A
```

![img](img/image1.png)

MicroK8s запущен, нода `k8s-lab` находится в состоянии `Ready`. 
Системные компоненты Kubernetes находятся в состоянии `Running`.

Также проверим наличие свободного дискового пространства:

```
df -h
```

![img](img/image2.png)

На системном разделе виртуальной машины доступно около 34 ГБ свободного пространства, чего достаточно для выполнения задания.

Перед выполнением текущей домашней работы удалим ресурсы, оставшиеся после предыдущего задания:

```
microk8s kubectl delete -f deployment-multi-container.yaml
microk8s kubectl delete -f service-clusterip.yaml
microk8s kubectl delete -f deployment-backend.yaml
microk8s kubectl delete -f deployment-frontend.yaml
microk8s kubectl delete -f service-backend.yaml
microk8s kubectl delete -f service-frontend.yaml
microk8s kubectl delete -f ingress.yaml
microk8s kubectl delete -f middleware-strip-api.yaml
microk8s kubectl delete -f service-nodeport.yaml
```

![img](img/image3.png)

После удаления проверим состояние namespace `default`:

```
microk8s kubectl get all
microk8s kubectl get ingress
```

![img](img/image4.png)

После удаления ресурсов предыдущей домашней работы в namespace `default` остался только стандартный Service `kubernetes`.

Перед началом работы с хранилищами также проверим отсутствие ранее созданных PersistentVolume, PersistentVolumeClaim и StorageClass:

```
microk8s kubectl get pv,pvc,storageclass
```

![img](img/image5.png)

Ранее созданные `PersistentVolume`, `PersistentVolumeClaim` и `StorageClass` в кластере отсутствуют. Таким образом, кластер подготовлен к выполнению домашнего задания.