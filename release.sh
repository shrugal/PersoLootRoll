#!/bin/bash

if [ -f ".release/.env" ]; then
	source ".release/.env"
fi

tag=$(git describe --tags)
if [[ -z "$tag" || ! ( "$tag" =~ ^v?[0-9][0-9.]*$ || "${tag,,}" == *"stable"* ) ]]; then
	WOWI_ID=$WOWI_ID_BETA
fi

.release/release.sh -p $CF_ID -w $WOWI_ID "$@"