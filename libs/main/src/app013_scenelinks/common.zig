const std = @import("std");
// const stb = @import("stb");
// const memory = @import("memory.zig");

pub const ImageLoadOpts = struct {
    flip_vertically: bool = true,
};

pub fn SizedAllocation(comptime T: type) type {
    return struct {
        ptr: *T,
        size: usize,
    };
}

pub const LoadImageResult = struct {
    width: c_int,
    height: c_int,
    channels: c_int,
    data: []u8,

    pub fn deinit(self: LoadImageResult) void {
        _ = self;
        // c.stbi_image_free(self.data.ptr);
    }
};

pub const Image = struct {
    width: i32,
    height: i32,
    channels: i32,

    const _alignment: comptime_int = 16;

    pub inline fn data(self: *@This()) []u8 {
        const len = @intCast(usize, self.width * self.height * self.channels);
        return @intToPtr([*]u8, @ptrToInt(self) + std.mem.alignForward(@sizeOf(Image), 16))[0..len];
    }

    pub fn loadFromMemory(allocator: std.mem.Allocator, file_data: []const u8, opts: ImageLoadOpts) !SizedAllocation(Image) {
        // var loadresult = try stb.loadImageFromMemoryAllocEx(
        //     file_data,
        //     .{ .flip_vertically = opts.flip_vertically });
        _ = file_data;
        _ = opts;
        var loadresult = std.mem.zeroInit(LoadImageResult, .{});
        defer loadresult.deinit();
        

        var storage_size = _storageSize(_alignment, loadresult.width, loadresult.height, loadresult.channels);
        var storage = try allocator.alignedAlloc(u8, _alignment, storage_size);
        var fba = std.heap.FixedBufferAllocator.init(storage);

        var result: *Image = &(try fba.allocator().allocWithOptions(Image, 1, _alignment, null))[0];
        result.width = loadresult.width;
        result.height = loadresult.height;
        result.channels = loadresult.channels;
        std.mem.copy(u8, result.data(), loadresult.data);

        // return memory.SizedAllocation(Image){
        return SizedAllocation(Image){
            .ptr = result,
            .size = storage_size,
        };
    }

    pub fn loadAlloc(allocator: std.mem.Allocator, path: []const u8) !*Image {
        return loadAllocEx(allocator, path, .{});
    }

    pub fn loadAllocEx(allocator: std.mem.Allocator, path: []const u8, opts: ImageLoadOpts) !*Image {
        var file_data = try std.fs.cwd().readFileAlloc(allocator, path, std.math.maxInt(usize));
        defer allocator.free(file_data);
        return (try loadFromMemory(allocator, file_data, opts)).ptr;
    }

    inline fn _alignedHeaderSize(comptime alignment: comptime_int) usize {
        return std.mem.alignForward(@sizeOf(Image), alignment);
    }

    inline fn _storageSize(comptime alignment: comptime_int, w: i32, h: i32, c: i32) usize {
        var data_size = @intCast(usize, w * h * c);
        const aligned_data_size = std.mem.alignForward(data_size, alignment);
        return aligned_data_size + _alignedHeaderSize(alignment);
     }

    pub fn asBytes(self: *Image) []u8 {
        const len: usize = _storageSize(_alignment, self.width, self.height, self.channels);
        return @ptrCast([*]u8, self)[0..len];
    }
};
