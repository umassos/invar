#!/usr/bin/env bash
for input_file in ../analysis/results/*_knitro1.yml; do
  echo $input_file
  for ((i = 0; i < 400; i++)); do
    echo $i
    poetry run python src/main.py $input_file $i >> $(basename "$input_file" .yml).txt
  done
done
