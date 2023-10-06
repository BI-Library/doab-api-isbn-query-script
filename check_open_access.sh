#!/bin/bash

# Function to convert ISBN-10 to ISBN-13
convert_isbn10_to_13() {
    local isbn10=$1

    # Pad the ISBN-10 with leading zeros if it's less than 10 digits
    while [ ${#isbn10} -lt 10 ]; do
        isbn10="0${isbn10}"
    done

    if [ ${#isbn10} -eq 10 ]; then
        local isbn13="978${isbn10:0:9}"
        local sum=0
        for (( i=0; i<${#isbn13}; i++ )); do
            local digit="${isbn13:$i:1}"
            if [ $((i % 2)) -eq 0 ]; then
                sum=$((sum + digit))
            else
                sum=$((sum + digit * 3))
            fi
        done
        local check=$((10 - sum % 10))
        [ $check -eq 10 ] && check=0
        echo "${isbn13}${check}"
    else
        echo "$isbn10"
    fi
}

# Initialize counters
total_count=0
open_access_count=0

# Check if the input file exists
if [ ! -f "isbn_list.txt" ]; then
    echo "File isbn_list.txt does not exist."
    exit 1
fi

# Loop through each ISBN in the file
while IFS= read -r isbn; do
    # Skip empty lines
    if [ -z "$isbn" ]; then
        continue
    fi

    # Convert ISBN-10 to ISBN-13 if needed
    isbn=$(convert_isbn10_to_13 "$isbn")

    # Increment the total count
    total_count=$((total_count + 1))

    # Generate the URL for debugging
    url="https://directory.doabooks.org/rest/search?query=isbn:${isbn}"
    echo "Checking URL: $url"

    # Make a request to the DOAB API
    response=$(curl -s "$url")

    # Print the raw API response for debugging
    echo "Raw API Response: $response"

    # Check if the book is open access by looking for the pattern "uuid"
    if [[ "$response" == *"uuid"* ]]; then
        echo "$isbn is open access."
        open_access_count=$((open_access_count + 1))
    else
        echo "$isbn is not open access."
    fi
done < "isbn_list.txt"

# Calculate and print the percentage of open access books
if [ $total_count -eq 0 ]; then
    echo "No ISBNs processed."
else
    percentage=$(awk "BEGIN { pc=100*${open_access_count}/${total_count}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
    echo "$open_access_count out of $total_count books are open access. ($percentage%)"
fi
