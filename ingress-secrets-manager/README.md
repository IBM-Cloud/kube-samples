# IBM Cloud Kubernetes and IBM Cloud Secrets Manager integration sample

This example shows an end-to end-integration of IBM Cloud Kubernetes and IBM Cloud Secrets Manager.

1. Create an IBM Cloud Secrets Manager instance through the resource controller.
2. Set up service-to-service authorization through IAM.
3. Register the Secrets Manager instance to the IBM Cloud Kubernetes cluster.
4. Create an arbitrary secret in Secrets Manager and enable automatic rotation.
5. In the cluster, create a persistent Opaque secret that is backed by the CRN of the arbitrary secret in Secrets Manager.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name          | Description                                           | Type   | Default        | Required |
|---------------|-------------------------------------------------------|--------|----------------|----------|
| sm_instance_name      | The name of the Secrets Manager instance.                            | string | n/a            | yes      |
| sm_instance_plan   | The plan ID of the Secrets Manager instance.               | string | n/a            | yes      |
| sm_instance_region    | The region of the Secrets Manager instance      | string | trial            | no      |
| sm_secret_group_name     | The name of the secret group created in the Secrets Manager instance.          | string | n/a | yes       |
| sm_secret_group_description     | The description of the secret group created in the Secrets Manager instance.          | string | n/a | no       |
| cluster_name_or_id     | The cluster ID or name.         | string | n/a | yes       |
| sm_endpoint_type     | The Secrets Manager secret endpoint type.          | string | `public` or `private` | no       |
| sm_arbitrary_secret_name     | The name of the arbitrary secret in Secrets Manager.          | string | n/a | yes       |
| sm_arbitrary_secret_expiration_date     | The expiration date of the secret, shown in the RFC 3339 format (ex. 2022-04-12T23:20:50.520Z).         | string | n/a | yes       |
| sm_arbitrary_secret_labels     | Labels that you can use to search for secrets in your instance. Up to 30 labels can be created.         | string | ["dev", "stage] | no       |
| sm_arbitrary_secret_payload     | The arbitrary secret's data payload.         | string | ibm-cert-store | no       |
| opaque_secret_name     | The name of the Opaque secret in the cluster.        | string | n/a | no       |
| opaque_secret_namespace     | The namespace where the Opaque secret is created.      | string | default | no       |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Usage
```
terraform init

terraform plan

terraform apply
```
