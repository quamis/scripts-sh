#!/bin/bash

sensors | grep "Core 0" | sed -r "s/Core 0:[ ]+\+//" | sed -r "s/°C.+//";

