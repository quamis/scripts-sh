#!/bin/bash

wget http://localhost/server-status?view=auto -qO- | grep ConnsTotal | sed "s/ConnsTotal: //";

