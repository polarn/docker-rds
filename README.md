# docker-rds

**DEPRECATED**

This has been replaced by [polarn/kubesdb](https://github.com/polarn/kubesdb) instead!

**DEPRECATED**

A docker image to create databases inside an RDS

This is published as a Docker image [polarn/docker-rds](https://hub.docker.com/r/polarn/docker-rds/).

## Why?
Well, our problem was that we decided to have one RDS Aurora cluster on a private subnet and share it between all our micro services, by creating MySQL databases for each service inside it. We wanted to do this in an "infrastructure as code" way but it proved a bit difficult using SSH tunnels to a bastion host, etc...

So my idea is to use a Kubernetes pod to create the database(s). You will need the following:

* AWS RDS Aurora MySQL
* RDS endpoint, master username and password as Kubernetes Secret
* Kubernetes Secrets for all databases needed containing JDBC URL, username and password. Label with docker-rds=true
* The deployment itself

## Usage

### Create RDS cluster
Create the RDS cluster using your favourite tool (we use [Terraform](https://www.terraform.io/)) or using the UI.

### RDS Endoint, Username and password as Kubernetes Secret
We add them using the terraform kubernetes plugin

### Kubernetes Secret
We put the following in our Secrets:

* `database` : Database name
* `url` : The JDBC URL
* `username` : The username of the grant to be created
* `password` : And the password to that grant

You could obviously put the `database`, `url` and `username` in a ConfigMap but I don't see the point of having two resources.

Here is an example:

```
kubectl create secret generic docker-rds-secret --from-literal=database=exampledb --from-literal=username=exampleuser --from-literal=password=$(openssl rand -hex 8) --from-literal=url=jdbc:mysql://examplerds.randomstring.region.rds.amazonaws.com:3306/exampledb?useSSL=false
kubectl label secret docker-rds-secret docker-rds=true
```

### Kubernetes job / pod
In the repo there is an example file of how we use it: [kubernetes-deployment.yaml](kubernetes-deployment.yaml)

## Taking it further
A daemon running listening for secrets being added instead of a looping bash script.
