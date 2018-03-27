# docker-rds
A docker image to create databases inside an RDS

This is published as a Docker image [polarn/docker-rds](https://hub.docker.com/r/polarn/docker-rds/).

## Why?
Well, our problem was that we decided to have one RDS Aurora cluster on a private subnet and share it between all our micro services, by creating MySQL databases for each service inside it. We wanted to do this in an "infrastructure as code" way but it proved a bit difficult using SSH tunnels to a bastion host, etc...

So my idea is to use a Kubernetes job to create the database(s). You will need the following:

* AWS RDS Aurora MySQL
* RDS master username and password as AWS SSM Parameters
* AWS IAM role for the Kubernetes job/pod using [kube2iam](https://github.com/jtblin/kube2iam)
* Kubernetes Secret containing JDBC URL, username and password.
* The job/pod itself

## Usage

### Create RDS cluster
Create the RDS cluster using your favourite tool (we use [Terraform](https://www.terraform.io/)) or using the UI.

### RDS Username and password as AWS SSM parameters
In our setup, the password resource is created manually and then picked up by Terraform when creating the RDS cluster. The username resource is created by Terraform.

```
aws ssm put-parameter --name "/project/dev/aurora/password" --type "SecureString" --value "password123" --key-id "alias/project/master" --overwrite
```

Note: You could actually supply them in clear text when creating the Kubernetes job or add them as Kubernetes secrets and pick the up in the YAML, but my view of it is that they are part of the AWS infrastructure, not the Kubernetes, so I prefer to have them as AWS SSM parameters.

### AWS IAM Role
Either add the permissions on the Kubernetes nodes or use the more elegant [kube2iam](https://github.com/jtblin/kube2iam) or similar tool. Here is an example:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:<region>:<account-id>:parameter/project/dev/aurora/*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "kms:Decrypt",
            "Resource": "arn:aws:kms:<region>:<account-id>:key/<key>"
        }
    ]
}
```

### Kubernetes Secret
We put the following in our Secrets:

* JDBC URL
* Username
* Password

You could obviously put the `JDBC URL` and `Username` in a ConfigMap but I don't see the point of having two resources.

Here is an example:

```
kubectl create secret generic docker-rds-secret --from-literal=username=exampleuser --from-literal=password=$(openssl rand -hex 8) --from-literal=url=jdbc:mysql://examplerds.randomstring.region.rds.amazonaws.com:3306/exampledb?useSSL=false
```

### Kubernetes job / pod
In the repo there is an example file of how we use it: [kubernetes-job.yaml](kubernetes-job.yaml)

## Taking it further
One idea I had was to have a daemon running listening for secrets being added and then on demand create databases, maybe that will be the next step. :)
