**Infrastructure Take Home:**

Treat this system as a production system.

Getting Started

Clone this repository locally.

Create your own public repository in GitHub (or any platform accessible to the reviewer) and push this code into it.
Make changes to your repository as needed to complete the assignment.

The reviewer will clone your repository and run the instructions provided in this README to recreate the expected solution.

If the instructions cannot be followed to reproduce the environment, the solution cannot be assessed.


**Prerequisites**

The following tools must be installed on the system.

Docker runtime and Docker CLI
k3d CLI
Terraform or OpenTofu
kubectl
Git

**Project Structure**

```
infra-takehome
│
├── README.md
├── argocd
│   └── ArgoCD installation manifests
│
├── postgrest
│   ├── postgrest.sh
│   ├── deployment.yaml
│   ├── ingress.yaml
│   └── job.yaml
│
└── tofu
    ├── terraform-apply.sh
    ├── terraform-destroy.sh
    │
    ├── cluster
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── versions.tf
    │   └── outputs.tf
    │
    └── k8s-secret
        ├── main.tf
        ├── variables.tf
        └── versions.tf
```

        
**Deployment Instructions**
**1. Provision Infrastructure**

Run the infrastructure provisioning script:

`./terraform-apply.sh`

**This script performs the following actions:**

1. Executes Terraform inside the cluster directory to create the infrastructure.
2. Waits until the Kubernetes cluster becomes available.
3. Executes Terraform inside the k8s-secret directory to configure Kubernetes resources.
4. Runs the PostgREST deployment script.

**Infrastructure Provisioning (cluster/main.tf)**

The **cluster/main.tf** Terraform configuration is responsible for provisioning the base infrastructure.

This includes:

Kubernetes Cluster

A Kubernetes cluster is created locally using k3d, which runs a lightweight k3s cluster inside Docker.

The cluster exposes the ingress load balancer on:

`http://<SERVER_IP>:8080

**PostgreSQL Deployment**

A PostgreSQL 16 container is created using Docker with:

1. persistent Docker volume storage
2. port exposure on 5432
3. default database initialization

**Database Initialization**

Terraform connects to PostgreSQL and automatically creates:

**Database**

`postgrest`

**Superuser**

`postgrest_user`

**Password**

`postgrest_password`


**Privilege Configuration**

The following permissions are granted:

1. USAGE permission on the public schema
2. SELECT permission on all tables

This allows the PostgREST API to read data from PostgreSQL.

**Kubernetes Configuration (k8s-secret/main.tf)**

The Terraform configuration inside the k8s-secret directory creates Kubernetes resources required for the application.

**Namespace Creation**

A Kubernetes namespace named:

`postgrest

is created to isolate application resources.

**Kubernetes Secret**

A secret named:

`postgrest-db

is created inside the postgrest namespace.

This secret contains the database connection string used by PostgREST.

Example connection string stored in the secret:

`postgres://postgrest_user:postgrest_password@host.k3d.internal:5432/postgrest

This allows pods running inside the Kubernetes cluster to securely connect to PostgreSQL.

**Deploying the PostgREST Application**

After infrastructure provisioning, the script executes:

`Postgrest/postgrest.sh

This deployment script performs the following actions.

**Database Seed Job**

A Kubernetes Job runs a PostgreSQL container that inserts sample data into the database.

Example table created:

`users`

Example seeded data:

`Postgrest`

**PostgREST Deployment**

The script deploys the PostgREST container which automatically converts PostgreSQL tables into REST APIs.

**Service Creation**

A ClusterIP service is created so the application is accessible within the cluster.

**Ingress Configuration**

An Ingress resource is created so that Traefik can expose the API externally.

**External access endpoint:**

`http://<SERVER_IP>:8080/users`

**Accessing the API**

Once the deployment is complete, open the following URL in a browser.

`http://<SERVER_IP>:8080/users`

**Expected response:**

[
  {
    "id": 1,
    "name": "Postgrest"
  }
]

This confirms that:

1. PostgreSQL is running
2. Database user and privileges were configured
3, The Kubernetes job inserted data
4. PostgREST successfully exposed the database table as an API endpoint

**Destroying the Infrastructure**

To remove all resources, run:

`./terraform-destroy.sh`

This script performs the cleanup in reverse order:

1. Destroys Kubernetes resources created in k8s-secret
2. Destroys infrastructure created in cluster
3. Deletes the k3d Kubernetes cluster
4. Removes the PostgreSQL container and related resources

**Components Used**
**Infrastructure**

1. Terraform
2. k3d (Kubernetes cluster)
3. Docker
4. PostgreSQL 16

**Kubernetes Resources**

1. Namespace
2. Secret
3. Deployment
4. Service
5. Ingress
6. Database seed Job

**Application Layer**

**PostgREST**

PostgREST automatically maps database tables to REST endpoints.

Example:

`/users`

maps directly to the PostgreSQL table:

`users`

**Expected Result**

After running the deployment script, accessing the API endpoint should return the seeded database records.

**Screenshot**

<img width="1348" height="202" alt="Screenshot 2026-03-11 at 10 22 05 PM" src="https://github.com/user-attachments/assets/a0a5c51e-943e-4ece-bb9f-1e718833ecfe" />

