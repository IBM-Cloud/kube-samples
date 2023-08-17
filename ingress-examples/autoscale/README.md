# Enabling autoscaling based on custom metrics for IBM Cloud Kubernetes Service Ingress ALBs

When we want to use ALB metrics for autoscaling, we need a Prometheus what can scrape the ALB metrics, a Prometheus Adapter what can serve the custom metrics API to provide these metrics for the Horizontal Pod Autoscaler. This is example setup for `nginx_ingress_controller_requests_rate` custom metric with a simple, example application. Please note, the followings aren't intended to be deployed in production as-is, but rather serving as an example to help you get started configuring your setup. You can find the doc for the ALB autoscale doc [here](https://cloud.ibm.com/docs/containers?topic=containers-ingress-alb-manage#alb_replicas_autoscaler). For configuring custom metrics you can find the list of exposed metrics by the ALB in the [ingress-nginx documentation](https://kubernetes.github.io/ingress-nginx/user-guide/monitoring/#exposed-metrics).

## Setup

1. Replace the `<editme>` with your host and secret name in the `host`, `hosts` and `secretName` fields in the `example-deployment/example-ingress.yaml` file.

2. Now you can deploy an example application with ingress, Prometheus, and Prometheus adapter:
    * create `alb-autoscale-example` namespace for the new application with `kubectl apply -f alb-autoscale-example/autoscale-example-namespace.yaml` command. The new namespace will appear immediately:

    ```
    $ kubectl get ns alb-autoscale-example
    NAME                    STATUS   AGE
    alb-autoscale-example   Active   13s
    ```

    * deploy Promethus with `kubectl apply --kustomize alb-autoscale-example/prometheus` command. This will create a `prometheus-server` deployment in `alb-autoscale-example` namespace:

    ```
    $ kubectl get deployment -n alb-autoscale-example prometheus-server
    NAME                READY   UP-TO-DATE   AVAILABLE   AGE
    prometheus-server   1/1     1            1           30s
    ```

    * deploy Prometheus Adapter with `kubectl apply --kustomize alb-autoscale-example/prometheus-adapter` command. This will create a `alb-prometheus-adapter` deployment in `alb-autoscale-example` namespace. Note: the `alb-autoscale-example/prometheus-adapter/configmap.yaml` contains the description of the `nginx_ingress_controller_requests_rate` custom metric.

    ```
    $ kubectl get deployment -n alb-autoscale-example alb-prometheus-adapter
    NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
    alb-prometheus-adapter   1/1     1            1           50s
    ```

    * deploy the test application with `kubectl apply --kustomize alb-autoscale-example/example-deployment` command. This will create a `alb-autoscale-example` deployment in `alb-autoscale-example` namespace:

    ```
    $ kubectl get deployment -n alb-autoscale-example alb-autoscale-example-deployment
    NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
    alb-autoscale-example-deployment   1/1     1            1           81s
    ```

    * when the deployment is ready, open the example application to generate some traffic so the `nginx_ingress_controller_requests_rate` metric has values. Use the host you defined in the `example-deployment/example-ingress.yaml` file, example output:

    ```json
    ➜ curl -s https://mydomain.com/ | jq .
    {
      "path": "/",
      "headers": {
        "host": "mydomain.com",
        "x-request-id": "4780c7a0baa98c993d474be463c8b643",
        "x-real-ip": "10.189.192.233",
        "x-forwarded-for": "10.189.192.233",
        "x-forwarded-host": "mydomain.com",
        "x-forwarded-port": "443",
        "x-forwarded-proto": "https",
        "x-forwarded-scheme": "https",
        "x-scheme": "https",
        "user-agent": "curl/7.88.1",
        "accept": "*/*"
      },
      "method": "GET",
      "body": "",
      "fresh": false,
      "hostname": "mydomain.com",
      "ip": "10.189.192.233",
      "ips": [
        "10.189.192.233"
      ],
      "protocol": "https",
      "query": {},
      "xhr": false,
      "os": {
        "hostname": "alb-autoscale-example-deployment-56875c56f5-njm8h"
      },
      "connection": {}
    }
    ```

3. After a few minutes, you can use the following command to see that the custom metric is available for the Kubernetes metrics-server:

    ```
    $ kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta2/namespaces/alb-autoscale-example/ingress/alb-autoscale-example-ingress/nginx_ingress_controller_requests_rate"
    {
      "kind": "MetricValueList",
      "apiVersion": "custom.metrics.k8s.io/v1beta2",
      "metadata": {},
      "items": [
        {
          "describedObject": {
            "kind": "Ingress",
            "namespace": "alb-autoscale-example",
            "name": "alb-autoscale-example-ingress",
            "apiVersion": "networking.k8s.io/v1"
          },
          "metric": {
            "name": "nginx_ingress_controller_requests_rate",
            "selector": null
          },
          "timestamp": "2023-08-08T09:11:02Z",
          "value": "0"
        }
      ]
    }
    ```

    * If the above command fails even after 10 minutes, review the `apiservice v1beta2.custom.metrics.k8s.io` APIService: `AVAILABLE` must be `True`, otherwise you will need to check the `alb-prometheus-adapter` Service and `alb-prometheus-adapter` deployment in `alb-autoscale-example` namespace:

    ```
    ➜ kubectl get apiservice v1beta2.custom.metrics.k8s.io
    NAME                            SERVICE                                        AVAILABLE   AGE
    v1beta2.custom.metrics.k8s.io   alb-autoscale-example/alb-prometheus-adapter   True        15m
    ```

4. Enable the autoscale with `ibmcloud ks ingress alb autoscale set -c <clusterID> --alb <albID> --min-replicas 1 --max-replicas 2 --custom-metrics-file custom-metric.yaml` command. After a few minutes, you should see the following output:

    ```
    $ kubectl get hpa -n kube-system public-cr<clusterID>-alb1
    NAME                                 REFERENCE                                       TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
    public-cr<clusterID>-alb1            Deployment/public-cr<clusterID>-alb1            0/2k      1         2         1          2h
    ```

## Prometheus dashboard

* First you need the nodeport that the `prometheus` service uses. In the following example that is 32415.

```
➜  ~ kubectl get svc -n alb-autoscale-example
NAME                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
alb-autoscale-example-service   ClusterIP   172.21.41.173    <none>        80/TCP           4d20h
alb-prometheus-adapter          ClusterIP   172.21.246.127   <none>        443/TCP          4d20h
prometheus                      NodePort    172.21.252.23    <none>        9090:32415/TCP   4d20h
```

* Than you need a node external IP:

  ```
  ➜  ~ kubectl get nodes -o wide
  NAME             STATUS   ROLES    AGE    VERSION        INTERNAL-IP      EXTERNAL-IP      OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
  10.189.192.233   Ready    <none>   6d9h   v1.25.12+IKS   10.189.192.233   169.59.133.189   Ubuntu 20.04.6 LTS   5.4.0-155-generic   containerd://1.6.21
  10.189.192.235   Ready    <none>   6d9h   v1.25.12+IKS   10.189.192.235   169.59.133.173   Ubuntu 20.04.6 LTS   5.4.0-155-generic   containerd://1.6.21
  ```

* Open your browser and visit the following URL: http://{node IP address}:{prometheus-svc-nodeport} to load the Prometheus Dashboard.

* You can find more details about the metrics here: <https://kubernetes.github.io/ingress-nginx/user-guide/monitoring/#prometheus-dashboard>
