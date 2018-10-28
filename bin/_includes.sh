#!/usr/bin/env bash

show() {
	printf "\n$@\n\n"
}

require() {
	[[ -z "$2" ]] && usage && show "Argument <$1> is required." && exit 1
	eval "$1=$2"
}
