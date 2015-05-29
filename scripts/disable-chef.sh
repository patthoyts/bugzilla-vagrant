#!/bin/sh
# Halt and disable chef
service stop chef-client
update-rc.d chef-client disable
