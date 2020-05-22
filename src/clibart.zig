const std = @import("std");
const artc = @cImport({
    @cInclude("art.h");
});
const clibart = @cImport({
    @cInclude("src/clibart.c");
});
extern var show_debug: c_int;

const art = @import("art2.zig");
const ArtTree = art.ArtTree;
// const a = testing.allocator;
// var arena = std.heap.ArenaAllocator.init(testing.allocator);
// var a = &arena.allocator;
const testing = std.testing;
const a = std.heap.c_allocator;

const Lang = enum { c, z, both };

const lang = switch (clibart.LANG) {
    'c' => .c,
    'z' => .z,
    'b' => .both,
    else => unreachable,
};
const UTree = ArtTree(usize);
test "compare node keys" {
    var t: artc.art_tree = undefined;
    _ = artc.art_tree_init(&t);
    defer _ = artc.art_tree_destroy(&t);
    var ta = ArtTree(usize).init(a);
    defer ta.deinit();

    const f = try std.fs.cwd().openFile("./testdata/words.txt", .{ .read = true });
    defer f.close();

    var linei: usize = 1;
    const stream = &f.inStream();
    var buf: [512:0]u8 = undefined;
    const stopLine = 200;
    var i: usize = 0;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |*line| {
        defer i += 1;
        // if (i > stopLine) break;
        buf[line.len] = 0;
        line.len += 1;
        if (linei == stopLine) {
            std.debug.warn("", .{});
        }
        if (lang == .c or lang == .both) {
            // this prevents all inserted values from pointing to the same value
            // TODO fix leak
            const temp = try a.create(usize);
            temp.* = linei;
            const result = artc.art_insert(&t, line.ptr, @intCast(c_int, line.len), temp);
        } else if (lang == .z or lang == .both) {
            const result = try ta.insert(line.*, linei);
        }
        linei += 1;
    }

    if (lang == .c or lang == .both) {
        show_debug = 1;
        artc.art_print(&t);
    }
    if (lang == .z or lang == .both) {
        art.showLog = true;
        try ta.print();
    }
}

test "compare tree after delete" {
    var t: artc.art_tree = undefined;
    _ = artc.art_tree_init(&t);
    defer _ = artc.art_tree_destroy(&t);
    var ta = ArtTree(usize).init(a);
    // defer ta.deinit();

    const f = try std.fs.cwd().openFile("./testdata/words.txt", .{ .read = true });
    defer f.close();

    var linei: usize = 1;
    const stream = &f.inStream();
    var buf: [512:0]u8 = undefined;
    const stopLine = 400000;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |*line| {
        buf[line.len] = 0;
        line.len += 1;
        if (lang == .c or lang == .both) {
            // this prevents all inserted values from pointing to the same value
            // TODO fix leak
            const temp = try a.create(usize);
            temp.* = linei;
            const result = artc.art_insert(&t, line.ptr, @intCast(c_int, line.len), temp);
        } else if (lang == .z or lang == .both) {
            const result = try ta.insert(line.*, linei);
        }
        // if (linei == stopLine) break;
        linei += 1;
    }

    _ = try f.seekTo(0);
    linei = 1;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |*line| {
        buf[line.len] = 0;
        line.len += 1;
        if (linei == 233882) {
            if (lang == .c or lang == .both) {
                show_debug = 1;
                artc.art_print(&t);
                show_debug = 0;
            }
            if (lang == .z or lang == .both) {
                art.showLog = true;
                try ta.print();
                art.showLog = false;
            }
        }
        if (lang == .c or lang == .both) {
            const result = artc.art_delete(&t, line.ptr, @intCast(c_int, line.len));
            testing.expect(result != null);
        } else if (lang == .z or lang == .both) {
            const result = try ta.delete(line.*);
            if (result != .found) {
                std.debug.warn("\nfailed on line {}:{}\n", .{ linei, line.* });
            }
            testing.expect(result == .found);
        }
        if (linei == stopLine) break;
        linei += 1;
    }
    if (lang == .c or lang == .both) {
        show_debug = 1;
        artc.art_print(&t);
        show_debug = 0;
    }
    if (lang == .z or lang == .both) {
        art.showLog = true;
        try ta.print();
        art.showLog = false;
    }
}