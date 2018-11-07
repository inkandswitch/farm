#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/_includes.sh"

usage() {
	cat <<- EOF

		Usage:

		  $0 <name>

		    Installs the '@types/<name>' package or creates a
		    declaration file if it doesn't exist.

	EOF
}

types() {
	install_types "$@" || create_stub "$@"
}

install_types() {
	require "name" $1

	yarn add --dev @types/$name &>/dev/null \
		&& show "Installed '@types/$name'." \
		|| (echo "Package '@types/$1' not found..." && return 1)
}

create_stub() {
	require "name" $1
	module="${name%%/*}"

	path="./src/node_modules/@types/$module"
	index="$path/index.d.ts"

	if [ -f $index ]; then
		show "Found $index"
		return 0
	fi

	mkdir -p $path
	cat <<- EOF > $index
		declare module "$name"
	EOF

	show "Created '$name' module at $index"
}

types "$@"
