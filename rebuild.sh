#!/usr/bin/env bash

whoami
source ~/.bashrc
JEKYLL_ENV=production bundle exec jekyll build
