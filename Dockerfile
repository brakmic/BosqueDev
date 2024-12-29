FROM ubuntu:22.04

# (1) Set environment variables for pnpm
ARG PNPM_VERSION=9.15.2
ENV PNPM_VERSION=${PNPM_VERSION}
ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH:/usr/local/bin

# Configure default system locale settings
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

###############################################################################
# (2) Install necessary packages
###############################################################################
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    gnupg \
    software-properties-common \
    dirmngr \
    ca-certificates \
    xz-utils \
    libatomic1 \
    sudo \
    nano \
    unzip \
    build-essential \
    gcc \
    g++ \
    make \
    git \
    git-lfs \
    python3 \
    python3-pip \
    python3-distutils \
    bash-completion \
    locales \
    && rm -rf /var/lib/apt/lists/*

###############################################################################
# (3) Install Node.js
###############################################################################
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

###############################################################################
# (4) Configure locales
###############################################################################
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

###############################################################################
# (5) Install pnpm package manager
###############################################################################
RUN curl -fsSL https://get.pnpm.io/install.sh | bash -s -- --version $PNPM_VERSION \
    && ln -s $PNPM_HOME/pnpm /usr/local/bin/pnpm \
    && pnpm -v

###############################################################################
# (6) Install global Node.js/TypeScript development tools
###############################################################################
RUN pnpm add -g typescript ts-node eslint prettier node-gyp

###############################################################################
# (7) Install nano syntax highlighting
###############################################################################
RUN mkdir -p /usr/share/nano-syntax \
    && curl -fsSL https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | bash

###############################################################################
# (8) Create a non-root user with passwordless sudo
###############################################################################
ARG NONROOT_USER=bosquedev
ENV NONROOT_USER=${NONROOT_USER}
RUN useradd -m -s /bin/bash ${NONROOT_USER} \
    && echo "${NONROOT_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${NONROOT_USER} \
    && chmod 0440 /etc/sudoers.d/${NONROOT_USER}

###############################################################################
# (9) Set default shell to bash
###############################################################################
SHELL ["/bin/bash", "-c"]

###############################################################################
# (10) Set up the workspace and clone the BosqueCore repository
###############################################################################
WORKDIR /workspace
ARG BRANCH=main
ENV BRANCH=${BRANCH}
RUN git clone --recursive -b ${BRANCH} https://github.com/BosqueLanguage/BosqueCore.git \
    && cd BosqueCore && git pull && cd /workspace
RUN cp BosqueCore/package.json ./
RUN pnpm install

###############################################################################
# (11) Copy project files
###############################################################################
WORKDIR /workspace/BosqueCore
RUN cp -r src/ test/ build/ tsconfig.json /workspace

###############################################################################
# (12) Clean up the workspace
###############################################################################
WORKDIR /workspace
RUN rm -rf BosqueCore

# Build the application
RUN pnpm build

###############################################################################
# (13) Adjust file ownership for the non-root user
###############################################################################
RUN chown -R ${NONROOT_USER}:${NONROOT_USER} /workspace /pnpm /usr/local/bin/pnpm ${HOME}

###############################################################################
# (14) Switch to the non-root user
###############################################################################
USER ${NONROOT_USER}

###############################################################################
# (15) Configure default shell environment for the user
###############################################################################
ENV HOME=/home/${NONROOT_USER}
RUN cp /etc/skel/.bashrc ${HOME}/.bashrc \
    && cp /etc/skel/.profile ${HOME}/.profile

###############################################################################
# (16) Make bosque.js globally executable
###############################################################################
# Update the package.json to include the correct path to bosque.js
RUN sed -i 's|"bin": {"bosque":.*|"bin": {"bosque": "./bin/src/cmd/bosque.js"},|' /workspace/package.json

# Add a shebang to bosque.js and set it as executable
ENV BOSQUE_JS_PATH=/workspace/bin/src/cmd/bosque.js
RUN sed -i '1i #!/usr/bin/env node' $BOSQUE_JS_PATH \
    && chmod +x $BOSQUE_JS_PATH

# Symlink bosque.js to /usr/local/bin for easier access
RUN sudo ln -sf /workspace/bin/src/cmd/bosque.js /usr/local/bin/bosque

###############################################################################
# (17) Clone Bosque Language Tools for VSCode integration (syntax highlighting)
###############################################################################
ENV BSQ_LANG_TOOLS_PATH=${HOME}/.vscode-server/extensions/bosque-language-tools
RUN mkdir -p ${BSQ_LANG_TOOLS_PATH} \
    && git clone https://github.com/BosqueLanguage/bosque-language-tools.git ${BSQ_LANG_TOOLS_PATH} \
    && cd ${BSQ_LANG_TOOLS_PATH} && git pull && cd /workspace

###############################################################################
# (18) Add shell aliases
###############################################################################
RUN echo -e '\
alias ll="ls -la"\n\
alias la="ls -A"\n\
alias l="ls -CF"\n\
alias gs="git status"\n\
alias ga="git add"\n\
alias gp="git push"\n\
alias gl="git log"\n\
alias rm="rm -i"\n\
alias cp="cp -i"\n\
alias mv="mv -i"\n\
alias nano="nano -c"\n\
alias ..="cd .."\n\
alias ...="cd ../.."\n\
alias ....="cd ../../.."\n\
' >> ${HOME}/.bash_aliases

###############################################################################
# (19) Configure nano with syntax highlighting for the user
###############################################################################
RUN echo "include /usr/share/nano-syntax/*.nanorc" >> ${HOME}/.nanorc

###############################################################################
# (20) Set nano as the default editor and adjust ownership of config files
###############################################################################
RUN echo "export EDITOR=nano" >> ${HOME}/.bash_profile \
    && chown ${NONROOT_USER}:${NONROOT_USER} ${HOME}/.bashrc \
    ${HOME}/.profile \
    ${HOME}/.bash_profile \
    ${HOME}/.nanorc

###############################################################################
# (21) Customize the terminal prompt for the user
###############################################################################
ENV TERM=xterm-256color
RUN echo "\
# Colorized PS1 prompt\n\
export PS1=\"\[\e[0;32m\]\u@\h\[\e[m\]:\[\e[0;34m\]\w\[\e[m\]\$ \"\
" >> ${HOME}/.bashrc

###############################################################################
# (22) Default command to start an interactive bash shell
###############################################################################
CMD ["bash", "-i"]
