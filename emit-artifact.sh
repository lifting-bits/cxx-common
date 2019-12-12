#!/bin/bash

# install pixz then
# compress /opt/trailofbits/libraries and emit it to $1

apt-get update
apt-get install -yqq pixz
tar -Ipixz -cf "${1}" /opt/trailofbits/libraries -C /opt/trailofbits
