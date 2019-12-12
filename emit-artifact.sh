#!/bin/bash

# install pixz for parallel xz
apt-get update
apt-get install -yqq pixz
# compress /opt/trailofbits/libraries and emit it to $1
tar -Ipixz -cf "${1}" libraries -C /opt/trailofbits/
