#!/bin/bash
function terminate() {
  echo "Caught SIGTERM signal!"
  kill -TERM $PID1 2>/dev/null
  sleep 0.5s
  kill -TERM $PID2 2>/dev/null
  sleep 0.5s
  kill -TERM $PID3 2>/dev/null
  exit
}

function startScript() {
  NAME=$1
  LOG_NAME=$2
  octave $NAME > ../log/$LOG_NAME.log 2>&1 &
  return $!
}

trap terminate TERM INT

DIRNAME=$(dirname "$0")


cd $DIRNAME/../
mkdir -p log

# deleting outdated main_dev_id files
rm -f data_comm/*

cd octave

startScript mainCtrl.m ctrl
PID3=$!
# mainCtrl does not use playrec, no need to delay next process startup

startScript mainPlay.m play
PID1=$!
# delay to avoid possible deadlock in playrec if two processes (mainPlay, mainRec) open it concurrently
sleep 0.5s

startScript mainRec.m rec
PID2=$!


while true; do
  PIDS=$(jobs -p)
  if [ -z "$PIDS" ]; then
    # should not happen
    echo "all processes finished, exiting"
    exit
  fi

  wait -n
  if ! kill -0 $PID1 2> /dev/null ; then
    echo "mainPlay quit, restarting"
    startScript mainPlay.m play
    PID1=$!
  fi

  if ! kill -0 $PID2 2> /dev/null ; then
    echo "mainRec quit, restarting"
    startScript mainRec.m rec
    PID2=$!
  fi

  if ! kill -0 $PID3 2> /dev/null ; then
    echo "mainCtrl quit, restarting"
    startScript mainCtrl.m ctrl
    PID3=$!
  fi
  # to avoid clogging CPU in case some of the processes does not start
  sleep 0.5s
done

trap - TERM INT
wait
exit $?