#!/usr/bin/env bash

# Read build options from /usr/share/defaults/eopkg/eopkg.conf and replace
# replace '-mtune=generic -march=x86-64' with '-march=native'

cflags="$(cat /usr/share/defaults/eopkg/eopkg.conf | grep "cflags = ")"
cflags="$(echo $cflags | sed "s/-mtune=generic -march=x86-64/-march=native/g")"

cxxflags="$(cat /usr/share/defaults/eopkg/eopkg.conf | grep "cxxflags = ")"
cxxflags="$(echo $cxxflags | sed "s/-mtune=generic -march=x86-64/-march=native/g")"

cat <<EOF
Insert the following into /etc/eopkg/eopkg.conf:

[build]
$cflags
$cxxflags
EOF
