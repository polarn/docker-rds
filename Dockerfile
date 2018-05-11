FROM debian:stretch

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-client curl unzip python && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && unzip awscli-bundle.zip && ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && rm -f awscli-bundle.zip

RUN curl https://storage.googleapis.com/kubernetes-release/release/v1.10.2/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

COPY entrypoint.sh /entrypoint.sh

#ENTRYPOINT ["sleep", "1000000"]
ENTRYPOINT ["/entrypoint.sh"]
