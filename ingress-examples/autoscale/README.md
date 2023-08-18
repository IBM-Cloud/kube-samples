# Enabling autoscaling based on custom metrics for IBM Cloud Kubernetes Service Ingress ALBs

The ALBs expose [various metrics](https://kubernetes.github.io/ingress-nginx/user-guide/monitoring/#exposed-metrics) including request statistics and Nginx process metrics. These metrics can be captured and aggregated by a metric collector, such as [Prometheus](https://prometheus.io/docs/introduction/overview/) and made available to Kubernetes HPA by using [Prometheus Adapter](https://github.com/kubernetes-sigs/prometheus-adapter).

Depending on your use case, you might want to scale your ALBs based on custom metrics, for example based on the number of incoming requests per second or the number of established connections. In the followings we present an example on setting up autoscaling based on custom metrics. With this example you can get started easily on designing your custom metrics based setup. Please note that the configuration in this example is not a production ready setup, but a simple deployment for demonstration purposes.

For more information about autoscaling, check out our [official documentation](https://cloud.ibm.com/docs/containers?topic=containers-ingress-alb-manage#alb_replicas_autoscaler).

## Setup

1. Replace the `<editme>` with your host and secret name in the `host`, `hosts`, and `secretName` fields in the `example-deployment/example-ingress.yaml` file.

2. Now you can deploy an example application with ingress, Prometheus, and Prometheus adapter:
    * Create the `alb-autoscale-example` namespace for the new application with `kubectl apply -f alb-autoscale-example/autoscale-example-namespace.yaml` command. The new namespace will appear immediately:

    ```
    $ kubectl get ns alb-autoscale-example
    NAME                    STATUS   AGE
    alb-autoscale-example   Active   13s
    ```

    * Deploy Promethus with `kubectl apply --kustomize alb-autoscale-example/prometheus` command. This will create a `prometheus-server` deployment in `alb-autoscale-example` namespace:

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

4. Enable autoscaling with `ibmcloud ks ingress alb autoscale set -c <clusterID> --alb <albID> --min-replicas 1 --max-replicas 2 --custom-metrics-file custom-metrics.yaml` command. After a few minutes, you should see the following output:

    ```
    $ kubectl get hpa -n kube-system public-cr<clusterID>-alb1
    NAME                                 REFERENCE                                       TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
    public-cr<clusterID>-alb1            Deployment/public-cr<clusterID>-alb1            0/2k      1         2         1          2h
    ```
