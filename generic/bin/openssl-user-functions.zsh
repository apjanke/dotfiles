# shell functions for use while hacking on the OpenSSL documentation
# author: Andrew Janke <floss@apjanke.net>

# I'm using these on zsh but trying to keep them relatively portable

function compare-word-counts() {
  local word grep_flags
  grep_i="-i"
  if [[ "$1" == "-I" ]]; then
  	grep_i=""
  	shift 1
  fi
  for word ($*); do 
    echo -n "$word:"
    grep $grep_i "$word" $(find . -name '*.pod') | wc -l
  done 
}

function pod-unwrap-lines() {
  local file=$1;
  cat $file | sed -E -e 'H;1h;$!d;x; s/([^[:space:].!?]) *\n([[:alnum:]])/\1 \2/g' > $file.unfolded
  echo "Unfolded to $file.unfolded"
}


function pod-view-as-man-page() {
  local podfile=$1
  if [[ ! -e $podfile ]]; then
    podfile="$podfile.pod"
  fi
  if [[ ! -e $podfile ]]; then
    echo >&2 "error: no such file: $1 or $podfile"
    return 1
  fi

  echo "doing $podfile"

  local topic=${podfile/.*/}
  topic=${topic:t}
  local VERSION=1.1.0-dev
  local tempfile=$TMPDIR/$topic.XXXXX
  pod2man --center=OpenSSL \
      --release="OpenSSL $VERSION" $podfile $tempfile
  man $tempfile
  rm $tempfile
}
