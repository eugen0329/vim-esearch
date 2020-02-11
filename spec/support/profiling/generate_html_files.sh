#!/bin/bash

rm -r data
mkdir data

for n in {1..1000}; do
  name="data/file$( printf %03d "$n" ).html"

  { printf "<div>"; printf "%d" "$RANDOM"; printf "</div>"; } > "$name"
done
