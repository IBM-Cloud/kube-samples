# IBM Cloud Kubernetes and IBM Cloud Secrets Manager Integration Sample

This example is used to show an end to end integration with IBM Cloud Kubernetes and IBM Cloud Secrets Manager.

1. Create an IBM Cloud Secrets Manager instance through the resource controller
2. Set up service to service authorization through IAM
3. Register the Secrets Manager instance to the IBM Cloud Kubernetes cluster
4. Create an arbitrary secret in Secrets Manager enabled with auto rotation
5. Create a persistent opaque secret in the cluster backed by the Secrets Manager arbitrary secret CRN


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name          | Description                                           | Type   | Default        | Required |
|---------------|-------------------------------------------------------|--------|----------------|----------|
| sm_instance_name      | The name of the IBM Cloud Secrets Manager instance to be created                            | string | n/a            | yes      |
| sm_instance_plan   | The plan id of the IBM Cloud Secrets Manager instance.               | string | n/a            | yes      |
| sm_instance_region    | The region of the IBM Cloud Secrets Manager instance      | string | trial            | no      |
| sm_secret_group_name     | The name of the secret group to be created in the IBM Cloud Secrets Manager instance          | string | n/a | yes       |
| sm_secret_group_description     | The desciprtion of the secret group to be created in the IBM Cloud Secrets Manager instance          | string | n/a | no       |
| cluster_name_or_id     | IBM Cloud Kubernetes Cluster id or name          | string | n/a | yes       |
| sm_endpoint_type     | IBM Cloud Secrets Manager secret endpoint type. Type is 'public' or 'private'.          | string | public | no       |
| sm_arbitrary_secret_name     | IBM Cloud Secrets Manager arbitrary secret name          | string | n/a | yes       |
| sm_arbitrary_secret_expiration_date     | "The date a secret is expired. The date format follows RFC 3339 (ie 2022-04-12T23:20:50.520Z)."          | string | n/a | yes       |
| sm_arbitrary_secret_labels     | "Labels that you can use to search for secrets in your instance. Up to 30 labels can be created."          | string | ["dev", "stage] | no       |
| sm_arbitrary_secret_payload     | "The arbitrary secret's data payload."          | string | ibm-cert-store | no       |
| opaque_secret_name     | "The opaque secret name."          | string | n/a | no       |
| opaque_secret_namespace     | "The opaque secret namespace."          | string | default | no       |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Usage
```
terraform init

terraform plan

terraform apply
```
