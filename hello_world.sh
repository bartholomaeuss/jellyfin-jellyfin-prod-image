#!/bin/bash

show_help(){
    echo "usage: $0 [-n] [-h]"
    echo "  -n  your name"
    echo "  -h  show help"
    exit 0
}

main(){
  echo "Nice job $name, this seems to work!"
  exit 0
}

while getopts ":n:h" opt; do
  case $opt in
    n)
      name="$OPTARG"
      main
      ;;
    h)
      show_help
      ;;
    \?)
      echo "unknown option: -$OPTARG" >&2
      show_help
      ;;
    :)
      echo "option requires an argument -$OPTARG." >&2
      show_help
      ;;
  esac
done

if [ "$#" -le 0 ]
then
  echo "script requires an option"
  show_help
fi