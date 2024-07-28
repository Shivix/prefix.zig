const std = @import("std");
const tags = @import("tags.zig").tag_to_name;

const Opts = struct {
    colour: []const u8 = "auto",
    delimiter: []const u8 = "\n",
    help: bool = false,
    strip: bool = false,
    tag: bool = false,
    version: bool = false,
};

const usage =
    \\Usage: program [options]
    \\       --colour <when>         Adds colour to the delimiter and =, auto will colour only when printing directly into a tty [Default: auto]
    \\       --delimiter <delimiter> Delimiter to use between each field [Default: \n]
    \\       --help                  Show this help message
    \\       --strip                 Strips the whitespace around the printed =
    \\       --tag                   Treats the input as a single tag to parse
    \\       --version               Enable version mode
;

fn parseArgs() !struct {Opts, []const u8} {
    var args = std.process.args();
    _ = args.skip();
    var opts = Opts{};
    var msg: []const u8 = "";
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            opts.help = true;
        } else if (std.mem.eql(u8, arg, "--version")) {
            opts.version = true;
        } else if (std.mem.eql(u8, arg, "--delimiter")) {
            const delimiter = args.next() orelse {
                std.debug.print("--delimiter requires a value", .{});
                std.process.exit(1);
            };
            opts.delimiter = delimiter;
        } else if (std.mem.eql(u8, arg, "--color")) {
            const colour = args.next() orelse {
                std.debug.print("--color requires a value", .{});
                std.process.exit(1);
            };
            opts.colour = colour;
        } else if (std.mem.eql(u8, arg, "--strip")) {
            opts.strip = true;
        } else if (std.mem.eql(u8, arg, "--tag")) {
            opts.tag = true;
        } else if (arg.len > 0 and arg[0] == '-') {
            std.debug.print("Unknown argument: {s}", .{arg});
            std.process.exit(1);
        } else {
            msg = arg;
        }
    }
    return .{opts, msg};
}

const stdout_file = std.io.getStdOut();
const stdout_writer = stdout_file.writer();
var bw = std.io.bufferedWriter(stdout_writer);
const stdout = bw.writer();
const stdin = std.io.getStdIn().reader();

fn pretty_print_fix(input: []const u8, opts: *const Opts) !void {
    // Assume input might be a log line and contain more than just the message.
    const start = std.mem.indexOf(u8, input, "8=") orelse {
        try stdout.print("{s}\n", .{input});
        return;
    };
    const end = std.mem.indexOfPos(u8, input, start, "10=") orelse {
        try stdout.print("{s}\n", .{input});
        return;
    };
    // If we ever fail to parse, just print the whole string.
    // Use SOH, | and ^ as possible delimiters.
    // Assumes that there is a valid 3 digit checksum + a delim after the 10=.
    if (input.len <= end + 6) {
        try stdout.print("{s}\n", .{input});
        return;
    }
    var fields = std.mem.splitAny(u8, input[start..end + 6], "\x01|^");
    while (fields.next()) |field| {
        var split = std.mem.splitScalar(u8, field, '=');
        const tag = try std.fmt.parseInt(usize, split.first(), 10);
        const value = split.next().?;
        const tag_name = if (tag < tags.len) tags[tag] else split.first();
        const equals = " = ";
        const delimiter = opts.delimiter;
        const should_colour = std.mem.eql(u8, opts.colour, "auto") and stdout_file.isTty() or std.mem.eql(u8, opts.colour, "always");

        if (should_colour) {
            try stdout.print("{s}\x1b[33m{s}\x1b[0m{s}\x1b[33m{s}\x1b[0m", .{tag_name, equals, value, delimiter});
        } else {
            try stdout.print("{s}{s}{s}{s}", .{tag_name, equals, value, delimiter});
        }
    }
}

fn pretty_print_tag(input: []const u8) !void {
    const tag = std.fmt.parseInt(usize, input, 10) catch {
        std.debug.print("Could not parse tag", .{});
        return;
    };
    const tag_name = if (tag < tags.len) tags[tag] else input;
    try stdout.print("{s}", .{tag_name});
}

pub fn main() !void {
    const args = try parseArgs();
    const opts = args[0];
    const msg = args[1];

    defer bw.flush() catch unreachable;
    if (opts.help) {
        try stdout.print(usage, .{});
        return;
    } else if(opts.version) {
        //try stdout.print("{s}", builtin.version);
        return;
    } else if (opts.tag) {
        // TODO: translate all tags in input
        try pretty_print_tag(msg);
        return;
    }
    // TODO: Implement summary
    // TODO: Implement value

    try pretty_print_fix(msg, &opts);

    if (msg.len == 0) {
        var buffer: [1024]u8 = undefined;
        _ = try stdin.readAll(&buffer);
        try pretty_print_fix(&buffer, &opts);
    }
    try bw.flush();
}

test "parse args test" {
}

test "pretty print test" {
}
