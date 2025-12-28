# Use a lightweight Ubuntu base
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Set environment variables to allow non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Core Dependencies & LaTeX
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # ---- Core Build Tools ----
    latexmk \
    chktex \
    texlive-extra-utils \
    # ---- Dependencies for Formatter (Perl) ----
    libyaml-tiny-perl \
    libfile-homedir-perl \
    # ---- LaTeX Packages ----
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-latex-extra \
    texlive-bibtex-extra \
    biber \
    texlive-lang-european \
    # ---- Extension Installation Tools ----
    curl \
    jq \
    unzip \
    # ---- Cleanup ----
    && apt-get autoremove -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup VS Code Extensions Directory
# We create the directory and ensure the 'vscode' user owns it.
RUN mkdir -p /home/vscode/.vscode-server/extensions \
    && chown -R vscode:vscode /home/vscode/.vscode-server

# 3. Install Extensions (Run as 'vscode' user)
USER vscode
WORKDIR /tmp/extensions

# Download latest VSIX files
# Note: These URLs fetch the latest version.
RUN curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/james-yu/vsextensions/latex-workshop/latest/vspackage -o latex-workshop.vsix \
    && curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/streetsidesoftware/vsextensions/code-spell-checker/latest/vspackage -o code-spell-checker.vsix

# Extract and Install
# Loop through VSIX files, read metadata from package.json, and move to the correct path.
RUN for file in *.vsix; do \
        unzip -q "$file" -d extension_temp; \
        PUB=$(jq -r '.publisher' extension_temp/extension/package.json); \
        NAME=$(jq -r '.name' extension_temp/extension/package.json); \
        VER=$(jq -r '.version' extension_temp/extension/package.json); \
        mv extension_temp/extension "/home/vscode/.vscode-server/extensions/${PUB}.${NAME}-${VER}"; \
        rm -rf extension_temp; \
    done \
    && rm *.vsix

# Switch back to root (clean up)
USER root
WORKDIR /
ENV DEBIAN_FRONTEND=dialog
