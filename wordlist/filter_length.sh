#!/bin/sh
awk 'length($0)>10' ${1}
