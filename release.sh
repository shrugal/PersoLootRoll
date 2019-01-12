#!/bin/bash

if [ -f ".release/.env" ]; then
	source ".release/.env"
fi

.release/release.sh -p $CF_ID -w $WOWI_ID "$@"