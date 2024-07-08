#!/bin/bash

sensors -j 2>/dev/null  | jq '."thinkpad-isa-0000"."fan1"."fan1_input"'
