# bashy-langs.sh - language loading for bashlikes
#
# This file, called as part of bashrc/bashyrc, does path and env setup for languages
# which have development environments that aren't part of the "main" system paths.

# Call uname once and stash results for performance
if [[ -z $__uname ]]; then
  __uname=$(uname)
fi


# Ruby Environment

# Ruby needs a few things:
#   * Add Gems bin to path.
#   * Set Gems GEM_* env vars (for gem install locations).
#   * Load RVM.
#   * Maybe others?

# TODO: Figure out a better way to handle this Ruby versioning stuff!
# I am currently using Ruby on both Mac and Linux. On Mac, I install it with
# either MacPorts or Homebrew. On Linux, I use the distro Ruby/bundler packages.
# (I don't really know how Ruby Gems path management is supposed to work.)
# (Maybe I should be using rvm instead?)
#
# Besides the stuff here, there's also MacPorts-managed Ruby/gem/bundler, but that
# should be handled by the MacPorts path management stuff. I think.

# Set GEM_* variables so it defaults to user instead of system installs, which is needed
# for systems with locked-down permissions, like MacPorts-managed macOS and some Linux
# setups. And I want to default to user-scoped Gem installs anyway.
#
# TODO: Also, you're not supposed to set GEM_HOME or GEM_PATH manually when using RVM.
# Dunno if the later call to RVM will override the.

# if [[ -z $GEM_HOME ]]; then
#   if [[ -d "$HOME/.gem" ]]; then
#     export GEM_HOME="$HOME/.gem"
#     # TODO: Is this actually necessary?
#     export GEM_PATH="${HOME}/.gem"
#   fi
# fi

# This is disabled because as of 2023-01-17 I think it's wrong; it sticks the
# version-specific system-managed Gem stuff on the path ahead of the MacPorts unversioned
# stuff, or something like that? -apj
#
# for MY_RUBY_VER in 2.6.0 2.7.0 3.0.0 3.1.0 3.2.0 3.3.0; do
#   # Pull in system Ruby Gems
#   jx_maybe_add_path "/usr/local/lib/ruby/gems/${MY_RUBY_VER}/bin" prepend
#   # Add version-specific user Ruby Gems binary path
#   jx_maybe_add_path "$HOME/.gem/ruby/${MY_RUBY_VER}/bin" prepend
# done

# Load a requested Ruby env mgr
function jx-rbenvmgr-load () {
  local envmgr my_shell
  envmgr="$1"
  be_quiet="$2"

  if [[ $envmgr == rbenv ]]; then
    if which rbenv &>/dev/null; then
      if [[ -n "$ZSH_VERSION" ]]; then my_shell="zsh"; else my_shell="bash"; fi
      eval "$(rbenv init - $my_shell)"
    else
      if [[ $be_quiet != quiet ]]; then
        echo >&2 "rbenv not found on path; not loaded"
      fi
    fi
  elif [[ $envmgr == rvm ]]; then
    if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
      source "$HOME/.rvm/scripts/rvm"
    else
      if [[ $be_quiet != quiet ]]; then
        echo >&2 "rvm not found under ~/.rvm; not loaded"
      fi
    fi
  elif [[ $envmgr == none || $envmgr == '' ]]; then
    :
  else
    if [[ $be_quiet != quiet ]]; then
      echo >&2 "ERROR: unrecognized ruby envmgr: ${envmgr}"
    fi
  fi
}

if [[ -n $JX_RUBY_AUTOLOAD_ENVMGR ]]; then
  jx-rbenvmgr-load "$JX_RUBY_AUTOLOAD_ENVMGR" quiet
fi


# Anaconda and Python

function jx-conda-load () {
  # "Load" conda, adding it to the path, but not activating its base env.
  #
  # Call regular `conda activate` afternward to actually activate it.
  # This supports both Anaconda and Mamba installations.
  # If no conda installation is found, does not load anything, and silently succeeds.

  local -a conda_prefix_cands
  local -a conda_impl_cands
  local conda_prefix conda_impl conda_path conda_path_cand conda_setup_code my_shell
  conda_prefix_cands=("${HOME}" '/opt/pythons' '/opt' '/usr/local')
  conda_impl_cands=('miniforge3' 'miniforge' 'anaconda3' 'anaconda')

  if [[ -n "$ZSH_VERSION" ]]; then my_shell="zsh"; else my_shell="bash"; fi
 
  for conda_prefix in "${conda_prefix_cands[@]}"; do
    for conda_impl in "${conda_impl_cands[@]}"; do
      conda_path_cand="${conda_prefix}/${conda_impl}"
      # echo "Checking for conda at ${conda_path_cand}"
      if [[ -f "${conda_path_cand}/bin/conda" ]]; then
        # echo "Found ${conda_path_cand}/bin/conda"
        conda_path="$conda_path_cand"
        conda_setup_code="$('${conda_path}/bin/conda' "shell.${my_shell}" 'hook' 2> /dev/null)"
        if [[ $? = 0 ]]; then
          eval "$conda_setup_code"
        else
          if [[ -f "${conda_path}/etc/profile.d/conda.sh" ]]; then
            source "${conda_path}/etc/profile.d/conda.sh"
          else
            PATH="${conda_path}/bin:$PATH"
          fi
        fi
        if [[ -f "${conda_path}/etc/profile.d/mamba.sh" ]]; then
          source "${conda_path}/etc/profile.d/mamba.sh"
        fi

        # echo "Loaded conda from ${conda_path} for shell ${my_shell}"
        break
      fi
    done
    if [[ -n "$conda_path" ]]; then
      break
    fi
  done
}

if [[ $JX_CONDA_AUTOLOAD = 1 ]]; then
  jx-conda-load
  if [[ $JX_CONDA_AUTOACTIVATE = 1 ]]; then
    conda activate
  fi
fi

# Node, NVM, npm, and JavaScript

# Load NVM in to this shell session
#
# NVM initialization is too slow for me to want it on every shell startup, so stick it
# inside a function I'll call manually when I want NVM.
#
# TODO: Support alternate NVM installation locations, probably including detecting from
# path or some `nvm --root` query.
function jx-nvm-load() {
  local -a nvm_locn_cands
  local cand found verbose=0

  #TODO: Maybe adapt NVM's official instructions (from https://github.com/nvm-sh/nvm):
  # export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  # [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
  #   or
  # [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use # This loads nvm, without auto-using the default version

  if [[ "$1" == '-v' ]]; then
    verbose=1
  fi
  # TODO: only check Homebrew and MacPorts locations if they're loaded, respectively?
  nvm_locn_cands=(
    # User-local installation (NVM's own recommended installation approach)
    # This is ~/.nvm if you're following NVM's recommendations
    "$NVM_DIR"
    # Homebrew (Intel)
    /usr/local/opt/nvm
    # Homebrew (As)
    /opt/homebrew/nvm
    # MacPorts - disabled bc I don't use it lately
    # /opt/local/share/nvm
  )
  for cand in "${nvm_locn_cands[@]}"; do
    if [[ -s "${cand}/nvm.sh" ]]; then
      found="${cand}"
      break
    fi
  done
  if [[ -n "$found" ]]; then
    source "${found}/nvm.sh"
    if [[ "$verbose" == 1 ]]; then
      echo >&2 "Loaded NVM from ${found}"
    fi
  else
    echo >&2 "No NVM installation found"
  fi
}

if [[ $JX_NVM_AUTOLOAD = 1 ]]; then
  jx-nvm-load
fi

# MacOS specifics

if [[ $__uname = "Darwin" ]]; then

  # Matlab

  function jx-locate-matlab-on-mac() {
    # Locate Matlab dynamically and add to PATH

    # TODO: Accept the version as an argument, and add a variable to control whether this
    # gets called automatically.
    # TODO: Add Linux support.
    if ! which matlab &> /dev/null; then
      # Prefer newer versions
      want_matlab_rels=(R2025a R2024b R2024a R2023b R2023a R2022b R2022a R2021b R2021a R2020b R2020a R2019b R2019a R2018b R2018a R2017b R2017a)
      for matlab_rel in "${want_matlab_rels[@]}"; do
        matlab_app="/Applications/MATLAB_${matlab_rel}.app"
        if [[ -f "$matlab_app/bin/matlab" ]]; then
          PATH="$PATH:$matlab_app/bin"
          break
        fi
      done
      unset want_matlab_rels
    fi
  }
  jx-locate-matlab-on-mac

fi # end MacOS specifics
