#!/bin/zsh
# Runs the in-app self-test against a fresh store in /tmp. Exit code 0 when every check passed.
set -u
rm -rf ~/Library/Saved\ Application\ State/com.apresley.virtualkeysplease.savedState
store=/tmp/VirtualKeysPlease-self.store
rm -f $store $store-shm $store-wal
APP_STORE=$store ~/Applications/VirtualKeysPlease.app/Contents/MacOS/VirtualKeysPlease --selftest
