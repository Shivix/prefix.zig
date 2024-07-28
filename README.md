# PREtty FIX
A commandline based pretty printer for FIX messages.

Based on a FIX4.4 dictionary, but is usable with most versions.

## Usage
input can be piped in or passed as an argument:
```bash
echo "8=FIX4.4|1=test|55=EUR/USD|10=123|" | prefix
prefix "8=FIX4.4|1=test|55=EUR/USD|10=123|"
```
outputs:
```
BeginString = FIX4.4
Account = test
Symbol = EUR/USD
CheckSum = 123
```

Currently can use ^ and | and SOH as delimiters.

Use `prefix --help` for more details.

## Piping
Unix piping greatly increases the potential uses. For example:
Parsing a log file and aligning the values for easy scan reading.
```bash
# Pipe the file contents to prefix which parses and pipes them to awk, which prints them aligned.
cat example.log | xargs prefix | awk '{printf("%-20s %-30s\n", $1,$3)}'
```
outputs:
```
BeginString          FIX.4.4
Account              TEST
Symbol               EUR/USD
ExecType             PartialFill
```

## Installation
Can be installed using:
```
zig build install
```
## Issues
Any bugs/ requests can be added to the [issues](https://github.com/Shivix/prefix.zig/issues) page on the github repository.
