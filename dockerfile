# syntax=docker/dockerfile:1
# -----------------------------------------------------------------------------
# Open OnDemand portal image for HPE PCAI
# -----------------------------------------------------------------------------
# OSC does not publish a production image, so we build one from the ondemand RPM
# repo (this mirrors the upstream Dockerfile.example) and add the two things the
# PCAI Helm chart needs:
#   1. kubectl        -> the Kubernetes job adapter shells out to it per session
#   2. a boot oneshot -> regenerates the Apache config from the mounted
#                        /etc/ood/config/ood_portal.yml (so portal.servername works)
#
# Build & push to your PCAI registry (Harbor):
#   docker build -t <harbor>/ondemand:4.2.4 .
#   docker push  <harbor>/ondemand:4.2.4
#
# The container runs systemd (CMD /sbin/init); the pod must be privileged/root.
# -----------------------------------------------------------------------------
FROM rockylinux/rockylinux:9

LABEL maintainer="PCAI frameworks" \
      org.opencontainers.image.title="Open OnDemand" \
      org.opencontainers.image.source="https://github.com/OSC/ondemand"

# OnDemand release line (4.2) and kubectl version. Keep kubectl within one minor
# of the PCAI cluster's Kubernetes version.
ARG OOD_RELEASE=4.2
ARG KUBECTL_VERSION=v1.30.5

# Enable the OnDemand repo and install the portal + its runtime deps.
RUN dnf -y install "https://yum.osc.edu/ondemand/${OOD_RELEASE}/ondemand-release-web-${OOD_RELEASE}-1.el9.noarch.rpm" && \
    dnf -y update && \
    dnf install -y dnf-utils epel-release && \
    dnf module enable -y ruby:3.3 nodejs:22 && \
    dnf install -y ondemand && \
    dnf clean all && rm -rf /var/cache/dnf/*

# kubectl for the Kubernetes resource-manager adapter (clusters.d bin path).
RUN curl -fsSL -o /usr/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x /usr/bin/kubectl

# Generate the localhost TLS cert some default vhosts expect (harmless behind
# Istio, which terminates TLS at the gateway).
RUN /usr/libexec/httpd-ssl-gencerts || true

# Regenerate the Apache portal config from the mounted ood_portal.yml on boot,
# before httpd starts, so the chart's portal.servername takes effect.
RUN cat <<'EOF' > /etc/systemd/system/ood-portal-update.service
[Unit]
Description=Regenerate Open OnDemand Apache portal config
After=network-online.target
Before=httpd.service

[Service]
Type=oneshot
ExecStart=/opt/ood/ood-portal-generator/sbin/update_ood_portal
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

RUN systemctl enable httpd ood-portal-update.service

EXPOSE 80
EXPOSE 443

CMD ["/sbin/init"]
