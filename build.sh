#!/usr/bin/env bash

docker build --no-cache \
  -t "rubensa/ubuntu-tini-x11:18.04" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .
