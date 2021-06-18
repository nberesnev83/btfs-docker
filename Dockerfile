FROM debian:latest
MAINTAINER Nikolay Bereznyak "beresnevn70@gmail.com"
ENV TZ=Asia/Barnaul
ENV NEW_WALLET=true

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get install -y -q
RUN apt-get update && apt-get full-upgrade -y && apt-get -y install openssh-server mc wget curl net-tools
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
RUN mkdir /var/run/sshd
RUN echo 'root:password' | chpasswd
RUN sed -i 's|#Port 22|Port 22|' /etc/ssh/sshd_config
RUN sed -i 's|#AddressFamily any|AddressFamily any|' /etc/ssh/sshd_config
RUN sed -i 's|#HostKey /etc/ssh/ssh_host_rsa_key|HostKey /etc/ssh/ssh_host_rsa_key|' /etc/ssh/sshd_config
RUN sed -i 's|#HostKey /etc/ssh/ssh_host_ecdsa_key|HostKey /etc/ssh/ssh_host_ecdsa_key|' /etc/ssh/sshd_config
RUN sed -i 's|#HostKey /etc/ssh/ssh_host_ed25519_key|HostKey /etc/ssh/ssh_host_ed25519_key|' /etc/ssh/sshd_config
RUN sed -i 's|#LoginGraceTime 2m|LoginGraceTime 30|' /etc/ssh/sshd_config
RUN sed -i 's|#PermitRootLogin prohibit-password|PermitRootLogin yes|' /etc/ssh/sshd_config
RUN sed -i 's|#StrictModes yes|StrictModes yes|' /etc/ssh/sshd_config
RUN sed -i 's|#MaxAuthTries 6|MaxAuthTries 3|' /etc/ssh/sshd_config
RUN sed -i 's|#MaxSessions 10|MaxSessions 5|' /etc/ssh/sshd_config
RUN sed -i 's|#PubkeyAuthentication yes|PubkeyAuthentication yes|' /etc/ssh/sshd_config
RUN sed -i 's|#AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2|AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2|' /etc/ssh/sshd_config
RUN sed -i 's|#PasswordAuthentication yes|PasswordAuthentication yes|' /etc/ssh/sshd_config
RUN sed -i 's|#PermitEmptyPasswords no|PermitEmptyPasswords no|' /etc/ssh/sshd_config
RUN sed -i 's|#KerberosAuthentication no|KerberosAuthentication no|' /etc/ssh/sshd_config
RUN sed -i 's|#GSSAPIAuthentication no|GSSAPIAuthentication no|' /etc/ssh/sshd_config
RUN sed -i 's|#AllowAgentForwarding yes|AllowAgentForwarding no|' /etc/ssh/sshd_config
RUN sed -i 's|#AllowTcpForwarding yes|AllowTcpForwarding no|' /etc/ssh/sshd_config
RUN sed -i 's|X11Forwarding yes|X11Forwarding no|' /etc/ssh/sshd_config
RUN sed -i 's|#PrintLastLog yes|PrintLastLog yes|' /etc/ssh/sshd_config
RUN sed -i 's|#TCPKeepAlive yes|TCPKeepAlive no|' /etc/ssh/sshd_config
RUN sed -i 's|#Compression delayed|Compression delayed|' /etc/ssh/sshd_config
RUN sed -i 's|#ClientAliveInterval 0|ClientAliveInterval 0|' /etc/ssh/sshd_config
RUN sed -i 's|#ClientAliveCountMax 3|ClientAliveCountMax 3|' /etc/ssh/sshd_config
RUN sed -i 's|#UseDNS no|UseDNS no|' /etc/ssh/sshd_config

# Download and install btfs
RUN mkdir -p /opt/btfs
RUN mkdir -p /etc/btfs
RUN cd /opt/btfs
RUN wget https://raw.githubusercontent.com/TRON-US/btfs-binary-releases/master/install.sh
RUN bash install.sh -o linux -a amd64
RUN mv /root/btfs/bin/fs-repo-migrations /usr/bin/fs-repo-migrations
RUN mv /root/btfs/bin/btfs /usr/bin/btfs
RUN mv /root/btfs/bin/config.yaml /etc/btfs/config.yaml
RUN rm -rf /root/btfs
RUN rm -f install.sh

# initiate environment
RUN echo 'BTFS_PATH="/opt/btfs"' >> /etc/environment
RUN echo 'ENABLE_WALLET_REMOTE="true"' >> /etc/environment

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE="in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
EXPOSE 5001
VOLUME /opt/btfs
COPY run.sh run.sh
RUN  chmod +x run.sh
 
CMD  ./run.sh
