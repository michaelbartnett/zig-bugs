const std = @import("std");
const builtin = @import("builtin");

const sokol = @import("sokol");

const app_scenelinks = @import("app013_scenelinks/app.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{.stack_trace_frames = 32}){};
    defer std.debug.assert(!gpa.deinit());

    var app013 = app_scenelinks.App.init(gpa.allocator());
    app013.run();
}
