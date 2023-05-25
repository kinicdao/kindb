#! /bin/sh

reprotest -vv --variations '+all, -domain_host' '/project_root/build/build.sh' 'build/outputs/*.wasm'