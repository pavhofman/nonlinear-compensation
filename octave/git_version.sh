#!/bin/bash

DIRNAME=$(dirname "$0")
cd $DIRNAME

# revision info
git log -1

# status
git status