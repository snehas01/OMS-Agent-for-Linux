#! /bin/bash

set -e

# For running this script, you must be running on a 64-bit system!
# This is for text substitution that happens below.

if [ `uname -m` != "x86_64" ]; then
    echo "This script must be run from a 64-bit system" >& 2
    exit 1
fi

substitute_arch()
{
    if [ -z "$1" ]; then
	echo "Internal error: substitute_arch requires a parameter" >& 2
	exit 1
    fi

    # Substitute machine name as needed
    echo $1 | grep -q -- "/extensions"
    if [ $? -eq 0 ]; then
	RESULT=`echo $1 | sed "s~/x86_64-linux~/\\${{RUBY_ARCH}}~"`
    else
	RESULT=`echo $1 | sed "s~/x86_64-linux~/\\${{RUBY_ARCM}}~"`
    fi

    echo -n "$RESULT"
}

# This script will generate a "starting point" for an InstallBuilder data file.
# For example, this generated ruby.data in the omsagent project. This is useful
# for a package that has an install process (i.e. make install), but we need to
# generate an install data file for it.

OUTPUT_RESULTS="/tmp/installBuilder-$USER"
rm -f $OUTPUT_RESULTS

# Evaluate any wildcards in the filename ...
SOURCE_DIR=`stat -c "%n" ~/dev/work/oms/intermediate/*/ruby`

OUTPUT_DIR=/tmp/outdir.txt.$$
OUTPUT_FILE=/tmp/outfile.txt.$$

echo "%Directories" > $OUTPUT_DIR
echo "%Files" > $OUTPUT_FILE

# Verify validity of source directory

if [ -z "$SOURCE_DIR" -o ! -d $SOURCE_DIR ]; then
    echo "Source directory ($SOURCE_DIR) does not exist" >& 2
    exit 1
fi

# For each destination file, generate the appropriate lines for InstallBuilder

NEW_BASE_DIR=""
for i in `find $SOURCE_DIR -name \* -print`; do
    if [ -d $i ]; then
        DIR_NAME=`echo $i | sed "s~$SOURCE_DIR~~"`
	[ -n "$DIR_NAME" ] && DIR_NAME=`substitute_arch $DIR_NAME`
        STAT_INFO=`stat -c "%a; %U; %G" $i`
        printf "%-55s %s\n" "\${{RUBY_DEST}}${DIR_NAME};" "$STAT_INFO" >> $OUTPUT_DIR
    else
        OLD_BASE_DIR=`dirname $i`
        [ "$OLD_BASE_DIR" != "$NEW_BASE_DIR" ] && echo "" >> $OUTPUT_FILE
        NEW_BASE_DIR=$OLD_BASE_DIR

        FILE_NAME=`echo $i | sed "s~$SOURCE_DIR~~"`
	FILE_NAME=`substitute_arch $FILE_NAME`
        STAT_INFO=`stat -c "%a; %U; %G" $i`
        printf "%-72s %-64s %s\n" "\${{RUBY_DEST}}${FILE_NAME};" "\${{RUBY_INT}}${FILE_NAME};" "$STAT_INFO" >> $OUTPUT_FILE
    fi
done

# Generate results

echo "Writing results to file: $OUTPUT_RESULTS"

echo "%Variables" > $OUTPUT_RESULTS
printf "%-25s %s\n" RUBY_DEST: "'/opt/microsoft/omsagent/ruby'" >> $OUTPUT_RESULTS
echo "" >> $OUTPUT_RESULTS

cat $OUTPUT_FILE >> $OUTPUT_RESULTS
echo "" >> $OUTPUT_RESULTS
echo "" >> $OUTPUT_RESULTS
cat $OUTPUT_DIR >> $OUTPUT_RESULTS

rm $OUTPUT_DIR
rm $OUTPUT_FILE

exit 0
