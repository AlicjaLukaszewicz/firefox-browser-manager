#!bin/bash

# Author           : Alicja Łukaszewicz 188562
# Created On       : 01.06.2022
# Last Modified By : Alicja Łukaszewicz 188562
# Last Modified On : 12.05.2022
# Version          : 1.0
#
# Description      : Program for managing browser deletion option and phrase search.
#                    User can choose "match case" and "match entire word only" is phrase search.
#                    In history deletion user can choose between deleting all history and specifying time.
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

VERSION="1.0"
INPUT=""       # stores the most recent input
RETURN_VALUE=1 # stores the return value of the most recent function call
REQUIRED_PACKAGES=("zenity" "sqlite3")
FIREFOX=$(dirname $(find $HOME/.mozilla -name "places.sqlite" -print)) # path to the folder which contains firefox databases
FIREFOX_HISTORY_DB="${FIREFOX}/places.sqlite"
FIREFOX_COOKIES_DB="${FIREFOX}/cookies.sqlite"

is_package_installed() {
  PACKAGE="$1"

  CHECK="$(command -v "${PACKAGE}" >/dev/null 2>&1)"
  if [[ "${CHECK}" != 0 ]]; then
    RETURN_VALUE=0
  else
    RETURN_VALUE=1
  fi
}

install_package() {
  PACKAGE="$1"
  is_package_installed "${PACKAGE}"
  if [[ $RETURN_VALUE == 0 ]]; then
    echo "${PACKAGE} is already installed."
    RETURN_VALUE=0
  else
    if command -v apt-get >/dev/null 2>&1; then    # If apt-get exists (Debian, Ubuntu, etc.)
      sudo apt-get install -y "${PACKAGE}"
    elif command -v yum >/dev/null 2>&1; then      # If yum exists (CentOS, Fedora, etc.)
      sudo yum install -y "${PACKAGE}"
    elif command -v pacman >/dev/null 2>&1; then   # If pacman exists (Arch Linux)
      sudo pacman -S --noconfirm "${PACKAGE}"
    elif command -v zypper >/dev/null 2>&1; then   # If zypper exists (openSUSE)
      sudo zypper -n install "${PACKAGE}"
    else
      echo "Could not determine package manager. Please install ${PACKAGE} manually."
      return 1
    fi

    if is_package_installed "${PACKAGE}"; then
      RETURN_VALUE=0
    else
      RETURN_VALUE=1
    fi
  fi
}

function close_browser_if_open() {
  IS_FIREFOX_RUNNING="N"
  pgrep -u $USER firefox >/dev/null

  if [ $? -eq 0 ]; then
    IS_FIREFOX_RUNNING="Y"
    zenity --question --text="You can not run the program with an open browser. Do you want to close Firefox?" --ok-label="Close browser" --cancel-label="Exit program" --height 200 --width 240
    if [[ $? == 0 ]]; then
      FPID=$(pgrep -u "$USER" firefox)
      FPID=$(echo "$FPID" | cut -d" " -f1)
      kill -1 "$FPID"
      IS_FIREFOX_RUNNING="N"
    else
      exit
    fi
  fi
}

function install_required_packages {
  for PACKAGE in "${REQUIRED_PACKAGES[@]}"; do
    install_package "${PACKAGE}"
    if [[ $RETURN_VALUE == 0 ]]; then
      echo "Successfully installed required package: ${PACKAGE}"
      RETURN_VALUE=0
    else
      echo "Could not install required package: ${PACKAGE}"
      RETURN_VALUE=1
    fi
  done
}

# functions responsible for displaying information about program in terminal
function print_version_info {
  echo "Firefox_history-Manager v${VERSION}"
  echo "Author: Alicja Łukaszewicz 188562"
}

function print_author_info {
  echo "Author: Alicja Łukaszewicz 188562"
}

function print_help {
  echo "Commandline options:"
  echo "-v, --version      Displays version and author information."
  echo "-h, --help         Displays help on commandline options."
  echo "-a, --author       Displays author information."
  echo "--display-history  Displays current browser history."
  echo "--display-cookies  Displays current browser cookies."
  echo "--display-all      Displays both history and cookies."
}

function print_current_browser_history {
  close_browser_if_open
  sleep 1
  # last visit of the page is in the UNIX EPOCH format
  # adding 2 hours -> changing GMT time to CEST
  # displaying: [year-month-day hours:minutes:seconds] + title
  echo "Current Firefox History"
  sqlite3 "${FIREFOX_HISTORY_DB}" "SELECT datetime(moz_historyvisits.visit_date/1000000, 'unixepoch', '+2 hours'), moz_places.title FROM moz_places, moz_historyvisits WHERE moz_places.id = moz_historyvisits.place_id AND moz_places.title IS NOT NULL;"
}

function print_current_cookies {
  close_browser_if_open
  sleep 1
  echo "Current Firefox Cookies"
  sqlite3 "${FIREFOX_COOKIES_DB}" "SELECT datetime(creationTime,'unixepoch', '+2 hours'),host from moz_cookies;"
}

function print_current_browser_history_and_cookies {
  print_current_browser_history
  print_current_cookies
}

#functions responsible for managing browser history and cookies deletion
function select_history_deletion_options() {
  # lets user choose between deleting all history or just a portion of it
  get_current_date

  zenity --question --text="Select a range of history to be deleted" --ok-label="ALL" --cancel-label="Different" --height 200 --width 240
  if [ $? == 0 ]; then
    update_date_to_default
  else
    select_period_of_time
    update_date_based_on_user_input
  fi
}

function select_period_of_time {
  YEARS=$(zenity --scale --text="Years: " --value=0 --min-value=0 --step=1)
  MONTHS=$(zenity --scale --text="Months: " --value=0 --min-value=0 --max-value=12 --step=1)
  DAYS=$(zenity --scale --text="Days: " --value=0 --min-value=0 --max-value=31 --step=1)
}

function update_date_based_on_user_input {
  YEARS=$((YEARS * 31556926))  # 1 year = 31556926 seconds
  MONTHS=$((MONTHS * 2629743)) # 1 month = 2629743 seconds
  DAYS=$((DAYS * 86400))       # 1 day = 86400 seconds
  DATE=$((CURRENT_DATE - YEARS - MONTHS - DAYS))
}

function get_current_date {
  CURRENT_DATE=$(date +%s)
  CURRENT_DATE=$((CURRENT_DATE))
}

function update_date_to_default {
  DATE="0000000000"
}

function delete_history {
  # deletes history from given time period
  select_history_deletion_options
  sqlite3 "${FIREFOX_HISTORY_DB}" "DELETE FROM moz_places WHERE last_visit_date BETWEEN $DATE AND $CURRENT_DATE"
  sqlite3 "${FIREFOX_HISTORY_DB}" "DELETE FROM moz_historyvisits WHERE visit_date/1000000 BETWEEN $DATE AND $CURRENT_DATE"
  zenity --info --text="The program will now close to apply changes" --ok-label="OK" --width=600
  exit # for program to register change in database it needs to be closed, after restarting changes will be saved
}

function delete_cookies {
  # deletes ALL cookies from the browser
  echo "Deleting Firefox Cookies"
  sqlite3 "${FIREFOX_COOKIES_DB}" "select datetime(creationTime/1000000,'unixepoch'),host from moz_cookies; delete from moz_cookies;"
  zenity --info --text="The program will now close to apply changes" --ok-label="OK" --width=600
  exit # for program to register change in database it needs to be closed, after restarting changes will be saved
}

#functions responsible for managing user phrase search in history
function display_search_menu {
  # lets user choose search option
  MATCH_CASE="NO"             # will search with case sensitivity "cat" != "Cat"
  MATCH_ENTIRE_WORD_ONLY="NO" # will search only the entire world, will not output result "catastrophe" in "cat" search

  PHRASE=""

  select_search_options
  update_search_options

  if [ "$PHRASE" = "" ]; then
    zenity --error \
      --text="There was no phrase entered. Please try again" \
      --height 100 --width 150
  else
    search_phrase
  fi
}

function select_search_options {
  OUTPUT=$(zenity --forms --title="Find" \
    --text="Pick options" \
    --separator="," \
    --add-entry="Phrase" \
    --add-combo="Match case" \
    --combo-values="YES|NO" \
    --add-combo="Match entire word only" \
    --combo-values="YES|NO")
}

function update_search_options {
  update_phrase
  update_match_case
  update_match_entire_word_only
}

function update_match_case {
  SEARCH_MATCH_CASE=$(echo "$OUTPUT" | cut -d "," -f2)
  if [ "$SEARCH_MATCH_CASE" == "YES" ]; then
    MATCH_CASE="YES"
  fi
}

function update_match_entire_word_only {
  SEARCH_MATCH_ENTIRE_WORD_ONLY=$(echo "$OUTPUT" | cut -d "," -f3)
  if [ "$SEARCH_MATCH_ENTIRE_WORD_ONLY" == "YES" ]; then
    MATCH_ENTIRE_WORD_ONLY="YES"
  fi
}

function update_phrase {
  SEARCH_PHRASE=$(echo "$OUTPUT" | cut -d "," -f1)
  if [ -z "$SEARCH_PHRASE" ]; then
    PHRASE=""
  else
    PHRASE=${SEARCH_PHRASE}
  fi
}

function display_search_result_output {
  zenity --question --text="How do you want to display the results." --ok-label="All results" --cancel-label="First result" --height 200 --width 240
  if [[ $? == 0 ]]; then
    if [ -z "$SEARCH" ]; then
      echo "Phrase was not found in search" | zenity --text-info --width=600
    else
      echo "$SEARCH" | zenity --text-info --width=600 --height=600
    fi
  else
    if [ -z "$FIRST_SEARCH" ]; then
      echo "Phrase was not found in search" | zenity --text-info --width=600
    else
      echo "$FIRST_SEARCH" | zenity --text-info --width=600 --height=600
    fi
  fi
}

function search_phrase {
  MATCH_CASE_FUNCTION=""
  if [ "$MATCH_CASE" = "YES" ]; then
    MATCH_CASE_FUNCTION="PRAGMA case_sensitive_like = 1"
  fi
  # if match entire word only is disabled search any string containing the phrase
  if [ "$MATCH_ENTIRE_WORD_ONLY" = "NO" ]; then
    POSSIBILITIES=("%${PHRASE}%")
  else
    POSSIBILITIES=("${PHRASE}" "% ${PHRASE} %" "${PHRASE} %" "% ${PHRASE}")
  fi

  for possibility in "${POSSIBILITIES[@]}"; do
    SEARCH+=$(sqlite3 "${FIREFOX_HISTORY_DB}" "${MATCH_CASE_FUNCTION}; SELECT datetime(moz_historyvisits.visit_date/1000000, 'unixepoch', '+2 hours'), moz_places.title FROM moz_places, moz_historyvisits WHERE moz_places.id = moz_historyvisits.place_id AND moz_places.title IS NOT NULL AND moz_places.title LIKE '${possibility}'")
  done
  # the first found search result
  FIRST_SEARCH="$(echo "$SEARCH" | head -1)"

  display_search_result_output
}

# main menu
function display_menu {
  close_browser_if_open
  menu=("Search for phrase" "Delete history" "Delete cookies" "Exit")
  option=$(zenity --list --column=Menu "${menu[@]}" --height 350 --width 480)
  case "$option" in
  "Search for phrase") INPUT=1 ;;
  "Delete history") INPUT=2 ;;
  "Delete cookies") INPUT=3 ;;
  "Exit") INPUT=4 ;;
  esac
}

# handles long commandline arguments manually and short arguments using get-opts
function handle_arguments() {
  runProgram=0
  if [[ $# != 0 ]]; then
    numberOfArguments=$#
    for ((i = 1; i <= numberOfArguments; i++)); do
      if [[ "${!i}" == "--version" ]]; then
        print_version_info
        runProgram=1
        set -- "${@:1:i-1}" "${@:i+1}" # deletes handled argument so that get-opts can work correctly
      elif [[ "${!i}" == "--help" ]]; then
        print_help
        runProgram=1
        set -- "${@:1:i-1}" "${@:i+1}"
      elif [[ "${!i}" == "--author" ]]; then
        print_author_info
        runProgram=1
        set -- "${@:1:i-1}" "${@:i+1}"
      elif [[ "${!i}" == "--display-history" ]]; then
        print_current_browser_history
        runProgram=1
        set -- "${@:1:i-1}" "${@:i+1}"
      elif [[ "${!i}" == "--display-cookies" ]]; then
        print_current_cookies
        runProgram=1
        set -- "${@:1:i-1}" "${@:i+1}"
      elif [[ "${!i}" == "--display-all" ]]; then
        print_current_browser_history_and_cookies
        runProgram=1
        set -- "${@:1:i-1}" "${@:i+1}"
      elif [[ "${!i}" == --* ]]; then
        echo "Unknown option"
        runProgram=1
        set -- "${@:1:i-1}" "${@:i+1}"
      fi
    done
    while getopts vha OPT; do
      case $OPT in
      h)
        print_help
        runProgram=1
        ;;
      v)
        print_version_info
        runProgram=1
        ;;
      a)
        print_author_info
        runProgram=1
        ;;
      *)
        echo "Unknown option"
        runProgram=1
        ;;
      esac
    done
  fi
  if [[ $runProgram == 1 ]]; then
    exit
  fi
}

function main() {
  handle_arguments "$@"
  install_required_packages
  if [[ $RETURN_VALUE == 1 ]]; then
    exit
  fi
  display_menu
  while [ $INPUT -ne 4 ]; do
    case "$INPUT" in
    "1") display_search_menu ;;
    "2") delete_history ;;
    "3") delete_cookies ;;
    "4") exit ;;
    esac
    display_menu
  done
}

main "$@"
