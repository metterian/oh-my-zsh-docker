FROM ubuntu:18.04 as base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -ex \
  && apt-get update \
  # install dependencies
  && apt-get install --yes --no-install-recommends \
  ca-certificates=* \
  wget \
  git \
  zsh \
  sudo \
  screen \
  curl \
  vim \
  net-tools  \
  openssh-server


# install LSDeluxe
RUN \
  LSDELUXE_VERSION="0.17.0" \
  && LSDELUXE_DOWNLOAD_SHA256="ac85771d6195ef817c9d14f8a8a0d027461bfc290d46cb57e434af342a327bb2" \
  && wget -nv -O lsdeluxe.deb https://github.com/Peltoche/lsd/releases/download/${LSDELUXE_VERSION}/lsd_${LSDELUXE_VERSION}_amd64.deb \
  && echo "$LSDELUXE_DOWNLOAD_SHA256 lsdeluxe.deb" | sha256sum -c - \
  && dpkg -i lsdeluxe.deb \
  && rm lsdeluxe.deb


ENV APP_USER=joon
ENV APP_USER_GROUP=www-data
ARG APP_USER_HOME=/home/$APP_USER

# create non root user
RUN \
  adduser --quiet --disabled-password \
  --shell /bin/bash \
  --gecos "User" $APP_USER \
  --ingroup $APP_USER_GROUP

USER $APP_USER
WORKDIR $APP_USER_HOME

# install oh-my-zsh
RUN wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | zsh || true

ARG ZSH_CUSTOM=$APP_USER_HOME/.oh-my-zsh/custom


# install oh-my-zsh plugins and theme
RUN \
  ZSH_PLUGINS=$ZSH_CUSTOM/plugins \
  && ZSH_THEMES=$ZSH_CUSTOM/themes \
  && git clone --single-branch --branch '0.7.1' --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_PLUGINS/zsh-syntax-highlighting \
  && git clone --single-branch --branch 'v0.6.4' --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_PLUGINS/zsh-autosuggestions


# install oh-my-zsh config files
COPY --chown=$APP_USER:$APP_USER_GROUP ./config/.zshrc $APP_USER_HOME/
COPY --chown=$APP_USER:$APP_USER_GROUP ./config/aliases.zsh $ZSH_CUSTOM

# install ssh config files
ADD --chown=$APP_USER:$APP_USER_GROUP ./config/.ssh $APP_USER_HOME/.ssh

# install Miniconda3
WORKDIR $APP_USER_HOME/Downloads
RUN wget -O Miniconda3.sh https://repo.anaconda.com/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh


WORKDIR $APP_USER_HOME


CMD ["zsh"]
