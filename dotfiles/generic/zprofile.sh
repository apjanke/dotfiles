
# MacPorts

function () {
  local bindir
  local -a bindirs
  # In reverse order of addition
  bindirs=(
    '/opt/local/sbin'
    '/opt/local/bin'
  )
  for bindir in $bindirs; do
    if [[ -d "$bindir" ]]; then
      PATH="${bindir}:$PATH"  
    fi
  done
}

