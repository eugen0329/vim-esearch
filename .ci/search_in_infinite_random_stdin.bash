util=$1
arguments=${@:2}

cat /dev/urandom | $util $arguments
