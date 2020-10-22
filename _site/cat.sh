#!/bin/sh

set -e

if [ -z "$1" ]; then
    echo "Please provide the category name."
    exit 1
fi

CATEGORY=$1
TITLE=`echo ${CATEGORY:0:1} | tr '[a-z]' '[A-Z]'`${CATEGORY:1}

echo "category: ${CATEGORY}"
echo "title: ${TITLE}"

FILE_NAME="category/${CATEGORY}.md"
echo "creating file: ${FILE_NAME}"
touch ${FILE_NAME}

echo "writing header.."

echo "---" >> $FILE_NAME
echo "layout: posts_by_category" >> $FILE_NAME
echo "categories: ${CATEGORY}" >> $FILE_NAME
echo "title: ${TITLE}" >> $FILE_NAME
echo "permalink: /category/${CATEGORY}" >> $FILE_NAME
echo "---" >> $FILE_NAME

echo "done."
