#!/bin/bash

# Get the directory where the script is located (current directory when running the script)
script_dir="$PWD"

# Define the root directory as the parent of the script directory
root_dir="$(dirname "$script_dir")"

# Specify the input file and output directory (parent directory of the script location)
input_file="$script_dir/New-API-endpoints.txt"
output_dir="$root_dir"  # Output files will be saved in the parent folder

# Define the number of lines per split file
lines_per_file=100000
max_lines_per_file=100000  # New limit for each part file

# Remove "/" at the start and end of each line in the input file
sed -i 's/^\/\+//' "$input_file"     # Remove leading slashes
sed -i 's/\/\+$//' "$input_file"     # Remove trailing slashes

echo "Removed leading and trailing slashes from $input_file"

# Get the total number of lines in the file
total_lines=$(wc -l < "$input_file")

# Calculate the number of files needed
num_files=$(( (total_lines + lines_per_file - 1) / lines_per_file ))

# Create a temporary file to track all unique endpoints
unique_endpoints="unique_endpoints.txt"
> "$unique_endpoints"  # Empty the file if it exists

# Create an array to keep track of the current line number for each file
current_line=1

# Split the file into smaller files, checking existing ones
for (( i=0; i<num_files; i++ ))
do
    # Calculate the line range for the current file
    start_line=$current_line
    end_line=$(( start_line + lines_per_file - 1 ))
    
    # Generate the filename for the current part, output to the parent directory
    output_file="$output_dir/API-RuleThemAll-part$(( i + 1 )).txt"
    
    # Check if the file already exists and has less than 100K lines
    if [[ -f "$output_file" && $(wc -l < "$output_file") -lt $max_lines_per_file ]]; then
        # Find out how many lines are needed to complete 100K lines
        existing_lines=$(wc -l < "$output_file")
        remaining_lines=$(( max_lines_per_file - existing_lines ))
        
        # Add the remaining lines from the original file to this part
        sed -n "${start_line},$(( start_line + remaining_lines - 1 ))p" "$input_file" >> "$output_file"
        current_line=$(( start_line + remaining_lines ))  # Update the current line
        echo "Added lines to existing file: $output_file"
    else
        # If the file doesn't exist or already has enough lines, create a new one
        sed -n "${start_line},${end_line}p" "$input_file" > "$output_file"
        current_line=$(( end_line + 1 ))  # Update the current line
        echo "Created new file: $output_file"
    fi
    
    # Check for unique endpoints in the newly created or updated part file
    while IFS= read -r line
    do
        # Check if this line already exists in any existing part file
        if ! grep -Fxq "$line" "$unique_endpoints"; then
            # If not, add it to the unique_endpoints file
            echo "$line" >> "$unique_endpoints"
        fi
    done < "$output_file"
done

# Clean up: Remove temporary files used for processing
rm "$unique_endpoints"

# Combine all part files, sort them, remove duplicates, and save to a final file in the parent folder
cat "$output_dir"/API-RuleThemAll-part*.txt | sort | uniq > "$output_dir/API-RuleThemAll-All_Parts.txt"

echo "Combined and sorted all endpoints into API-RuleThemAll-All_Parts.txt."

# Clean the input file after processing (optional: to clear the contents)
> "$input_file"

echo "The input file ($input_file) has been cleared."
