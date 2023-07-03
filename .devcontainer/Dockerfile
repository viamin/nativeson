FROM mcr.microsoft.com/vscode/devcontainers/ruby:3.1-bullseye

# Default value to allow debug server to serve content over GitHub Codespace's port forwarding service
# The value is a comma-separated list of allowed domains 
ENV RAILS_DEVELOPMENT_HOSTS=".githubpreview.dev,.preview.app.github.dev,.app.github.dev"

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update -qq && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -yq dist-upgrade \
    && apt-get -y install --no-install-recommends \
    cmake \
    graphviz \
    imagemagick libmagickwand-dev \
    pkg-config \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* \
    && truncate -s 0 /var/log/*log

# [Optional] Uncomment this line to install additional gems.
RUN su vscode -c "gem update --system && gem install bundler git_curate listen ruby-lsp standard"

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1
