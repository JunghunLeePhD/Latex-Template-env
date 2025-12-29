# Use a lightweight Ubuntu base
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Core Dependencies & LaTeX
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    latexmk chktex texlive-extra-utils libyaml-tiny-perl libfile-homedir-perl \
    texlive-latex-base texlive-latex-recommended texlive-fonts-recommended \
    texlive-latex-extra texlive-bibtex-extra biber texlive-lang-european \
    curl jq unzip \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Create a folder for Offline Extensions
# We store them here because this folder will NOT be overwritten by VS Code.
RUN mkdir -p /opt/vsix-cache && chown vscode:vscode /opt/vsix-cache

# 3. Download Extensions to the Cache (Run as 'vscode')
USER vscode
WORKDIR /opt/vsix-cache

# Download VSIX files (LaTeX Workshop & Spell Checker)
RUN curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/james-yu/vsextensions/latex-workshop/latest/vspackage -o latex-workshop.vsix \
    && curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/streetsidesoftware/vsextensions/code-spell-checker/latest/vspackage -o code-spell-checker.vsix

# 4. Create an 'Offline Install' Script
# This script will run every time the container starts to ensure extensions are installed.
RUN echo '#!/bin/bash' > /opt/vsix-cache/install-extensions.sh \
    && echo 'for file in /opt/vsix-cache/*.vsix; do' >> /opt/vsix-cache/install-extensions.sh \
    && echo '  code --install-extension "$file" --force' >> /opt/vsix-cache/install-extensions.sh \
    && echo 'done' >> /opt/vsix-cache/install-extensions.sh \
    && chmod +x /opt/vsix-cache/install-extensions.sh

# Switch back to root
USER root
WORKDIR /
ENV DEBIAN_FRONTEND=dialog
