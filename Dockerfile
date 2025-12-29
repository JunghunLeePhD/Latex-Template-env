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

# We use a User-Agent to prevent the Marketplace from blocking the request.
# We also use '-o' to explicitly name the files, ensuring they are saved correctly.
RUN curl -f -L -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/james-yu/vsextensions/latex-workshop/latest/vspackage" \
    -o latex-workshop.vsix \
    && curl -f -L -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/streetsidesoftware/vsextensions/code-spell-checker/latest/vspackage" \
    -o code-spell-checker.vsix

# (Optional verify step: This will fail the build if the files are too small/corrupted)
RUN if [ $(stat -c%s "latex-workshop.vsix") -lt 10000 ]; then echo "Error: Download failed"; exit 1; fi

# 4. Create an 'Offline Install' Script (Manual Extraction)
# We use 'unzip' and 'jq' to install extensions without needing the 'code' CLI.
RUN echo '#!/bin/bash' > /opt/vsix-cache/install-extensions.sh \
    && echo 'EXT_DIR="$HOME/.vscode-server/extensions"' >> /opt/vsix-cache/install-extensions.sh \
    && echo 'mkdir -p "$EXT_DIR"' >> /opt/vsix-cache/install-extensions.sh \
    && echo 'for file in /opt/vsix-cache/*.vsix; do' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    echo "Installing $file..."' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    # Unzip to a temporary directory' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    unzip -q "$file" -d extension_temp' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    # Read metadata to determine the correct folder name' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    PUB=$(jq -r ".publisher" extension_temp/extension/package.json)' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    NAME=$(jq -r ".name" extension_temp/extension/package.json)' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    VER=$(jq -r ".version" extension_temp/extension/package.json)' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    TARGET="$EXT_DIR/$PUB.$NAME-$VER"' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    # Move if it does not exist yet' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    if [ ! -d "$TARGET" ]; then' >> /opt/vsix-cache/install-extensions.sh \
    && echo '        mv extension_temp/extension "$TARGET"' >> /opt/vsix-cache/install-extensions.sh \
    && echo '        echo "Installed to $TARGET"' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    else' >> /opt/vsix-cache/install-extensions.sh \
    && echo '        echo "Extension already installed."' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    fi' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    rm -rf extension_temp' >> /opt/vsix-cache/install-extensions.sh \
    && echo 'done' >> /opt/vsix-cache/install-extensions.sh \
    && chmod +x /opt/vsix-cache/install-extensions.sh
    
# Switch back to root
USER root
WORKDIR /
ENV DEBIAN_FRONTEND=dialog
