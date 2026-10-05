# Built by .github/workflows/deploy.yml (context ., file Dockerfile) and pushed
# to Artifact Registry.
#
# A job image, not a server: the default command runs scripts/check.sh
# (hcl fmt --check, terraform fmt -check, run --all validate, run --all plan)
# and exits 0 when all of it passes. It never listens on $PORT.
#
# Terragrunt has no official image: the release binary is downloaded from
# GitHub and checked against the release's SHA256SUMS. Every unit is
# initialised at BUILD time (providers from the committed lock files, shared
# through a plugin cache), so the job itself needs no registry access.

FROM hashicorp/terraform:1.16.5 AS runtime
ARG TERRAGRUNT_VERSION=1.1.6
ARG TARGETARCH
ARG BUILD_ID=""
ENV BUILD_ID=$BUILD_ID TF_IN_AUTOMATION=1 TF_INPUT=0 HOME=/home/app \
    TG_TF_PATH=terraform TG_NON_INTERACTIVE=true \
    TF_PLUGIN_CACHE_DIR=/home/app/.terraform.d/plugin-cache
RUN set -eux; arch="${TARGETARCH:-amd64}"; \
    cd /tmp; \
    wget -q "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${arch}"; \
    wget -q "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/SHA256SUMS"; \
    grep " terragrunt_linux_${arch}\$" SHA256SUMS | sha256sum -c -; \
    install -m 0755 "terragrunt_linux_${arch}" /usr/local/bin/terragrunt; \
    rm -f "terragrunt_linux_${arch}" SHA256SUMS; \
    adduser -D -u 10001 -h /home/app app; \
    mkdir -p /app "$TF_PLUGIN_CACHE_DIR"; chown -R app:app /app /home/app
WORKDIR /app
COPY --chown=app:app . .
USER app
RUN terragrunt run --all --parallelism 1 --working-dir live -- init -input=false -lockfile=readonly
# the base image's ENTRYPOINT is `terraform`; the job is a script
ENTRYPOINT []
CMD ["sh", "scripts/check.sh"]
