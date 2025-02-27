#!/bin/bash

time matlab -nodisplay -r 'generate_dataset_gael; quit' | tee output.log