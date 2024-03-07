#!/bin/bash

time matlab -nodisplay -r 'process_dataset; quit' | tee output.log