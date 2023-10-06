# Development Guide

## Verible SystemVerilog Tools

- Install the [Verible Toolchain](https://github.com/chipsalliance/verible/tree/master) for your operating system
    - [Releases](https://github.com/chipsalliance/verible/releases)
- Make sure the verible tools are exposed to PATH
    - This is accomplished by adding the verible directory to PATH

System-Specific guides to modifying the PATH variable:
- [POSIX](https://unix.stackexchange.com/questions/26047/how-to-correctly-add-a-path-to-path)  
- [WINDOWS](https://www.howtogeek.com/118594/how-to-edit-your-system-path-for-easy-command-line-access/)

```sh
# Prints "found" if the command is exposed to PATH

# Powershell
if(Get-Command verible-verilog-lint){"found"}

# Bash
! $(type -P verible-verilog-lint) || echo "found"
```

## Working With the Verible Toolchain

### [Linter Options](https://chipsalliance.github.io/verible/verilog_lint.html)

Base options are defined in the [official documentation](https://github.com/chipsalliance/verible/tree/master/verilog/tools/lint). Additional linting preferences are placed in `.rules.verible_lint` in the root directory.

Example:
```sh
# Powershell/Bash
$ cat .rules.verible_lint
-explicit-parameter-storage-type
+line-length=length:80
+endif-comment
-generate-label-prefix
```

### [Formatter Documentation](https://github.com/chipsalliance/verible/tree/master/verilog/tools/formatter)

The automatic formatting run by the git hook is set to include `--column_limit 80`, other options can be included for personal testing, but will not be enforced on commits.

## [Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)

### Pre Commit

This repository contains a pre-commit hook that runs automatically before the user adds a commit message. The script will attempt to reformat and lint code, preventing a commit if any errors are encountered.

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
