#!/bin/bash

grep -lrIZ "exceeded for this endpoint" ./cache/ | xargs -0 rm -f --