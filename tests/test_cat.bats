#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031
# above is to avoid shellcheck info warnings that we don't understand

load _test_base

FILE_TO_HIDE="$TEST_DEFAULT_FILENAME"
FILE_CONTENTS="hidden content юникод"

FINGERPRINT=""


function setup {
  FINGERPRINT=$(install_fixture_full_key "$TEST_DEFAULT_USER")

  set_state_initial
  set_state_git
  set_state_secret_init
  set_state_secret_tell "$TEST_DEFAULT_USER"
  set_state_secret_add "$FILE_TO_HIDE" "$FILE_CONTENTS"
  set_state_secret_hide
}


function teardown {
  uninstall_fixture_full_key "$TEST_DEFAULT_USER" "$FINGERPRINT"
  unset_current_state
}


@test "run 'cat' with password argument" {
  local password
  password=$(test_user_password "$TEST_DEFAULT_USER")
  run git secret cat -d "$TEST_GPG_HOMEDIR" -p "$password" "$FILE_TO_HIDE"

  [ "$status" -eq 0 ]

  # $output is the output from 'git secret cat' above
  [ "$FILE_CONTENTS" == "$output" ]
}


@test "run 'cat' with password argument and SECRETS_VERBOSE=1" {
  local password
  password=$(test_user_password "$TEST_DEFAULT_USER")
  SECRETS_VERBOSE=1 run git secret cat -d "$TEST_GPG_HOMEDIR" -p "$password" "$FILE_TO_HIDE"

  [ "$status" -eq 0 ]

  # $output _contains_ the output from 'git secret cat',
  # may have extra output from gpg
  [[ "$output" == *"$FILE_CONTENTS"* ]]
}


@test "run 'cat' with wrong filename" {
  run git secret cat -d "$TEST_GPG_HOMEDIR" -p "$password" NO_SUCH_FILE
  [ "$status" -eq 1 ]
}


@test "run 'cat' with bad arg" {
  local password
  password=$(test_user_password "$TEST_DEFAULT_USER")
  run git secret cat -Z -d "$TEST_GPG_HOMEDIR" -p "$password" "$FILE_TO_HIDE"
  [ "$status" -ne 0 ]
}

@test "run 'cat' from subdir" {
  local password
  password=$(test_user_password "$TEST_DEFAULT_USER")

  mkdir subdir
  echo "content2" > subdir/new_filename.txt

  ( # start subshell for subdir tests
    cd subdir
    run git secret add new_filename.txt
    [ "$status" -eq 0 ]
    run git secret hide
    [ "$status" -eq 0 ]

    run git secret cat -d "$TEST_GPG_HOMEDIR" -p "$password" new_filename.txt
    [ "$status" -eq 0 ]
  ) # end subshell, cd back up

  # clean up
  rm -rf subdir
}
