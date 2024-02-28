#!/bin/bash

time matlab -nodisplay -r 'generate_dataset; quit' | tee output.log