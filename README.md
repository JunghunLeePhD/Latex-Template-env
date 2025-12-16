# LaTeX Environment Docker Image

This repository hosts the **Dockerfile** and build configuration for my standardized LaTeX development environment. 

It automatically builds and publishes a public Docker image to the **GitHub Container Registry (GHCR)** whenever changes are pushed to `main`.
This image is designed to be consumed by my private LaTeX projects to ensure a consistent, zero-configuration environment.

## 📦 Image Details

- **Registry:** `ghcr.io`
- **Image Name:** `ghcr.io/junghunleephd/latex-template-env:latest`
- **Base:** Ubuntu 22.04 (via Microsoft Dev Containers)

### Included Tools
The image is optimized for academic writing and includes:
- **Core:** `latexmk`, `chktex`, `git`, `make`
- **TeX Live Packages:** 
    - `texlive-latex-base` & `recommended`
    - `texlive-fonts-recommended`
    - `texlive-latex-extra` & `bibtex-extra`
    - `biber`
    - `texlive-lang-european`
- **Perl Dependencies:** Required for `latexindent` (auto-formatting).

## 🚀 Usage

**Do not clone this repository to write papers.** 
Instead, use the [Latex-Template](https://github.com/JunghunLeePhD/Latex-Template) repository,
which is pre-configured to pull this image automatically.

If you need to pull this image manually:
```bash
docker pull ghcr.io/junghunleephd/latex-template-env:latest
```

## **🛠 Maintenance**

To add new LaTeX packages or system tools:

1. Edit the `Dockerfile`.

2. Push to `main`.

3. The **Publish Dev Container Image** workflow will automatically rebuild and update the image on GHCR.