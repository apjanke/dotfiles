#!/bin/bash
#
# Sets up this user's iTerm2 settings

system_profiler SPDisplaysDataType | grep "Retina: Yes" &>/dev/null
if [[ $? == 0 ]]
  IS_RETINA=1
else
  IS_RETINA=0
fi


# TODO: Figure out how to get it to read its prefs from a directory