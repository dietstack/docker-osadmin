FROM debian:stretch-slim

# set timezone
ENV TZ=Europe/Bratislava
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV BUILD_PACKAGES="build-essential python-dev"

RUN echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf && \
    echo 'APT::Get::Install-Suggests "false";' >> /etc/apt/apt.conf && \
    apt update; apt install -y ca-certificates bash-completion wget nano vim mariadb-client python socat; \
    update-ca-certificates; \
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py; \
    python get-pip.py;

RUN apt install -y $BUILD_PACKAGES  && \
    pip install python-openstackclient==3.11.0 python-heatclient openstacksdk py2-ipaddress && \
    apt remove -y --auto-remove $BUILD_PACKAGES &&  \
    apt-get clean && apt -y autoremove && \
    rm -rf /var/lib/apt/lists/*; rm -rf /root/.cache

# copy files
COPY files/cirros-0.3.5-x86_64-disk.img /app/cirros.img
COPY configs/* /app/
COPY scripts/* /app/
RUN chmod +x /app/entrypoint.sh

# bash completion for openstack client
RUN openstack complete > /etc/bash_completion.d/openstack && \
    echo '. /etc/bash_completion' >> /root/.bashrc

# Define workdir
WORKDIR /app

ENTRYPOINT ["bash", "/app/entrypoint.sh"]

CMD /bin/bash
