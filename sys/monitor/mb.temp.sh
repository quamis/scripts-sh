#!/bin/bash

sensors -j 2>/dev/null  | jq '."thinkpad-isa-0000"."CPU"."temp1_input"'