#!/usr/bin/env bash
set -euo pipefail

# Developer Variables
dependencies=("aria2c")
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
    echoerr "$0 <biosamples_of_interest>"
    echoerr " <biosamples_of_interest>  a file containing newline separated biosample names to search for"
    echoerr " -v | --version    )   print version"
    echoerr " -h | --help       )   print this help message"
    exit 1
}


# If zero arguments are supplied, print usage
if [ "$#" == "0" ]; then
	usage
fi


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
if [ $positional_arg == "NA" ]; then
    echoerrfail "Must supply a positional argument"
fi


#url="https://www.encodeproject.org/search/?type=Annotation&encyclopedia_version=ENCODE+v5&annotation_type=candidate+Cis-Regulatory+Elements&biosample_ontology.classification=cell+line&biosample_ontology.term_name=A549&biosample_ontology.term_name=MCF+10A"


url="https://www.encodeproject.org/search/?type=Annotation&encyclopedia_version=ENCODE+v5&annotation_type=candidate+Cis-Regulatory+Elements&organism.scientific_name=Homo+sapiens&files.file_type=bed+bed9%2B&assembly=GRCh38"
tsv_summary_url="https://www.encodeproject.org/report.tsv?type=Annotation&encyclopedia_version=ENCODE+v5&annotation_type=candidate+Cis-Regulatory+Elements&organism.scientific_name=Homo+sapiens&assembly=GRCh38"
file_metadata_summary_url="https://www.encodeproject.org/metadata/?type=Annotation&encyclopedia_version=ENCODE+v5&annotation_type=candidate+Cis-Regulatory+Elements&organism.scientific_name=Homo+sapiens&files.file_type=bed+bed9%2B&assembly=GRCh38"

cell_line_query=""

while read cell_line; do
    cell_line=$(echo $cell_line | tr ' ' '+')
    cell_line_query=$cell_line_query"&biosample_ontology.term_name=$cell_line"
done <<< $(cat $positional_arg)

echo ${cell_line_query}

url=${url}${cell_line_query}
tsv_summary_url=${tsv_summary_url}${cell_line_query}
file_metadata_summary_url=${file_metadata_summary_url}${cell_line_query}


echoerr "See results search in encode website using the url:\n"$url"\n\n"
echoerr "\n\n"

echoerr "Tabular summary of results will to be downloaded from $tsv_summary_url\n"
curl -s $tsv_summary_url | tee "summary_of_available_data.tsv"

echoerr "\n\n"
echoerr "File metadata being downloaded from $file_metadata_summary_url\n"
curl -s $file_metadata_summary_url | tee "file_metadata.tsv"

echoerr "\n"
echoerr "Grabbing download links from metadata file and saving in aria2c.txt\n"
cut -f22 file_metadata.tsv | tail -n +2 > aria2c.txt

echoerr "\nTo download data run:\naria2c -i aria2c.txt -d data"
