FROM debian:buster-slim AS build

ENV GOLANG_VERSION dev.go2go
ENV GOLANG_BUILDDIR /usr/src/go
ENV GOPATH /usr/src
ENV GOROOT_FINAL /usr/local/lib/go
ENV GO_LDFLAGS -buildmode=pie

RUN set -eux \
    && echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list \
    && echo "deb-src http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        gcc \
        git \
        libc6-dev \
        make \
        netbase \
    && apt-get -t buster-backports install -y --no-install-recommends golang-go \
    && export \
        GOOS="$(go env GOOS)" \
        GOARCH="$(go env GOARCH)" \
        GOROOT_BOOTSTRAP="$(go env GOROOT)" \
        GOROOT="${GOLANG_BUILDDIR}" \
        GOBIN="${GOLANG_BUILDDIR}/bin" \
    && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
            armhf) export GOARM='6' ;; \
            armv7) export GOARM='7' ;; \
            i386) export GO386='387' ;; \
        esac \
    \
    # Build
    && git clone --depth=1 --single-branch -b ${GOLANG_VERSION} https://github.com/golang/go.git ${GOLANG_BUILDDIR} \
    && cd ${GOLANG_BUILDDIR}/src \
    && ./make.bash -v \
    \
    && export PATH="${GOLANG_BUILDDIR}/bin:$PATH" \
    && go version \
    \
    # Test
    && ./run.bash -k -no-rebuild \
    \
    # Install
    && cd ${GOLANG_BUILDDIR} \
    && mkdir -p ${GOROOT_FINAL}/bin \
    && for binary in go gofmt; do \
            strip bin/${binary}; \
            install -Dm755 bin/${binary} ${GOROOT_FINAL}/bin/${binary}; \
        done \
    && cp -a pkg lib src ${GOROOT_FINAL} \
    && rm -rf ${GOROOT_FINAL}/pkg/obj \
    && rm -rf ${GOROOT_FINAL}/pkg/bootstrap \
    && rm -f ${GOROOT_FINAL}/pkg/tool/*/api \
    && strip ${GOROOT_FINAL}/pkg/tool/$(go env GOOS)_$(go env GOARCH)/* \
    # Remove tests from go/src to reduce package size,
    # these should not be needed at run-time by any program.
    && find ${GOROOT_FINAL}/src -type f -a \( -name "*_test.go" \) \
        -exec rm -rf \{\} \+ \
    && find ${GOROOT_FINAL}/src -type d -a \( -name "testdata" -not -path "*/go2go/*" \) \
        -exec rm -rf \{\} \+ \
    # Remove scripts and docs to reduce package
    && find ${GOROOT_FINAL}/src -type f \
        -a \( -name "*.rc" -o -name "*.bat" -o -name "*.sh" -o -name "Make*" -o -name "README*" \) \
        -exec rm -rf \{\} \+

FROM debian:latest
MAINTAINER Nikolay Bereznyak "beresnevn70@gmail.com"
ENV TZ=Asia/Barnaul
ENV NEW_WALLET=true
ENV MNEMONIC_WORDS=
ENV PRIVATE_KEY=
ENV DOMAINAPI=0.0.0.0
ENV WALLET_PASSWORD=
ENV ENABLE_STORAGE=true
ENV STORAGE_MAX=32
ENV GOPATH /go
ENV GOROOT /usr/local/lib/go
ENV PATH "${GOPATH}/bin:${GOROOT}/bin:${PATH}"
ENV GO2PATH "${GOROOT}/src/cmd/go2go/testdata/go2path"

COPY --from=build /usr/local/lib/go /usr/local/lib/go

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get install -y -q
RUN apt-get update && apt-get full-upgrade -y && apt-get -y install openssh-server mc wget curl net-tools tini ca-certificates
RUN mkdir -p "${GOPATH}/src" "${GOPATH}/bin" \
    && chmod -R 777 "${GOPATH}" \
    && ln -s /usr/local/lib/go/bin/go /usr/bin/ \
    && ln -s /usr/local/lib/go/bin/gofmt /usr/bin/
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
WORKDIR "${GOPATH}"
COPY run.sh run.sh
RUN  chmod +x run.sh
 
ENTRYPOINT ["/usr/bin/tini", "--", "/run.sh"]
