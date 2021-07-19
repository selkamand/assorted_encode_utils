#!/usr/bin/env bash
set -euo pipefail

# Developer Variables
dependencies=("curl" "jq")
version="0.0.1"
FORMATTED_TEXT_ENABLED=true
verbose=false
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


#Colours
c_normal="\e[0m"
c_bold="\e[1m"
c_red="\e[31m"
c_green="\e[32m"
c_cyan="\e[96"
c_magenta="\e[35m"
c_underlined="\e[4m"
c_yellow="\e[33m"
c_line="--------------------------------------------"


# Echo
function echoerr() {
    echo -e "$@" >&2
}


function echoerrformatted() {
    if $FORMATTED_TEXT_ENABLED; then
        echoerr "$1${@:2}$c_normal"
    else
        echoerr "${@:2}"
    fi
}

function echoerrfail() {
    echoerrformatted $c_bold$c_red "$@"
}

function echoerrwarning() {
    echoerrformatted $c_yellow "$@"
}

function echoerrsuccess() {
    echoerrformatted $c_green "$@"
}

#Test Dependencies
function test_dependencies() {
    failed=false
    for dependency in $@; do

        if which $dependency > /dev/null; then
            if "$verbose"; then
                echoerr "Testing Dependencies: "
                echoerr " $dependency"
                echoerrsuccess "    > $(which $dependency)"
            fi
        else
            echoerr "Testing Dependencies: "
            echoerr " $dependency"
            echoerrfail "   > MISSING"
            failed=true
        fi
    done

    if $failed; then
        echoerrformatted $c_bold$c_red "\nplease install missing dependencies"
        exit 1
    elif $verbose; then
        echoerr ""
    fi
}

# Usage
function usage() {
    echoerr "$0 <encode biosample accession (e.g. ENCBS164RWQ)>"
    echoerr " -v | --version    )   print version"
    echoerr " -h | --help       )   print this help message"
    exit 1
}


# If zero arguments are supplied, print usage
#if [ "$#" == "0" ]; then
#	usage
#fi


#Parse Arguments
positional_arg="NA"
while (("$#")); do
    case $1 in
        -h | --help)
            usage
            exit
            ;;
        -v | --version)
            echoerr "Version: $version"
            exit
            ;;

        *)
            if [ "$positional_arg" = "NA" ]; then
                positional_arg=$1
            else
                echoerrfail "Wrong number of positional arguments\n"
                usage
            fi
            ;;
    esac
    shift
done

#Test dependencies
test_dependencies ${dependencies[@]}

#Options for qc
#Ensure postitional argument is supplied
#if [ $positional_arg == "NA" ]; then
#    echoerrfail "Must supply a positional argument"
#fi

#download_url="https://api.wenglab.org/screen_v13/fdownloads/Seven-Group/"$positional_arg".7group.bed"

#echoerr "Trying to download bed from:\n"$download_url

#curl -o $positional_arg.bed $download_url
url="https://www.encodeproject.org/matrix/?type=Experiment&control_type!=*&status=released&perturbed=false&format=json"
echoerr "Querying the url:\n" $url
echoerr "Saving results in encode_experiment_matrix.json"
curl -H "Accept: application/json" $url -o encode_experiment_matrix.json

echoerr "Extracting key data and flattening json"
cat encode_experiment_matrix.json | jq '[.matrix.y."biosample_ontology.classification".buckets | .[] | { biosample_class: .key, experiment_details: ."biosample_ontology.term_name".buckets[] } | {biosample_class, sample: .experiment_details.key,  experiment_details: .experiment_details.assay_title.buckets[]} | {biosample_class, sample, experiment: .experiment_details.key, doc_count: .experiment_details.doc_count}]' > encode_experiment_matrix.simple.json
#cat encode_biosamples.json | jq '."@graph"[] |  {accession, biosample_ontology_term : .biosample_ontology.term_name, biosample_ontology_classification : .biosample_ontology.classification, applied_modifications: .applied_modifications[0].category}' > encode_biosamples.simple.json
