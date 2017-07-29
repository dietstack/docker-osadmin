FROM alpine:3.5
RUN apk add --no-cache ca-certificates bash wget nano vim mariadb-client python; \
    update-ca-certificates; \
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py; \
    python get-pip.py;

RUN pip install python-openstackclient python-heatclient openstacksdk py2-ipaddress

# copy files
COPY files/cirros-0.3.5-x86_64-disk.img /app/cirros.img
COPY configs/* /app/
COPY scripts/* /app/
RUN chmod +x /app/entrypoint.sh

# Apply patches
RUN mkdir -p /patches
COPY patches/* /patches/
RUN /patches/patch.sh

# bash completion for openstack client
RUN openstack complete > /etc/bash_completion.d/openstack && \
    echo '. /etc/bash_completion' >> /root/.bashrc

# Define workdir
WORKDIR /app

ENTRYPOINT ["/app/entrypoint.sh"]

CMD /bin/bash

