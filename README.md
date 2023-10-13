# Setup and Usage

## Verible SystemVerilog Tools

- Install the [Verible Toolchain](https://github.com/chipsalliance/verible/tree/master) for your operating system
    - [Releases](https://github.com/chipsalliance/verible/releases)
- Make sure the verible tools are exposed to PATH
    - This is accomplished by adding the verible directory to PATH

System-Specific guides to modifying the PATH variable:
- [POSIX](https://unix.stackexchange.com/questions/26047/how-to-correctly-add-a-path-to-path)  
- [WINDOWS](https://www.howtogeek.com/118594/how-to-edit-your-system-path-for-easy-command-line-access/)

```sh
# Prints "found" if required tools are exposed to PATH

# Powershell
if(Get-Command verible-verilog-lint && Get-Command verible-verilog-format){"found"}

# Bash
[[ -n $(type -P verible-verilog-format) && -n $(type -P verible-verilog-lint) ]] && echo "found"
```

# Working With the Verible Toolchain

## Linting

Default options are defined in the [official documentation](https://github.com/chipsalliance/verible/tree/master/verilog/tools/lint), and the full command list is available at the [verible lint options page.](https://chipsalliance.github.io/verible/verilog_lint.html) 

User-defined linting preferences are placed in `.rules.verible_lint` in the base directory of the repository. This file contains a line-separated list of linter options to be added or removed from the linter defaults.

Linter commands to be added have a '+' as a prefix, while linter commands to be removed have a '-' as a prefix.

*Example:*
```sh
# Powershell/Bash
$ cat .rules.verible_lint
-explicit-parameter-storage-type
+line-length=length:80
+endif-comment
-generate-label-prefix
```

## Formatting

The full list of formatting options is available at the official [Formatter Documentation](https://github.com/chipsalliance/verible/tree/master/verilog/tools/formatter) page. 

User-defined formatter options are placed in `.rules.verible_format` in the base directory of the repository. This file contains a line-separated list of formatter commands to be applied when reformatting code.

*Example:*
```sh
# Powershell/Bash
$ cat .rules.verible_format
--column-limit 80
--indentation-spaces 4
```


## [Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)

### Pre Commit

This repository contains a pre-commit hook that runs automatically before the user adds a commit message. The script will attempt to reformat and lint all Verilog and SystemVerilog files in the current repository, preventing a commit if any errors are encountered.

To use the script, create a hard link to the appropriate directory.

From the base directory of the git repository:

```sh
# Powershell
cmd /c mklink /h .\.git\hooks\pre-commit .\verible-pre-commit

# Bash
ln ./verible-pre-commit ./.git/hooks/pre-commit
```

### verible.filelist

Running the git hook will automatically create or update the `verible.filelist` file. This contains a line-separated list of every `*.v` and `*.sv` file relative to the project's base directory.

```sh
# Powershell/Bash
$ cat verible.filelist
./DE1_SoC.sv
./test.sv
./othertest.sv
./file.v
```
The hook relies on this file to apply formatting and linting suggestions: do not remove this file!

The `verible-verilog-ls` Language Server also uses this list to parse files for symbol searching. This tool is optional and not used by the git hook.

### verible.filelist.ignore

To prevent the formatting/linting of a specific set of files, one can optionally create the `verible.filelist.ignore` file in the project's base directory. The format of this file (similar to `verible.filelist`) is a line-separated list of the paths of each desired 'ignored' file relative to the project base directory.

Example `verible.filelist.ignore`:
```sh
# Powershell/Bash
$ cat verible.filelist.ignore
./test.sv
./othertest.sv
```

### Overriding Git Hooks

If there are linter/formatter warnings that can be overlooked or ignored, the pre-commit hook can be overwritten with:

```sh
# Powershell/Bash
git commit --no-verify
```
