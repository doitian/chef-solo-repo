#!/bin/bash -e
[ "$1" = "-n" ] && DRY_RUN=1

# ==================================================
# Config
ruby_version='1.9.3-p327'
gems=(bundler)
rbenv_user=rbenv
rbenv_group=rbenv

# ==================================================
# Helpers

COLUMNS=${COLUMNS-80}
CLOSE_STEP=
SKIP_STEP=
SKIP_RUN=
SKIP_THIS_RUN=

function line() {
  printf "%0${COLUMNS}d\n" 0 | sed 's/./-/g'
}
function fold_lines() {
  fold -s -w "${COLUMNS}"
}
function wrap_lines() {
  fold_lines | sed "s/.*/${1}&${2}/"
}

function close_step() {
  line | sed 's/^./\`/'
  echo
}
function step() {
  if [ -n "$CLOSE_STEP" ]; then
    close_step
  else
    trap 'close_step' EXIT
  fi

  SKIP_RUN="$SKIP_STEP"
  line | sed 's/^./\//'
  if [ -n "$SKIP_STEP" ]; then
    echo '| [033mSkipped[0m'
  fi
  echo "$*" | wrap_lines '| [032m' '[0m'
  SKIP_STEP=
  CLOSE_STEP=1
}
function xstep() {
  SKIP_STEP=1
  step "$@"
}

function run() {
  echo "$*" | wrap_lines '[036;1m$[0m ' | sed '2,$s/\$/>  /'
  if [ -z "$DRY_RUN" -a -z "$SKIP_RUN" -a -z "$SKIP_THIS_RUN" ]; then
    eval "$*" || exit
  fi
}
function xrun() {
  SKIP_THIS_RUN=1
  run "$@"
  SKIP_THIS_RUN=
}
function info() {
  echo "$*" | wrap_lines '[036;1m*[0m '
}

function cat_error() {
  cat | wrap_lines '[031;1m>>> ' '[0m' >&3
}
exec 3>&2
exec 2> >(cat_error)

[ "$UID" = "0" ] || {
  echo "Require root privilege to bootstrap" >&2
  exit 1
}

mkdir -p tmp


step '== NOTICE =='
info 'After installation, ' \
  ' please append content of tmp/rbenv-profile.sh to your bashrc or zshrc.' \
  ' Also comment out `[ -z "$PS1" ] && return` in .bashrc'

info "Add your self to group $rbenv_group so that you can manage rbenv"
info sudo gpasswd -a my_login_id "$rbenv_group"

step "Create user ${rbenv_user}:${rbenv_group}"
run groupadd -f "$rbenv_group"
if ! id "$rbenv_user" &> /dev/null; then
  run useradd -r -d /usr/local/rbenv -g "$rbenv_group" -M "$rbenv_user"
fi

step "Install nessesary packages"
run apt-get update
run aptitude install -y \
  openssh-server openjdk-6-jdk \
  build-essential zlib1g-dev \
  libssl-dev openssl \
  libreadline-dev \
  sqlite3 libsqlite3-dev \
  libxslt-dev libxml2-dev \
  curl wget git-core \
  mysql-client libmysqlclient-dev

step "Install/Upgrade rbenv in /usr/local/rbenv"
if [ -d /usr/local/rbenv ]; then
  info 'install rbenv'
  run pushd /usr/local/rbenv
  run git pull
  run popd
else
  info 'upgrade rbenv'
  run git clone git://github.com/sstephenson/rbenv.git /usr/local/rbenv
fi
info 'generate profile file'
echo 'export RBENV_ROOT=/usr/local/rbenv' > tmp/rbenv-profile.sh
echo 'export PATH="$PATH:$RBENV_ROOT/bin"' >> tmp/rbenv-profile.sh
echo 'eval "$(rbenv init -)"' >> tmp/rbenv-profile.sh
info '== begin of rbenv-profile.sh =='
cat tmp/rbenv-profile.sh
info '== end of rbenv-profile.sh =='
if [ -d /usr/local/rbenv ]; then
  info source tmp/rbenv-profile.sh
  source tmp/rbenv-profile.sh || true
fi
run cp -f tmp/rbenv-profile.sh /etc/profile.d
if ! grep 'rbenv init' /etc/skel/.bashrc &> /dev/null; then
  run 'sed -i "1asource /etc/profile.d/rbenv-profile.sh" /etc/skel/.bashrc'
fi
run 'touch "/root/.bashrc"'
if ! grep 'rbenv init' "/root/.bashrc" &> /dev/null; then
  run 'sed -i "1asource /etc/profile.d/rbenv-profile.sh" /root/.bashrc'
fi
run 'touch "/root/.zshenv"'
if ! grep 'rbenv init' "/root/.zshenv" &> /dev/null; then
  run 'cat tmp/rbenv-profile.sh >> "/root/.zshenv"'
fi

step "Install/Upgrade rbenv-vars in /usr/local/rbenv/plugins/rbenv-vars"
if [ -d /usr/local/rbenv/plugins/rbenv-vars ]; then
  info 'install rbenv-vars'
  pushd /usr/local/rbenv/plugins/rbenv-vars
  run git pull
  popd
else
  info 'upgrade rbenv-vars'
  run mkdir -p /usr/local/rbenv/plugins/
  run git clone git://github.com/sstephenson/rbenv-vars.git /usr/local/rbenv/plugins/rbenv-vars
fi

step "Install/Upgrade ruby-build in /usr/local/rbenv/plugins/ruby-build"
if [ -d /usr/local/rbenv/plugins/ruby-build ]; then
  info 'install ruby-build'
  pushd /usr/local/rbenv/plugins/ruby-build
  run git pull
  popd
else
  info 'upgrade ruby-build'
  run mkdir -p /usr/local/rbenv/plugins/
  run git clone git://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build
fi

step "Install ruby $ruby_version"
if [ -f "/usr/local/rbenv/versions/$ruby_version/bin/ruby" ]; then
  info "ruby $ruby_version is already installed"
else
  info 'installation may take a long time, restart bootstrap if failed.'
  run rbenv install "$ruby_version" # --with-openssl-dir=/usr/local
  run rbenv rehash
fi
run rbenv global "$ruby_version"
info `ruby -v 2>&1`

step "Setup gems ${gems[*]}"
test -s ~/.gemrc || echo 'gem: --no-rdoc --no-ri' >> ~/.gemrc
run gem install "${gems[@]}"
run rbenv rehash

step "Setup permission of /usr/local/rbenv"
run chown -R "$rbenv_user:$rbenv_group" /usr/local/rbenv
run chmod -R u=rwX,g=rwX,o=rX /usr/local/rbenv
run 'find /usr/local/rbenv -type d -exec chmod g+s "{}" \;'
