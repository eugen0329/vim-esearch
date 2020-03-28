#!/bin/sh

vimlint="$1"
vimlparser="$2"
shift 2
directories=$*

# VIMLINT_IGNORE_JOB_CONTROL_WARNINGS are ignored.  TODO figure out why,
# until that VIMLINT_WARNING_UNUSED_ARGUMENTS_AND_VARIABLES_WORKAROUND
# will be used. Seems, similar problem happens with
# VIMLINT_IGNORE_UNDERSCORED_VARIABLE_NAME

# vimlint_ignore_job_control_warnings='-e EVL103.a:channel=1 -e EVL103.a:event=1 -e EVL103.a:job=1 -e EVL103.a:pty=1 -e EVL103.a:timer=1'
# vimlint_ignore_underscored_variable_name='-e EVL102.l:_=1'

vimlint_warning_unused_arguments_and_variables_workaround='-e EVL103=3'
todo_vimlint_warning_unused_local_variables='-e EVL102=3'
todo_vimlint_warning_scipt_encodings='-e EVL205=3'

command=$(cat <<EOF
sh "$vimlint/bin/vimlint.sh" -l "$vimlint" -p "$vimlparser"
  $vimlint_warning_unused_arguments_and_variables_workaround
  $todo_vimlint_warning_unused_local_variables
  $todo_vimlint_warning_scipt_encodings
  $directories
EOF
)
# shellcheck disable=SC2086
output=$(eval $command)
status=$?
printf "%s\n" "$output"

[ $status -eq 0 ] && exit 0 # if no errors or warnings
printf "%s\n" "$output" | grep --color ":Error:" && exit 1 # Allow warnings but not errors
exit 0
