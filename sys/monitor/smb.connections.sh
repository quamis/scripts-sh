#!/bin/bash

smbstatus --shares | tail -n +4 | wc -l;

