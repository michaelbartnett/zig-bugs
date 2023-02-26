const builtin = @import("builtin");
const std = @import("std");
const sokol = @import("sokol");
const sgfx = sokol.gfx;
// const sdtx = sokol.debugtext;
// const sokol_imgui = @import("sokol_imgui");
// const imgui = @import("imgui");
// const shaders = @import("shaders");
// const m = @import("gamemath");
// const Keycode = sokol.app.Keycode;
// const KeystateMap = blk: {
//     @setEvalBranchQuota(1144);
//     break :blk std.enums.EnumArray(Keycode, bool);
// };
const Allocator = std.mem.Allocator;
// const Rgba8 = @import("color.zig").Rgba8;
// const Storage = @import("storage.zig").Storage;
const type_registry = @import("type_registry.zig");
// const type_attributes = @import("type_attributes.zig");
// const RuntimeTypeID = type_registry.RuntimeTypeID;
const RuntimeType = type_registry.RuntimeType;
// const TypeNameID = type_registry.TypeNameiD;
// const NamedTypeRegistry = type_registry.NamedTypeRegistry;
const Image = @import("common.zig").Image;
// const ecs = @import("ecs");
// const metautils = @import("metautils.zig");
// const serialization = @import("serialization.zig");
// const gamemath_serializers = @import("gamemath_serializers.zig");
// const memory = @import("memory.zig");
// const String = @import("string.zig").String;
// const interface = @import("interface.zig");

const resources = @import("resources.zig");
// const ResourceHandle = resources.ResourceHandle;
const ResourcePin = resources.ResourcePin;
const ResourceID = resources.ResourceID;
const Resources = resources.Resources;
// const debug = @import("debug.zig");
// const algo = @import("algo.zig");
// const generic = @import("generic.zig");
// const nfd = @import("nfd");
// const editorui = @import("editorui.zig");

const ThisModule = @This();

// fn appName() []const u8 {
//     return std.fs.path.basename(std.fs.path.dirname(@src().file).?);
// }

pub const App = struct {
    app_desc: sokol.app.Desc = .{
        // .init_cb = &onAppInit,
        // .frame_cb = &onAppFrame,
        // .cleanup_cb = &onAppCleanup,
        // .event_cb = &onAppEvent,
        // .width = 800,
        // .height = 600,
        // .window_title = appName().ptr,
        // .enable_clipboard = true,
        // .clipboard_size = 1024 * 1024, // a whole meg of clipboard space baybee
    },
    // alloc: Allocator,

    pub fn init(alloc: Allocator) @This() {
        globals.postInit(alloc);

        return .{
            // .alloc = alloc,
        };
    }

    pub fn run(self: *@This()) void {
        self.app_desc.user_data = @ptrCast(*anyopaque, self);
        sokol.app.run(self.app_desc);
    }

    // pub fn get() *@This() {
    //     return @ptrCast(*@This(), @alignCast(@alignOf(@This()), sokol.app.userdata().?));
    // }
};


// const GfxBufferPool = struct {
//     buffers: std.ArrayList(sgfx.Buffer),
//     next: usize = 0,
//     buffer_desc: sgfx.BufferDesc = .{},

//     pub fn init(alloc: Allocator) @This() {
//         return .{
//             .buffers = std.ArrayList(sgfx.Buffer).init(alloc),
//         };
//     }

//     pub fn deinit(self: *@This()) void {
//         self.buffers.deinit();
//     }

//     fn destroyBuffers(self: *@This()) void {
//         for (self.buffers.items) |buffer| {
//             sgfx.destroyBuffer(buffer);
//         }
//         self.buffers.clearRetainingCapacity();
//         self.next = 0;
//     }

//     pub fn updateDesc(self: *@This(), desc: sgfx.BufferDesc) void {
//         self.destroyBuffers();
//         self.buffer_desc = desc;
//     }

//     pub fn releaseAll(self: *@This()) void {
//         self.next = 0;
//     }

//     pub fn acquire(self: *@This()) sgfx.Buffer {
//         std.debug.assert(self.next <= self.buffers.items.len);

//         if (self.next == self.buffers.items.len) {
//             std.log.info("allocating new buffer with size={}", .{self.buffer_desc.size});
//             self.buffers.append(sgfx.makeBuffer(self.buffer_desc)) catch unreachable;
//         }

//         self.next += 1;
//         return self.buffers.items[self.next - 1];
//     }
// };

// const DrawState = struct {
//     shader: sgfx.Shader = .{},
//     vbuffer: sgfx.Buffer = .{},
//     ibuffer: sgfx.Buffer = .{},
//     // inst_vbuffer_pool: GfxBufferPool = undefined,
//     num_elements: u32 = 0,

//     pipeline: sgfx.Pipeline = .{},

//     pipeline_dirty: bool = false,

//     fn initSelf(self: *@This(), alloc: Allocator) void {
//         _ = self;
//         _ = alloc;
//         // self.inst_vbuffer_pool = GfxBufferPool.init(alloc);
//     }

//     fn deinit(self: *@This()) void {
//         _ = self;
//         // self.inst_vbuffer_pool.deinit();
//     }

//     fn resetPipeline(self: *@This()) void {
//         std.log.info("RESETTING PIPELINE", .{});
//         var pipeline_desc = sgfx.PipelineDesc{
//             .index_type = .UINT16,
//             .shader = self.shader,
//             .cull_mode = globals.cull,
//         };

//         pipeline_desc.colors[0] = .{
//             .blend = .{
//                 .enabled = true,
//                 .src_factor_rgb = .SRC_ALPHA,
//                 .src_factor_alpha = .SRC_ALPHA,
//                 .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
//                 .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
//             },
//         };

//         pipeline_desc.layout.attrs[shaders.universalsprite.ATTR_vs_st_pos] = .{
//             .format = .FLOAT3,
//             .buffer_index = 0,
//         };
//         pipeline_desc.layout.attrs[shaders.universalsprite.ATTR_vs_st_uv_factor] = .{
//             .format = .FLOAT4,
//             .buffer_index = 0,
//         };

//         pipeline_desc.layout.attrs[shaders.universalsprite.ATTR_vs_inst_world2d_from_vertex2d_0] = .{
//             .format = .FLOAT3,
//             .buffer_index = 1,
//         };
//         pipeline_desc.layout.attrs[shaders.universalsprite.ATTR_vs_inst_world2d_from_vertex2d_1] = .{
//             .format = .FLOAT3,
//             .buffer_index = 1,
//         };
//         pipeline_desc.layout.attrs[shaders.universalsprite.ATTR_vs_inst_world2d_from_vertex2d_2] = .{
//             .format = .FLOAT3,
//             .buffer_index = 1,
//         };

//         // pipeline_desc.layout.attrs[shaders.universalsprite.ATTR_vs_inst_world2d_from_vertex2d] = .{
//         //     .format = .FLOAT3,
//         //     .buffer_index = 1,
//         // };
//         // pipeline_desc.layout.attrs[shaders.universalsprite.ATTR_vs_inst_world2d_from_vertex2d + 1] = .{
//         //     .format = .FLOAT3,
//         //     .buffer_index = 1,
//         // };
//         // pipeline_desc.layout.attrs[shaders.universalsprite.ATTR_vs_inst_world2d_from_vertex2d + 2] = .{
//         //     .format = .FLOAT3,
//         //     .buffer_index = 1,
//         // };

//         pipeline_desc.layout.attrs[shaders.universalsprite.ATTR_vs_inst_size_pivot] = .{
//             .format = .FLOAT4,
//             .buffer_index = 1,
//         };
//         pipeline_desc.layout.attrs[shaders.universalsprite.ATTR_vs_inst_uvrect] = .{
//             .format = .FLOAT4,
//             .buffer_index = 1,
//         };
//         pipeline_desc.layout.attrs[shaders.universalsprite.ATTR_vs_inst_depth] = .{
//             .format = .FLOAT,
//             .buffer_index = 1,
//         };
        
//         pipeline_desc.layout.buffers[1] = .{
//             .step_func = .PER_INSTANCE,
//         };
//         self.pipeline = sgfx.makePipeline(pipeline_desc);
//     }
// };

// const Camera = struct {
//     position: m.Vec2f = .{},
//     zoom: f32 = 1,
// };

// const WindowState = enum {
//     open,
//     minimized,
// };

const Globals = struct {
    const test_scene_path = "assets/test_write_scene.scn";

    alloc: Allocator = undefined,
    // pass_action: sgfx.PassAction = .{},
    // scroll: m.Vec3f = .{},
    // rotate: f32 = 0,
    // spritescale: m.Vec2f = m.Vec2f.one,
    // tilescale: m.Vec2f = m.Vec2f.one,
    // tilerotate: f32 = 0,
    // keystate: [sokol.app.max_keycodes]bool = [1]bool{false} ** sokol.app.max_keycodes,
    // keystate: KeystateMap = KeystateMap.initFill(false),
    // time_ticks: u64 = 0,
    // dt_ticks: u64 = 0,
    // w2p: m.Mat4f = m.Mat4f.identity,
    // window_size: m.Vec2f = undefined,
    // window_state: WindowState = .open,

    // cam_ortho_size: m.Vec2f = undefined,
    // cam_zoom: f32 = 0,
    // cam_zoom: f32 = 1,
    // cam_zoom_max: f32 = 10,
    // cam_zoom_min: f32 = 0,
    // cam_pos: m.Vec2f = .{},
    // cull: sgfx.CullMode = .DEFAULT,
    // draw_state: DrawState = .{},
    // modifiers: u32 = 0,
    // show_imgui_demo: bool = false,
    // menubar: MainMenuBar = .{},
    // scene_editor: SceneEditor = undefined,

    // entities: EntityManager = undefined,
    // texcache: TextureCache = undefined,
    sprite_render_globals: SpriteRenderGlobals = undefined,
    // registered_types: NamedTypeRegistry = undefined,
    // scene_loader: SceneLoader = undefined,

    // pub fn preInit(self: *@This(), alloc: Allocator) void {
    //     self.registered_types = NamedTypeRegistry.init(alloc);        
    // }

    pub fn postInit(self: *@This(), alloc: Allocator) void {
        // self.alloc = alloc;
        // self.draw_state.initSelf(alloc);
        // const app = App.get();
        // _ = app;
        // self.window_size = m.vec2f(app.app_desc.width, app.app_desc.height);
        // self.cam_ortho_size = self.window_size;
        // self.texcache = TextureCache.init(alloc);

        // self.sprite_render_globals.initSelf(alloc, &self.texcache);
        self.sprite_render_globals.initSelf(alloc);

        // self.entities = EntityManager.init(alloc);
        // self.scene_loader = SceneLoader.init(&self.entities);
        // self.scene_editor = SceneEditor.init(alloc);
    }

    // pub fn deinit(self: *@This()) void {
    //     // self.scene_editor.deinit();
    //     // self.scene_loader.deinit();
    //     // self.entities.deinit();

    //     // self.draw_state.deinit();
    //     // self.sprite_render_globals.deinit();
    //     // self.texcache.deinit();

    //     // self.registered_types.deinit();
    //     _ = self;
    // }

    // pub fn drawImGui(self: *@This()) void {
    //     _ = self;
    //     // if (imgui.Begin("Globals Debugger")) {
    //     //     _ = imgui.DragFloat2("Sprite Scale", self.spritescale.array());
    //     //     _ = imgui.DragFloat("Sprite Rotate", &self.rotate);
    //     //     _ = imgui.DragFloat2("Tile Scale", self.tilescale.array());
    //     //     _ = imgui.DragFloat("Tile Rotate", &self.tilerotate);
    //     // }
    //     // imgui.End();
    // }
};

pub const SpriteRenderGlobals = struct {
    // texcache: *TextureCache,
    // spritedesc_frames_cache: std.AutoHashMap(ResourceID, []sgfx.Image),
    spritedesc_frames_cache: std.AutoHashMap(u32, []sgfx.Image),

    // pub fn initSelf(self: *@This(), alloc: Allocator, texcache: *TextureCache) void {
    pub fn initSelf(self: *@This(), alloc: Allocator) void {
        // _ = texcache;
        self.* = .{
            // .texcache = texcache,
            // .spritedesc_frames_cache = std.AutoHashMap(ResourceID, []sgfx.Image).init(alloc),
            .spritedesc_frames_cache = std.AutoHashMap(u32, []sgfx.Image).init(alloc),
        };
        Resources.addUnloadCallback(SpriteDesc, onResourceUnload, @ptrToInt(self));
        Resources.addUnloadCallback(Image, onResourceUnload, @ptrToInt(self));
    }

    fn onResourceUnload(ctx: usize, res: resources.ResourceOpaqueHandle) void {
        var self = @intToPtr(*@This(), ctx);

        // std.log.info("Got unload callback for {s}: {s}", .{globals.registered_types.lookupByRttid(res.rttid).name, res.getPath()});

        switch (res.rttid) {
            RuntimeType.id(SpriteDesc) => {
                const alloc = &self.spritedesc_frames_cache.allocator;
                if (self.spritedesc_frames_cache.fetchRemove(@enumToInt(res.id))) |kv| {
                    alloc.free(kv.value);
                }
            },
            RuntimeType.id(Image) => {},//self.texcache.purge(res.getTypedHandle(Image)),
            else => {},
        }
    }

    // pub fn textureHandlesForSprite(self: *@This(), desc: ResourceHandle(SpriteDesc)) ![]sgfx.Image {
    //     var gop = try self.spritedesc_frames_cache.getOrPut(desc.id);

    //     if (!gop.found_existing) {
    //         const alloc = &self.spritedesc_frames_cache.allocator;
    //         const desc_data: *const SpriteDesc = desc.get();

    //         errdefer gop.value_ptr.* =  &.{};

    //         gop.value_ptr.* = try alloc.alloc(sgfx.Image, desc_data.frames.len);

    //         errdefer alloc.free(gop.value_ptr.*);

    //         var frame_textures = gop.value_ptr.*;
    //         for (desc_data.frames) |frame, i| {
    //             frame_textures[i] = self.texcache.getOrUpload(frame.atlas.toHandle());
    //         }
    //         gop.value_ptr.* = frame_textures;            
    //     }

    //     return gop.value_ptr.*; 
    // }

    // pub fn deinit(self: *@This()) void {
    //     Resources.removeUnloadCallback(SpriteDesc, &onResourceUnload);
    //     Resources.removeUnloadCallback(Image, &onResourceUnload);

    //     var alloc = &self.spritedesc_frames_cache.allocator;
    //     var iter = self.spritedesc_frames_cache.iterator();
    //     while (iter.next()) |entry| {
    //         alloc.free(entry.value_ptr.*);
    //     }
    //     self.spritedesc_frames_cache.deinit();
    // }
};

// const ResourceDebugger = struct {
//     pub fn drawImGui() void {
//         defer imgui.End();
//         if (imgui.Begin("Resource Debugger")) {
//             var stats = Resources.getStats();
//             _ = imgui.InputScalar(
//                 "num_loaded",
//                 .U32,
//                 &stats.num_loaded,
//             );

//             _ = imgui.InputScalar(
//                 "num_invalids",
//                 .U32,
//                 &stats.num_invalids,
//             );

//             _ = imgui.InputScalar(
//                 "storage_len",
//                 .U64,
//                 &stats.storage_len,
//             );

//             var iter = Resources.iterator();
//             while (iter.next()) |entry| {
//                 const rtti = globals.registered_types.lookupByRttid(entry.handle.rttid);
//                 const res_path = entry.handle.getPath();
//                 imgui.Text(
//                     "%s: %.*s",
//                     rtti.name.ptr,
//                     res_path.len,
//                     res_path.ptr,
//                 );
//                 imgui.Text("\trefcount: %i", entry.refcount);
//             }

//             if (imgui.Button("Unload all")) {
//                 iter = Resources.iterator();
//                 while (iter.next()) |entry| {
//                     Resources.unloadByID(entry.handle.id);
//                 }
//             }
//         }
//     }
// };

// const MainMenuBar = struct {
//     visible: bool = true,

//     pub fn toggle(self: *@This()) void {
//         self.visible = !self.visible;
//     }

//     pub fn drawImGui(self: *@This()) void {
//         _ = self;
//         // if (self.visible and imgui.BeginMainMenuBar()) {
//         //     // first line of the on-screen debug text can get blocked by the menu bar
//         //     sdtx.crlf();

//         //     if (imgui.MenuItem_Bool("New Scene")) {
//         //         globals.entities.destroyAllEntities();
//         //     }
//         //     if (imgui.MenuItem_Bool("Save Scene")) {
//         //         if (editorui.saveFileDlg("scn", "assets/")) |save_path| {
//         //             const scene_json = globals.scene_loader.writeSceneToJsonString();
//         //             defer globals.scene_loader.entity_manager.allocator().free(scene_json);
//         //             std.fs.cwd().writeFile(save_path, scene_json) catch unreachable;
//         //             std.log.info("Wrote scene to {s}", .{save_path});
//         //         }

//         //         // var pathbuf: [255:0]u8 = undefined;
//         //         // const assets_path = std.fs.cwd().realpath("assets/", &pathbuf) catch unreachable;
//         //         // pathbuf[assets_path.len] = 0;
//         //         // const assets_path_z = @ptrCast([:0]u8, assets_path);
                
//         //         // if (nfd.saveFileDialog("scn", assets_path_z) catch unreachable) |save_path| {
//         //         //     defer nfd.freePath(save_path);
//         //         //     const scene_json = globals.scene_loader.writeSceneToJsonString();
//         //         //     defer globals.scene_loader.entity_manager.allocator().free(scene_json);
//         //         //     std.fs.cwd().writeFile(save_path, scene_json) catch unreachable;
//         //         //     std.log.info("Wrote scene to {s}", .{save_path});
//         //         // }
//         //     }

//         //     if (imgui.MenuItem_Bool("Load Scene")) {
                
//         //         // var pathbuf: [255:0]u8 = undefined;
//         //         // const assets_path = std.fs.cwd().realpath("assets/", &pathbuf) catch unreachable;
//         //         // pathbuf[assets_path.len] = 0;
//         //         // const assets_path_z = @ptrCast([:0]u8, assets_path);

//         //         if (editorui.openFileDlg("scn", "assets/")) |open_path| {
//         //             // if (nfd.openFileDialog("scn", assets_path_z) catch unreachable) |open_path| {
//         //             // defer nfd.freePath(open_path);
//         //             globals.entities.destroyAllEntities();
//         //             setupAppendSceneFromJsonFile(globals.alloc, open_path);
//         //         }
//         //     }
            
//         //     if (imgui.MenuItem_Bool("Add Example Entities")) {
//         //         setupAppendSceneFromJsonStringLiteral();
//         //         std.log.info("Loaded scene from test json literal", .{});
//         //     }

//         //     imgui.Text("(F12 to toggle this menu bar)");

//         //     imgui.EndMainMenuBar();
//         // }

//     }
// };

// const ComponentSelection = struct {
//     entity: ecs.Entity, // handle
//     component: RuntimeTypeID,

//     pub fn init(e: ecs.Entity, rttid: RuntimeTypeID) @This() {
//         return .{
//             .entity = e,
//             .component = rttid,
//         };
//     }

//     pub fn matches(self: @This(), entity: ecs.Entity, component: RuntimeTypeID) bool {
//         return self.entity == entity and self.component == component;
//     }
// };

// const EditorSelection = union(enum) {
//     component: ComponentSelection,
//     entity: ecs.Entity,
//     nothing: void,

//     pub fn isEntity(self: @This(), e: ecs.Entity) bool {
//         return self == .entity and self.entity == e;
//     }

//     pub fn isComponent(self: @This(), e: ecs.Entity, rttid: RuntimeTypeID) bool {
//         return self == .component and self.component.entity == e and self.component.component == rttid; 
//     }
// };

// pub const SimpleSlice1 = struct {
//     ptr: [*]const u8,
//     len: usize,
// };

// pub const InspectorDrawer = struct {
//     data: interface.Pointer(@This()),

//     pub fn drawInspector(
//         self: *@This(),
//         editor: *SceneEditor,
//         label: [:0]const u8,
//         rt_type: *const type_registry.RtTypeInfo,
//     ) void {
//         return self.data.call3(.drawInspector, editor, label, rt_type);
//     }
// };

// pub const SceneEditor = struct {
//     // selection: std.ArrayList(EditorSelection),
//     selection: EditorSelection = .nothing,
//     open_nodes: i32 = 0,
    // input_text_helper: editorui.InputTextHelper,

//     pub fn DrawInspectorFnType(comptime T: type) type {
//         return fn (
//             self: *T,
//             editor: *SceneEditor,
//             label: [:0]const u8,
//             rt_type: *const type_registry.RtTypeInfo,
//         ) void;
//     }
//     pub const DrawInspectorFn = DrawInspectorFnType(anyopaque);
//     pub const DrawInspectorFnPtr = *const DrawInspectorFn;

//     pub const Generate = struct {
//         pub fn inspectorDrawerFor(comptime T: type) ?DrawInspectorFn {
//             if (comptime std.meta.trait.isContainer(T) and @hasDecl(T, "drawInspector")) {
//                 const DrawInspectorType = @TypeOf(T.drawInspector);
//                 if (DrawInspectorType == DrawInspectorFnType(T)) {
//                     return @ptrCast(DrawInspectorFn, T.drawInspector);
//                 }
//             } else if (type_attributes.get(T, "COMPONENT.drawInspector", DrawInspectorFnType(T))) |draw_inspector_fn| {
//                 return @ptrCast(DrawInspectorFn, draw_inspector_fn.*);
//             }

//             return null;
//         }
//     };

//     // pub fn init(alloc: Allocator) SceneEditor {
//     //     return SceneEditor{
//     //         .selection = 
//     //     }
//     // }

//     pub const InspectorVisibility = enum {
//         visible,
//         hidden,
//     };

    fn init(alloc: Allocator) @This() {
        _ = alloc;
        return .{
            // .input_text_helper = editorui.InputTextHelper.init(alloc),
        };
    }

    pub fn deinit(self: @This()) void {
        _ = self;
        // self.input_text_helper.deinit();
    }

//     fn drawBeginEntity(self: *@This(), entity: ecs.Entity) bool {
//         var treenode_flags = imgui.TreeNodeFlags{
//             .Selected = self.selection.isEntity(entity),
//             .OpenOnArrow = true,
//             .OpenOnDoubleClick = true,
//             .SpanFullWidth = true,
//         };

//         const node_open = imgui.TreeNodeEx_StrStr("entity_node", treenode_flags.toInt(), "Entity#%u", .{entity});
//         const node_clicked = imgui.IsItemClicked() and !imgui.IsItemToggledOpen();
//         if (node_clicked) {
//             if (treenode_flags.Selected) {
//                 self.selection = .nothing;
//             } else {
//                 self.selection = .{.entity = entity};
//             }
//         }

//         if (node_open) {
//             self.open_nodes += 1;
//         }
//         return node_open;
//     }

//     fn drawEndEntity(self: *@This()) void {
//         if (self.open_nodes > 0) {
//             imgui.TreePop();
//             self.open_nodes -= 1;
//         }
//     }

//     fn drawEntityComponents(self: *@This(), entity: ecs.Entity) void {
//         var iter = globals.entities.entityComponentsIterator(entity);
//         while (iter.next()) |rttidptr| {
//             imgui.PushID_Ptr(@intToPtr(?*anyopaque, rttidptr.tid.toInt()));
//             defer imgui.PopID();

//             var treenode_flags = imgui.TreeNodeFlags{
//                 .Selected = self.selection.isComponent(entity, rttidptr.tid),
//                 .OpenOnArrow = true,
//                 .OpenOnDoubleClick = true,
//                 .SpanFullWidth = true,
//                 .Bullet = true,
//                 .Leaf = true,
//             };

//             const name = globals.registered_types.tryLookupByRttid(rttidptr.tid).?.name;

//             const node_open = imgui.TreeNodeEx_StrStr("component_node", treenode_flags.toInt(), "Component: %s", name.ptr);

//             const node_clicked = imgui.IsItemClicked() and !imgui.IsItemToggledOpen();
//             if (node_clicked) {
//                 if (treenode_flags.Selected) {
//                     self.selection = .nothing;
//                 } else {
//                     self.selection = .{.component = ComponentSelection.init(entity, rttidptr.tid)};
//                 }
//             }

//             if (node_open){
//                 imgui.TreePop();
//             }            
//         }        
//     }

//     pub fn drawEntityListImGui(self: *@This()) void {
//         if (imgui.Begin("Scene Editor - Entity List")) {
//             var iter = globals.entities.entities();
//             while (iter.next()) |entity| {
//                 imgui.PushID_Int(@bitCast(i32, entity));
//                 defer imgui.PopID();

//                 const entity_expanded = self.drawBeginEntity(entity);
//                 defer self.drawEndEntity();

//                 if (entity_expanded) {
//                     self.drawEntityComponents(entity);
//                 }

//                 // var name_label: []const u8 = "[NO NAME]";
//                 // if (globals.entities.tryGet(NameComponent, entity)) |name_comp| {
//                 //     name_label = name_comp.name;
//                 // }
//                 // _ = imgui.Text("Entity id=%u, name=%s", entity, name_label.ptr);
//             }

//             self.validateSelection();

//             if (imgui.Button("+")) {
//                 _ = globals.entities.createEntity();
//             }
//             imgui.SameLine();
//             imgui.BeginDisabledExt(self.selection == .nothing);
//             defer imgui.EndDisabled();
//             if (imgui.Button("-")) {
//                 switch (self.selection) {
//                     .entity => |entity| {
//                         globals.entities.destroyEntity(entity);
//                     },
//                     .component => |comp_sel| {
//                         _ = globals.entities.remove(comp_sel.component, comp_sel.entity);
//                     },
//                     .nothing => {},
//                 }
//             }
//         }

//         std.debug.assert(self.open_nodes == 0);

//         imgui.End();
//     }

//     pub fn drawEntityInspectorImGui(self: *@This(), e: ecs.Entity) void {
//         imgui.TextUnformatted("Entity");
//         imgui.LabelText("id", "%u", e);

//         imgui.SetNextItemOpen(true);
//         if (imgui.TreeNode_StrStr("complist", "Components")) {
//             var iter = globals.entities.entityComponentsIterator(e);
//             while (iter.next()) |rttidptr| {
//                 imgui.PushID_Ptr(@intToPtr(?*anyopaque, rttidptr.tid.toInt()));
//                 defer imgui.PopID();

//                 const comp_name = globals.registered_types.tryLookupByRttid(rttidptr.tid).?.name;

//                 if (imgui.Button(@ptrCast([*:0]const u8, comp_name))) {
//                     self.selection = .{ .component = ComponentSelection.init(e, rttidptr.tid) };
//                 }
//             }            

//             imgui.TreePop();
//         }

//         const add_component_popup_id = "add_component_popup";
//         if (imgui.Button("+")) {
//             imgui.OpenPopup_Str(add_component_popup_id);
//         }
//         if (imgui.BeginPopup(add_component_popup_id)) {
//             imgui.Text("Choose component");
//             imgui.Separator();
//             var it = globals.entities.registeredComponentsIterator();
//             var selected: ?RuntimeTypeID = null;
//             while (it.next()) |comp_tid| {
//                 if (globals.entities.tryGetOpaque(comp_tid.*, e) == null) {
//                     const comp_rtti = globals.registered_types.lookupByRttid(comp_tid.*);
//                     if (imgui.Selectable_Bool(comp_rtti.name)) {
//                         selected = comp_tid.*;
//                     }
//                 }
//             }
//             imgui.EndPopup();

//             if (selected) |comp_tid| {
//                 _ = globals.entities.getOrAddZeroInitOpaque(comp_tid, e);
//             }
//         }
//     }

//     pub fn drawInspectorForStruct(
//         self: *@This(),
//         label: [:0]const u8,
//         ptr: *anyopaque,
//         rt_type: *const type_registry.RtTypeInfo,
//         rt_struct: *const type_registry.RtContainerInfo,
//     ) void {
//         imgui.SetNextItemOpenExt(true, imgui.CondFlags{.Once = true});
//         if (imgui.TreeNode_StrStr(label, "%.*s: %.*s", label.len, label.ptr, rt_type.name.len, rt_type.name.ptr)) {
//             for (rt_struct.fields) |f| {
//                 const show_field = if (f.tryGetAttributeOfType(InspectorVisibility)) |visibility| switch (visibility.*) {
//                     .visible => true,
//                     .hidden => false,
//                 } else true;

//                 if (show_field) {
//                     self.drawInspectorForType(f.name, f.access(ptr), f.type_info);
//                 }
//             }
//             imgui.TreePop();
//         }        
//     }

//     pub fn drawInspectorForArray(
//         self: *@This(),
//         label: [:0]const u8,
//         ptr: *anyopaque,
//         rt_type: *const type_registry.RtTypeInfo,
//         rt_array: *const type_registry.RtArrayInfo,
//     ) void {
//         imgui.SetNextItemOpenExt(true, imgui.CondFlags{.Once = true});
//         if (imgui.TreeNode_StrStr(label, "%.*s: %.*s", label.len, label.ptr, rt_type.name.len, rt_type.name.ptr)) {
//             var label_buf: [31:0]u8 = undefined;
//             var i: usize = 0;
//             while (i < rt_array.len) : (i += 1) {
//                 const idx_label = std.fmt.bufPrintZ(&label_buf, "[{}]", .{i}) catch unreachable;
//                 const elem_ptr = rt_array.access(ptr, i);
//                 self.drawInspectorForType(idx_label, elem_ptr, rt_array.child);
//             }

//             imgui.TreePop();
//         }
//     }

//     pub fn drawInspectorForSlice(
//         self: *@This(),
//         label: [:0]const u8,
//         ptr: *anyopaque,
//         rt_type: *const type_registry.RtTypeInfo,
//         rt_slice: *const type_registry.RtSliceInfo,
//     ) void {
//         const slice_len = rt_slice.sliceLen(ptr);
//         imgui.SetNextItemOpenExt(true, imgui.CondFlags{.Once = false});
//         if (imgui.TreeNode_StrStr(label, "%.*s: %.*s (len = %zu)", label.len, label.ptr, rt_type.name.len, rt_type.name.ptr, slice_len)) {
//             imgui.BeginDisabledExt(rt_slice.is_const or rt_slice.sentinel != null);
//             defer imgui.EndDisabled();

//             var label_buf: [31:0]u8 = undefined;
//             var iter = rt_slice.iterator(.NonConst, ptr);
//             const comp_alloc = globals.entities.allocator();
//             const Operation = union(enum) {
//                 insert: usize,
//                 delete: usize,
//                 move_up: usize,
//                 move_down: usize,
//                 none: void,
//             };

//             const SliceManipulation = struct {
//                 operation: Operation = .none,

//                 fn drawButtons(this: *@This(), cur_index: usize, len: usize) void {
//                     if (len == 0) {
//                         if (imgui.Button("+")) {
//                             this.operation = .{ .insert = 0 };
//                         }
//                     } else {
//                         if (imgui.Button("+")) {
//                             this.operation = .{ .insert = cur_index + 1 };
//                         }                        
//                     }

//                     imgui.SameLine();

//                     {
//                         imgui.BeginDisabledExt(len == 0);
//                         defer imgui.EndDisabled();
//                         if (imgui.Button("-")) {
//                             this.operation = .{ .delete = cur_index };
//                         }
//                     }

//                     imgui.SameLine();
                    
//                     {
//                         imgui.BeginDisabledExt(cur_index <= 0);
//                         defer imgui.EndDisabled();
//                         if (imgui.Button("^")) {
//                             this.operation = .{ .move_up = cur_index };
//                         }
//                     }

//                     imgui.SameLine();

//                     {
//                         imgui.BeginDisabledExt(cur_index + 1 >= len);
//                         defer imgui.EndDisabled();
//                         if (imgui.Button("v")) {
//                             this.operation = .{ .move_down = cur_index };
//                         }                    
//                     }
//                 }                
//             };
//             var slice_manip = SliceManipulation{};

//             while (iter.next()) |it| {
//                 const index = iter.indexOf(it);
//                 imgui.PushID_Int(@intCast(i32, index));
//                 defer imgui.PopID();
//                 const idx_label = std.fmt.bufPrintZ(&label_buf, "[{}]", .{index}) catch unreachable;                
//                 self.drawInspectorForType(idx_label, it, rt_slice.child);
//                 imgui.Indent();
//                 defer imgui.Unindent();
//                 slice_manip.drawButtons(index, slice_len);
//             }
//             if (slice_len == 0) {
//                 slice_manip.drawButtons(0, 0);
//             }

//             switch (slice_manip.operation) {
//                 .insert => |index| {
//                     const byte_index = index * rt_slice.stride();
//                     // var as_list = std.ArrayListUnmanaged(u8).fromOwnedSlice(rt_slice.asBytes(.NonConst, ptr));
//                     var as_list = blk: {
//                         var slice = rt_slice.asBytes(.NonConst, ptr);
//                         break :blk std.ArrayListUnmanaged(u8) {
//                             .items = slice,
//                             .capacity = slice.len,
//                         };
//                     };
//                     as_list.ensureTotalCapacityPrecise(comp_alloc, as_list.items.len + rt_slice.stride()) catch unreachable;
//                     if (as_list.items.len == 0) {
//                         as_list.appendNTimesAssumeCapacity(undefined, rt_slice.stride());
//                     } else {
//                         as_list.insertSlice(comp_alloc, byte_index, as_list.items[0..rt_slice.stride()]) catch unreachable;
//                     }
//                     rt_slice.child.zeroInit(&as_list.items[byte_index]);
//                     std.debug.assert(as_list.capacity == as_list.items.len);
//                     var slice = as_list.toOwnedSlice(comp_alloc);
//                     slice.len = slice_len + 1;
//                     rt_type.set(ptr, &slice);
//                 },
//                 .delete => |index| {
//                     const byte_index = index * rt_slice.stride(); 
//                     rt_slice.child.deinit(rt_slice.atIndex(.NonConst, ptr, index), comp_alloc);
//                     // var as_list = std.ArrayListUnmanaged(u8).fromOwnedSlice(rt_slice.asBytes(.NonConst, ptr));
//                     var as_list = blk: {
//                         var slice = rt_slice.asBytes(.NonConst, ptr);
//                         break :blk std.ArrayListUnmanaged(u8) {
//                             .items = slice,
//                             .capacity = slice.len,
//                         };
//                     };
//                     as_list.replaceRange(
//                         comp_alloc,
//                         byte_index,
//                         as_list.items.len - byte_index,
//                         as_list.items[byte_index + rt_slice.stride()..],
//                     ) catch unreachable;
//                     as_list.shrinkAndFree(comp_alloc, as_list.items.len);
//                     var as_bytes = as_list.toOwnedSlice(comp_alloc);
//                     as_bytes.len = slice_len - 1;
//                     rt_type.set(ptr, &as_bytes);
//                 },
//                 .move_up, .move_down => |index| {
//                     const swap_index = if (slice_manip.operation == .move_up)
//                         index - 1
//                         else index + 1;
//                     var as_bytes = rt_slice.asBytes(.NonConst, ptr);
//                     const byte_index_lhs = index * rt_slice.stride();
//                     const byte_index_rhs = swap_index * rt_slice.stride();
//                     var slice_lhs = as_bytes[byte_index_lhs..][0..rt_slice.child.size];
//                     var slice_rhs = as_bytes[byte_index_rhs..][0..rt_slice.child.size];
//                     for (slice_lhs) |*it, idx| {
//                         std.mem.swap(u8, it, &slice_rhs[idx]);
//                     }
//                 },
//                 .none => {},
//             }

//             imgui.TreePop();
//         }
//     }

//     pub fn rtIntInfoToImGuiDataType(int_info: *const type_registry.RtIntInfo) ?imgui.DataType {
//         return switch (int_info.signedness) {
//             .signed => {
//                 return switch (int_info.bits) {
//                     8 => .S8,
//                     16 => .S16,
//                     32 => .S32,
//                     64 => .S64,
//                     else => null,
//                 };
//             },
//             .unsigned => {
//                 return switch (int_info.bits) {
//                     8 => .U8,
//                     16 => .U16,
//                     32 => .U32,
//                     64 => .U64,
//                     else => null,
//                 };
//             }
//         };
//     }

//     pub fn drawInspectorForEnum(
//         self: *@This(),
//         label: [:0]const u8,
//         ptr: *anyopaque,
//         rt_type: *const type_registry.RtTypeInfo,
//         rt_enum: *const type_registry.RtEnumInfo,
//     ) void {
//         _ = self;
//         _ = rt_type;

//         var fmtbuf: [127:0]u8 = [1:0]u8{0} ++ ([1:0]u8{undefined} ** 126);
//         var current_field_idx = rt_enum.findFieldIndexByValuePtr(ptr);
//         const current_field_value = if (current_field_idx) |i| rt_enum.fields[i] else null;

//         const rt_integer = rt_enum.tag_type.detail.?.rt_integer;
        
//         if (rt_enum.is_exhaustive) {
//             const current_input = if (current_field_value) |field|
//                 field.name
//                 else switch (rt_integer.read64(ptr)) {
//                     // inline else => |value| std.fmt.bufPrintZ(fmtbuf, "UNKNOWN({})", .{value}),
//                     // inline else => |value| std.fmt.bufPrintIntToSlice(fmtbuf, value, 10, .lower, .{}),
//                     .signed => |value| std.fmt.bufPrintZ(&fmtbuf, "UNKNOWN({})", .{value}) catch unreachable,
//                     .unsigned => |value| std.fmt.bufPrintZ(&fmtbuf, "UNKNOWN({})", .{value}) catch unreachable,
//             };

//             var changed = false;
//             if (imgui.BeginCombo(label, current_input)) {
//                 for (rt_enum.fields) |field, i| {
//                     var selected = current_field_idx == i;
//                     if (imgui.Selectable_BoolPtr(field.name, &selected)) {
//                         if (selected) {
//                             current_field_idx = i;
//                             changed = true;
//                         }
//                     }
//                 }
//                 imgui.EndCombo();
//             }
//             if (changed) {
//                 if (current_field_idx) |field_idx| {
//                     _ = rt_integer.writeTrunc(ptr, rt_enum.fields[field_idx].value);
//                 }
//             }
//         } else {
//             if (current_field_value) |field| {
//                 std.mem.copy(u8, &fmtbuf, field.name);
//             } else {
//                 switch (rt_integer.read64(ptr)) {
//                     // inline else => |value| std.fmt.bufPrintIntToSlice(fmtbuf, value, 10, .lower, .{}),
//                     .signed => |value| { _ = std.fmt.bufPrintIntToSlice(&fmtbuf, value, 10, .lower, .{}); },
//                     .unsigned => |value| { _ = std.fmt.bufPrintIntToSlice(&fmtbuf, value, 10, .lower, .{}); },
//                 }
//             }
//             const changed = imgui.InputTextExt(
//                 label,
//                 &fmtbuf,
//                 @sizeOf(@TypeOf(fmtbuf)),
//                 .{.EnterReturnsTrue = true},
//                 null,
//                 null,
//             );
            
//             // const current_input = fmtbuf[0..std.mem.len(@as([*:0]u8, &fmtbuf)) :0];
//             const current_input = fmtbuf[0..std.mem.indexOfSentinel(u8, 0, &fmtbuf) :0];

//             if (changed) {
//                 if (rt_enum.nameToValue(current_input, .case_agnostic)) |enumerated_value| {
//                     _ = rt_integer.writeTrunc(ptr, enumerated_value);
//                 } else {
//                     const parsed_value: ?u64 = switch (rt_integer.signedness) {
//                         // todo: cooler runtime-generic int parsing function that helps 0x, 0b, and 0o prefixes
//                         .signed => blk: {
//                             const signed_value = std.fmt.parseInt(i64, current_input, 10) catch break :blk null;
//                             break :blk @bitCast(u64, signed_value);
//                         },
//                         .unsigned => std.fmt.parseInt(u64, current_input, 10) catch null,
//                     };
//                     if (parsed_value) |value| {
//                         _ = rt_integer.writeTrunc(ptr, value);
//                     }
//                 }
//             }
//         }
//     }

//     pub fn drawInspectorForType(
//         self: *@This(),
//         label: [:0]const u8,
//         ptr: *anyopaque,
//         rt_type: *const type_registry.RtTypeInfo,
//     ) void {

//         // hard-coded fundamental types
//         if (rt_type.rttid == RuntimeType.id(String)) {
//             const alloc = globals.entities.allocator();
//             const pstr = @ptrCast(*String, @alignCast(@alignOf(String), ptr));
//             _ = self.input_text_helper.inputString(alloc, label, pstr);
//             return;
//         }

//         if (rt_type.implOf(InspectorDrawer, ptr)) |*inspector_drawer| {
//             inspector_drawer.drawInspector(self, label, rt_type);
//             return;
//         }

//         // Generic inspector drawing
//         switch (rt_type.detail.?) {
//             .rt_struct => |rt_struct| {
//                 self.drawInspectorForStruct(label, ptr, rt_type, rt_struct);
//             },
//             .rt_enum => |rt_enum| {
//                 self.drawInspectorForEnum(label, ptr, rt_type, rt_enum);
//             },
//             .rt_float => |float_info| switch (float_info.bits) {
//                 32, 64 => |bits| {
//                     _ = imgui.DragScalar(
//                         label,
//                         if (bits == 32) .Float else .Double,
//                         ptr,
//                     );
//                 },
//                 else => {
//                     _ = imgui.Text("Field %.*s has a %ubit float field, but only 32/64bit are supported", label.len, label.ptr, float_info.bitsU32());
//                 },
//             },
//             .rt_integer => |int_info| {
//                 if (rtIntInfoToImGuiDataType(int_info)) |ig_data_type| {
//                     _ = imgui.DragScalar(label, ig_data_type, ptr);
//                 } else {
//                     _ = imgui.Text(
//                         "Field %.*s has a %ubit %.*s int field, which is not supported",
//                         label.len, label.ptr,
//                         int_info.bitsU32(),
//                         @tagName(int_info.signedness).len,
//                         @tagName(int_info.signedness).ptr);
//                 }
//             },
//             .rt_bool => {
//                 _ = imgui.Checkbox(label, @ptrCast(*bool, ptr));
//             },
//             .rt_array => |arr_info| {
//                 // fixed-length array
//                 self.drawInspectorForArray(label, ptr, rt_type, arr_info);
//             },
//             .rt_slice => |slice_info| {
//                 self.drawInspectorForSlice(label, ptr, rt_type, slice_info);
//             },
//             else => imgui.Text("Unable to draw inspector for %.*s: %.*s (type kind is %.*s)", label.len, label.ptr, rt_type.name.len, rt_type.name.ptr, @tagName(rt_type.detail.?).len, @tagName(rt_type.detail.?).ptr),
//         }
//     }

//     pub fn drawComponentInspectorImGui(self: *@This(), comp_sel: ComponentSelection) void {
//         imgui.TextUnformatted("Component");

//         var buf: [64]u8 = undefined;
//         if (imgui.Button(std.fmt.bufPrintZ(&buf, "Entity {}", .{comp_sel.entity}) catch unreachable)) {
//             self.selection = .{ .entity = comp_sel.entity };
//         }

//         const component_runtime_type_info = globals.registered_types.tryLookupByRttid(comp_sel.component);

//         if (component_runtime_type_info) |comp_rtti| {
//             if (globals.entities.tryGetOpaque(comp_sel.component , comp_sel.entity)) |comp_ptr| {               
//                 // const detail = comp_rtti.detail.?;
//                 // imgui.LabelText("Name", "%.*s", comp_rtti.name.len, comp_rtti.name.ptr);

//                 if (globals.entities.tryGetComponentInspectorDrawer(comp_rtti.rttid)) |draw_inspector_fn| {
//                     draw_inspector_fn(comp_ptr, self, comp_rtti.name, comp_rtti);
//                 } else {
//                     self.drawInspectorForType(comp_rtti.name, comp_ptr, comp_rtti);                    
//                 }

//             }

//             if (imgui.Button("debug log")) {
//                 std.log.debug("rt type is {}", .{comp_rtti.*});
//                 std.log.debug("fields {any}", .{comp_rtti.detail.?.rt_struct.fields});
//             }

//         } else {
//             imgui.LabelText("##error", "Unknown component with rttid: %zu", comp_sel.component.toInt());
//         }
//     }

//     pub fn validateSelection(self: *@This()) void {
//         switch (self.selection) {
//             .nothing => {},
//             .entity => |entity| {
//                 if (!globals.entities.entityExists(entity)) {
//                     self.selection = .nothing;
//                 }
//             },
//             .component => |compsel| {
//                 if (globals.entities.tryGetOpaque(compsel.component, compsel.entity) == null) {
//                     self.selection = .nothing;
//                 }
//             },
//         }
//     }

//     pub fn drawSelectionInspectorImGui(self: *@This()) void {
//         if (imgui.Begin("Scene Editor - Inspector")) {
//             self.validateSelection();
//             switch (self.selection) {
//                 .nothing => {},
//                 .entity => |entity| self.drawEntityInspectorImGui(entity),
//                 .component => |comp_handle| self.drawComponentInspectorImGui(comp_handle),
//             }
//         }

//         imgui.End();
//     }

//     pub fn drawImGui(self: *@This()) void {
//         self.drawEntityListImGui();
//         self.drawSelectionInspectorImGui();
//     }
// };

var globals = Globals{};
// var p_globals = &globals;
// const g_max_sprites: usize = 1024;

// const NameComponent = struct {
//     name: [:0]const u8 = "",
//     name_storage: ?[:0]u8 = null,

//     pub const ATTRIBUTES = .{
//         .COMPONENT = .{
//             .drawInspector = @This().drawMe,
//         }
//     };

//     pub fn drawMe(
//         self: *@This(),
//         editor: *SceneEditor,
//         label: [:0]const u8,
//         rt_type: *const type_registry.RtTypeInfo,
//     ) void {
//         _ = label;
//         _ = rt_type;

//         imgui.SetNextItemOpenExt(true, imgui.CondFlags{ .Once = true });
//         if (imgui.TreeNode_Str("NameComponent")) {
//             const alloc = globals.entities.allocator();
//             if (editor.input_text_helper.inputText(alloc, "Name", self.name, &self.name_storage)) {
//                 self.name = self.name_storage.?;
//             }
//             imgui.TreePop();
//         }
//     }

//     pub const SerializerHooks = struct {
//         pub fn loadFromJsonStream(
//             // comptime TSerializer: type,
//             dest: *NameComponent,
//             state: *serialization.SerializerJsonLoadState,
//         ) !void {
//             var helper = serialization.StreamHelper.init(state);
//             try helper.expectObjBegin();
//             try helper.expectProperty("name");
//             const name_str = try helper.expectString();
//             if (name_str.len > 0) {
//                 dest.name_storage = try state.alloc.dupeZ(u8, name_str);
//                 dest.name = dest.name_storage.?;
//             }
//             try helper.expectObjEnd();
//         }

//         pub fn writeToJsonStream(
//             src: *const NameComponent,
//             state: *serialization.SerializerJsonWriteState,
//         ) !void {
//             var w = state.jsonWriter();
//             w.singleLineBegin();
//             defer w.singleLineEnd();

//             try w.objBegin();

//             try w.field("name");
//             try w.quoted(src.name);

//             try w.objEnd();
//         }
//     };

//     pub fn deinit(self: *@This(), alloc: Allocator) void {
//         if (self.name_storage) |slice_z| {
//             alloc.free(slice_z);
//         }
//     }
// };

// const Vertex = extern struct {
//     pos: m.Vec2f,
//     uv: m.Vec2f,
// };

// const SpriteStaticVertex = extern struct {
//     pos: m.Vec3f,
//     uv_factor: m.Vec4f, // topleft = 1001, bottomleft = 1100
// };

// const SpriteInstanceVertex = extern struct {
//     inst_world2d_from_vertex2d: m.Mat3f,
//     inst_size: m.Vec2f,
//     inst_pivot: m.Vec2f,
//     inst_uvrect: m.Vec4f, // left, bottom, right, top
//     inst_depth: f32,
// };

// fn bindStaticSpriteQuad(vertex_buffer: *sgfx.Buffer, index_buffer: *sgfx.Buffer) u32 {
//     vertex_buffer.* = sgfx.makeBuffer(sgfx.BufferDesc{
//         .label = "static-sprite-verts",
//         .type = .VERTEXBUFFER,
//         .data = sgfx.asRange(&[_]SpriteStaticVertex{
//             .{ .pos = m.vec3f(0, 0, 0.5), .uv_factor = m.vec4f(1, 1, 0, 0) },
//             .{ .pos = m.vec3f(0, 1, 0.5), .uv_factor = m.vec4f(1, 0, 0, 1) },
//             .{ .pos = m.vec3f(1, 0, 0.5), .uv_factor = m.vec4f(0, 1, 1, 0) },
//             .{ .pos = m.vec3f(1, 1, 0.5), .uv_factor = m.vec4f(0, 0, 1, 1) },
//         })
//     });

//     var indices = [_]u16{0, 1, 2, 2, 1, 3};
//     index_buffer.* = sgfx.makeBuffer(sgfx.BufferDesc{
//         .label= "static-sprite-indices",
//         .type = .INDEXBUFFER,
//         .data = sgfx.asRange(&indices),
//     });
//     return indices.len;
// }



// fn checkerboardTex(image_binding: *sgfx.Image) void {
//     var image_desc = sgfx.ImageDesc{
//         .width = 4,
//         .height = 4,
//     };
//     image_desc.data.subimage[0][0] = sgfx.asRange([16]Rgba8{
//         Rgba8.white, Rgba8.black, Rgba8.white, Rgba8.black,
//         Rgba8.black, Rgba8.white, Rgba8.black, Rgba8.white,
//         Rgba8.white, Rgba8.black, Rgba8.white, Rgba8.black,
//         Rgba8.black, Rgba8.white, Rgba8.black, Rgba8.white,
//     });
//     image_binding.* = sgfx.makeImage(image_desc);
// }

// const array_hash_map = @import("std").array_hash_map;

// const TextureCache = struct {
//     // const TextureHandleMap = std.AutoArrayHashMap(ResourceHandle(Image), sgfx.Image);
//     // const TextureHandleMap = std.AutoArrayHashMap(ResourceHandle(Image), u32);
//     // const TextureHandleMap = std.AutoArrayHashMap(ResourceID, sgfx.Image);
//     const TextureHandleMap = std.AutoArrayHashMap(ResourceID, u32);
//     // const TextureHandleMap = std.AutoHashMap(ResourceID, u32);
//     // const TextureHandleMap = void;//std.AutoArrayHashMap(ResourceID, u32);
//     // const Ctx = array_hash_map.AutoContext(ResourceHandle(Image));
//     res_to_tex_map: TextureHandleMap = undefined,
//     // res_to_tex_map: TextureHandleMap,

//     pub fn init(alloc: Allocator) @This() {
//         _ = alloc;
//         return .{
//             // .res_to_tex_map = TextureHandleMap.init(alloc),
//         };
//     }

//     // pub fn deinit(self: *@This()) void {
//     //     _ = self;
//     //     // self.res_to_tex_map.deinit();
//     // }

//     // pub fn getOrUpload(self: *@This(), image_res: ResourceHandle(Image)) sgfx.Image {
//     //     // const gop = self.res_to_tex_map.getOrPut(image_res) catch unreachable;
//     //     const gop = self.res_to_tex_map.getOrPut(image_res.id) catch unreachable;
//     //     if (!gop.found_existing) {
//     //         gop.value_ptr.* = texFromImage(image_res.get());
//     //     }
//     //     return gop.value_ptr.*;
//     // }

//     // pub fn purge(self: *@This(), handle: ResourceHandle(Image)) void {
//     //     _ = self;
//     //     _ = handle;
//     // //     // if (self.res_to_tex_map.fetchOrderedRemove(handle)) |kv| {
//     // //     if (self.res_to_tex_map.fetchOrderedRemove(handle.id)) |kv| {
//     // //         sgfx.destroyImage(kv.value);
//     // //     }
//     // }

//     // fn texFromImage(img: *Image) sgfx.Image {
//     //     var image_desc = sgfx.ImageDesc{
//     //         .width = img.width,
//     //         .height = img.height,
//     //         .mag_filter = .NEAREST,
//     //         .min_filter = .NEAREST,
//     //         .pixel_format = switch (img.channels) {
//     //             1 => .R8,
//     //             2 => .RG8,
//     //             4 => .RGBA8,
//     //             else => unreachable,
//     //         },
//     //     };
//     //     const data: []u8 = img.data();
//     //     image_desc.data.subimage[0][0] = sgfx.asRange(data);
//     //     return sgfx.makeImage(image_desc);
//     // }
// };

// fn drawText(str: [:0]const u8, color: Rgba8) void {
//     sdtx.font(0);
//     sdtx.color3b(color.r, color.g, color.b);
//     sdtx.puts(str);
//     sdtx.crlf();
// }

// fn setupAppendSceneFromJsonStringLiteral() void {
//     const json =
//         \\{
//         \\  "entities": [1, 2],
//         \\  "components": [
//         \\    {
//         \\      "%entity": 1,
//         \\      "%type": "Transform2DComponent",
//         \\      "%data": {
//         \\        "local": {
//         \\          "position": { "x": 200, "y": 250 }
//         \\        }
//         \\      }
//         \\    },
//         \\    {
//         \\      "%entity": 1,
//         \\      "%type": "SpriteRenderComponent",
//         \\      "%data": {
//         \\        "desc": { "path": "assets/dancegirl_slide_spritedesc.json" }
//         \\      }
//         \\    },
//         \\    {
//         \\      "%entity": 2,
//         \\      "%type": "Transform2DComponent",
//         \\      "%data": {
//         \\        "local": {
//         \\          "position": { "x": 0, "y": 0 }
//         \\        }
//         \\      }
//         \\    },
//         \\    {
//         \\      "%entity": 2,
//         \\      "%type": "SpriteRenderComponent",
//         \\      "%data": {
//         \\        "desc": { "path": "assets/test_spritedesc.json" }
//         \\      }
//         \\    }
//         \\  ]
//         \\}
//         \\
//     ;

//     globals.scene_loader.loadSceneFromJson(json) catch unreachable;
// }

// fn setupSceneReloadFromJsonFile(alloc: Allocator, path: []const u8) void {
//     globals.entities.destroyAllEntities();
//     setupAppendSceneFromJsonFile(alloc, path);
// }

// fn setupAppendSceneFromJsonFile(alloc: Allocator, path: []const u8) void {
//     const scn_json = std.fs.cwd().readFileAlloc(alloc, path, std.math.maxInt(usize)) catch unreachable;
//     defer alloc.free(scn_json);
//     globals.scene_loader.loadSceneFromJson(scn_json) catch unreachable;
// }

// pub fn registerComponents(emgr: *EntityManager, sldr: *SceneLoader, typereg: *NamedTypeRegistry) void {
//     const registrar = struct {
//         emgr: *EntityManager,
//         sldr: *SceneLoader,
//         typereg: *NamedTypeRegistry,

//         pub fn add(self: @This(), comptime T: type) void {
//             _ = self.typereg.register(T);
//             // self.emgr.ensureComponentRegistered(T);
//             // self.sldr.ensureComponentRegistered(T);
//         }
//     } { .emgr = emgr, .sldr = sldr, .typereg = typereg };

//     // registrar.add(SpriteRenderComponent);
//     // registrar.add(TilemapRenderComponent);
//     registrar.add(Transform2DComponent);
//     // registrar.add(NameComponent);
//     // registrar.add(TestSliceComponent);
//     // registrar.add(TestStructSlice);
//     // registrar.add(TestDeinitComponent);
//     // registrar.add(FrendtityComponent);
//     // registrar.add(FollowFriendComponent);
// }

// fn onAppInit() callconv(.C) void {
//     // const alloc = App.get().alloc;
//     // _ = alloc;
//     // globals.preInit(alloc);
//     // Storage.init(alloc);
//     // Resources.startup(&globals.registered_types, alloc);
//     // globals.postInit(alloc);
//     // editorui.startup(alloc) catch unreachable;

//     // registerTypes(&globals.registered_types);
//     // registerComponents(&globals.entities, &globals.scene_loader, &globals.registered_types);

//     // sokol.time.setup();

//     // sgfx.setup(sgfx.Desc{
//     //     .context = sokol.app_gfx_glue.context(),
//     // });

//     // var sdtx_desc: sdtx.Desc = .{};
//     // sdtx_desc.fonts[0] = sdtx.fontCpc();
//     // sdtx.setup(sdtx_desc);

//     // sokol_imgui.setup(sokol_imgui.Desc{});

//     // globals.draw_state.shader = sgfx.makeShader(shaders.universalsprite.universalspriteShaderDesc(sgfx.queryBackend()));

//     // globals.draw_state.num_elements = bindStaticSpriteQuad(
//     //     &globals.draw_state.vbuffer,
//     //     &globals.draw_state.ibuffer,
//     // );

//     // globals.draw_state.inst_vbuffer_pool.updateDesc(.{
//     //     .label = "sprite-instance-verts",
//     //     .type = .VERTEXBUFFER,
//     //     .usage = .STREAM,
//     //     .size = 32 * @sizeOf(SpriteInstanceVertex), //g_max_sprites //unsure if I'm allowed to resize
//     // });

//     // // clears to gray
//     // globals.pass_action.colors[0] = sgfx.ColorAttachmentAction{
//     //     .action = sgfx.Action.CLEAR,
//     //     .value = Rgba8.gray.asColorf(),
//     // };

//     // globals.draw_state.pipeline_dirty = true;
// }


// fn input() void {
//     const dt_secs64: f64 = sokol.time.sec(globals.dt_ticks);
//     const dt_secs = @floatCast(f32, dt_secs64);
//     const t_secs = @floatCast(f32, sokol.time.sec(sokol.time.now()));
//     _ = t_secs;

//     const gofast = (0 != (globals.modifiers & sokol.app.modifier_shift));
//     var speed: f32 = if (gofast) 100 else 10;
//     var scalespeed: f32 = if (gofast) 100 else 5;

//     if (globals.keystate.get(Keycode.UP))    globals.scroll.y += dt_secs * speed;
//     if (globals.keystate.get(Keycode.DOWN))  globals.scroll.y -= dt_secs * speed;
//     if (globals.keystate.get(Keycode.LEFT))  globals.scroll.x -= dt_secs * speed;
//     if (globals.keystate.get(Keycode.RIGHT)) globals.scroll.x += dt_secs * speed;

//     if (globals.keystate.get(Keycode.LEFT_BRACKET))  globals.rotate -= dt_secs;
//     if (globals.keystate.get(Keycode.RIGHT_BRACKET)) globals.rotate += dt_secs;

//     if (globals.keystate.get(Keycode.KP_8)) globals.spritescale.y += dt_secs * scalespeed;
//     if (globals.keystate.get(Keycode.KP_2)) globals.spritescale.y -= dt_secs * scalespeed;
//     if (globals.keystate.get(Keycode.KP_4)) globals.spritescale.x -= dt_secs * scalespeed;
//     if (globals.keystate.get(Keycode.KP_6)) globals.spritescale.x += dt_secs * scalespeed;

//     // const zoom_before = globals.cam_zoom;
//     if (globals.keystate.get(Keycode.EQUAL)) globals.cam_zoom += dt_secs;
//     if (globals.keystate.get(Keycode.MINUS)) globals.cam_zoom -= dt_secs;
//     globals.cam_zoom = std.math.clamp(globals.cam_zoom, globals.cam_zoom_min, globals.cam_zoom_max);
//     // if (zoom_before != globals.cam_zoom) {
//     //     std.log.info("zoom is now {}", .{globals.cam_zoom});
//     // }

//     if (globals.keystate.get(Keycode.W)) globals.cam_pos.y += dt_secs * speed;
//     if (globals.keystate.get(Keycode.S)) globals.cam_pos.y -= dt_secs * speed;
//     if (globals.keystate.get(Keycode.A)) globals.cam_pos.x -= dt_secs * speed;
//     if (globals.keystate.get(Keycode.D)) globals.cam_pos.x += dt_secs * speed;

//     // const zbefore = globals.scroll.z;
//     if (globals.keystate.get(Keycode.PAGE_UP)) globals.scroll.z += dt_secs * speed;
//     if (globals.keystate.get(Keycode.PAGE_DOWN)) globals.scroll.z -= dt_secs * speed;

//     // if (zbefore != globals.scroll.z) {
//     //     std.log.info("Z POS: {}", .{globals.scroll.z});
//     // }

//     // for (globals.sprites.items) |sprite| {
//     //     sprite.transform.position = globals.scroll.swz("xy");
//     // }

// }

// const RenderBatch = struct {
//     texture: sgfx.Image,
//     inst_buffer: sgfx.Buffer,
//     inst_count: u32,
// };


// const SpriteBatch = struct {
//     texture: sgfx.Image,
//     vertices: std.ArrayList(SpriteInstanceVertex),
// };

// const SpriteBatchSet = struct {
//     batches: std.AutoArrayHashMap(sgfx.Image, SpriteBatch),

//     pub fn init(init_alloc: Allocator) @This() {
//         return .{
//             .batches = std.AutoArrayHashMap(sgfx.Image, SpriteBatch).init(init_alloc),
//         };
//     }

//     pub fn count(self: @This()) usize {
//         return self.batches.count();
//     }

//     pub fn iterator(self: @This()) std.meta.fieldInfo(@This(), .batches).field_type.Iterator {
//         return self.batches.iterator();
//     }

//     pub fn getOrAdd(self: *@This(), tex: sgfx.Image) !*SpriteBatch {
//         var result = try self.batches.getOrPut(tex);
//         if (!result.found_existing) {
//             result.value_ptr.* = SpriteBatch{
//                 .texture = tex,
//                 .vertices = std.ArrayList(SpriteInstanceVertex).init(self.batches.allocator),
//             };
//         }
//         return result.value_ptr;
//     }
// };

// fn addSpriteToBatch(
//     sprite_batches: *SpriteBatchSet,
//     frame_textures: []const sgfx.Image,
//     frame_anim_state: FrameAnimState,
//     transform: Transform2D,
//     sprite_desc: *const SpriteDesc,
// ) !void {
//     if (frame_textures.len == 0) {
//         if (Resources.lookupHandleByPtr(SpriteDesc, sprite_desc)) |res| {
//             var buf: [256]u8 = undefined;
//             std.log.err("Image has zero textures, SpriteDesc: {s}", .{res.displayStr(&buf)});
//         } else {
//             std.log.err("Image has zero textures, unknown SpriteDesc: {}", .{sprite_desc});
//         }
//         return;
//     }

//     var pos: m.Vec2f = transform.position.add(globals.scroll.swz("xy"));
//     var batch = try sprite_batches.getOrAdd(frame_textures[frame_anim_state.frame]);

//     const frame: *const SpriteFrame = &sprite_desc.frames[frame_anim_state.frame];
//     const uv_rectf = frame.uvrect.convert(f32);
//     var atlas_data = frame.atlas.get();
//     const atlas_sizef = m.vec2f(atlas_data.width, atlas_data.height);

//     try batch.vertices.append(.{
//         .inst_world2d_from_vertex2d = m.Mat3f.transform(
//             pos,
//             transform.rotation + globals.rotate,
//             transform.scale.add(globals.spritescale)),
//         .inst_size = frame.uvrect.size.convert(f32),
//         .inst_pivot = sprite_desc.pivot,
//         .inst_uvrect = m.vec4f(
//             uv_rectf.left() / atlas_sizef.x,
//             uv_rectf.bottom() / atlas_sizef.y,
//             uv_rectf.right() / atlas_sizef.x,
//             uv_rectf.top() / atlas_sizef.y,
//         ),
//         .inst_depth = 0,
//     });    
// }

// fn prepareRender(alloc: Allocator) ![]RenderBatch {
//     var pglobals = &globals;
//     _ = pglobals;

//     var arena = std.heap.ArenaAllocator.init(alloc);
//     defer arena.deinit();

//     var sprite_batches = SpriteBatchSet.init(arena.allocator());

//     try prepareRenderSpriteEntities(&sprite_batches);

//     try prepareRenderTilemapEntities(alloc, &sprite_batches);

//     globals.draw_state.inst_vbuffer_pool.releaseAll();
//     var batches = std.ArrayList(RenderBatch).init(alloc);
//     if (sprite_batches.count() > 0) {
//         try batches.ensureTotalCapacity(sprite_batches.count());
//         var it = sprite_batches.iterator();
//         while (it.next()) |entry| {
//             const buffer = globals.draw_state.inst_vbuffer_pool.acquire();

//             sgfx.updateBuffer(
//                 buffer,
//                 sgfx.asRange(entry.value_ptr.vertices.items),
//             );
            
//             batches.appendAssumeCapacity(RenderBatch{
//                 .texture = entry.value_ptr.texture,
//                 .inst_buffer = buffer,
//                 .inst_count = @intCast(u32, entry.value_ptr.vertices.items.len),
//             });
//         }
//     }
//     return batches.toOwnedSlice();
// }

// fn prepareRenderSpriteEntities(sprite_batches: *SpriteBatchSet) !void {
//     var view = globals.entities.reg.view(.{SpriteRenderComponent, Transform2DComponent}, .{});
//     var iter = view.iterator();
//     while (iter.next()) |entity| {
//         var sprite = view.get(SpriteRenderComponent, entity);
//         const sprite_desc: *const SpriteDesc = sprite.desc.get();

//         if (sprite.textures.len != sprite_desc.frames.len) {
//             // todo: handle purging and reloading image or spritedesc resource
//             sprite.textures = try globals.sprite_render_globals.textureHandlesForSprite(sprite.desc.toHandle());
//         }

//         const transform = view.get(Transform2DComponent, entity);

//         try addSpriteToBatch(
//             sprite_batches,
//             sprite.textures,
//             sprite.frame_anim_state,
//             transform.local,
//             sprite_desc,
//         );
//     }
// }

// fn prepareRenderTilemapEntities(alloc: Allocator, sprite_batches: *SpriteBatchSet) !void {
//     var view = globals.entities.reg.view(.{TilemapRenderComponent, Transform2DComponent}, .{});
//     var iter = view.iterator();
//     var image_handle = ResourceHandle(Image).invalid;
//     var image_data: ?*const Image = null;
//     while (iter.next()) |entity| {
//         var tilemap = view.get(TilemapRenderComponent, entity);
//         const tilemap_desc: *const TilemapDesc = tilemap.desc.get();
//         if (tilemap.tiles.len != tilemap_desc.tile_grid.len) {
//             const old_len = tilemap.tiles.len;
//             tilemap.tiles = alloc.realloc(tilemap.tiles, tilemap_desc.tile_grid.len) catch unreachable;
//             for (tilemap.tiles[old_len..tilemap.tiles.len]) |*tile| {
//                 tile.* = std.mem.zeroInit(Tile, .{});
//             }
//         }

//         const transform = view.get(Transform2DComponent, entity);

//         var x: usize = undefined;
//         var y: usize = 0;
//         var i: usize = 0;

//         while (y < tilemap_desc.dimensions.y) : (y += 1) {
//             x = 0;
//             while (x < tilemap_desc.dimensions.x) : ({ x+= 1; i += 1; }) {
//                 const tile: *Tile = &tilemap.tiles[i];
//                 const tile_ref: *const TilemapDesc.TileRef = &tilemap_desc.tile_refs[tilemap_desc.tile_grid[i]];
//                 const tile_spritedesc: *const SpriteDesc = tile_ref.sprite.get();

//                 if (tile.textures.len != tile_spritedesc.frames.len) {
//                     // todo: handle purging and reloading image or spritedesc resource
//                     // also tiles shouldn't individually store the texture slice
//                     // put that in a shared thing that aligns index-wise with tilemap_desc.tile_refs
//                     tile.textures = try globals.sprite_render_globals.textureHandlesForSprite(tile_ref.sprite.toHandle());
//                 }

//                 const tex = tile.textures[tile.frame_anim_state.frame];
//                 const batch = try sprite_batches.getOrAdd(tex);

//                 const frame: *SpriteFrame = &tile_spritedesc.frames[tile.frame_anim_state.frame];
//                 if (!frame.atlas.equiv(image_handle)) {
//                     image_data = frame.atlas.get();
//                     image_handle = frame.atlas.toHandle();
//                 }

//                 if (image_data) |img| {
//                     const uv_rectf = frame.uvrect.convert(f32);
//                     const atlas_sizef = m.vec2f(img.width, img.height);

//                     var tile_transform = m.Mat3f.transform(
//                         tilemap_desc.tile_size.scale(m.vec2f(x, y)),
//                         globals.tilerotate,
//                         globals.tilescale,
//                     );
//                     var map_transform = m.Mat3f.transform(
//                         transform.local.position.add(globals.scroll.swz("xy")),
//                         transform.local.rotation + globals.rotate,
//                         transform.local.scale.add(globals.spritescale),
//                     );

//                     try batch.vertices.append(.{
//                         .inst_world2d_from_vertex2d = map_transform.mul(tile_transform),
//                         // .inst_world2d_from_vertex2d = transform.local.mul(tile_transform),
//                         .inst_size = uv_rectf.size,
//                         .inst_pivot = tile_spritedesc.pivot,
//                         .inst_uvrect = m.vec4f(
//                             uv_rectf.left() / atlas_sizef.x,
//                             uv_rectf.bottom() / atlas_sizef.y,
//                             uv_rectf.right() / atlas_sizef.x,
//                             uv_rectf.top() / atlas_sizef.y,
//                         ),
//                         .inst_depth = 0,
//                     });                        
//                 } else {
//                     var buf: [260]u8 = .{0}**260;
//                     std.log.err("Failed to load image resource: {s}", .{frame.atlas.displayStr(&buf)});
//                 }
//             }
//         }
//     }    
// }


// fn render(alloc: Allocator) void {
//     if (globals.show_imgui_demo) {
//         imgui.ShowDemoWindowExt(&globals.show_imgui_demo);
//     }

//     const batches = prepareRender(alloc) catch unreachable;
//     defer alloc.free(batches);

//     const cam_viewport_size: m.Vec2f = globals.window_size.scale(1 / @max(std.math.epsilon(f32), globals.cam_zoom));
//     const half_cam_viewport_size: m.Vec2f = cam_viewport_size.scale(0.5);
//     const cam_bottom_left = globals.cam_pos.sub(half_cam_viewport_size);
//     var camera_rect = m.Rectf.init(
//         cam_bottom_left,
//         cam_viewport_size,
//     );

//     const projection_from_world = m.Mat4f.ortho(
//         camera_rect.left(),
//         camera_rect.right(),
//         camera_rect.bottom(),
//         camera_rect.top(),
//         0, 100);

//     var vs_params = shaders.universalsprite.VsParams{
//         .projection_from_world = projection_from_world.array().*,
//     };

//     if (globals.draw_state.pipeline_dirty) {
//         globals.draw_state.pipeline_dirty = false;
//         globals.draw_state.resetPipeline();
//     }

//     var bindings = sgfx.Bindings{
//         .index_buffer = globals.draw_state.ibuffer,
//     };
//     bindings.vertex_buffers[0] = globals.draw_state.vbuffer;

//     sgfx.beginDefaultPass(globals.pass_action, sokol.app.width(), sokol.app.height());

//     sgfx.applyPipeline(globals.draw_state.pipeline);

//     sgfx.applyUniforms(.VS, shaders.universalsprite.SLOT_vs_params, sgfx.asRange(&vs_params));

//     for (batches) |batch| {
//         bindings.vertex_buffers[1] = batch.inst_buffer;
//         if (batch.inst_count > 0) {
//             bindings.fs_images[shaders.universalsprite.SLOT_my_texture] = batch.texture;
//         }
//         sgfx.applyBindings(bindings);

//         sgfx.draw(0, globals.draw_state.num_elements, batch.inst_count);
//     }

//     sgfx.endPass();

//     sgfx.commit();
// }

// fn renderBeginDebugPass() void {
//     // sdtx.canvas(sokol.app.widthf() * 0.75, sokol.app.heightf() * 0.5);
//     sdtx.canvas(sokol.app.widthf() * 0.5, sokol.app.heightf() * 0.5);
//     sdtx.origin(0.5, 0.5);
    
//     var noOpPassAction = sgfx.PassAction{};
//     noOpPassAction.colors[0] = sgfx.ColorAttachmentAction{
//         .action = .DONTCARE,
//     };
//     sgfx.beginDefaultPass(noOpPassAction, sokol.app.width(), sokol.app.height());

// }

// fn renderEndDebugPass() void {
//     sgfx.endPass();
//     sgfx.commit();
// }

// fn renderDebugText() void {
//     sdtx.draw();
// }

// fn renderImGui() void {
//     sokol_imgui.render();
// }

// fn followFriendsSystem() void {
//     const ms_elapsed = @floatCast(f32, sokol.time.sec(globals.dt_ticks));
//     var view = globals.entities.reg.view(.{FollowFriendComponent, Transform2DComponent}, .{});
//     var iter = view.iterator();
//     while (iter.next()) |entity| {
//         const follow_friend: *FollowFriendComponent = globals.entities.get(FollowFriendComponent, entity);
//         const transform: *Transform2DComponent = globals.entities.get(Transform2DComponent, entity);

//         if (follow_friend.friend.resolveLink(Transform2DComponent)) |friend_transform| {
//             const follow_dist_sq = follow_friend.distance * follow_friend.distance;
//             const diff = friend_transform.local.position.sub(transform.local.position);
//             const dist_sq = diff.lenSq();
//             const direction = diff.normalized();
//             if (dist_sq > follow_dist_sq) {
//                 transform.local.position.addTo(direction.scale(follow_friend.rate * ms_elapsed)).done();
//             }
//         }
//     }
// }

// fn updateFrameAnimState(ms_elapsed: f64, state: *FrameAnimState, frame_rate: u32, num_frames: usize) void {
//     var frame_time_ms = 1000.0 / @intToFloat(f64, frame_rate);
//     if (num_frames <= 1) {
//         if (state.frame > 0) {
//             state.last_frame_elapsed_ms += ms_elapsed;
//             state.frame = 0;
//         }
//         return;
//     }

//     state.last_frame_elapsed_ms += ms_elapsed;
//     if (state.last_frame_elapsed_ms >= frame_time_ms) {
//         var frames_elapsed = @floatToInt(u32, state.last_frame_elapsed_ms / frame_time_ms);            
//         state.last_frame_elapsed_ms -= frame_time_ms;
//         state.frame = @mod(state.frame + frames_elapsed, @intCast(u32, num_frames));
//     }
// }

// fn updateAnimatedSpriteEntities() void {
//     const ms_elapsed: f64 = sokol.time.ms(globals.dt_ticks);
//     var view = globals.entities.reg.view(.{SpriteRenderComponent}, .{});
//     for (view.raw()) |*sprite| {
//         const desc: *const SpriteDesc = sprite.desc.get();
//         updateFrameAnimState(ms_elapsed, &sprite.frame_anim_state, desc.frame_rate, desc.frames.len);
//     }
// }

// fn updateAnimatedTileEntities() void {
//     const ms_elapsed: f64 = sokol.time.ms(globals.dt_ticks);
//     var view = globals.entities.reg.view(.{TilemapRenderComponent}, .{});
//     for (view.raw()) |*tilemap| {
//         for (tilemap.tiles) |*tile, i| {
//             const tile_spritedesc: *const SpriteDesc = tilemap.desc.get().tileAtIndex(i);
//             if (tile_spritedesc.frames.len <= 1) {
//                 continue;
//             }
//             updateFrameAnimState(ms_elapsed, &tile.frame_anim_state, tile_spritedesc.frame_rate, tile_spritedesc.frames.len);
//         }
//     }
// }

// fn beginImGuiFrame() void {
//     const dt_secs64: f64 = sokol.time.sec(globals.dt_ticks);
//     sokol_imgui.newFrame(.{
//         .width = @floatToInt(i32, globals.window_size.x),
//         .height = @floatToInt(i32, globals.window_size.y),
//         .delta_time = dt_secs64,
//         .dpi_scale = 1,
//     });   
// }

fn onAppFrame() callconv(.C) void {
    // const app = App.get();

    // // advance time
    // globals.dt_ticks = sokol.time.laptime(&globals.time_ticks);

    // beginImGuiFrame();

    // input();

    // globals.drawImGui();
    // globals.menubar.drawImGui();
    // globals.scene_editor.drawImGui();
    // ResourceDebugger.drawImGui();

    // followFriendsSystem();

    // updateAnimatedSpriteEntities();
    // updateAnimatedTileEntities();

    // var str = std.fmt.allocPrintZ(app.alloc, "Cam zoom: {}", .{globals.cam_zoom}) catch unreachable;
    // defer app.alloc.free(str);
    // drawText(str, Rgba8.yellow);

    // render(app.alloc);

    // renderBeginDebugPass();
    // renderDebugText();
    // renderImGui();
    // renderEndDebugPass();

    // Resources.processUnloadQueue();
}

// fn onAppCleanup() callconv(.C) void {
//     // sokol_imgui.shutdown();
//     // sgfx.shutdown();
//     // globals.deinit();
//     // editorui.shutdown();
//     // Resources.shutdown();
//     // Storage.deinit();
// }

// fn onAppEvent(sokol_event: [*c] const sokol.app.Event) callconv(.C) void {
//     _ = sokol_event;
//     // var evt = @as(*const sokol.app.Event, sokol_event);
//     // switch (evt.type) {
//     //     .MOUSE_DOWN, .MOUSE_UP, .MOUSE_MOVE, .MOUSE_ENTER, .MOUSE_LEAVE, .CHAR => {},
//     //     else => {
//     //         if (evt.type != .KEY_DOWN and evt.type != .KEY_UP) {
//     //         // {
//     //             if (evt.type != .KEY_DOWN or !evt.key_repeat) {
//     //                 std.log.info("event: {}, w/h: {}/{}, k: {}, mx/my: {}/{}", .{evt.type, evt.window_width, evt.window_height, evt.key_code, evt.mouse_x, evt.mouse_y});
//     //             }
//     //         }
//     //     },
//     // }

//     // // if (sokol_imgui.handleEvent(sokol_event)) {
//     // //     return;
//     // // }

//     // switch (evt.type) {
//     //     // .ICONIFIED => globals.window_state = .minimized,
//     //     // .RESTORED => globals.window_state = .open,
//     //     .RESIZED => {
//     //         if (evt.window_width > 0 or evt.window_height > 0) {
//     //             // globals.window_size = m.vec2f(@max(1, evt.window_width), @max(1, evt.window_height));
//     //         }
//     //     },
//     //     .KEY_DOWN => {
//     //         // globals.modifiers = evt.modifiers;
//     //         // globals.keystate.getPtr(evt.key_code).* = true;

//     //         if (evt.key_code == .C) {
//     //             // globals.cull = @intToEnum(sgfx.CullMode, @mod(@enumToInt(globals.cull) + 1, @enumToInt(sgfx.CullMode.NUM)));
//     //             // std.log.info("Cull mode: {}", .{globals.cull});
//     //             // globals.draw_state.pipeline_dirty = true;
//     //         }

//     //         if (evt.key_code == .U) {
//     //             // globals.show_imgui_demo = !globals.show_imgui_demo;
//     //         }

//     //         if (evt.key_code == .F12) {                
//     //             // globals.menubar.toggle();
//     //         }
//     //     },
//     //     .KEY_UP => {
//     //         // globals.modifiers = evt.modifiers;
//     //         // globals.keystate.getPtr(evt.key_code).* = false;
//     //     },
//     //     else => {}
//     // }
// }

////////////////////////////////////////////////////////////////////////////////
// Common data (static/runtime)
////////////////////////////////////////////////////////////////////////////////

// const Transform2D = struct {
//     // position: m.Vec2f = .{},
//     // scale: m.Vec2f = .{.x = 1, .y = 1},
//     rotation: f32 = 0,
// };

// ////////////////////////////////////////////////////////////////////////////////
// // Constant/static data
// ////////////////////////////////////////////////////////////////////////////////

pub const SpriteFrame = struct {
    atlas: ResourcePin(Image),
    // uvrect: m.Recti,
};

pub const SpriteDesc = struct {
    frames: []SpriteFrame,
    frame_rate: u32 = 30, 
    // pivot: m.Vec2f = m.vec2f(0, 0),

    pub fn deinit(self: *@This(), alloc: Allocator) void {
        type_registry.DeinitFor([]SpriteFrame).deinit(&self.frames, alloc);
        // alloc.free(self.frames);
    }
};

// pub const TilemapDesc = struct {
//     pub const TileRef = struct {
//         sprite: ResourcePin(SpriteDesc),
//         tile_id: u32,

//         pub fn cmpTileID(_: void, key: u32, rhs: TileRef) std.math.Order {
//             const Ord = std.math.Order;
//             return
//                 if (key == rhs.tile_id) Ord.eq
//                 else if (key < rhs.tile_id) Ord.lt
//                 else Ord.gt;
//         }

//         pub fn cmpLess(_: void, lhs: TileRef, rhs: TileRef) bool {
//             return lhs.tile_id < rhs.tile_id;
//                 // if (lhs.tile_id == rhs.tile_id) std.math.Order.eq
//                 // else if () std.math.Order.lt
//                 // else std.math.Order.gt;
//         }
//     };

//     tile_refs: []TileRef,
//     tile_grid: []u32,
//     dimensions: m.Vec2i,
//     tile_size: m.Vec2f,

//     pub fn tileAtIndex(self: @This(), i: usize) *const SpriteDesc {
//         const tile_id = self.tile_grid[i];
//         if (algo.binarySearch(TileRef, tile_id, self.tile_refs, void{}, TileRef.cmpTileID)) |tile_index| {
//             return self.tile_refs[tile_index].sprite.get();
//         }
//         @panic("Couldn't find the tile!");
//         // return ResourceHandle(SpriteDesc).invalid;
//     }

//     pub fn tileAt(self: @This(), x: usize, y: usize) *const SpriteDesc {
//         std.debug.assert(x < self.dimensions.x);
//         std.debug.assert(y < self.dimensions.y);
//         return self.tileAtIndex(y * @intCast(usize, self.dimensions.x) + x);
//     }

//     // pub fn deinit(self: *@This(), alloc: Allocator) void {
//     //     alloc.free(self.tile_refs);
//     //     alloc.free(self.tile_grid);
//     // }

//     pub const SerializerHooks = struct {
//         pub fn postLoad(self: *TilemapDesc) void {
//             std.sort.sort(TileRef, self.tile_refs, void{}, TileRef.cmpLess);
//         }
//     };
// };

// ////////////////////////////////////////////////////////////////////////////////
// // Runtime data
// ////////////////////////////////////////////////////////////////////////////////

// const FrameAnimState = struct {
//     frame: u32 = 0,
//     last_frame_elapsed_ms: f64 = 0,
// };

// const Tile = struct {
//     textures: []const sgfx.Image,
//     frame_anim_state: FrameAnimState = .{},
// };

// ////////////////////////////////////////////////////////////////////////////////
// // Components
// ////////////////////////////////////////////////////////////////////////////////

// pub const SpriteRenderComponent = struct {
//     desc: ResourcePin(SpriteDesc), // serialize
//     debug_name: metautils.Conditional(String, .{.Debug}) = String.empty,

//     textures: []const sgfx.Image = &.{}, // noserialize
//     frame_anim_state: FrameAnimState = .{}, // noserialize

//     pub const ATTRIBUTES = .{
//         .FIELDS = .{
//             .textures = .{
//                 serialization.Attributes.unserialized,
//                 SceneEditor.InspectorVisibility.hidden,
//             },
//             .frame_anim_state = .{
//                 serialization.Attributes.unserialized,
//             },
//         }
//     };
// };

// pub const Transform2DComponent = struct {
//     pub const UniqueTypeName = "Transform2DComponent";

//     local: Transform2D = .{},
// };

// pub const TilemapRenderComponent = struct {
//     desc: ResourcePin(TilemapDesc), // serialize

//     tiles: []Tile = &.{},

//     name: metautils.Conditional([]const u8, .{.Debug}),

//     // pub fn deinit(self: @This(), alloc: Allocator) void {
//     //     alloc.free(self.tiles);
//     // }
// };

// // pub fn OwnedSlice(comptime T: type) type {
// //     return struct {
// //         slice: []T,

// //         pub fn init(slice: []T) OwnedSlice {
// //             var result: @This() = undefined;
// //             result.initSelf(slice);
// //             return result;
// //         }

// //         pub fn initSelf(self: @This(), slice: []T) OwnedSlice {
// //             self.slice = slice;
// //         }

// //         pub fn deinit(self: @This(), alloc: Allocator) void {
// //             alloc.free(self.slice);
// //         }
// //     };
// // }

// pub const TestSliceComponent = struct {
//     numbers_numbers_numbers: []i32,

//     pub fn deinit(self: @This(), alloc: Allocator) void {
//         alloc.free(self.numbers_numbers_numbers);
//     }
// };

// pub const TestStruct = struct {
//     my_sbyte: i8,
//     my_string: []u8,
// };

// pub const TestStructSlice = struct {
//     the_list: []TestStruct,

//     // pub fn deinit(self: @This(), alloc: Allocator) void {
//     //     alloc.free(self.the_list);
//     // }
// };

// pub const TypeWithDeinit = struct {
//     _: u8 = undefined,

//     pub fn deinit(_: @This()) void {
//         std.log.info("TypeWithDeinit has its deinit being called!!!", .{});
//     }
// };

// pub const TestDeinitComponent = struct {
//     _: u8 = undefined,
//     with_deinit: TypeWithDeinit = .{},

//     pub const ATTRIBUTES = .{
//         .FIELDS = .{
//         //     .with_deinit = .{
//         //         type_registry.Attributes.no_auto_deinit,
//         //     },
//         },
//         .COMPONENT = .{
//         },
//         .THIS = .{
//             // type_registry.Attributes.no_auto_deinit,
//         },
//     };


//     pub fn deinit(_: @This()) void {
//         std.log.info("TestDeinitComponent has its deinit being called!!!", .{});
//     }
// };

// pub const SceneAnyLink = struct {
//     link: ?LinkData = null,

//     pub const LinkData = struct {
//         entity: ecs.Entity,
//         component: ?RuntimeTypeID = null,
//     };

//     pub const IMPLEMENTS = .{
//         interface.ifx(InspectorDrawer).implSelf(@This()),
//     };

//     pub fn resolveLink(self: @This(), comptime T: type) ?*T {
//         if (self.link) |link| {
//             if (comptime T == ecs.Entity) {
//                 return link.entity;
//             }

//             if (link.component) |comp_tid| {
//                 if (comp_tid == RuntimeType.id(T)) {
//                     return globals.entities.tryGet(T, link.entity);
//                 }
//             }
//         }
//         return null;
//     }

//     pub fn drawInspector(
//         self: *@This(),
//         editor: *SceneEditor,
//         label: [:0]const u8,
//         rt_type: *const type_registry.RtTypeInfo
//     ) void {
//         _ = rt_type;

//         imgui.Text("woo baby it worked, SceneAnyLink!");
//         imgui.SetNextItemOpen(true);
//         _ = imgui.TreeNode_Str(label);
//         defer imgui.TreePop();

//         {
//             const EntityPickerContext = struct {
//                 buf: [64]u8 = [1]u8{0} ** 64,
//                 pub fn itemLabel(this: *@This(), entity: ?ecs.Entity) [:0]const u8 {
//                     return if (entity) |e|
//                         std.fmt.bufPrintZ(&this.buf, "Entity#{}", .{e}) catch unreachable
//                     else
//                         "[None]";
//                 }
//                 pub fn pushID(_: *@This(), entity: ecs.Entity) void {
//                     imgui.PushID_Int(@bitCast(i32, entity));
//                 }
//             };
//             var picker = editorui.ImPicker(ecs.Entity, EntityPickerContext){
//                 .selected = if (self.link) |link|
//                     link.entity
//                 else
//                     null,
//             };
//             {
//                 defer picker.end();
//                 if (picker.begin("entity_picker")) {
//                     if (picker.option(null)) {
//                         self.link = null;
//                     }
//                     var iter = globals.entities.entities();
//                     while (iter.next()) |entity| {
//                         if (picker.option(entity)) {
//                             self.link = self.link orelse LinkData{
//                                 .entity = entity,
//                             };

//                             if (self.link.?.component) |comp_tid| {
//                                 if (globals.entities.tryGetOpaque(comp_tid, entity) == null) {
//                                     self.link.?.component = null;
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
//             imgui.SameLine();
//             const selected_entity = if (self.link) |link| link.entity else null;
//             const cur_entity_label = if (selected_entity) |e| picker.context.itemLabel(e) else "[None]";
//             imgui.SetNextItemWidth(picker.available_item_width);
//             editor.input_text_helper.copyableText("entity", cur_entity_label);
//         }

//         if (self.link) |*link| {
//             const ComponentPickerContext = struct {
//                 pub fn itemLabel(_: *@This(), comp: ?RuntimeTypeID) [:0]const u8 {
//                     if (comp) |c| {
//                         const comp_rtti = globals.registered_types.lookupByRttid(c);
//                         return comp_rtti.name;
//                     } else {
//                         return "[None]";
//                     }
//                 }
//                 pub fn pushID(_: *@This(), comp: RuntimeTypeID) void {
//                     imgui.PushID_Ptr(comp);
//                 }
//             };
//             var picker = editorui.ImPicker(RuntimeTypeID, ComponentPickerContext){ .selected = link.component };
//             {
//                 defer picker.end();
//                 if (picker.begin("component_picker")) {

//                     if (picker.option(null)) {
//                         link.component = null;
//                     }
//                     var it = globals.entities.registeredComponentsIterator();
//                     while (it.next()) |comp_tid| {
//                         if (globals.entities.tryGetOpaque(comp_tid.*, link.entity) != null) {
//                             if (picker.option(comp_tid.*)) {
//                                 link.component = comp_tid.*;
//                             }
//                         }
//                     }
//                 }
//             }
//             imgui.SameLine();
//             const selected_comp = link.component;
//             const cur_comp_label = if (selected_comp) |comp| picker.context.itemLabel(comp) else "[None]";
//             imgui.SetNextItemWidth(picker.available_item_width);
//             editor.input_text_helper.copyableText("component", cur_comp_label);
//         }
//     }

//     pub const SerializerHooks = struct {
//         pub fn loadFromJsonStream(
//             // comptime TSerializer: type,
//             dest: *SceneAnyLink,
//             state: *serialization.SerializerJsonLoadState,
//         ) !void {
//             //
//             // { entity: id, component: id}
//             //

//             const entity_remapper = state.context.get(EntityRemapper);

//             var helper = serialization.StreamHelper.init(state);
//             try helper.expectObjBegin();
//             try helper.expectProperty("entity");
//             const entity_id = try helper.expectNumber(ecs.Entity);
//             try helper.expectProperty("component");

//             const maybe_reg_type = if (try helper.tryString()) |comp_typename|
//                 globals.registered_types.lookupName(comp_typename)
//             else
//                 try helper.expectNull(*const type_registry.RtTypeInfo);

//             const maybe_component_rttid = if (maybe_reg_type) |reg_type|
//                 reg_type.rttid
//             else
//                 null;

//             dest.* = .{
//                 .link = .{
//                     .entity = entity_remapper.getOrAdd(entity_id),
//                     .component = maybe_component_rttid,
//                 }
//             };
            
//             try helper.expectObjEnd();
//         }

//         pub fn writeToJsonStream(
//             src: *const SceneAnyLink,
//             state: *serialization.SerializerJsonWriteState,
//         ) !void {
//             var w = state.jsonWriter();
//             w.singleLineBegin();
//             defer w.singleLineEnd();

//             try w.objBegin();
//             try w.field("entity");

//             if (src.link) |link| {
//                 try SceneLoader.RootSerializerType.writeToJsonWithState(ecs.Entity, &link.entity, state);

//                 try w.field("component");

//                 const maybe_component_rtti = if (link.component) |comp|
//                     globals.registered_types.lookupByRttid(comp)
//                 else
//                     null;

//                 if (maybe_component_rtti) |comp_rtti| {
//                     try w.quoted(comp_rtti.name);
//                 } else {
//                     try w.unquoted("null");
//                 }
//             } else {
//                 try w.unquoted("null");
//                 try w.field("component");
//                 try w.unquoted("null");
//             }
            
//             try w.objEnd();
//         }
//     };
// };

// pub const FrendtityComponent = struct {
//     friend: SceneAnyLink,
// };

// pub const FollowFriendComponent = struct {
//     friend: SceneAnyLink,
//     distance: f32 = 9999,
//     rate: f32 = 10,
// };

// ////////////////////////////////////////////////////////////////////////////////
// // Entity Manager
// ////////////////////////////////////////////////////////////////////////////////

// pub const EntityComponentIterator = struct {
//     g_comp_iter: std.meta.fieldInfo(EntityManager, .registered_components).field_type.Iterator,
//     entity: ecs.Entity,

//     pub fn init(em: EntityManager, entity: ecs.Entity) @This() {
//         return .{
//             .g_comp_iter = em.registered_components.iterator(),
//             .entity = entity,
//         };
//     }

//     pub fn next(self: *@This()) ?type_registry.RtTIDPtr {
//         while (self.g_comp_iter.next()) |kv| {
//             const comp_rttid: RuntimeTypeID = kv.key_ptr.*;
//             if (globals.entities.tryGetOpaque(comp_rttid, self.entity)) |comp_ptr| {
//                 return type_registry.RtTIDPtr{ .ptr = comp_ptr, .tid = comp_rttid };
//             }
//         }
//         return null;
//     }
// };

// pub const RegisteredComponent = struct {
//     destructor: Generate.DestructorFor(void) = undefined,
//     adder_fn: AddComponentFnPtr = undefined,
//     remover_fn: RemoveComponentFnPtr = undefined,
//     try_get_opaque_fn: TryGetOpaqueFnPtr = undefined,
//     draw_inspector_fn: ?SceneEditor.DrawInspectorFnPtr = undefined,

//     pub fn add(self: @This(), em: *EntityManager, entity: ecs.Entity, comp_init: ComponentInit) *anyopaque {
//         return self.adder_fn(em, entity, comp_init);
//     }

//     pub fn remove(self: @This(), em: *EntityManager, entity: ecs.Entity) bool {
//         return self.remover_fn(em, entity);
//     }

//     pub fn tryGetOpaque(self: @This(), em: *EntityManager, entity: ecs.Entity) ?*anyopaque {
//         return self.try_get_opaque_fn(em, entity);
//     }

//     pub fn setup(self: *@This(), comptime T: type, em: *EntityManager) void {
//         const Destructor = Generate.DestructorFor(T);
//         if (comptime Destructor.has_deinit) {
//             self.destructor = .{
//                 .emgr = em,
//             };
//             em.reg.onDestruct(T).connectBound(metautils.castPtr(*Destructor, &self.destructor), "destruct");
//         }
//         self.adder_fn = Generate.componentAdderFor(T);
//         self.remover_fn = Generate.componentRemoverFor(T);
//         self.try_get_opaque_fn = Generate.tryGetOpaqueFnFor(T);
//         self.draw_inspector_fn = Generate.inspectorDrawerFor(T);
//     }

//     const ComponentInit = enum {
//         uninit,
//         zeroinit,
//     };

//     const DestructorPtr = *align(@alignOf(Generate.DestructorFor(void))) [@sizeOf(Generate.DestructorFor(void))]u8;
//     const AddComponentFn = fn (*EntityManager, ecs.Entity, init: ComponentInit) *anyopaque;
//     const AddComponentFnPtr = *const AddComponentFn;
//     const RemoveComponentFn = fn(*EntityManager, ecs.Entity) bool;
//     const RemoveComponentFnPtr = *const RemoveComponentFn;
//     const TryGetOpaqueFn = fn (*EntityManager, ecs.Entity) ?*anyopaque;
//     const TryGetOpaqueFnPtr = *const TryGetOpaqueFn;

//     const Generate = struct {
//         fn inspectorDrawerFor(comptime T: type) ?SceneEditor.DrawInspectorFn {
//             return SceneEditor.Generate.inspectorDrawerFor(T);
//         }

//         fn DestructorFor(comptime T: type) type {
//             return struct {
//                 emgr: *anyopaque,

//                 const has_deinit =
//                     !type_attributes.hasAttributeValue(T, type_registry.Attributes.no_auto_deinit)
//                     and type_registry.typeNeedsDeinit(T);

//                 pub fn destruct(self: *@This(), entity: ecs.Entity) void {
//                     if (comptime has_deinit) {
//                         var entity_manager = metautils.castPtr(*EntityManager, self.emgr);
//                         var comp: *T = entity_manager.reg.get(T, entity);
//                         type_registry.DeinitFor(T).deinit(comp, entity_manager.reg.allocator);
//                     }
//                 }
//             };
//         }

//         fn componentRemoverFor(comptime T: type) RemoveComponentFn {
//             return struct {
//                 pub fn removeFromEntity(emgr: *EntityManager, entity: ecs.Entity) bool {
//                     if (emgr.reg.has(T, entity)) {
//                         emgr.reg.remove(T, entity);
//                         return true;
//                     }
//                     return false;
//                 }
//             }.removeFromEntity;
//         }

//         fn componentAdderFor(comptime T: type) AddComponentFn {
//             return struct {
//                 pub const ComponentType = T;
//                 pub fn addToEntity(emgr: *EntityManager, entity: ecs.Entity, comp_init: RegisteredComponent.ComponentInit) *anyopaque {
//                     return emgr.add(
//                         entity,
//                         switch (comp_init) {
//                             .uninit => @as(T, undefined),
//                             .zeroinit => std.mem.zeroInit(T, .{}),
//                         },
//                     );
//                 }
//             }.addToEntity;
//         }

//         fn tryGetOpaqueFnFor(comptime T: type) TryGetOpaqueFn {
//             return struct {
//                 pub fn tryGetFromRttid(emgr: *EntityManager, entity: ecs.Entity) ?*anyopaque {
//                     return emgr.tryGet(T, entity);
//                 }
//             }.tryGetFromRttid;
//         }
//     };
// };

// pub const EntityManager = struct {
//     const Self = @This();
//     const RegisteredComponentsMap = std.AutoHashMap(RuntimeTypeID, *RegisteredComponent);

//     reg: ecs.Registry,
//     registered_components: RegisteredComponentsMap,    

//     pub fn init(alloc: Allocator) EntityManager {
//         return .{
//             .reg = ecs.Registry.init(alloc),
//             .registered_components = RegisteredComponentsMap.init(alloc),
//         };
//     }

//     pub fn allocator(self: @This()) Allocator {
//         return self.registered_components.allocator;
//     }

//     pub fn deinit(self: *Self) void {
//         // This is required to run destructors on all remaining components
//         // would be nice if destructors weren't totally necessary :shrug:
//         var entity_iter = self.reg.entities();
//         while (entity_iter.next()) |entity| {
//             self.reg.removeAll(entity);
//         }
//         self.reg.deinit();

//         var comp_iter = self.registered_components.valueIterator();
//         while (comp_iter.next()) |ptr| {
//             self.registered_components.allocator.destroy(ptr.*);
//         }
//         self.registered_components.deinit();
//     }

//     pub fn entityComponentsIterator(self: Self, entity: ecs.Entity) EntityComponentIterator {
//         return EntityComponentIterator.init(self, entity);
//     }

//     pub fn registeredComponentsIterator(self: Self) RegisteredComponentsMap.KeyIterator {
//         return self.registered_components.keyIterator();
//     }

//     pub fn ensureComponentRegistered(self: *Self, comptime T: type) void {
//         if (comptime @sizeOf(T) == 0) {
//             @compileError("Component is a zero-sized type, which is not allowed: " ++ @typeName(T));
//         }
//         if (globals.registered_types.tryLookupType(T)) |reg_type| {
//             var gop = self.registered_components.getOrPut(reg_type.rttid) catch unreachable;
//             // var gop = self.registered_components.getOrPut(reg_type.getRTTID()) catch unreachable;
//             if (!gop.found_existing) {
//                 var reg_comp_ptr: *RegisteredComponent = self.registered_components.allocator.create(RegisteredComponent) catch unreachable;
//                 reg_comp_ptr.setup(T, self);
//                 gop.value_ptr.* = reg_comp_ptr;
//             }
//         } else {
//             @panic("Register component types in the type registry before adding them to EntityManager");
//         }
//     }

//     pub fn entityExists(self: *Self, e: ecs.Entity) bool {
//         return self.reg.valid(e);
//     }

//     pub fn createEntity(self: *Self) ecs.Entity {
//         return self.reg.create();
//     }

//     pub fn add(self: *Self, entity: ecs.Entity, value: anytype) *@TypeOf(value) {
//         const T = @TypeOf(value);

//         // prime31 not as his best with this api tbh
//         self.reg.add(entity, value);
//         return self.reg.get(T, entity);
//     }

//     pub fn addUninit(self: *Self, rttid: RuntimeTypeID, entity: ecs.Entity) *anyopaque {
//         return self.tryAddUninit(rttid, entity).?;
//     }

//     pub fn tryAddUninit(self: *Self, rttid: RuntimeTypeID, entity: ecs.Entity) ?*anyopaque {
//         if (self.registered_components.get(rttid)) |reg_comp| {
//             return reg_comp.add(self, entity, .uninit);
//         }
//         return null;
//     }

//     pub fn addZeroInit(self: *Self, rttid: RuntimeTypeID, entity: ecs.Entity) ?*anyopaque {
//         return self.tryAddZeroInit(rttid, entity).?;
//     }

//     pub fn tryAddZeroInit(self: *Self, rttid: RuntimeTypeID, entity: ecs.Entity) ?*anyopaque {
//         if (self.registered_components.get(rttid)) |reg_comp| {
//             return reg_comp.add(self, entity, .zeroinit);
//         }
//         return null;
//     }

//     pub fn remove(self: *Self, rttid: RuntimeTypeID, entity: ecs.Entity) bool {
//         if (self.registered_components.get(rttid)) |reg_comp| {
//             return reg_comp.remove(self, entity);
//         }
//         return false;
//     }

//     pub fn get(self: *Self, comptime T: type, entity: ecs.Entity) *T {
//         return self.reg.get(T, entity);
//     }

//     pub fn tryGet(self: *Self, comptime T: type, entity: ecs.Entity) ?*T {
//         return self.reg.tryGet(T, entity);
//     }

//     pub fn tryGetOpaque(self: *Self, rttid: RuntimeTypeID, entity: ecs.Entity) ?*anyopaque {
//         if (self.registered_components.get(rttid)) |reg_component_ptr| {
//             return reg_component_ptr.tryGetOpaque(self, entity);
//         }
//         return null;
//     }

//     pub fn tryGetOrAddUninitOpaque(self: *Self, rttid: RuntimeTypeID, entity: ecs.Entity) ?*anyopaque {
//         return self.tryGetOrAddOpaqueImpl(rttid, entity, .uninit);
//     }

//     pub fn tryGetOrAddZeroInitOpaque(self: *Self, rttid: RuntimeTypeID, entity: ecs.Entity) ?*anyopaque {
//         return self.tryGetOrAddOpaqueImpl(rttid, entity, .zeroinit);
//     }

//     pub fn getOrAddUninitOpaque(self: *Self, rttid: RuntimeTypeID, entity: ecs.Entity) *anyopaque {
//         return self.tryGetOrAddOpaqueImpl(rttid, entity, .uninit).?;
//     }

//     pub fn getOrAddZeroInitOpaque(self: *Self, rttid: RuntimeTypeID, entity: ecs.Entity) *anyopaque {
//         return self.tryGetOrAddOpaqueImpl(rttid, entity, .zeroinit).?;
//     }

//     fn tryGetOrAddOpaqueImpl(self: *Self, rttid: RuntimeTypeID, entity: ecs.Entity, comp_init: RegisteredComponent.ComponentInit) ?*anyopaque {
//         if (self.registered_components.get(rttid)) |reg_comp| {
//             if (reg_comp.tryGetOpaque(self, entity)) |component_ptr| {
//                 return component_ptr;
//             } else {
//                 return reg_comp.add(self, entity, comp_init);
//             }
//         }
//         return null;
//     }

//     pub fn entities(self: *Self) metautils.RetTypeOf(ecs.Registry.entities) {
//         return self.reg.entities();
//     }

//     // pub fn view(self: *Self, comptime includes: anytype, comptime excludes: anytype) ecs.Registry.ViewType(includes, excludes) {
//     //     return self.reg.view(includes, excludes);
//     // }

//     pub fn destroyEntity(self: *Self, entity: ecs.Entity) void {
//         self.reg.destroy(entity);
//     }

//     pub fn destroyAllEntities(self: *Self) void {
//         var entity_iter = self.reg.entities();
//         while (entity_iter.next()) |entity| {
//             self.destroyEntity(entity);
//         }
//     }

//     pub fn tryGetComponentInspectorDrawer(self: @This(), rttid: RuntimeTypeID) ?SceneEditor.DrawInspectorFn {
//         if (self.registered_components.get(rttid)) |reg_comp| {
//             return reg_comp.draw_inspector_fn;
//         }
//         return null;
//     }
// };

// ////////////////////////////////////////////////////////////////////////////////
// // Scene Resource
// ////////////////////////////////////////////////////////////////////////////////

// // pub const ComponentStaticInterface = struct {
// //     fn_addToEntity: fn (emgr: *EntityManager, entity: ecs.Entity) Allocator.Error![]u8,
// //     fn_destroy: fn (data: *anyopaque, alloc: Allocator) void,
// //     fn_postLoad: fn (data: *anyopaque, alloc: Allocator) void,

// //     pub fn addToEntity(self: @This(), emgr: *EntityManager, entity: ecs.Entity) ComponentError![]u8 {
// //         return self.fn_create(alloc);
// //     }

// //     pub fn postLoad(self: @This(), data: *anyopaque, alloc: Allocator) void {
// //         self.fn_postLoad(data, alloc);
// //     }
// // };

// pub const EntityRemapper = struct {
//     id_table: std.AutoHashMap(ecs.Entity, ecs.Entity),
//     entity_manager: *EntityManager,

//     pub fn init(entity_manager: *EntityManager) @This() {
//         return .{
//             .id_table = std.AutoHashMap(ecs.Entity, ecs.Entity).init(entity_manager.allocator()),
//             .entity_manager = entity_manager,
//         };
//     }

//     pub fn deinit(self: *@This()) void {
//         self.id_table.deinit();
//     }

//     pub fn reset(self: *@This()) void {
//         self.id_table.clearRetainingCapacity();
//     }

//     pub fn getOrAdd(self: *@This(), entity: ecs.Entity) ecs.Entity {
//         var gop = self.id_table.getOrPut(entity) catch unreachable;
//         if (!gop.found_existing) {
//             gop.value_ptr.* = self.entity_manager.createEntity();
//         }

//         return gop.value_ptr.*;
//     }
// };

// pub const SceneLoader = AutoSceneLoader(.{});

// pub fn AutoSceneLoader(comptime Serializers: anytype) type {
//     _ = Serializers;
//     return struct {
// //         const RootSerializerType = serialization.ChainedSerializer(.{@This()} ++ Serializers);
// //         const ComponentSerializerMap = std.AutoHashMap(RuntimeTypeID, ComponentSerializer);

// //         entity_manager: *EntityManager,
// //         component_serializers: ComponentSerializerMap,
// //         entity_remapper: EntityRemapper,

// //         const Scene = struct{};
// //         const Component = struct{};

// //         const ComponentSerializer = struct {
// //             write_to_json_fn: WriteComponentFnPtr,
// //             load_from_json_fn: LoadComponentFnPtr,
// //             serialized_name: []const u8,

// //             pub fn writeToJson(
// //                 self: ComponentSerializer,
// //                 src: *anyopaque,
// //                 state: *serialization.SerializerJsonWriteState,
// //             ) anyerror!void {
// //                 return self.write_to_json_fn(src, state);
// //             }

// //             pub fn loadFromJson(
// //                 self: ComponentSerializer,
// //                 dest: *anyopaque,
// //                 state: *serialization.SerializerJsonLoadState,
// //             ) anyerror!void {
// //                 return self.load_from_json_fn(dest, state);
// //             }
// //         };

// //         const LoadComponentFn = fn (
// //             dest: *anyopaque,
// //             state: *serialization.SerializerJsonLoadState,
// //         ) anyerror!void;
// //         const LoadComponentFnPtr = *const LoadComponentFn;

// //         const WriteComponentFn = fn (
// //             src: *anyopaque,
// //             state: *serialization.SerializerJsonWriteState,
// //         ) anyerror!void;
// //         const WriteComponentFnPtr = *const WriteComponentFn;
        

// //         pub fn init(entity_manager: *EntityManager) SceneLoader {
// //             return .{
// //                 .entity_manager = entity_manager,
// //                 .component_serializers = ComponentSerializerMap.init(entity_manager.allocator()),
// //                 .entity_remapper = EntityRemapper.init(entity_manager),
// //             };
// //         }

// //         pub fn deinit(self: *@This()) void {
// //             self.entity_remapper.deinit();
// //             self.component_serializers.deinit();
// //         }

// //         pub fn ensureComponentRegistered(self: *@This(), comptime T: type) void {
// //             const rttid = RuntimeType.id(T);
// //             // std.log.info("SceneLoader.ensureComponentRegistered: rttid of {s} is {}", .{@typeName(T), rttid});

// //             var gop_serializer = self.component_serializers.getOrPut(rttid) catch unreachable;
// //             if (!gop_serializer.found_existing) {
// //                 gop_serializer.value_ptr.* = ComponentSerializer{
// //                     .write_to_json_fn = ComponentWriterFor(T).writeComponentToJson,
// //                     .load_from_json_fn = ComponentLoaderFor(T).loadComponentFromJson,
// //                     .serialized_name = type_registry.uniqueTypeName(T),
// //                 };
// //             }
// //         }

// //         pub fn loadSceneFromJsonFile(
// //             self: *@This(),
// //             path: []const u8,
// //         ) !void {
// //             const alloc = self.entity_manager.allocator();
// //             var file_data = std.fs.cwd().readFileAlloc(alloc, path, std.math.maxInt(usize)) catch unreachable;
// //             defer alloc.free(file_data);
// //             loadSceneFromJson(file_data);
// //             // var stream = std.json.TokenStream.init(file_data);

// //             // var load_state = serialization.SerializerJsonLoadState.initWithContext(&stream, alloc, .{self, &self.entity_remapper});
// //             // defer load_state.deinit();
// //             // var fake_scene = Scene{};
// //             // try RootSerializerType.loadFromJsonWithState(Scene, &fake_scene, &load_state);
// //         }

// //         pub fn loadSceneFromJson(
// //             self: *@This(),
// //             json: []const u8,
// //         ) !void {
// //             var stream = std.json.TokenStream.init(json);
// //             var load_state = serialization.SerializerJsonLoadState.initWithContext(&stream, self.entity_manager.allocator(), .{self, &self.entity_remapper});
// //             defer load_state.deinit();
// //             var fakeScene = Scene{};
// //             try RootSerializerType.loadFromJsonWithState(Scene, &fakeScene, &load_state);
// //         }

// //         pub fn writeSceneToJsonString(
// //             self: *@This(),
// //         ) []u8 {
// //             var write_state = serialization.SerializerJsonWriteState.initWithContext(self.entity_manager.allocator(), .{self});
// //             defer write_state.deinit();

// //             var fake_scene = Scene{};
// //             RootSerializerType.writeToJsonWithState(Scene, &fake_scene, &write_state) catch unreachable;
// //             return write_state.jsonWriter().toOwnedSlice();
// //         }

// //         pub fn TryResolveSerializer(comptime T: type) ?type {
// //             // if (comptime T == ecs.Entity or T == Scene) {
// //                 // return SceneSerializer;
// //             // }
// //             if (T == Scene) {
// //                 return SceneSerializer;
// //             }
// //             return null;
// //         }

// //         pub fn ComponentLoaderFor(comptime T: type) type {
// //             return struct {
// //                 pub fn loadComponentFromJson(dest: *anyopaque, state: *serialization.SerializerJsonLoadState) !void {
// //                     std.log.info("Deserializing component {}, align of " ++ @typeName(T) ++ " is {}", .{dest, @alignOf(T)});
// //                     try RootSerializerType.loadFromJsonWithState(T, metautils.castPtr(*T, dest), state);
// //                 }
// //             };
// //         }

// //         pub fn ComponentWriterFor(comptime T: type) type {
// //             return struct {
// //                 pub fn writeComponentToJson(src: *anyopaque, state: *serialization.SerializerJsonWriteState) anyerror!void {
// //                     std.log.info("Serializing component " ++ @typeName(T), .{});
// //                     try RootSerializerType.writeToJsonWithState(T, metautils.castPtr(*const T, src), state);
// //                 }
// //             };
// //         }

// //         const SceneSerializer = struct {
// //             pub fn loadFromJsonStream(
// //                 comptime TSerializer: type,
// //                 dest: anytype,
// //                 state: *serialization.SerializerJsonLoadState,
// //             ) !void {
// //                 typeCheckSerializer(TSerializer);

// //                 // {
// //                 //   "entities": [
// //                 //     {
// //                 //       "components": [
// //                 //         {
// //                 //           "%metadata": {
// //                 //             "type": "Transform2DComponent",
// //                 //           },
// //                 //           "%data": {
// //                 //             "local": {
// //                 //               "position": { "x"; 200, "y": 250 }
// //                 //             }
// //                 //           }
// //                 //         },
// //                 //         {
// //                 //           "%type": "SpriteRenderComponent",
// //                 //           "desc": { "path": "assets/test_tilemapdesc.json" }
// //                 //         },
// //                 //       ],
// //                 //     },
// //                 //   ]
// //                 // }

// //                 const Dest = generic.singleItemPtr(@TypeOf(dest));

// //                 if (comptime Dest.Child == Scene) {
// //                     return loadScene(TSerializer, dest, state);
// //                 // } else if (comptime Dest.Child == ecs.Entity) {
// //                     // return loadEntity(TSerializer, dest, state);
// //                 }

// //                 std.log.err("Type of dest is {s}", .{@TypeOf(dest)});
// //                 std.log.err("Unexpected type: {s}", .{Dest.Child});

// //                 unreachable;
// //             }

            
// //             pub fn writeToJsonStream(
// //                 comptime TSerializer: type,
// //                 src: anytype,
// //                 state: *serialization.SerializerJsonWriteState,
// //             ) !void {
// //                 typeCheckSerializer(TSerializer);

// //                 const Src = generic.singleItemPtr(@TypeOf(src));

// //                 if (comptime Src.Child == Scene) {
// //                     return writeScene(TSerializer, src, state);
// //                 // } else if (comptime Src.Child == ecs.Entity) {
// //                     // return writeEntity(TSerializer, src, state);
// //                 }

// //                 std.log.err("Type of src is {s}", .{@TypeOf(src)});
// //                 std.log.err("Unexpected type: {s}", .{Src.Child});

// //                 unreachable;
// //             }


// //             pub fn loadScene(
// //                 comptime TSerializer: type,
// //                 dest: *Scene,
// //                 state: *serialization.SerializerJsonLoadState
// //             ) !void {
// //                 _ = dest;
// //                 const loader: *SceneLoader = state.context.get(SceneLoader);
// //                 loader.entity_remapper.reset();
// //                 typeCheckSerializer(TSerializer);
                

// //                 var helper = serialization.StreamHelper.init(state);
// //                 try helper.expectObjBegin();

// //                 try helper.expectProperty("entities");
// //                 try helper.expectArrayBegin();
// //                 while (try helper.nextToken()) |token| {
// //                     if (token == .ArrayEnd) {
// //                         break;
// //                     }
// //                     helper.putBack(token);

// //                     const entity = try helper.expectNumber(ecs.Entity);
// //                     _ = loader.entity_remapper.getOrAdd(entity);
// //                 }

// //                 try helper.expectProperty("components");

// //                 try helper.expectArrayBegin();

// //                 while (try helper.nextToken()) |token| {
// //                     if (token == .ArrayEnd) {
// //                         break;
// //                     }
// //                     helper.putBack(token);

// // ///////////////////////////////////

// //                     try helper.expectObjBegin();

// //                     try helper.expectProperty("%entity");

// //                     const entity = loader.entity_remapper.getOrAdd(try helper.expectNumber(ecs.Entity));

// //                     try helper.expectProperty("%type");

// //                     const type_name = try helper.expectString();

// //                     try helper.expectProperty("%data");

// //                     if (globals.registered_types.tryLookupName(type_name)) |reg_type| {
// //                         if (loader.component_serializers.get(reg_type.rttid)) |comp_ser| {
// //                             const component_ptr: *anyopaque = loader.entity_manager.addUninit(reg_type.rttid, entity);
// //                             std.log.info(
// //                                 "added component {s}, align of type is {}, ptr is {}",
// //                                 .{reg_type.name, reg_type.alignment, component_ptr});

// //                             comp_ser.loadFromJson(component_ptr, state) catch |err| {
// //                                 if (metautils.isErrorSetMember(serialization.SerializationLoadError, err)) {
// //                                     return @errSetCast(serialization.SerializationLoadError, err);
// //                                 } else {
// //                                     std.log.info("Encountered unknown error: {}", .{err});
// //                                     return error.UnknownError;
// //                                 }
// //                             };

// //                             // end "%data" object
// //                             try helper.expectObjEnd();
// //                             continue;
// //                         }
// //                     }

// //                     std.log.err("Unknown type name: {s}", .{type_name});
// //                     return error.UnknownTypeName;
// //                 }
// //                 std.log.info("Done loading entity components", .{});

// // /////////////////////////////////////

// //                 try helper.expectObjEnd();
// //             }

// //             pub fn writeScene(
// //                 comptime TSerializer: type,
// //                 _: *const Scene,
// //                 state: *serialization.SerializerJsonWriteState,
// //             ) !void {
// //                 const loader: *SceneLoader = state.context.get(SceneLoader);
// //                 typeCheckSerializer(TSerializer);

// //                 const w = state.jsonWriter();
// //                 try w.objBegin();

// //                 try w.field("entities");
// //                 try w.arrBegin();

// //                 var entity_iter = loader.entity_manager.entities();
// //                 while (entity_iter.next()) |entity| {
// //                     try TSerializer.writeToJsonWithState(ecs.Entity, &entity, state);
// //                 }

// //                 try w.arrEnd();

// //                 try w.field("components");

// //                 try w.arrBegin();

// //                 entity_iter = loader.entity_manager.entities();
// //                 while (entity_iter.next()) |entity| {

// //                     var comp_iter = loader.component_serializers.iterator();
// //                     while (comp_iter.next()) |kv| {
// //                         var comp_ser: *const ComponentSerializer = kv.value_ptr;
// //                         if (loader.entity_manager.tryGetOpaque(kv.key_ptr.*, entity)) |component_ptr| {
// //                             try w.objBegin();
// //                             try w.field("%entity");
// //                             try TSerializer.writeToJsonWithState(ecs.Entity, &entity, state);
// //                             try w.field("%type");
// //                             try w.quoted(comp_ser.serialized_name);
// //                             try w.field("%data");
// //                             try comp_ser.writeToJson(component_ptr, state);
// //                             try w.objEnd();
// //                         }
// //                     }

// //                 }
// //                 try w.arrEnd();

// //                 try w.objEnd();                
// //             }

// //             fn typeCheckSerializer(comptime T: type) void {
// //                 if (comptime T != RootSerializerType) {
// //                     @compileError(
// //                         "Expected root serializer types to match, scene loader's RootSerializerType is " ++
// //                             @typeName(RootSerializerType) ++ " but was passed " ++ @typeName(T));
// //                 }
// //             }
// //         };
//     };
// }
