#!/bin/bash

# Define the target output directory relative to where the script is run
OUTPUT_DIR="./General_test"

# Function to display options and handle user selection
navigate() {
    local current_path="$1"
    
    # Ensure the path exists
    if [[ ! -d "$current_path" ]]; then
        echo "Error: Directory not found: $current_path"
        exit 1
    fi

    echo "--- Current Directory: $current_path ---"

    PS3="Select an item (or type '..' to go back, or 'exit' to quit): "

    # Use 'select' loop for interactive menu creation
    select item in *; do
        if [[ "$REPLY" == "exit" ]]; then
            echo "Exiting script."
            break
        elif [[ "$REPLY" == ".." ]]; then
            # Go up one directory level
            parent_dir=$(dirname "$current_path")
            cd "$parent_dir" || exit
            navigate "$(pwd)"
            break
        elif [[ -n "$item" ]]; then
            # If a valid numbered item was selected
            local selected_path="$current_path/$item"
            
            if [[ -d "$selected_path" ]]; then
                # If it's a directory, change into it and repeat the selection process
                cd "$selected_path" || exit
                navigate "$(pwd)"
                break
            elif [[ -f "$selected_path" ]]; then
                # If it's a file, we found the target.
                echo "Selected output file: $selected_path"
                process_file "$selected_path"
                break
            else
                echo "Invalid selection: $item"
            fi
        else
            echo "Invalid selection number. Please try again."
        fi
    done
}

# Function to simulate "running the script" and placing an output file in General_test
process_file() {
    local input_file="$1"
    
    # 5. if output file is selected run the script and make output file in General_test directroy

    # Create the output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR" || { echo "Error creating $OUTPUT_DIR"; exit 1; }

    local output_filename="processed_$(basename "$input_file").log"
    local output_file_path="$OUTPUT_DIR/$output_filename"
    
    echo "--- Processing file ---"
    echo "Input: $input_file"
    echo "Output: $output_file_path"
    
    # Simulate a file processing step (e.g., creating a simple log file)
    echo "Log generated from file: $input_file" > "$output_file_path"
    echo "Processing complete. Check $output_file_path"
}


# --- Main execution ---

echo "Starting navigation script."

# Start the navigation loop in the current working directory
navigate "$(pwd)"
