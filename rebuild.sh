#!/usr/bin/env bash

whoami
source ~/.bashrc
source ~/.profile
JEKYLL_ENV=production bundle exec jekyll build
