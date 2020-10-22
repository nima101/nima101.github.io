#!/bin/sh

set -e

if [ -z "$1" ]; then
    echo "Please provide <post_file_name> and <post_title>."
    exit 1
fi
if [ -z "$2" ]; then
    echo "Please provide <post_file_name> and <post_title>."
    exit 1
fi
POST_NAME=$1
TITLE=$2

DATE=`date +%Y-%m-%d`
TIME=`date +%H:%M:%S`

FILE_NAME=_posts/${DATE}-${POST_NAME}.md
echo "post_name: ${POST_NAME}"
echo "title: ${TITLE}"
echo "file name: $FILE_NAME"

echo "creating file.."
touch ${FILE_NAME}

echo "writing header.."

echo "---" >> $FILE_NAME
echo "layout: post" >> $FILE_NAME
echo "title: \"${TITLE}\"" >> $FILE_NAME
echo "date:  ${DATE} ${TIME} +0700" >> $FILE_NAME
echo "categories: []" >> $FILE_NAME
echo "---" >> $FILE_NAME

echo "done."
