#!/usr/bin/env bash

whoami
source ~/.bashrc
source ~/.profile
wget https://cdn.jsdelivr.net/npm/bootstrap@5/dist/css/bootstrap.min.css -O $(bundle info --path jekyll-theme-chirpy)/_sass/dist/bootstrap.css
JEKYLL_ENV=production bundle exec jekyll build
