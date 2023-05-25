#! /bin/sh

vessel bin
vessel install
reprotest  -vv --variations '+all, -domain_host, -locales' 'bash build/build.sh && ls -la ./build/outputs' 'build/outputs/*.wasm'


# "+environment, +build_path, +kernel, +aslr, +num_cpus, +time, +user_group, +fileordering, +domain_host, +home, +locales, +exec_path, +timezone, +umask"