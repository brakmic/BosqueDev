FROM ubuntu:22.04

# Set environment variables for pnpm
ARG PNPM_VERSION=9.15.1
ENV PNPM_VERSION=${PNPM_VERSION}
ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH:/usr/local/bin
ENV HOME=/home/bosquedev

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

###############################################################################
# (1) Install necessary packages and nano
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
# (2) Install Node.js v22.9.0
###############################################################################
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

###############################################################################
# (3) Configure locales
###############################################################################
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

###############################################################################
# (4) Install pnpm as the default package manager
###############################################################################
RUN curl -fsSL https://get.pnpm.io/install.sh | bash -s -- --version $PNPM_VERSION \
    && ln -s $PNPM_HOME/pnpm /usr/local/bin/pnpm \
    && pnpm -v

###############################################################################
# (5) Install global Node.js/TypeScript development tools
###############################################################################
RUN pnpm add -g typescript ts-node eslint prettier node-gyp

###############################################################################
# (6) Install nano syntax highlighting manually
###############################################################################
RUN mkdir -p /usr/share/nano-syntax

# Download and install nanorc syntax files from a reputable source
RUN curl -fsSL https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | bash

###############################################################################
# (7) Create non-root user with passwordless sudo
###############################################################################
RUN useradd -m -s /bin/bash bosquedev \
    && echo "bosquedev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/bosquedev \
    && chmod 0440 /etc/sudoers.d/bosquedev

###############################################################################
# (8) Set default shell to bash
###############################################################################
SHELL ["/bin/bash", "-c"]

###############################################################################
# (9) Set working directory
###############################################################################
WORKDIR /workspace

###############################################################################
# (10) Copy package.json and install dependencies
###############################################################################
COPY package.json ./
# Install dependencies
RUN pnpm install

###############################################################################
# (11) Copy src, test, and build directories and build application
###############################################################################
COPY src/ /workspace/src/
COPY test/ /workspace/test/
COPY build/ /workspace/build/
COPY tsconfig.json /workspace/tsconfig.json

# Build the application
RUN pnpm build

###############################################################################
# (12) Change ownership of the working directory and pnpm
###############################################################################
RUN chown -R bosquedev:bosquedev /workspace /pnpm /usr/local/bin/pnpm /home/bosquedev

###############################################################################
# (13) Switch to non-root user
###############################################################################
USER bosquedev

###############################################################################
# (14) Copy default shell configuration files from /etc/skel
###############################################################################
RUN cp /etc/skel/.bashrc /home/bosquedev/.bashrc \
    && cp /etc/skel/.profile /home/bosquedev/.profile

###############################################################################
# (15) Make bosque.js executable and globally available
###############################################################################
# Ensure correct path in package.json
RUN sed -i 's|"bin": {"bosque":.*|"bin": {"bosque": "./bin/src/cmd/bosque.js"},|' /workspace/package.json

# Add shebang and set executable permissions
ENV BOSQUE_JS_PATH=/workspace/bin/src/cmd/bosque.js
RUN sed -i '1i #!/usr/bin/env node' $BOSQUE_JS_PATH \
    && chmod +x $BOSQUE_JS_PATH

# Symlink to /usr/local/bin for convenience
RUN sudo ln -sf /workspace/bin/src/cmd/bosque.js /usr/local/bin/bosque

###############################################################################
# (16) Append custom aliases to .bash_aliases
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
' >> /home/bosquedev/.bash_aliases

###############################################################################
# (17) Configure nano to use syntax highlighting
###############################################################################
RUN echo "include /usr/share/nano-syntax/*.nanorc" >> /home/bosquedev/.nanorc

###############################################################################
# (18) Set default editor and ensure proper ownership
###############################################################################
RUN echo "export EDITOR=nano" >> /home/bosquedev/.bash_profile \
    && chown bosquedev:bosquedev /home/bosquedev/.bashrc \
    /home/bosquedev/.profile \
    /home/bosquedev/.bash_profile \
    /home/bosquedev/.nanorc

###############################################################################
# (19) Configure PS1 for colorized prompt
###############################################################################
ENV TERM=xterm-256color

# Append PS1 to .bashrc for the bosquedev user
RUN echo "\
# Colorized PS1 prompt\n\
export PS1=\"\[\e[0;32m\]\u@\h\[\e[m\]:\[\e[0;34m\]\w\[\e[m\]\$ \"\
" >> /home/bosquedev/.bashrc

###############################################################################
# (20) Default command to start a bash shell in interactive mode
###############################################################################
CMD ["bash", "-i"]
