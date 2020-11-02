# iks-life-preserver

## What is this?
Life Preserver is a simple project designed to be used with the 
IBM Cloud Schematics service to make the process of inviting 
someone to your IBM Cloud account for the purpose of helping you 
troubleshoot issues with your IBM Cloud Kubernetes Service Clusters
 (including OpenShift on IBM Cloud clusters).

## How it works
Follow the steps below to invite a user to your account and grant them: 

* A `Viewer` IAM platform policy that allows the user to see only Kubernetes and OpenShift clusters
* A `Reader` IAM service policy that allows the user to have **view-only** access to the **specific cluster you grant them access to**. 

> Note: In terms of Kubernetes RBAC, this user will not have access to any Secrets or RBAC resources inside the cluster.


### Step 1

 Login to the IBM Cloud web console at https://cloud.ibm.com.

### Step 2 

Browse to the IBM Cloud Schematics offering at https://cloud.ibm.com/schematics

### Step 3

Click `Create workspace` and give your new workspace a relevant name and pick a location and click `Create`. 

### Step 4

Now you should be looking at your workspace settings. Provide `https://github.com/jpapejr/iks-life-preserver/tree/main` as the Terraform template URL and ensure that you choose a Terraform version of 0.12 or higher for this workspace. Click `Save template information` to save your changes. Wait for the system import and process the Terraform data before continuing.

### Step 5

You should now see four variables that need to be populated before continuing:

* `reference` - This is a user-defined reference that will be appeanded to the generated service ID name for purpose reference.
* `cluster` - This is the **cluster ID** of the specific cluster to grant **read-only** access to.
* `apikey` - This is an IBM Cloud API Key with sufficient privileges to invite new members to the account. For security purposes, ensure you check the `Sensitive` box on the far right so your key is obscured from view after it input.
* `account` - This is the target account within which the operations will occur. 

When done, click `Save changes`.

### Step 6

At the top of the screen click on the `Generate plan` button. Ensure it completes successfully before moving on. Address any Terraform errors that might arise due to back API Key or cluster ID values. 

### Step 7

Again, at the top of the screen, click on the `Apply plan` button. Once the `apply` operation has completed, you can click on `View Logs` to find the generated Service ID API Key. Share this securely with the individual providing assistance; they will be able to authenticate using this API Key for the targeted account & cluster resources as defined above. 

### Step 8

At this point, if the `apply` operation was successful you should be able to browse into the [IAM portion of the console](https://cloud.ibm.com/iam/users) to confirm the access. 



### Step 9 (roll-back/revert the process)

From the main workspace page, click on the `Actions` drop-down button near the top-right part of the screen and select `Delete`:

* If you want to remove all the changes and delete the workspace completely, check both boxes.
* If you want to remove all the changes and keep the workspace around for re-use at a later time, just check the second box. 

Confirm the operation by typing in the workspace name and then clicking `Delete`
