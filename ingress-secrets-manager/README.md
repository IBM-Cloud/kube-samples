# IBM Cloud Kubernetes and IBM Cloud Secrets Manager integration sample

This example shows an end-to end-integration of IBM Cloud Kubernetes and IBM Cloud Secrets Manager.

1. Create an IBM Cloud Secrets Manager instance through the resource controller.
2. Set up service-to-service authorization through IAM.
3. Register the Secrets Manager instance to the IBM Cloud Kubernetes cluster.
4. Create secrets in Secrets Manager.
5. In the cluster, create a persistent Opaque secret that is backed by the CRN of the secrets in Secrets Manager.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name                           | Description                                                                                                                                                            | Type           | Default   | Required |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | --------- | -------- |
| ibmcloud\_api\_key             | IBM Cloud API key                                                                                                                                                      | `string`       | false     | true     |
| name                           | A name for the resource instance.                                                                                                                                      | `string`       | `trial`   | true     |
| plan                           | The plan type of the service.                                                                                                                                          | `string`       | false     | true     |
| location                       | Target location or environment to create the resource instance. (Forces new resource.)                                                                                 | `string`       | false     | true     |
| secrets\_manager\_instance\_id | Secrets Manager Instance GUID                                                                                                                                          | `string`       | false     | true     |
| region                         | Secrets Manager Instance region                                                                                                                                        | `string`       | `us-south`| true     |
| description                    | An extended description of your secret group.To protect your privacy, do not use personal data, such as your name or location, as a description for your secret group. | `string`       | false     | true     |
| cluster                        | Name or id of the cluster.                                                                                                                                             | `string`       | false     | true     |
| instance\_crn                  | The instance secrets will be created in.                                                                                                                               | `string`       | false     | true     |
| instance\_id                   | Secrets Manager Instance GUID                                                                                                                                          | `string`       | false     | true     |
| endpoint\_type                 | Secrets manager endpoint type                                                                                                                                          | `string`       | `public`  | true     |
| description                    | An extended description of your secret group.To protect your privacy, do not use personal data, such as your name or location, as a description for your secret group. | `string`       | false     | true     |
| expiration_date                | The date a secret is expired. The date format follows RFC 3339.                                                                                                        | `string`       | false     | true     |
| labels                         | Labels that you can use to search for secrets in your instance.Up to 30 labels can be created.                                                                         | `list(string)` | false     | true     |
| secret\_group\_id              | A v4 UUID identifier, or `default` secret group.                                                                                                                       | `string`       | false     | true     |
| username                       | The username that is assigned to the secret.                                                                                                                           | `string`       | false     | true     |
| password                       | The password that is assigned to the secret.                                                                                                                           | `string`       | false     | true     |
| payload                        | The arbitrary secret's data payload.                                                                                                                                   | `string`       | false     | true     |
| secret_name                    | The name of the opaque secret in the cluster.                                                                                                                          | `string`       | false     | true     |
| secret_namespace               | The namespace of the opaque secret in the cluster.                                                                                                                     | `string`       | false     | true     |
| fields                         | The fields added to an opaque secret.                                                                                                                                  | `set(string)`  | false     | true     |

| Name                                    | Description                             |
| --------------------------------------- | --------------------------------------- |
| ibm\_sm\_instance                       | The Secrets Manager instance object     |
| ibm\_sm\_secret\_group                  | The Secrets Manager secret group object |
| ibm\_sm\_arbitrary\_secret              | The arbitrary secret object             |
| ibm\_sm\_username\_password\_secret     | The username password object            |
| ibm\_container\_ingress\_secret\_opaque | The ingress secret opaque object        |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Usage
```
terraform init

terraform plan

terraform apply
```