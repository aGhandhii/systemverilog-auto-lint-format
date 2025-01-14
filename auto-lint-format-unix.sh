#!/bin/sh

# Author: Alex Ghandhi
# SystemVerilog Verible Auto Formatter/Linter UNIX Shell Script


# Update verible-filelist
echo -n "Updating verible-filelist..."
exec find . -name '*.sv' -o -name '*.svh' -o -name '*.v' | sort > verible.filelist
echo -n -e "Success\n"

# Skip checks if tools are not present
if [[ ! -n $(type -P verible-verilog-format) || ! -n $(type -P verible-verilog-lint) ]] then
    echo -e "\nFailed to Locate Verible Toolchain"
    echo "Install Toolchain: https://github.com/chipsalliance/verible"
    echo -e "\nSkipping formatter/linter checks\n"
    read -p "Press any key to exit" -n 1 -r
    exit 0
fi

# Create temporary files to store output and errors
touch scriptOut
touch scriptError


##################
# Reformat files #
##################

# Iterate files and run formatter
for file in $(cat verible.filelist); do
    echo -n "Reformatting $file..."

    # Check if the file should be ignored
    if [[ -f verible.filelist.ignore && ! -z $(grep "$file" verible.filelist.ignore) ]] then
        echo -n -e "Skipped\n"
    else
        # Apply user-declared formatter options in .rules.verible_format
        if [[ -f .rules.verible_format ]] then
            params=$(cat .rules.verible_format | sed -z 's/\n/ /g')
        else
            params=""
        fi
        verible-verilog-format $params --inplace $file $file &> scriptOut
        if [[ -s scriptOut ]] then
            echo -n -e "Failed\n"
        else
            echo -n -e "Success\n"
        fi
        echo "" > scriptOut
    fi
done


##############
# Lint Files #
##############

# Iterate files and run linter
for file in $(cat verible.filelist); do
    echo -n "Linting $file..."

    # Check if the file should be ignored
    if [[ -f verible.filelist.ignore && ! -z $(grep "$file" verible.filelist.ignore) ]] then
        echo -n -e "Skipped\n"
    else
        # Apply user-declared linter rules defined in .rules.verible_lint
        verible-verilog-lint --rules_config_search $file &> scriptOut
        if [[ -s scriptOut ]] then
            echo -n -e "Failed\n"
            cat scriptOut >> scriptError
        else
            echo -n -e "Success\n"
        fi
        echo "" > scriptOut
    fi
done

# If linter errors were detected, print diagnostics and fail
if [[ -s scriptError ]] then
    echo -e "\nFailed: Fix the following\n"
    cat scriptError
    cat scriptError > autolint_errors.txt
    rm scriptOut
    rm scriptError
    echo -e "\n"
    read -p "Press any key to exit" -n 1 -r
    exit 1
fi

# No errors detected: Remove temporary files and end the script
rm scriptOut
rm scriptError
echo -e "\n"
read -p "Press any key to exit" -n 1 -r
exit 0