#!/bin/bash
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null
echo -e 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.asc' | tee /etc/apt/sources.list.d/sublime-text.sources
apt-get update
apt-get install -y sublime-text
