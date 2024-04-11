#!/bin/bash
pgrep wofi >/dev/null 2>&1 && killall wofi || wofi --show drun