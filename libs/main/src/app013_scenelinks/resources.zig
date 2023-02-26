const std = @import("std");
const Allocator = std.mem.Allocator;
const type_registry = @import("type_registry.zig");
const RuntimeTypeID = @import("type_registry.zig").RuntimeTypeID;
const RuntimeType = @import("type_registry.zig").RuntimeType;
// const metautils = @import("metautils.zig");
// const memory = @import("memory.zig");
// const serialization = @import("serialization.zig");
// const imgui = @import("imgui");
// const editorui = @import("editorui.zig");
// const interface = @import("interface.zig");

// this are bad cross cutting concerns, figure out how to decouple
// const SceneEditor = @import("app.zig").SceneEditor;
// const InspectorDrawer = @import("app.zig").InspectorDrawer;

fn castPtr(comptime TDest: type, ptr: anytype) TDest {
    const target_align = comptime @alignOf(std.meta.Child(TDest));
    const align_as = if (target_align == 0)
        1
    else
        target_align;
    return @ptrCast(TDest, @alignCast(align_as, ptr));
}

pub fn NthArgTypeOrEmpty(comptime T: type, comptime fn_name: []const u8, comptime n: usize) type {
    if (comptime std.meta.trait.hasFn(fn_name)(T)) {
        return @typeInfo(@TypeOf(@field(T, fn_name))).Fn.args[n].arg_type.?;
    } else {
        return struct{};
    }
}


pub const ResourceID = enum(u32) {
    invalid = 0,
    _,

    pub fn fromString(s: []const u8) @This() {
        const result = @intToEnum(@This(), std.hash.Fnv1a_32.hash(s));
        std.debug.assert(result != .invalid);
        return result;
    }
};

const UnloadedResource = struct {
    _: u8,
};

pub const ResourceOpaqueHandle = struct {
    id: ResourceID,
    rttid: RuntimeTypeID,

    pub fn tryGetTypedHandle(self: @This(), comptime T: type) ?ResourceHandle(T) {
        const dest_rttid = RuntimeType.id(T);
        if (self.rttid == dest_rttid) {
            return ResourceHandle(T) {
                .id = self.id,
            };
        }
        return null;
    }

    pub fn getTypedHandle(self: @This(), comptime T: type) ResourceHandle(T) {
        return self.tryGetTypedHandle(T).?;
    }

    pub fn getPath(self: @This()) []const u8 {
        return Resources.getPath(self.id);
    }
};

pub fn ResourceHandle(comptime T: type) type {
    return struct {
        id: ResourceID,

        pub const invalid: ResourceHandle(T) = .{ .id = .invalid };
        pub const ResourceType = T;
        pub const UniqueTypeName = "ResourceHandle(" ++ type_registry.uniqueTypeName(T) ++ ")";

        pub const IMPLEMENTS = .{
            // interface.ifx(InspectorDrawer).implSelf(@This()),
        };

        pub fn eq(self: @This(), other: @This()) bool {
            return self.id == other.id;
        }

        pub fn equiv(self: @This(), other: anytype) bool {
            const OtherType = @TypeOf(other);
            return switch (comptime OtherType) {
                ResourceHandle(T), ResourcePin(T) => self.id == other.id,
                // *T, *const T => self.ptr == other,
                ResourceID => self.id == other,
                else => @compileError("Can't compare a " ++ @typeName(T) ++ " and a " ++ @typeName(OtherType)),
            };
        }

        pub fn tryGet(self: @This()) ?*T {
            return Resources.tryGet(ResourceType, self.id);
        }

        pub fn get(self: @This()) *T {
            return Resources.getOrReload(ResourceType, self.id);
        }

        pub fn displayStr(self: @This(), output: []u8) []u8 {
            return std.fmt.bufPrint(output, "ResourceHandle({s}) {s}#{}", .{
                @typeName(ResourceType),
                Resources.getPath(self.id),
                @enumToInt(self.id),
            }) catch unreachable;
        }

        // pub fn drawInspector(
        //     self: *@This(),
        //     editor: *SceneEditor,
        //     label: [:0]const u8,
        //     rt_type: *const type_registry.RtTypeInfo,
        // ) void {
        //     _ = rt_type;
        //     imgui.PushID_Str("resource_handle_inspector");
        //     defer imgui.PopID();

        //     imgui.Text("ResourceHandle(" ++ @typeName(T) ++ ") inspector");

        //     const path = Resources.getPath(self.id);
        //     editor.input_text_helper.copyableText(
        //         label,
        //         path
        //     );

        //     // imgui.SameLine();
        //     // if (imgui.Button("..")) {
        //     //     if (editorui.openFileDlg("json", "assets/")) |open_path| {
        //     //         // self.reassign(Resources.loadPath(ResourceType, open_path, .{}));
        //     //         // todo: handle refcounts in a way that's not easy to forget
        //     //         var new_handle = Resources.loadPath(ResourceType, open_path, .{});
        //     //         self.id = new_handle.id;
        //     //     }
        //     // }
        // }

        // pub const SerializerHooks = struct {
        //     pub fn loadFromJsonStream(
        //         dest: *ResourceHandle(T),
        //         state: *serialization.SerializerJsonLoadState,
        //     ) !void {
        //         // Expcted structure:
        //         //
        //         // { "path": "path/to/file.extension" }
        //         //

        //         // var helper = serialization.StreamHelper.init(state.recallToken(), state.stream);
        //         var helper = serialization.StreamHelper.init(state);
        //         try helper.expectObjBegin();
        //         try helper.expectProperty("path");
        //         var path = try helper.expectString();
        //         try helper.expectObjEnd();

        //         dest.* = Resources.loadPath(T, path, .{});
        //     }

        //     pub fn writeToJsonStream(
        //         self: *const ResourceHandle(T),
        //         state: *serialization.SerializerJsonWriteState,
        //     ) !void {
        //         state.jsonWriter().singleLineBegin();
        //         defer state.jsonWriter().singleLineEnd();
        //         try state.jsonWriter().objBegin();
        //         try state.jsonWriter().field("path");
        //         try state.jsonWriter().quoted(Resources.getPath(self.id));
        //         try state.jsonWriter().objEnd();
        //     }
        // };
    };
}

pub fn ResourcePin(comptime T: type ) type {
    return struct {
        id: ResourceID = .invalid,
        _ptr: ?*T = null,

        pub const ResourceType = T;
        pub const UniqueTypeName = "ResourcePin(" ++ type_registry.uniqueTypeName(T) ++ ")";

        pub const IMPLEMENTS = .{
            // interface.ifx(InspectorDrawer).implSelf(@This()),
        };

        fn init(cached_res: *Resources.CachedResource) @This() {
            std.debug.assert(cached_res.type_id == RuntimeType.id(T));
            cached_res.incRef();
            return .{
                .id = cached_res.id,
                ._ptr = cached_res.asType(T),
            };
        }

        pub fn get(self: @This()) *T {
            return if (self._ptr) |ptr|
                ptr
            else
                Resources.invalidResource(T);
        }

        pub fn setPath(self: *@This(), path: []const u8) void {
            var pin = Resources.pinPath(T, path, .{});
            std.mem.swap(@This(), self, &pin);
            pin.deinit(Resources.alloc);
        }

        pub fn setID(self: *@This(), id: ResourceID) bool {
            if (Resources.pinID(T, id, .{})) |*pin| {
                std.mem.swap(@This(), self, pin);
                pin.deinit(Resources.alloc);
                return true;
            }
            return false;
        }

        pub fn deinit(self: *@This(), alloc: Allocator) void {
            _ = alloc;
            Resources.unpin(T, self);
        }

        pub fn eq(self: @This(), other: @This()) bool {
            std.debug.assert((self.id == other.id) == (self.get() == other.get()));
            return self.id == other.id;
        }

        pub fn equiv(self: @This(), other: anytype) bool {
            const OtherType = @TypeOf(other);
            return switch (comptime OtherType) {
                ResourceHandle(T), ResourcePin(T) => self.id == other.id,
                *T, *const T => self.ptr == other,
                ResourceID => self.id == other,
                else => @compileError("Can't compare a " ++ @typeName(T) ++ " and a " ++ @typeName(OtherType)),
            };
        }

        pub fn toHandle(self: @This()) ResourceHandle(T) {
            return .{ .id = self.id };
        }

        pub fn displayStr(self: @This(), output: []u8) []u8 {
            return std.fmt.bufPrint(output, "ResourcePin({s}) {s}#{}", .{
                @typeName(ResourceType),
                Resources.getPath(self.id),
                @enumToInt(self.id),
            }) catch unreachable;
        }

        // pub fn drawInspector(
        //     self: *@This(),
        //     editor: *SceneEditor,
        //     label: [:0]const u8,
        //     rt_type: *const type_registry.RtTypeInfo,
        // ) void {
        //     _ = rt_type;
        //     imgui.PushID_Str("resource_pin_inspector");
        //     defer imgui.PopID();

        //     const path = Resources.getPath(self.id);
        //     editor.input_text_helper.copyableText(
        //         label,
        //         path
        //     );

        //     // imgui.SameLine();
        //     // if (imgui.Button("..")) {
        //     //     if (editorui.openFileDlg("json", "assets/")) |open_path| {
        //     //         // self.reassign(Resources.loadPath(ResourceType, open_path, .{}));
        //     //         // todo: handle refcounts in a way that's not easy to forget
        //     //         self.setPath(open_path);
        //     //     }
        //     // }
        // }

        // pub const SerializerHooks = struct {
        //     pub fn loadFromJsonStream(
        //         dest: *ResourcePin(T),
        //         state: *serialization.SerializerJsonLoadState,
        //     ) !void {
        //         // Expcted structure:
        //         //
        //         // { "path": "path/to/file.extension" }
        //         //

        //         // var helper = serialization.StreamHelper.init(state.recallToken(), state.stream);
        //         var helper = serialization.StreamHelper.init(state);
        //         try helper.expectObjBegin();
        //         try helper.expectProperty("path");
        //         var path = try helper.expectString();
        //         try helper.expectObjEnd();

        //         dest.* = Resources.pinPath(T, path, .{});
        //     }

        //     pub fn writeToJsonStream(
        //         self: *const ResourcePin(T),
        //         state: *serialization.SerializerJsonWriteState,
        //     ) !void {
        //         state.jsonWriter().singleLineBegin();
        //         defer state.jsonWriter().singleLineEnd();
        //         try state.jsonWriter().objBegin();
        //         try state.jsonWriter().field("path");
        //         try state.jsonWriter().quoted(Resources.getPath(self.id));
        //         try state.jsonWriter().objEnd();
        //     }
        // };
    };
}

fn deinitNoOp(_: *anyopaque, _: Allocator) void { }

// fn drawUnloadedResourceInspector(
//     self: *anyopaque,
//     editor: *SceneEditor,
//     label: [:0]const u8,
//     rt_type: *const type_registry.RtTypeInfo,
// ) void {
//     _ = self;
//     _ = rt_type;
//     editor.input_text_helper.copyableText(label, "UNLOADED RESOURCE");
// }

const ResourceHooks = struct {

    const unloaded_hooks = @This(){
        .deinit = &deinitNoOp,
        // .drawResourceHandleInspector = drawUnloadedResourceInspector,
        // .drawResourcePinInspector = drawUnloadedResourceInspector,
    };

    deinit: type_registry.DeinitFnPtr,
    // drawResourceHandleInspector: ?SceneEditor.DrawInspectorFn,
    // drawResourcePinInspector: ?SceneEditor.DrawInspectorFn,

    fn auto(comptime T: type) *const ResourceHooks {
        const Storage = struct {
            const hooks: ResourceHooks = .{
                .deinit = type_registry.DeinitFor(T).asOpaque(),
                // .drawResourceHandleInspector = SceneEditor.Generate.inspectorDrawerFor(ResourceHandle(T)),
                // .drawResourcePinInspector = SceneEditor.Generate.inspectorDrawerFor(ResourcePin(T)),
            };
        };
        return &Storage.hooks;
    }
};

const PathTable = struct {
    const StringToID = std.StringHashMap(ResourceID);
    const IDToString = std.AutoHashMap(ResourceID, []const u8);
    path_ids: StringToID,
    reverse_lookup: IDToString,

    pub fn init(alloc: Allocator) PathTable {
        return .{
            .path_ids = StringToID.init(alloc),
            .reverse_lookup = IDToString.init(alloc),
        };
    }

    pub fn deinit(self: *@This()) void {
        var key_iter = self.path_ids.keyIterator();
        while (key_iter.next()) |key| {
            self.path_ids.allocator.free(key.*);
        }

        self.reverse_lookup.deinit();
        self.path_ids.deinit();
    }

    pub fn intern(self: *@This(), path: []const u8) InternedPath {
        var norm_path = normalizePath(path);
        var gop = self.path_ids.getOrPut(norm_path) catch unreachable;
        if (!gop.found_existing) {
            const alloc = self.path_ids.allocator;
            gop.key_ptr.* = alloc.dupe(u8, norm_path) catch unreachable;
            gop.value_ptr.* = ResourceID.fromString(norm_path);
            self.reverse_lookup.put(gop.value_ptr.*, gop.key_ptr.*) catch unreachable;
        }
        return .{
            .id = gop.value_ptr.*,
            .norm_path = gop.key_ptr.*,
        };
    }

    pub fn tryLookup(self: @This(), id: ResourceID) ?InternedPath {
        return if (self.reverse_lookup.get(id)) |norm_path| InternedPath{
            .norm_path = norm_path,
            .id = id,
        }
        else
            null;
    }
};

const InternedPath = struct {
    id: ResourceID,
    norm_path: []const u8,
};


pub const ResourceUnloadCallback = fn (ctx: usize, res: ResourceOpaqueHandle) void;
pub const ResourceUnloadCallbackPtr = *const ResourceUnloadCallback;

pub const Resources = struct {
    pub const LoadedResourceIterator = struct {
        iter: ResourceMap.ValueIterator,

        pub const Entry = struct {
            handle: ResourceOpaqueHandle,
            refcount: i32,
        };

        pub fn next(self: *@This()) ?Entry {
            if (self.iter.next()) |cached| {
                return Entry{
                    .handle = cached.*.toOpaqueHandle(),
                    .refcount = cached.*.refcount,
                };
            }
            return null;
        }
    };

    threadlocal var normpath_scratch: [512]u8 = undefined;
    var alloc: Allocator = undefined;

    // var registered_types: *type_registry.NamedTypeRegistry = undefined;

    // todo: increase prealloc size later
    // Also, the SegmentedList unfortunately does exponential growth
    // A better version of this can exist
    const ResourceStorage = std.SegmentedList(CachedResource, 4);
    var resource_storage: ResourceStorage = undefined;
    var resource_free_list: i32 = -1;

    const ResourceMap = std.AutoHashMap(ResourceID, *CachedResource);
    var resource_map: ResourceMap = undefined;

    const ResourceHooksMap = std.AutoHashMap(RuntimeTypeID, *const ResourceHooks);
    var resource_hooks: ResourceHooksMap = undefined;

    const InvalidResourceMap = std.AutoHashMap(RuntimeTypeID, *CachedResource);
    var invalid_resources: InvalidResourceMap = undefined;

    const ResourceUnloadCallbackMap = std.AutoHashMap(RuntimeTypeID, std.AutoArrayHashMapUnmanaged(ResourceUnloadCallbackPtr, usize));
    var unload_callbacks: ResourceUnloadCallbackMap = undefined;

    const ResourceUnloadQueue = std.ArrayList(*CachedResource);
    var resource_unload_queue: ResourceUnloadQueue = undefined;
    var resource_unload_processing_queue: ResourceUnloadQueue = undefined;

    var path_table: PathTable = undefined;

    const AddOrReplace = enum { add, replace };

    const CachedResource = struct {
        id: ResourceID,
        free_list: i32 = -1,
        storage_index: i32,
        refcount: i32 = 0,
        type_id: RuntimeTypeID,
        norm_path: []const u8,
        hooks: *const ResourceHooks,
        data: ?[]u8,

        pub fn releaseData(self: *@This(), _alloc: Allocator) void {
            if (self.data) |slice| {
                self.hooks.deinit_fn(slice.ptr, _alloc);
                _alloc.free(slice);
            }
        }

        pub fn replaceData(self: *@This(), new_data: []u8, _alloc: Allocator) AddOrReplace {
            var result = AddOrReplace.add;
            if (self.data) |slice| {
                self.hooks.deinit(slice.ptr, _alloc);
                _alloc.free(slice);
                result = .replace;
            }
            self.data = new_data;
            return result;
        }

        pub fn deinit(self: *@This(), _alloc: Allocator) void {
            if (self.data) |slice| {
                self.hooks.deinit(slice.ptr, _alloc);
                _alloc.free(slice);
            }
            self.id = .invalid;
            self.data = null;
            // self.norm_path = "";
            self.hooks = &ResourceHooks.unloaded_hooks;
            self.type_id = RuntimeType.id(UnloadedResource);// undefined;//RuntimeType.id(void);
        }

        pub fn toResourceHandle(self: @This(), comptime T: type) ResourceHandle(T) {
            return .{ .id = self.id };
        }

        pub fn toOpaqueHandle(self: @This()) ResourceOpaqueHandle {
            return .{ .id = self.id, .rttid = self.type_id };
        }

        pub fn incRef(self: *@This()) void {
            self.refcount += 1;
        }

        pub fn decRef(self: *@This()) i32 {
            self.refcount -= 1;
            return self.refcount;
        }

        pub fn asType(self: @This(), comptime T: type) *T {
            std.debug.assert(self.type_id == RuntimeType.id(T));
            return castPtr(*T, self.data.?.ptr);
        }
    };

    pub fn startup(type_reg: *type_registry.NamedTypeRegistry, allocator: Allocator) void {
        alloc = allocator;
        path_table = PathTable.init(alloc);
        // registered_types = type_reg;
        _ = type_reg;
        resource_map = ResourceMap.init(alloc);
        resource_hooks = ResourceHooksMap.init(alloc);
        invalid_resources = InvalidResourceMap.init(alloc);
        path_table = PathTable.init(alloc);
        resource_unload_queue = ResourceUnloadQueue.init(alloc);
        unload_callbacks = ResourceUnloadCallbackMap.init(alloc);
        resource_unload_processing_queue = ResourceUnloadQueue.init(alloc);

        // _ = registered_types.ensureTypeRegistered(UnloadedResource);
    }

    pub fn shutdown() void {
        var res_iter = resource_storage.iterator(0);
        while (res_iter.next()) |res| {
            res.deinit(alloc);
        }
        resource_unload_queue.deinit();
        resource_unload_processing_queue.deinit();
        resource_map.deinit();
        resource_hooks.deinit();
        resource_storage.deinit(alloc);

        var callback_set_iter = unload_callbacks.valueIterator();
        while (callback_set_iter.next()) |callback_set| {
            callback_set.deinit(unload_callbacks.allocator);
        }
        unload_callbacks.deinit();

        invalid_resources.deinit();

        path_table.deinit();
    }

    pub fn addUnloadCallback(comptime T: type, on_unload: ResourceUnloadCallbackPtr, ctx: usize) void {
        var list_gop = unload_callbacks.getOrPut(RuntimeType.id(T)) catch unreachable;
        if (!list_gop.found_existing) {
            list_gop.value_ptr.* = .{};
        }
        const callback_set = list_gop.value_ptr;
        var set_gop = callback_set.getOrPut(unload_callbacks.allocator, on_unload) catch unreachable;
        if (set_gop.found_existing) {
            std.log.err("Double unload callback registration for type " ++ @typeName(T), .{});
            return;
        }
        set_gop.value_ptr.* = ctx;
    }

    pub fn removeUnloadCallback(comptime T: type, on_unload: ResourceUnloadCallbackPtr) void {
        if (unload_callbacks.getPtr(RuntimeType.id(T))) |callback_set| {
            if (callback_set.orderedRemove(on_unload)) {
                return;
            }
        }
        std.log.err("Tried to remove unload callback for type " ++ @typeName(T) ++ " but found none registered", .{});
    }

    pub fn processUnloadQueue() void {
        std.debug.assert(resource_unload_processing_queue.items.len == 0);
        while (resource_unload_queue.items.len > 0) {
            std.mem.swap(ResourceUnloadQueue, &resource_unload_queue, &resource_unload_processing_queue);
            for (resource_unload_processing_queue.items) |cached_res| {
                if (cached_res.refcount > 0) {
                    continue;
                }

                if (cached_res.refcount < 0) {
                    std.log.err(
                        "error in Resources.processUnloadQueue: resource decref called too many times [{s}]",
                        .{cached_res.norm_path}
                    );
                    @panic("refcount bad");
                }

                std.log.debug("Unloading {s}", .{cached_res.norm_path});
                unloadCachedResource(resource_map.getEntry(cached_res.id).?);
            }
            resource_unload_processing_queue.clearRetainingCapacity();
        }
    }

    pub fn unloadByID(id: ResourceID) void {
        if (resource_map.getEntry(id)) |kv| {
            unloadCachedResource(kv);
        }
    }

    fn unloadCachedResource(cached_res_entry: ResourceMap.Entry) void {
        const cached_res = cached_res_entry.value_ptr.*;
        // send unload callbacks
        if (unload_callbacks.get(cached_res.type_id)) |callback_set| {
            var iter = callback_set.iterator();
            while (iter.next()) |kv| {
                kv.key_ptr.*(kv.value_ptr.*, cached_res.toOpaqueHandle());
            }
        }

        resource_map.removeByPtr(cached_res_entry.key_ptr);

        // invalidate CachedResource
        const prev_free_list = resource_free_list;
        resource_free_list = cached_res.storage_index;
        cached_res.deinit(alloc);
        cached_res.free_list = prev_free_list;
    }

    pub fn lookupHandleByPtr(comptime T: type, ptr: *const T) ?ResourceHandle(T) {
        var iter = resource_storage.constIterator(0);
        const rttid = RuntimeType.id(T);
        while (iter.next()) |it| {
            if (it.data) |res_data| {
                if (it.type_id == rttid and res_data.ptr == castPtr([*]const u8, ptr)) {
                    return it.toResourceHandle(T);
                }
            }
        }
        return null;
    }

    fn ensureInvalidResourceExists(comptime T: type) *CachedResource {
        const gop = invalid_resources.getOrPut(RuntimeType.id(T)) catch unreachable;
        if (!gop.found_existing) {
            const zeroed = std.mem.zeroInit(T, .{});
            const bytes: []const u8 = @alignCast(@alignOf(u8), std.mem.asBytes(&zeroed));
            // const bytes = &[0]u8{};
            // @compileError(@typeName(@TypeOf(bytes)));
            _ = loadOrReplaceImpl(T, &gop.value_ptr, false, path_table.intern("dyn://INVALID/" ++ type_registry.uniqueTypeName(T) ++ ".json"), LoadingResourceData{ .unowned_data = bytes }, .{});
        }
        return gop.value_ptr.*;
    }

    pub fn invalidResource(comptime T: type) *T {
        return castPtr(*T, ensureInvalidResourceExists(T).data.?);
        // const gop = invalid_resources.getOrPut(RuntimeType.id(T)) catch unreachable;
        // if (!gop.found_existing) {
        //     const zeroed = std.mem.zeroInit(T, .{});
        //     const bytes: []const u8 = @alignCast(@alignOf(u8), std.mem.asBytes(&zeroed));
        //     // const bytes = &[0]u8{};
        //     // @compileError(@typeName(@TypeOf(bytes)));
        //     _ = loadOrReplaceImpl(T, &gop.value_ptr, false, path_table.intern("dyn://INVALID/" ++ type_registry.uniqueTypeName(T) ++ ".json"), LoadingResourceData{ .unowned_data = bytes }, .{});
        // }

        // return castPtr(*T, gop.value_ptr.*.data.?);        
    }

    pub fn getOrReload(comptime T: type, id: ResourceID) *T {
        if (tryGetOrReload(T, id)) |rsrc| {
            return rsrc;
        }

        return invalidResource(T);
    }

    pub fn get(comptime T: type, id: ResourceID) *T {
        if (tryGet(T, id)) |rsrc| {
            return rsrc;
        }

        return invalidResource(T);
        // const gop = invalid_resources.getOrPut(RuntimeType.id(T)) catch unreachable;
        // if (!gop.found_existing) {
        //     const zeroed = std.mem.zeroInit(T, .{});
        //     const bytes: []const u8 = @alignCast(@alignOf(u8), std.mem.asBytes(&zeroed));
        //     // const bytes = &[0]u8{};
        //     // @compileError(@typeName(@TypeOf(bytes)));
        //     _ = loadOrReplaceImpl(T, &gop.value_ptr, false, path_table.intern("dyn://INVALID/" ++ type_registry.uniqueTypeName(T) ++ ".json"), LoadingResourceData{ .unowned_data = bytes }, .{});
        // }

        // return castPtr(*T, gop.value_ptr.*.data.?);
    }

    pub fn tryGetOrReload(comptime T: type, id: ResourceID) ?*T {
        if (tryGet(T, id)) |rsrc| {
            return rsrc;
        }

        if (path_table.tryLookup(id)) |interned| {
            return get(T, Resources.loadPath(T, interned.norm_path, .{}).id);
        }
        return null;
    }

    pub fn tryGet(comptime T: type, id: ResourceID) ?*T {
        // todo: type-segregated resource tables
        if (tryGetUntyped(id)) |entry| {
            if (entry.type_id == RuntimeType.id(T)) {
                if (entry.data) |slice| {
                    return castPtr(*T, slice.ptr);
                }
            }
        }
        return null;
    }

    pub fn tryGetHooks(rttid: RuntimeTypeID) ?*const ResourceHooks {
        return resource_hooks.get(rttid);
    }

    pub fn getHooks(rttid: RuntimeTypeID) ?*const ResourceHooks {
        return resource_hooks.get(rttid).?;
    }

    fn tryGetUntyped(id: ResourceID) ?*CachedResource {
        return resource_map.get(id);
    }

    pub fn pinID(comptime T: type, id: ResourceID, opts: NthArgTypeOrEmpty(T, "loadFromMemory", 2)) ?ResourcePin(T) {
        return if (path_table.tryLookup(id)) |interned_path|
            pinImpl(T, interned_path, opts)
        else
            null;
    }

    pub fn pinPath(comptime T: type, path: []const u8, opts: NthArgTypeOrEmpty(T, "loadFromMemory", 2)) ResourcePin(T) {
        return pinImpl(T, path_table.intern(path), opts);
    }

    fn pinImpl(comptime T: type, interned_path: InternedPath, opts: anytype) ResourcePin(T) {
        const gop = resource_map.getOrPut(interned_path.id) catch unreachable;
        if (gop.found_existing) {
            return ResourcePin(T).init(gop.value_ptr.*);
        }
        var file_data = std.fs.cwd().readFileAlloc(alloc, interned_path.norm_path, std.math.maxInt(usize)) catch unreachable;
        defer alloc.free(file_data);

        var cached_res = loadOrReplaceImpl(
            T,
            &gop.value_ptr,
            gop.found_existing,
            interned_path,
            .{ .file_data = file_data },
            opts,
        );

        return ResourcePin(T).init(cached_res);
    }

    pub fn unpin(comptime T: type, pin: *ResourcePin(T)) void {
        if (pin.id != .invalid) {
            if (resource_map.get(pin.id)) |cached_res| {
                std.log.debug("Unpinning a ref for {s}, refcount={}", .{cached_res.norm_path, cached_res.refcount});
                if (0 >= cached_res.decRef()) {
                    std.log.debug("Queueing for unload {s}", .{cached_res.norm_path});
                    resource_unload_queue.append(cached_res) catch unreachable;
                }
            }
        }
        pin._ptr = null;
    }

    pub fn unloadResource(resource: anytype) void {
        // const TResource = @TypeOf(resource);
        // comptime metautils.typeCheckHasTypeDecl(TResource, "ResourceType", "expected ResourceHandle(T)");
        // comptime metautils.typeCheckEq(TResource, ResourceHandle(TResource.ResourceType), "expected ResourceHandle(T)");

        unloadByID(resource.id);
    }

    pub fn loadPath(comptime T: type, path: []const u8, opts: NthArgTypeOrEmpty(T, "loadFromMemory", 2)) ResourceHandle(T) {
        var interned_path = path_table.intern(path);
        const gop = resource_map.getOrPut(interned_path.id) catch unreachable;
        if (gop.found_existing) {
            return gop.value_ptr.*.toResourceHandle(T);
        }
        var file_data = std.fs.cwd().readFileAlloc(alloc, path, std.math.maxInt(usize)) catch unreachable;
        defer alloc.free(file_data);
        return loadOrReplaceImpl(
            T,
            &gop.value_ptr,
            gop.found_existing,
            interned_path,
            .{ .file_data = file_data },
            opts,
        ).toResourceHandle(T);
    }

    pub fn loadMemory(comptime T: type, path: []const u8, file_data: []const u8, opts: NthArgTypeOrEmpty(T, "loadFromMemory", 2)) ResourceHandle(T) {
        var interned_path = path_table.intern(path);
        var gop = resource_map.getOrPut(interned_path.id) catch unreachable;
        return loadOrReplaceImpl(
            T,
            gop.value_ptr,
            gop.found_existing,
            interned_path,
            .{ .file_data = file_data },
            opts,
        ).toResourceHandle(T);
    }

    const LoadingResourceData = union(enum) {
        file_data: []const u8,
        owned_data: []u8, // gives ownership to resource cache
        unowned_data: []const u8, // makes a copy
    };

    fn getResourceData(comptime T: type, interned_path: InternedPath, res_data: LoadingResourceData, opts: anytype) ?[]u8 {
        var result = switch (res_data) {
            .file_data => |file_data| blk: {
                // if (comptime metautils.hasFnWithSig(T, "loadFromMemory", &[_]type{ Allocator, []const u8, @TypeOf(opts) })) {
                if (comptime @hasDecl(T, "loadFromMemory") and @typeInfo(@TypeOf(T.loadFromMemory)) == .Fn) {
                    var loaded_data = T.loadFromMemory(alloc, file_data, opts) catch unreachable;
                    // explicit type annotation required because of compiler bug
                    var slice: []u8 = std.mem.asBytes(loaded_data.ptr);
                    // if (comptime @TypeOf(loaded_data) == memory.SizedAllocation(T)) {
                    //     slice.len = loaded_data.size;
                    // }
                    const result: []u8 = slice;
                    break :blk result;
                } else {
                    if (std.ascii.endsWithIgnoreCase(interned_path.norm_path, ".json")) {
                        var storage = alloc.create(T) catch unreachable;
                        // serialization.loadFromJson(T, storage, file_data, alloc) catch unreachable;
                        // alignCast required because of compiler bug
                        const result: []u8 = @alignCast(@alignOf(u8), std.mem.asBytes(storage));
                        break :blk result;
                    }
                }
                break :blk null;
            },
            .owned_data => |bytes| bytes,
            .unowned_data => |bytes| alloc.dupe(u8, bytes) catch unreachable,
        };
        return result;
    }

    fn loadOrReplaceImpl(
        comptime T: type,
        value_ptr: *const **CachedResource,
        had_existing: bool,
        // gop: ResourceMap.GetOrPutResult,
        interned_path: InternedPath,
        res_data: LoadingResourceData,
        // file_data: []const u8,
        opts: anytype,
    ) *CachedResource {
    // ResourceHandle(T) {
        // const had_existing = gop.found_existing;
        if (!had_existing) {
            // this will be slow, pre-register hooks
            const hooks = (resource_hooks.getOrPutValue(RuntimeType.id(T), ResourceHooks.auto(T)) catch unreachable).value_ptr.*;

            var storage_index: i32 = -1;
            if (resource_free_list < 0) {
                value_ptr.*.* = resource_storage.addOne(alloc) catch unreachable;
                storage_index = @intCast(i32, resource_storage.len - 1);
            } else {
                storage_index = resource_free_list;
                value_ptr.*.* = resource_storage.at(@intCast(usize, resource_free_list));
                resource_free_list = value_ptr.*.*.free_list;                
            }

            value_ptr.*.*.* = CachedResource{
                .id = interned_path.id,
                .storage_index = storage_index,
                .type_id = RuntimeType.id(T),
                .norm_path = interned_path.norm_path,
                .hooks = hooks,
                .data = null,
            };
        }

        // _ = registered_types.ensureTypeRegistered(T);

        const cached_resource: *CachedResource = value_ptr.*.*;
        var new_data: ?[]u8 = getResourceData(T, interned_path, res_data, opts);
        if (new_data) |valid_data| {
            _ = cached_resource.replaceData(valid_data, alloc);
            return cached_resource;
        } else {
            if (!had_existing) {
                _ = resource_map.remove(interned_path.id);
            }
            return ensureInvalidResourceExists(T);
        }
    }

    pub fn getPath(id: ResourceID) []const u8 {
        if (tryGetUntyped(id)) |res| {
            return res.norm_path;
        }
        return "invalid";
    }

    pub fn iterator() LoadedResourceIterator {
        return .{
            .iter = resource_map.valueIterator(),
        };
    }

    pub fn getStats() ResourcesStats {
        return .{
            .num_loaded = resource_map.count(),
            .num_invalids = invalid_resources.count(),
            .storage_len = resource_storage.len,
        };
    }
};

pub const ResourcesStats = struct {
    num_loaded: u32,
    num_invalids: u32,
    storage_len: usize,
};

fn normalizePath(path: []const u8) []u8 {
    var fba = std.heap.FixedBufferAllocator.init(&Resources.normpath_scratch);
    var relpath = if (std.mem.startsWith(u8, path, "dyn://")) (fba.allocator().dupe(u8, path) catch unreachable) else std.fs.path.relative(fba.allocator(), ".", path) catch unreachable;
    std.mem.replaceScalar(u8, relpath, '\\', '/');
    // std.log.info("relpath.len is {}, addr={*}, scratch_addr={*} Relpath={s}", .{relpath.len, relpath.ptr, &normpath_scratch[0], relpath});
    var output = fba.allocator().alloc(u8, relpath.len) catch unreachable;
    return std.ascii.lowerString(output, relpath);
}
