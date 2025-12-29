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
RUN mkdir -p /opt/vsix-cache && chown vscode:vscode /opt/vsix-cache

# 3. Download Extensions from Open VSX
USER vscode
WORKDIR /opt/vsix-cache

# 3a. Download LaTeX Workshop
RUN echo "Resolving LaTeX Workshop..." \
    && LW_URL=$(curl -s https://open-vsx.org/api/James-Yu/latex-workshop/latest | jq -r '.files.download') \
    && if [ "$LW_URL" = "null" ]; then echo "Error: LateX Workshop not found on Open VSX"; exit 1; fi \
    && echo "Downloading from $LW_URL" \
    && curl -L "$LW_URL" -o latex-workshop.vsix

# 3b. Download Code Spell Checker
RUN echo "Resolving Code Spell Checker..." \
    && SC_URL=$(curl -s https://open-vsx.org/api/streetsidesoftware/code-spell-checker/latest | jq -r '.files.download') \
    && if [ "$SC_URL" = "null" ]; then echo "Error: Spell Checker not found on Open VSX"; exit 1; fi \
    && echo "Downloading from $SC_URL" \
    && curl -L "$SC_URL" -o code-spell-checker.vsix

# 3c. Verify downloads
RUN unzip -tq latex-workshop.vsix && unzip -tq code-spell-checker.vsix \
    && echo "✅ Extensions downloaded and verified successfully."

# 4. Create an 'Offline Install' Script with Notification
RUN echo '#!/bin/bash' > /opt/vsix-cache/install-extensions.sh \
    && echo 'EXT_DIR="$HOME/.vscode-server/extensions"' >> /opt/vsix-cache/install-extensions.sh \
    && echo 'mkdir -p "$EXT_DIR"' >> /opt/vsix-cache/install-extensions.sh \
    && echo 'for file in /opt/vsix-cache/*.vsix; do' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    echo "Installing $file..."' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    unzip -q "$file" -d extension_temp' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    PUB=$(jq -r ".publisher" extension_temp/extension/package.json)' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    NAME=$(jq -r ".name" extension_temp/extension/package.json)' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    VER=$(jq -r ".version" extension_temp/extension/package.json)' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    TARGET="$EXT_DIR/$PUB.$NAME-$VER"' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    if [ ! -d "$TARGET" ]; then' >> /opt/vsix-cache/install-extensions.sh \
    && echo '        mv extension_temp/extension "$TARGET"' >> /opt/vsix-cache/install-extensions.sh \
    && echo '        echo "Installed to $TARGET"' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    else' >> /opt/vsix-cache/install-extensions.sh \
    && echo '        echo "Extension already installed."' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    fi' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    rm -rf extension_temp' >> /opt/vsix-cache/install-extensions.sh \
    && echo 'done' >> /opt/vsix-cache/install-extensions.sh \
    && echo 'if command -v code >/dev/null 2>&1; then' >> /opt/vsix-cache/install-extensions.sh \
    && echo '    code --status-message "✅ LaTeX Setup Complete! Please Reload Window (Ctrl+R) to activate extensions."' >> /opt/vsix-cache/install-extensions.sh \
    && echo 'fi' >> /opt/vsix-cache/install-extensions.sh \
    && chmod +x /opt/vsix-cache/install-extensions.sh

# 5. Configure ChkTeX (Disable annoying warnings)
# We add this while still running as USER vscode so permissions are correct
RUN echo 'CmdLine { -n30 -n22 -n8 }' > /home/vscode/.chktexrc

# Switch back to root
USER root
WORKDIR /
ENV DEBIAN_FRONTEND=dialog
