#!/bin/bash

for unit in systemd/*; do
    systemctl --user link $unit;
done
