#!/usr/bin/env bash

source ~/.bashrc
#bundle exec jekyll serve -H 0.0.0.0 --destination _site_dev/ --drafts
bundle exec jekyll build -w --destination _site_dev/ --drafts
