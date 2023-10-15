#!/bin/sh

# Author: Alex Ghandhi
# SystemVerilog Verible Auto Formatter/Linter POSIX shell script


# Update verible-filelist
echo -n "Updating verible-filelist..."
exec find . -name '*.sv' -o -name '*.svh' -o -name '*.v' | sort > verible.filelist
git add verible.filelist
echo -n -e "Success\n"

# Skip checks if tools are not present
if [[ ! -n $(type -P verible-verilog-format) || ! -n $(type -P verible-verilog-lint) ]] then
    echo -e "\nFailed to Locate Verible Toolchain"
    echo "Install Toolchain: https://github.com/chipsalliance/verible"
    echo -e "\nSkipping formatter/linter checks\n"
    exit 0
fi

# Create temporary files to store output and errors
touch pre_commit_out
touch pre_commit_errmsg


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
        verible-verilog-format $(cat .rules.verible_format | sed -z 's/\n/ /g') --inplace $file $file &> pre_commit_out
        if [[ -s pre_commit_out ]] then
            echo -n -e "Failed\n"
        else
            echo -n -e "Success\n"
        fi
        echo "" > pre_commit_out
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
        verible-verilog-lint --rules_config_search $file &> pre_commit_out
        if [[ -s pre_commit_out ]] then
            echo -n -e "Failed\n"
            cat pre_commit_out >> pre_commit_errmsg
        else
            echo -n -e "Success\n"
        fi
        echo "" > pre_commit_out
    fi
done

# If linter errors were detected, print diagnostics and fail
if [[ -s pre_commit_errmsg ]] then
    echo -e "\nFailed: Fix the following\n"
    cat pre_commit_errmsg > autolint_errors.txt
    rm pre_commit_out
    rm pre_commit_errmsg
    exit 1
fi

# No errors detected: Remove temporary files and end the script
rm pre_commit_out
rm pre_commit_errmsg
exit 0
