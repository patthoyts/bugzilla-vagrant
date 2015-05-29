#!/bin/sh
# Halt and disable puppet
service stop puppet
update-rc.d puppet disable
