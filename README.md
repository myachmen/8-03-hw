# Домашнее задание по теме "Хранение в K8s" Ячмень Марк Викторович

## Задание 1. Volume: обмен данными между контейнерами в поде

Создать Deployment приложения, состоящего из двух контейнеров, обменивающихся данными.

## Решение 1

Подготовим окружение.

Для выполнения домашнего задания будем использовать виртуальную машину `k8s-lab` с MicroK8s, подготовленную в рамках предыдущей домашней работы.

После запуска виртуальной машины проверено состояние кластера:

```
microk8s status --wait-ready
microk8s kubectl get nodes -o wide
microk8s kubectl get pods -A
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

Создадим манифест `containers-data-exchange.yaml` следующего содержания:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-exchange
spec:
  replicas: 1
  selector:
    matchLabels:
      app: data-exchange
  template:
    metadata:
      labels:
        app: data-exchange
    spec:
      containers:
        - name: busybox
           image: busybox:1.36
           imagePullPolicy: IfNotPresent
          command: ["/bin/sh", "-c"]
          args:
            - |
              while true; do
                echo "$(date)" >> /data/output.txt
                sleep 5
              done
          volumeMounts:
            - name: shared-data
              mountPath: /data

        - name: multitool
          image: wbitt/network-multitool:latest
          imagePullPolicy: IfNotPresent
          command: ["/bin/sh", "-c"]
          args:
            - "tail -f /data/output.txt"
          volumeMounts:
            - name: shared-data
              mountPath: /data

      volumes:
        - name: shared-data
          emptyDir: {}
```

Выполним проверку манифеста:

```
microk8s kubectl apply --dry-run=server -f containers-data-exchange.yaml
```

![img](img/image6.png)


Применим манифест:

```
microk8s kubectl apply -f containers-data-exchange.yaml
```

Проверим Deployment и Pod:

```
microk8s kubectl get deployments
microk8s kubectl get pods -o wide
```

![img](img/image7.png)

Deployment успешно создан. Pod `data-exchange` находится в состоянии `Running`, оба контейнера готовы к работе (`2/2`).

Сохраним имя Pod, чтобы в дальнейшем не вводить длинное имя:

``
POD=$(microk8s kubectl get pod -l app=data-exchange -o jsonpath='{.items[0].metadata.name}')
echo $POD
```

![img](img/image8.png)

Читаем файл со стороны ```busybox```:

```
microk8s kubectl exec $POD -c busybox -- tail -n 5 /data/output.txt
```

![img](img/image9.png)

Читаем тот же файл из ```multitool```:

```
microk8s kubectl exec $POD -c multitool -- tail -n 5 /data/output.txt
```

![img](img/image10.png)

Выполним демонстрацию, необходимую по заданию:

```
microk8s kubectl exec $POD -c multitool -- tail -f /data/output.txt
```

В выводе видно, что новые строки появляются примерно каждые 5 секунд. Таким образом, контейнер `busybox` записывает данные в общий Volume, а контейнер `multitool` читает эти данные из того же файла.

Проверим конфигурацию Pod:

```
microk8s kubectl describe pod $POD
```

В выводе видно, что оба контейнера используют общий Volume:

```
Mounts:
  /data from shared-data (rw)
```

Сам Volume имеет тип `EmptyDir`:

```
Volumes:
  shared-data:
    Type: EmptyDir
```