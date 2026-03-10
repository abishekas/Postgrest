**Infrastructure Take Home:**

Treat this system as a production system.

Getting Started

Clone this repository locally.

Create your own public repository in GitHub (or any platform accessible to the reviewer) and push this code into it.
Make changes to your repository as needed to complete the assignment.

The reviewer will clone your repository and run the instructions provided in this README to recreate the expected solution.

If the instructions cannot be followed to reproduce the environment, the solution cannot be assessed.


**Prerequisites**

The following tools must be installed:

Docker runtime and Docker CLI

k3d CLI

Terraform or OpenTofu

kubectl

Git

**Deployment Instructions**
**1. Provision Infrastructure**

Navigate to the tofu directory and run:

terraform apply

This Terraform configuration will perform the following actions:

Create a local Kubernetes cluster using k3d

Provision a PostgreSQL 16 container

Create a PostgreSQL database named postgrest

Create a PostgreSQL superuser named:

postgrest_user

with password:

postgrest_password

Grant required privileges on:

the public schema

all tables within the schema

Create a Kubernetes namespace named:

postgrest

Create a Kubernetes secret named:

postgrest-db

inside the postgrest namespace containing the database connection credentials used by the PostgREST application.

**Note:**
During the first run, terraform apply may fail while the Kubernetes cluster is still initializing.
If this occurs, simply run the command again.

**2. Deploy the PostgREST Application**

Navigate to the Postgrest directory:

cd Postgrest

Run the deployment script:

./postgrest.sh

This script performs the following tasks:

Creates a Kubernetes Job that inserts seed data into the PostgreSQL database

Deploys the PostgREST application as a Kubernetes Deployment

Creates a ClusterIP Service to expose the application inside the cluster

Creates an Ingress resource to expose the PostgREST API externally

**3. Access the API**

Once the deployment is complete, the API can be accessed via the ingress endpoint.

Example:

http://<SERVER_IP>:8080/users

Expected output:

[
  {
    "id": 1,
    "name": "Alice"
  }
]

This output confirms that:

The database user was created successfully

The Kubernetes job inserted data into PostgreSQL

PostgREST is correctly exposing the table as a REST API endpoint

**4. Project Components**

This solution includes the following components.

Infrastructure (Terraform)

k3d Kubernetes cluster provisioning

PostgreSQL container deployment

PostgreSQL database creation

PostgreSQL role and privilege configuration

Kubernetes namespace creation

Kubernetes secret management

Kubernetes Resources

PostgREST Deployment

PostgREST Service

PostgREST Ingress

Database seeding Job

PostgREST

The PostgREST service automatically exposes PostgreSQL tables as REST API endpoints.

**For example:**

/users

maps directly to the users table in the PostgreSQL database.

**Expected Result**

After following the above steps, opening the API endpoint in a browser should display the seeded data from PostgreSQL.

A screenshot of this response should be included below.

**Screenshot**

<img width="2940" height="544" alt="image" src="https://github.com/user-attachments/assets/836942d6-5fda-4602-9716-57b35ed3f624" />

