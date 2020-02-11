rm -r test
mkdir test

for n in {1..10000}; do
  name="test/file$( printf %03d "$n" ).html"

  { printf "<div>"; printf "$RANDOM"; printf "</div>"; } > $name
done
