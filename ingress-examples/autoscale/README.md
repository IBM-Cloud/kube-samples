# ALB autoscale custom metrics example

When we want to use ALB metrics for autoscaling, we need a Prometheus what can scrape the ALB metrics, a Prometheus Adapter what can serve the custom metrics API to provide these metrics for the Horizontal Pod Autoscaler. This is example setup for `nginx_ingress_controller_requests_rate` custom metric with a simple, example application. Please note, the followings aren't intended to be deployed in production as-is, but rather serving as an example to help you get started configuring your setup. You can find the doc for the ALB autoscale doc [here](https://cloud.ibm.com/docs/containers?topic=containers-ingress-alb-manage#alb_replicas_autoscaler). 

## Custom metrics:

1. Replace the `<editme>` with your host and secret name in the `host`, `hosts` and `secretName` fields in the `example-deployment/example-ingress.yaml` file.

2. Run: `kubectl apply --kustomize alb-autoscale-example` to install everything. 

    - You can check the example application, it should be reachable on the host that you defined in the `example-deployment/example-ingress.yaml` file, example output:
    ```
    ➜ curl -s https://pvg-classic-od16r554ux7-1e7743ca80a399c9cff4eaf617434c72-0000.us-south.stg.containers.appdomain.cloud/ | jq .
    {
      "path": "/",
      "headers": {
        "host": "pvg-classic-od16r554ux7-1e7743ca80a399c9cff4eaf617434c72-0000.us-south.stg.containers.appdomain.cloud",
        "x-request-id": "4780c7a0baa98c993d474be463c8b643",
        "x-real-ip": "10.189.192.233",
        "x-forwarded-for": "10.189.192.233",
        "x-forwarded-host": "pvg-classic-od16r554ux7-1e7743ca80a399c9cff4eaf617434c72-0000.us-south.stg.containers.appdomain.cloud",
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
      "hostname": "pvg-classic-od16r554ux7-1e7743ca80a399c9cff4eaf617434c72-0000.us-south.stg.containers.appdomain.cloud",
      "ip": "10.189.192.233",
      "ips": [
        "10.189.192.233"
      ],
      "protocol": "https",
      "query": {},
      "subdomains": [
        "containers",
        "stg",
        "us-south",
        "pvg-classic-od16r554ux7-1e7743ca80a399c9cff4eaf617434c72-0000"
      ],
      "xhr": false,
      "os": {
        "hostname": "alb-autoscale-example-deployment-56875c56f5-njm8h"
      },
      "connection": {}
    }
    ```

3. After a few minutes, you can use the following commands to see the new custom metric: `kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta2/namespaces/alb-autoscale-example/ingress/alb-autoscale-example-ingress/nginx_ingress_controller_requests_rate" | jq .`

    - When the `kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta2/namespaces/alb-autoscale-example/ingress/alb-autoscale-example-ingress/nginx_ingress_controller_requests_rate" | jq .` command is not working after 10 minutes, please review the `apiservice v1beta2.custom.metrics.k8s.io` apiservice, the `AVAILABLE` must be `true`, otherwise check the `alb-prometheus-adapter` service and `alb-prometheus-adapter` in `alb-autoscale-example` namespace:
    ```
    ➜ kubectl get apiservice v1beta2.custom.metrics.k8s.io
    NAME                            SERVICE                                        AVAILABLE   AGE
    v1beta2.custom.metrics.k8s.io   alb-autoscale-example/alb-prometheus-adapter   True        15m
    ```

4. Enable the autoscale with `ibmcloud ks ingress alb autoscale set -c <clusterID> --alb <albID> --min-replicas 1 --max-replicas 2 --custom-metrics-file custom-metric.yaml` command.


## Prometheus dashboard: 
  - First you need the nodeport that the `prometheus` service uses. In the following example that is 32415.
  ```
  ➜  ~ kubectl get svc -n alb-autoscale-example
  NAME                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
  alb-autoscale-example-service   ClusterIP   172.21.41.173    <none>        80/TCP           4d20h
  alb-prometheus-adapter          ClusterIP   172.21.246.127   <none>        443/TCP          4d20h
  prometheus                      NodePort    172.21.252.23    <none>        9090:32415/TCP   4d20h
  ``` 
  - Than you need a node external IP: 
  ```
  ➜  ~ kubectl get nodes -o wide
  NAME             STATUS   ROLES    AGE    VERSION        INTERNAL-IP      EXTERNAL-IP      OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
  10.189.192.233   Ready    <none>   6d9h   v1.25.12+IKS   10.189.192.233   169.59.133.189   Ubuntu 20.04.6 LTS   5.4.0-155-generic   containerd://1.6.21
  10.189.192.235   Ready    <none>   6d9h   v1.25.12+IKS   10.189.192.235   169.59.133.173   Ubuntu 20.04.6 LTS   5.4.0-155-generic   containerd://1.6.21
  ```
  - Open your browser and visit the following URL: http://{node IP address}:{prometheus-svc-nodeport} to load the Prometheus Dashboard. 
  - You can find more details about the metrics here: https://kubernetes.github.io/ingress-nginx/user-guide/monitoring/#prometheus-dashboard
