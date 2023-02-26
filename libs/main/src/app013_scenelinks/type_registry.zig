const std = @import("std");
const meta = std.meta;
const trait = std.meta.trait;
const Allocator = std.mem.Allocator;
const Type = std.builtin.Type;
const builtin = @import("builtin");
// const type_attributes = @import("type_attributes.zig");
// const interface = @import("interface.zig");

// pub const Attributes = enum {
//     no_auto_deinit,
// };

// pub const CaseSensitivity = enum {
//     case_sensitive,
//     case_agnostic,
// };

pub const RuntimeTypeID = *const RuntimeType;

pub const RuntimeType = opaque {
    pub const id: fn (comptime T: type) RuntimeTypeID = struct {
        inline fn rttid(comptime T: type) RuntimeTypeID {
            _ = T;
            const TypeIDSlot = struct {
                var slot: u8 = undefined;
            };
            return @ptrCast(RuntimeTypeID, &TypeIDSlot.slot);
        }

        fn typeID(comptime T: type) RuntimeTypeID {
            return comptime rttid(T);
        }
    }.typeID;

    pub fn of(obj: anytype) RuntimeTypeID {
        return id(@TypeOf(obj));
    }

    pub fn toInt(self: RuntimeTypeID) usize {
        return @ptrToInt(self);
    }
};

fn hashName(name: []const u8) u32 {
    return std.hash.Fnv1a_32.hash(name);
}

pub const TypeNameID = enum(u32) {
    // none = 0,
    _,

    pub fn fromType(comptime T: type) @This() {
        return comptime @intToEnum(TypeNameID, hashName(uniqueTypeName(T)));
    }

    pub fn fromName(name: []const u8) @This() {
        return @intToEnum(TypeNameID, hashName(name));
    }
};

pub fn uniqueTypeName(comptime T: type) [:0]const u8 {
    comptime {
        if (trait.isContainer(T) and @hasDecl(T, "UniqueTypeName")) {
            return T.UniqueTypeName;
        }
        var type_name = @typeName(T).*;
        var start_of_name = std.mem.lastIndexOfScalar(u8, &type_name, '.') orelse 0;
        if (start_of_name == 0) {
            return &type_name;
        }
        var new_storage = [1:0]u8{undefined} ** (type_name.len - (start_of_name + 1));
        std.mem.copy(u8, &new_storage, type_name[(start_of_name + 1)..]);
        return &new_storage;
    }
}

test "TypeNameID uniqueness" {
    const A = struct {
        const B = struct {};
    };
    const C = struct {
        const B = struct {};
    };

    const ATNID = TypeNameID.fromType(A.B);
    const CTNID = TypeNameID.fromType(C.B);

    try std.testing.expectEqual(ATNID, CTNID);
}

// fn parseTypeFnName(type_name: []const u8) ?[]const u8 {
//     if (type_name.len < 3 or type_name[type_name.len - 1] != ')') {
//         return null;
//     }

//     var paren_depth: i32 = 0;
//     var i: usize = type_name.len - 1;
//     while (i < type_name.len) : (i -%= 1) {
//         switch (type_name[i]) {
//             ')' => {
//                 paren_depth += 1;
//             },
//             '(' => {
//                 paren_depth -= 1;
//                 if (paren_depth == 0) {
//                     return type_name[0..i];
//                 }
//             },
//             else => {},
//         }
//     }
//     return null;
// }

// test "parseTypeFnName" {
//     const type_name = ".gamemath.VecTypes(f32))(.VecOfLen(()(4)][])";
//     const type_fn_name = parseTypeFnName(type_name);
//     try std.testing.expectEqualStrings(
//         ".gamemath.VecTypes(f32))(.VecOfLen",
//         type_fn_name.?,
//     );
// }

// pub const TypeFnID = enum(usize) {
//     _,

//     pub fn tryFromType(comptime T: type) ?@This() {
//         comptime {
//             if (parseTypeFnName(@typeName(T))) |typefn_name| {
//                 // @compileLog("parsed type fn name: " ++ typefn_name);
//                 return @intToEnum(@This(), hashName(typefn_name));
//             }
//             return null;
//         }
//     }

//     pub fn fromType(comptime T: type) @This() {
//         return comptime tryFromType(T) orelse @compileError(@typeName(T) ++ " does not appear to be a type computed from a function");
//     }

//     pub fn fromTypeFnName(name: []const u8) @This() {
//         return @intToEnum(@This(), hashName(name));
//     }

//     // pub fn fromDeclName(comptime Container: type, comptime fn_name: []const u8) @This() {
//     //     comptime {
//     //         if (!trait.isContainer(Container)) {
//     //             @compileError("Type " ++ @typeName(Container) ++ " is not a decl-container type");
//     //         }

//     //         if (!@hasDecl(Container, fn_name)) {
//     //             @compileError("Type " ++ @typeName(Container) ++ " has no public declaration named " ++ fn_name);
//     //         }

//     //         const concatenated = @typeName(Container) ++ "." ++ fn_name;
//     //         @compileLog("decl name for type fn id: " ++ concatenated);
//     //         return fromTypeFnName(concatenated);
//     //     }
//     // }
// };

// const typeFnName = struct {
//     fn comptimeWrapper(comptime T: type) [:0]const u8 {
//         return comptime getTypeFnName(T);
//     }

//     fn getTypeFnName(comptime T: type) [:0]const u8 {
//         if (parseTypeFnName(@typeName(T))) |typefn_name| {
//             var array: [typefn_name.len:0]u8 = undefined;
//             std.mem.copy(u8, &array, typefn_name);
//             return &array;
//         } else {
//             return "";
//         }
//     }
// }.comptimeWrapper;

// pub const RtTypeIdFn = fn () RuntimeTypeID;

// pub const ZeroInitFn = fn (ptr: *anyopaque) void;
// pub const ZeroInitFnPtr = *const ZeroInitFn;
pub fn DeinitFnType(comptime T: type) type {
    return fn (self: T, allocator: std.mem.Allocator) void;
}
pub fn DeinitFnNoAllocatorType(comptime T: type) type {
    return fn (self: T) void;
}
pub const DeinitFn = DeinitFnType(*anyopaque);
pub const DeinitFnPtr = *const DeinitFn;

// // maybe it should just return the ptr to the RtTypeInfo, idk
// pub const InnerTypeFn = fn (decl_name: []const u8) ?RuntimeTypeID;

// fn innerTypeAlwaysNull(_: []const u8) ?RuntimeTypeID {
//     return null;
// }

// pub const RtInterfaceImpl = struct {
//     iface_type: *const RtTypeInfo,
//     vtable_ptr: *const anyopaque,

//     pub fn init(self: @This(), comptime T: type, ptr: interface.OpaqueReceiverType(T)) T {
//         if (self.iface_type.rttid != RuntimeType.id(T)) {
//             std.log.err("Tried to initialize interface pointer for {s}, but was passed to an implementation of type {s}", .{ @typeName(T), self.iface_type.name });
//             @panic("Mismatched interface type passed to RtInterfaceImpl");
//         }
//         const VTPtr = interface.VTablePtr(T);
//         return interface.ifx(T).initOpaque(ptr, @ptrCast(VTPtr, @alignCast(@alignOf(VTPtr), self.vtable_ptr)));
//     }
// };

// pub const RtTypeInfo = struct {
//     rttid: RuntimeTypeID,
//     tnid: ?TypeNameID, // TypeNameIDs are a privilege
//     name: [:0]const u8,
//     size: usize,
//     alignment: u29,
//     detail: ?RtTypeDetail,
//     // type_fn_id: ?TypeFnID,
//     // type_fn_name: [:0]const u8,
//     inner_types: []const RtInnerType,
//     // interface_impls: []const RtInterfaceImpl,

//     // zeroInit: std.meta.FnPtr(ZeroInitFn),
//     // deinit: std.meta.FnPtr(DeinitFn),

//     zeroInit: ZeroInitFnPtr,
//     deinit: DeinitFnPtr,

//     pub fn set(self: @This(), dest: *anyopaque, src: *const anyopaque) void {
//         const dest_bytes = @ptrCast([*]u8, dest)[0..self.size];
//         const src_bytes = @ptrCast([*]const u8, src)[0..self.size];
//         std.mem.copy(u8, dest_bytes, src_bytes);
//     }

//     pub fn innerType(self: @This(), name: []const u8) ?RuntimeTypeID {
//         for (self.inner_types) |inner_type| {
//             if (std.mem.eql(u8, inner_type.decl_name, name)) {
//                 return inner_type.aliased_type;
//             }
//         }

//         return null;
//     }

//     // pub fn implOf(self: @This(), comptime Interface: type, ptr: interface.OpaqueReceiverType(Interface)) ?Interface {
//     //     if (self.interface_impls.len == 0) {
//     //         return null;
//     //     }

//     //     const iface_rttid = RuntimeType.id(Interface);

//     //     if (self.interface_impls.len == 1) {
//     //         return if (self.interface_impls[0].iface_type.rttid == iface_rttid)
//     //             self.interface_impls[0].init(Interface, ptr)
//     //         else
//     //             null;
//     //     }

//     //     const Compare = struct {
//     //         fn cmp(key: RuntimeTypeID, _: RtInterfaceImpl, rhs: RtInterfaceImpl) std.math.Order {
//     //             const lhs_int = @ptrToInt(key);
//     //             const rhs_int = @ptrToInt(rhs.iface_type.rttid);
//     //             return if (lhs_int > rhs_int)
//     //                 std.math.Order.gt
//     //             else if (lhs_int < rhs_int)
//     //                 std.math.Order.lt
//     //             else
//     //                 std.math.Order.eq;
//     //         }
//     //     };

//     //     return if (std.sort.binarySearch(RtInterfaceImpl, undefined, self.interface_impls, iface_rttid, Compare.cmp)) |idx|
//     //         self.interface_impls[idx].init(Interface, ptr)
//     //     else
//     //         null;
//     // }
// };

// fn genInnerTypeFn(comptime T: type) InnerTypeFn {
//     if (!trait.isContainer(T)) {
//         return innerTypeAlwaysNull;
//     }

//     const NameRtTIDPair = meta.Tuple(&.{[]const u8, RuntimeTypeID});

//     var kvlist: []const NameRtTIDPair = &[0]NameRtTIDPair{};

//     for (meta.declarations(T)) |decl| {
//         if (@TypeOf(@field(T, decl.name)) == type) {
//             kvlist = kvlist ++ [1]NameRtTIDPair{ .{ decl.name, RuntimeType.id(@field(T, decl.name)) } };
//         }
//     }

//     if (kvlist.len == 0) {
//         return innerTypeAlwaysNull;
//     }

//     const declNameMap = std.ComptimeStringMap(RuntimeTypeID, kvlist);

//     const Static = struct {
//         pub fn innerType(decl_name: []const u8) ?RuntimeTypeID {
//             return declNameMap.get(decl_name);
//         }
//     };
//     return Static.innerType;
// }

// pub const NamedTypeRegistry = struct {
//     const RegisteredTypeList = std.SegmentedList(*const RtTypeInfo, 64);
//     const TypeNameMap = std.AutoHashMap(TypeNameID, *const RtTypeInfo);
//     const RuntimeTypeMap = std.AutoHashMap(RuntimeTypeID, *const RtTypeInfo);

//     type_list: RegisteredTypeList = .{},
//     typename_map: TypeNameMap,
//     runtimetype_map: RuntimeTypeMap,

//     pub fn init(alloc: Allocator) @This() {
//         return .{
//             .typename_map = TypeNameMap.init(alloc),
//             .runtimetype_map = RuntimeTypeMap.init(alloc),
//         };
//     }

//     pub fn deinit(self: *@This()) void {
//         self.runtimetype_map.deinit();
//         self.typename_map.deinit();
//         self.type_list.deinit(self.typename_map.allocator);
//     }

//     pub fn lookupType(self: @This(), comptime T: type) *const RtTypeInfo {
//         return self.tryLookupType(T).?;
//     }

//     pub fn tryLookupType(self: @This(), comptime T: type) ?*const RtTypeInfo {
//         const rttid = RuntimeType.id(T);
//         return if (self.runtimetype_map.get(rttid)) |registered_type|
//             registered_type
//         else
//             null;
//     }

//     pub fn lookupByRttid(self: @This(), rttid: RuntimeTypeID) *const RtTypeInfo {
//         return self.tryLookupByRttid(rttid).?;
//     }

//     pub fn tryLookupByRttid(self: @This(), rttid: RuntimeTypeID) ?*const RtTypeInfo {
//         return if (self.runtimetype_map.get(rttid)) |registered_type|
//             registered_type
//         else
//             null;
//     }

//     // panics if type not registered
//     pub fn lookupName(self: @This(), name: []const u8) *const RtTypeInfo {
//         return self.tryLookupName(name).?;
//     }

//     // returns null if type not registered
//     pub fn tryLookupName(self: @This(), name: []const u8) ?*const RtTypeInfo {
//         const tnid = TypeNameID.fromName(name);
//         // return if (self.typename_map.get(TypeNameID.fromName(name))) |registered_type|
//         return if (self.typename_map.get(tnid)) |registered_type|
//             registered_type
//         else
//             null;
//     }

//     // panics if type registered with same TypeNameID exists
//     pub fn register(self: *@This(), comptime T: type) *const RtTypeInfo {
//         return self.tryRegister(T).?;
//     }

//     // should try to use this sparingly
//     pub fn ensureTypeRegistered(self: *@This(), comptime T: type) *const RtTypeInfo {
//         const rttid = RuntimeType.id(T);
//         if (self.tryLookupByRttid(rttid)) |rt_type_info| {
//             return rt_type_info;
//         }

//         return self.register(T);
//     }

//     // returns null if type registered with same TypeNameID exists
//     // panics if allocation fails
//     pub fn tryRegister(self: *@This(), comptime T: type) ?*const RtTypeInfo {
//         const tnid = comptime TypeNameID.fromType(T);
//         const rttid = RuntimeType.id(T);
//         // const name = uniqueTypeName(T);
//         // std.log.debug("Registering type: {s}, tnid={}, rttid={}", .{name, tnid, rttid});

//         var gop_tnid = self.typename_map.getOrPut(tnid) catch unreachable;
//         var gop_rttid = self.runtimetype_map.getOrPut(rttid) catch unreachable;

//         std.debug.assert(gop_tnid.found_existing == gop_rttid.found_existing);

//         if (gop_tnid.found_existing) {
//             std.debug.assert(gop_tnid.value_ptr.* == gop_rttid.value_ptr.*);
//             return gop_tnid.value_ptr.*;
//         }

//         const ptr: **const RtTypeInfo = self.type_list.addOne(self.typename_map.allocator) catch unreachable;
//         ptr.* = genRtti(T);

//         gop_tnid.value_ptr.* = ptr.*;
//         gop_rttid.value_ptr.* = ptr.*;

//         return ptr.*;
//     }
// };

// pub const RtContainerKind = enum {
//     rt_struct,
//     rt_union,
// };

// pub const RtContainerInfo = struct {
//     kind: RtContainerKind,
//     fields: []const RtFieldInfo,
//     tag_type: ?*const RtTypeInfo,
// };

// pub const RtAttributeInfo = struct {
//     attr_type: *const RtTypeInfo,
//     ptr: *const anyopaque,
// };

// pub const RtFieldInfo = struct {
//     name: [:0]const u8,
//     type_info: *const RtTypeInfo,
//     offset: usize, // 0 for union members and enum tags
//     alignment: u29,
//     // attributes: []const RtAttributeInfo,

//     pub fn access(
//         self: RtFieldInfo,
//         container_ptr: anytype,
//     ) if (trait.isConstPtr(@TypeOf(container_ptr))) *const anyopaque else *anyopaque {
//         const ContainerPtrType = @TypeOf(container_ptr);
//         const is_const = comptime trait.isConstPtr(ContainerPtrType);
//         if (comptime !trait.is(.Pointer)(ContainerPtrType)) {
//             @compileError("RtFieldInfo.access expectes pointer type for container_ptr arg, not " ++ @typeName(ContainerPtrType));
//         }
//         const BytePtrType = if (is_const) [*]const u8 else [*]u8;
//         return @ptrCast(BytePtrType, container_ptr) + self.offset;
//     }

//     // pub fn hasAttributeValue(
//     //     self: @This(),
//     //     attr_value: anytype,
//     // ) bool {
//     //     const AttrParamType = @TypeOf(attr_value);
//     //     const is_pointer = @typeInfo(AttrParamType) == .Pointer;
//     //     const AttrType = if (is_pointer) meta.Child(AttrParamType) else AttrParamType;

//     //     if (self.tryGetAttributeOfType(AttrType)) |attr_found_ptr| {
//     //         const attr_value_ptr = if (is_pointer) attr_value else &attr_value;

//     //         if (attr_value_ptr == attr_found_ptr) {
//     //             return true;
//     //         }

//     //         if (@sizeOf(AttrType) == 0) {
//     //             return true;
//     //         }

//     //         if (std.meta.eql(attr_value_ptr.*, attr_found_ptr.*)) {
//     //             return true;
//     //         }
//     //     }

//     //     return false;
//     // }

//     // pub fn tryGetAttributeOfType(
//     //     self: @This(),
//     //     comptime T: type,
//     // ) ?*const T {
//     //     const rttid = RuntimeType.id(T);
//     //     for (self.attributes) |attr| {
//     //         if (attr.attr_type.rttid == rttid) {
//     //             const attr_as_bytes = @ptrCast(*const [@sizeOf(T)]u8, attr.ptr);
//     //             return std.mem.bytesAsValue(T, attr_as_bytes);
//     //         }
//     //     }
//     //     return null;
//     // }
// };

// pub const RtEnumFieldInfo = struct {
//     pub const ValueType = u64;

//     name: [:0]const u8,
//     value: ValueType,
// };

// pub const RtEnumInfo = struct {
//     fields: []const RtEnumFieldInfo,
//     tag_type: *const RtTypeInfo,
//     is_exhaustive: bool,

//     pub fn asBytes(self: @This(), ptr: *const anyopaque) []const u8 {
//         return @ptrCast([*]const u8, ptr)[0..self.tag_type.size];
//     }

//     pub fn tryReadAs(self: @This(), comptime T: type, ptr: *const anyopaque) ?T {
//         if (self.tag_type.size > @sizeOf(T)) {
//             return null;
//         }
//         return std.mem.readVarInt(T, self.asBytes(ptr), std.mem.native_endian);
//     }

//     pub fn findFieldIndexByValuePtr(self: @This(), value_ptr: *const anyopaque) ?usize {
//         const value = std.mem.readVarInt(RtEnumFieldInfo.ValueType, self.asBytes(value_ptr), builtin.cpu.arch.endian());

//         for (self.fields) |field, i| {
//             if (field.value == value) {
//                 return i;
//             }
//         }
//         return null;
//     }

//     pub fn nameToValue(self: @This(), name: []const u8, case_sensitive: CaseSensitivity) ?u64 {
//         switch (case_sensitive) {
//             .case_sensitive => {
//                 for (self.fields) |field| {
//                     if (std.mem.eql(u8, name, field.name)) {
//                         return field.value;
//                     }
//                 }
//             },
//             .case_agnostic => {
//                 for (self.fields) |field| {
//                     if (std.ascii.eqlIgnoreCase(name, field.name)) {
//                         return field.value;
//                     }
//                 }
//             },
//         }
//         return null;
//     }
// };

// pub const RtArrayInfo = struct {
//     len: usize,
//     child: *const RtTypeInfo,

//     pub fn access(
//         self: RtArrayInfo,
//         array_ptr: anytype,
//         index: usize,
//     ) if (trait.isConstPtr(@TypeOf(array_ptr))) *const anyopaque else *anyopaque {
//         const ArrayPtrType = @TypeOf(array_ptr);
//         const is_const = comptime trait.isConstPtr(ArrayPtrType);
//         if (comptime !trait.is(.Pointer)(ArrayPtrType)) {
//             @compileError("RtArrayInfo.access expects pointer type for array_ptr arg, not " ++ @typeName(ArrayPtrType));
//         }
//         const BytePtrType = if (is_const) [*]const u8 else [*]u8;
//         const stride = std.mem.alignForward(self.child.size, self.child.alignment);
//         return @ptrCast(BytePtrType, array_ptr) + (stride * index);
//     }
// };

// pub const RtWrapperKind = enum {
//     rt_pointer,
//     rt_optional,
// };

// pub const RtWrapperInfo = struct {
//     kind: RtWrapperKind,
//     child: *const RtTypeInfo,
// };

// pub const Constness = enum {
//     NonConst,
//     Const,

//     pub fn init(is_const: bool) Constness {
//         return if (is_const) .Const else .NonConst;
//     }

//     pub fn AnyPtr(comptime self: @This()) type {
//         return switch (self) {
//             .NonConst => *anyopaque,
//             .Const => *const anyopaque,
//         };
//     }

//     pub fn Ptr(comptime self: @This(), comptime T: type) type {
//         return switch (self) {
//             .NonConst => *T,
//             .Const => *const T,
//         };
//     }

//     pub fn Slice(comptime self: @This(), comptime T: type) type {
//         return switch (self) {
//             .NonConst => []T,
//             .Const => []const T,
//         };
//     }

//     pub fn Many(comptime self: @This(), comptime T: type) type {
//         return switch (self) {
//             .NonConst => [*]T,
//             .Const => [*]const T,
//         };
//     }
// };

// pub fn OpaqueSlice(comptime of_constness: Constness) type {
//     return struct {
//         const constness: Constness = of_constness;

//         ptr: ?constness.Many(u8),
//         len: usize,
//         stride: usize,

//         pub fn fromPtr(ptr: *const anyopaque, stride: usize) @This() {
//             var slice_ptr = @ptrCast(*const constness.Slice(u8), @alignCast(@alignOf([]u8), ptr));
//             return .{
//                 .ptr = slice_ptr.ptr,
//                 .len = slice_ptr.len,
//                 .stride = stride,
//             };
//         }

//         pub fn at(self: @This(), index: usize) constness.Ptr(u8) {
//             return &(self.ptr.?[index * self.stride]);
//         }

//         pub fn indexOf(self: @This(), ptr: *const anyopaque) usize {
//             return (@ptrToInt(ptr) - @ptrToInt(&self.ptr.?[0])) / self.stride;
//         }

//         pub fn iterator(self: @This()) Iterator {
//             return Iterator.init(self);
//         }

//         pub const Iterator = struct {
//             pub const Slice = OpaqueSlice(constness);
//             slice: Slice,
//             next_idx: usize,

//             pub fn init(opaque_slice: Slice) @This() {
//                 return .{
//                     .slice = opaque_slice,
//                     .next_idx = 0,
//                 };
//             }

//             pub fn next(self: *@This()) ?constness.Ptr(anyopaque) {
//                 if (self.next_idx < self.slice.len) {
//                     self.next_idx += 1;
//                     return self.slice.at(self.next_idx - 1);
//                 }

//                 return null;
//             }

//             pub fn indexOf(self: @This(), ptr: *const anyopaque) usize {
//                 return self.slice.indexOf(ptr);
//             }
//         };
//     };
// }

// pub const RtSliceInfo = struct {
//     child: *const RtTypeInfo,
//     is_const: bool,
//     alignment: u29,
//     sentinel: ?*const anyopaque,

//     pub fn asOpaqueSlice(self: @This(), comptime constness: Constness, ptr: *const anyopaque) OpaqueSlice(constness) {
//         return OpaqueSlice(constness).fromPtr(ptr, self.stride());
//     }

//     pub fn iterator(self: @This(), comptime constness: Constness, ptr: *const anyopaque) OpaqueSlice(constness).Iterator {
//         return self.asOpaqueSlice(constness, ptr).iterator();
//     }

//     pub fn sliceLen(self: @This(), ptr: *const anyopaque) usize {
//         _ = self;
//         return @ptrCast(*const []const u8, @alignCast(@alignOf([]u8), ptr)).len;
//     }

//     pub fn asBytes(
//         self: @This(),
//         comptime constness: Constness,
//         ptr: *const anyopaque,
//     ) constness.Slice(u8) {
//         var result = @ptrCast(*const constness.Slice(u8), @alignCast(@alignOf([]u8), ptr)).*;
//         result.len *= self.stride();
//         return result;
//     }

//     pub fn stride(self: @This()) usize {
//         return std.mem.alignForward(self.child.size, self.alignment);
//     }

//     pub fn atIndex(
//         self: @This(),
//         comptime constness: Constness,
//         ptr: *const anyopaque,
//         index: usize,
//     ) constness.AnyPtr() {
//         const bytes = self.asBytes(constness, ptr);
//         return &bytes[index * self.stride()];
//     }
// };

// pub const RtIntInfo = struct {
//     signedness: std.builtin.Signedness,
//     bits: u16,

//     pub fn bitsU32(self: @This()) u32 {
//         return @as(u32, self.bits);
//     }

//     pub const IntValue = union(enum) {
//         signed: i64,
//         unsigned: u64,
//     };

//     pub fn read64(self: @This(), ptr: *const anyopaque) IntValue {
//         // if (@rem(self.bits, 8) != 0) {
//         //     @panic("Trying to write to integer size which isn't a multiple of the byte size (8), this isn't supported yet");
//         // }

//         const ptr_as_bytes = @ptrCast([*]const u8, ptr)[0..(std.mem.alignForward(self.bits, 8) / 8)];
//         return switch (self.signedness) {
//             .signed => .{
//                 .signed = std.mem.readVarInt(i64, ptr_as_bytes, builtin.cpu.arch.endian()),
//             },
//             .unsigned => .{
//                 .unsigned = std.mem.readVarInt(u64, ptr_as_bytes, builtin.cpu.arch.endian()),
//             },
//         };
//     }

//     pub fn writeTrunc(self: @This(), ptr: *anyopaque, src_int: anytype) @TypeOf(src_int) {
//         if (comptime builtin.cpu.arch.endian() != std.builtin.Endian.Little) {
//             @compileError("This reflection system assumes little endian for now");
//         }

//         const SrcIntType = @TypeOf(src_int);
//         // if (@rem(self.bits, 8) != 0) {
//         //     @panic("Trying to write to integer size which isn't a multiple of the byte size (8), this isn't supported yet");
//         // }

//         const dest_byte_size = std.mem.alignForward(self.bits, 8) / 8;
//         const src_bytes = std.mem.asBytes(&src_int);
//         const ptr_as_bytes = @ptrCast([*]u8, ptr)[0..dest_byte_size];
//         if (dest_byte_size < src_bytes.len) {
//             const truncated = src_bytes[0..dest_byte_size];
//             std.mem.copy(u8, ptr_as_bytes, truncated);
//             var result: SrcIntType = src_int;
//             std.mem.set(u8, std.mem.asBytes(&result)[dest_byte_size..], 0);
//             return result;
//         } else if (dest_byte_size > src_bytes.len) {
//             std.mem.copy(u8, ptr_as_bytes, src_bytes);
//             const leftover = dest_byte_size - src_bytes.len;
//             std.mem.set(u8, ptr_as_bytes[src_bytes.len..][0..leftover], 0);
//             return src_int;
//         } else {
//             std.mem.copy(u8, ptr_as_bytes, src_bytes);
//             return src_int;
//         }
//     }

//     // pub fn tryWrite(self: @This(), ptr: *anyopaque, src: []const u8) !void {
//     //     if (@rem(self.bits, 8) != 0) {
//     //         @panic("Trying to write to integer size which isn't a multiple of the byte size (8), this isn't supported yet");
//     //     }
//     //     const dest_byte_size = self.bits * 8;
//     //     if (dest_byte_size < src.len) {
//     //         return error.DestinationTypeTooSmall;
//     //     }

//     //     const ptr_as_bytes = @ptrCast([*]u8, ptr)[0..dest_byte_size];
//     //     std.mem.copy(u8, ptr_as_bytes, src);
//     //     const leftover = dest_byte_size - src.len;
//     //     std.mem.set(u8, ptr_as_bytes[src.len..][0..leftover], 0);
//     // }
// };

// pub const RtFloatInfo = struct {
//     bits: u16,

//     pub fn bitsU32(self: @This()) u32 {
//         return @as(u32, self.bits);
//     }
// };

// pub const RtVectorInfo = struct {
//     len: u16,
//     child: *const RtTypeInfo,
// };

// pub const RtCollectionInfo = struct {
//     keyed: bool,
// };

// pub const RtTIDPtr = struct {
//     ptr: *anyopaque,
//     tid: RuntimeTypeID,
// };

// pub const RtAnyPtr = struct {
//     ptr: *anyopaque,
//     rttinfo: *const RtTypeInfo,
// };

// pub const RtAnyInterfacePtr = struct {
//     vtable: RtAnyPtr,
//     ptr: *anyopaque,
// };

// pub const RtAnyInterfaceAnyPtr = struct {
//     vtable: RtAnyPtr,
//     target: RtAnyPtr,
// };

// pub const ReflectionPointer = struct {
//     reflect_info: *const ReflectedTypeInfo,
//     ptr: *anyopaque,
// };

// pub const ReflectionInterfacePointer = struct {
//     vtable: ReflectionPtr,
//     target: *anyopaque,
// };

// pub const ReflectionTargetPreservingInterfacePointer = struct {
//     vtable: ReflectionPointer,
//     target: ReflectionPointer,
// };

// pub fn RtInterfacePtr(comptime Interface: type) type {
//     return struct {
//         vtable: *anyopaque,
//         ptr: *anyopaque,
//     };
// }

// pub const RtTypeDetail = union(enum) {
//     rt_struct: *const RtContainerInfo,
//     rt_union: *const RtContainerInfo,
//     rt_enum: *const RtEnumInfo,
//     rt_array: *const RtArrayInfo,
//     rt_pointer: *const RtWrapperInfo,
//     rt_slice: *const RtSliceInfo,
//     rt_optional: *const RtWrapperInfo,
//     rt_integer: *const RtIntInfo,
//     rt_float: *const RtFloatInfo,
//     rt_vector: *const RtVectorInfo,
//     rt_bool: void,

//     pub fn fieldCount(self: @This()) usize {
//         return switch (self) {
//             .rt_struct, .rt_union, .rt_enum => |info| info.fields.len,
//             else => 0,
//         };
//     }
// };

// pub fn zeroSizedBackingMemory(comptime T: type) *const anyopaque {
//     _ = T;
//     const Storage = struct {
//         var value: u8 = 0;
//     };
//     return &Storage.value;
// }

// pub const RtInnerType = struct {
//     decl_name: []const u8,
//     aliased_type: RuntimeTypeID,
// };

// fn genInnerTypesList(comptime T: type) []const RtInnerType {
//     if (!trait.isContainer(T)) {
//         return &[0]RtInnerType{};
//     }

//     const Storage = struct {
//         const inner_types = blk: {
//             var ct_innertype_array: []const RtInnerType = &[0]RtInnerType{};

//             for (meta.declarations(T)) |decl| {
//                 if (decl.is_pub) {
//                     if (@TypeOf(@field(T, decl.name)) == type) {
//                         ct_innertype_array = ct_innertype_array ++ [1]RtInnerType{.{
//                             .decl_name = decl.name,
//                             .aliased_type = RuntimeType.id(@field(T, decl.name)),
//                         }};
//                     }
//                 }
//             }

//             break :blk ct_innertype_array;
//         };
//     };
//     return Storage.inner_types;
// }

// fn genTypeInterfaceImplsArray(comptime T: type) []const RtInterfaceImpl {
//     if (!trait.isContainer(T) or !@hasDecl(T, "IMPLEMENTS")) {
//         return &[0]RtInterfaceImpl{};
//     }

//     const num_impls = blk: {
//         var n = 0;
//         for (T.IMPLEMENTS) |impl| {
//             const ImplType = @TypeOf(impl);
//             if (interface.isTargetImplementationType(T, ImplType)) {
//                 n += 1;
//             }
//         }
//         break :blk n;
//     };

//     const Storage = struct {
//         const impls = blk: {
//             var impls_array: [num_impls]RtInterfaceImpl = undefined;
//             var skipped: usize = 0;
//             for (T.IMPLEMENTS) |impl, i| {
//                 const ImplType = @TypeOf(impl);
//                 if (interface.isTargetImplementationType(T, ImplType)) {
//                     impls_array[i - skipped] = .{
//                         .iface_type = genRtti(ImplType.Interface), // this is where a partial-rtti would probably be useful
//                         .vtable_ptr = impl.vt,
//                     };
//                 } else {
//                     skipped += 1;
//                 }
//             }

//             std.sort.sort(RtInterfaceImpl, &impls_array, void{}, lessThan);

//             var prev_rttid: ?RuntimeTypeID = null;
//             for (impls_array) |rt_iface_impl| {
//                 if (prev_rttid) |prev| {
//                     if (prev == rt_iface_impl.iface_type.rttid) {
//                         @compileError(@typeName(T) ++ " claims to implement " ++ rt_iface_impl.iface_type.name ++ " twice");
//                     }
//                 }
//                 prev_rttid = rt_iface_impl.iface_type.rttid;
//             }

//             break :blk impls_array;
//         };

//         pub fn lessThan(_: void, lhs: RtInterfaceImpl, rhs: RtInterfaceImpl) bool {
//             return @ptrToInt(lhs.iface_type.rttid) < @ptrToInt(rhs.iface_type.rttid);
//         }
//     };

//     return &Storage.impls;
// }

// fn genTypeFieldAttributesArray(comptime T: type, comptime field_name: []const u8) []const RtAttributeInfo {
//     const Storage = struct {
//         const attributes = blk: {
//             const ct_attributes = type_attributes.getFieldAttrs(T, field_name);
//             var attr_array: [ct_attributes.*.len]RtAttributeInfo = undefined;

//             for (ct_attributes.*) |*attr, i| {
//                 const ptr: *const anyopaque = if (@sizeOf(@TypeOf(attr.*)) == 0)
//                     zeroSizedBackingMemory(@TypeOf(attr.*))
//                 else
//                     attr;

//                 attr_array[i] = RtAttributeInfo{
//                     .attr_type = genRtti(@TypeOf(attr.*)),
//                     .ptr = ptr,
//                 };
//             }

//             break :blk attr_array;
//         };
//     };
//     return &Storage.attributes;
// }

// fn genTypeFieldArray(comptime T: type) []const RtFieldInfo {
//     const num_fields = blk: {
//         var n = 0;
//         for (meta.fields(T)) |field| {
//             if (!std.mem.allEqual(u8, field.name, '_')) {
//                 n += 1;
//             }
//         }
//         break :blk n;
//     };
//     const Storage = struct {
//         const fields: [num_fields]RtFieldInfo = blk: {
//             var field_array: [num_fields]RtFieldInfo = undefined;
//             var skipped: usize = 0;
//             for (meta.fields(T)) |field, i| {
//                 // ignore all-underscore field names
//                 // this is assumed to be padding or unique-address bytes
//                 if (std.mem.allEqual(u8, field.name, '_')) {
//                     skipped += 1;
//                     continue;
//                 }
//                 var name_array: [field.name.len:0]u8 = undefined;
//                 std.mem.copy(u8, &name_array, field.name);
//                 name_array[field.name.len] = 0; // unnecessary?
//                 field_array[i - skipped] = RtFieldInfo{
//                     .name = &name_array, //field.name,
//                     .type_info = if (trait.is(.Enum)(T))
//                         genRtti(@typeInfo(T).Enum.tag_type, .full_rtti)
//                     else
//                         genRtti(field.type),
//                     .offset = if (trait.is(.Enum)(T))
//                         0
//                     else
//                         @offsetOf(T, field.name),
//                     .alignment = if (trait.is(.Struct)(T) or trait.is(.Union)(T))
//                         field.alignment
//                     else
//                         0,
//                     // .attributes = genTypeFieldAttributesArray(T, field.name),
//                 };
//             }
//             break :blk field_array;
//         };
//     };

//     return &Storage.fields;
// }

// fn genTypeEnumFieldArray(comptime T: type) []const RtEnumFieldInfo {
//     const ct_fields = meta.fields(T);
//     const Storage = struct {
//         const fields: [ct_fields.len]RtEnumFieldInfo = blk: {
//             var field_array: [ct_fields.len]RtEnumFieldInfo = undefined;
//             for (meta.fields(T)) |field, i| {
//                 var name_array: [field.name.len:0]u8 = undefined;
//                 std.mem.copy(u8, &name_array, field.name);
//                 name_array[field.name.len] = 0; // unnecessary?
//                 field_array[i] = RtEnumFieldInfo{
//                     .name = &name_array, //field.name,
//                     .value = @truncate(RtEnumFieldInfo.ValueType, field.value),
//                 };
//             }
//             break :blk field_array;
//         };
//     };

//     return &Storage.fields;
// }

// fn genRtTypeDetail(comptime T: type) RtTypeDetail {
//     const type_info = @typeInfo(T);
//     const Storage = struct {
//         const type_detail = if (T == RuntimeTypeID) RtIntInfo{
//             .signedness = .unsigned,
//             .bits = @bitSizeOf(*anyopaque),
//         } else switch (type_info) {
//             .Struct => RtContainerInfo{
//                 .kind = .rt_struct,
//                 .fields = genTypeFieldArray(T),
//                 .tag_type = null,
//             },
//             .Enum => |enum_info| blk: {
//                 if (@sizeOf(enum_info.tag_type) > @sizeOf(RtEnumFieldInfo.ValueType)) {
//                     @compileError(std.fmt.comptimePrint("Enum with an integer byte width greater than {} not supported, enum tag_type was {s}", .{ @sizeOf(RtEnumFieldInfo.ValueType), @typeName(enum_info.tag_type) }));
//                 }
//                 var info = RtEnumInfo{
//                     .fields = genTypeEnumFieldArray(T),
//                     .tag_type = genRtti(enum_info.tag_type),
//                     .is_exhaustive = enum_info.is_exhaustive,
//                 };
//                 break :blk info;
//             },
//             .Union => |union_info| RtContainerInfo{
//                 .kind = .rt_union,
//                 .fields = genTypeFieldArray(T),
//                 .tag_type = if (union_info.tag_type) |tag_type|
//                     genRtti(tag_type, .full_rtti)
//                 else
//                     null,
//             },
//             // .Pointer => |pointer_info| RtWrapperInfo {
//             //     .kind = switch (pointer_info.size) {
//             //         .One => .rt_pointer,
//             //         .Slice => .rt_slice,
//             //         .Many => @compileError("Runtime type detail not supported for many-item pointers: " ++ @typeName(T)),
//             //         .C => @compileError("Runtime type detail not supported for C pointers: " ++ @typeName(T)),
//             //     },
//             //     .child = genRtti(pointer_info.child, .full_rtti),
//             // },
//             .Pointer => |pointer_info| if (pointer_info.size == .Slice)
//                 RtSliceInfo{
//                     .child = genRtti(pointer_info.child),
//                     .alignment = pointer_info.alignment,
//                     .is_const = pointer_info.is_const,
//                     .sentinel = pointer_info.sentinel,
//                 }
//             else
//                 RtWrapperInfo{
//                     .kind = switch (pointer_info.size) {
//                         .One => .rt_pointer,
//                         .Slice => @compileError("BUG, SLICE SHOULD BE ABOVE"),
//                         .Many => @compileError("Runtime type detail not supported for many-item pointers: " ++ @typeName(T)),
//                         .C => @compileError("Runtime type detail not supported for C pointers: " ++ @typeName(T)),
//                     },
//                     .child = genRtti(pointer_info.child),
//                 },
//             .Array => |arr_info| blk: {
//                 if (arr_info.sentinel) {
//                     @compileError("Arrays with sentinel values are not supported: " ++ @typeName(T));
//                 }
//                 var rt_array = RtArrayInfo{
//                     .len = arr_info.len,
//                     .child = genRtti(arr_info.child),
//                 };
//                 break :blk rt_array;
//             },
//             .Optional => |opt_info| RtWrapperInfo{
//                 .kind = .rt_optional,
//                 .child = genRtti(opt_info.child),
//             },
//             .Int => |int_info| RtIntInfo{
//                 .signedness = int_info.signedness,
//                 .bits = int_info.bits,
//             },
//             .Float => |float_info| RtFloatInfo{
//                 .bits = float_info.bits,
//             },
//             .Bool => void{},
//             else => @compileError("Runtime type detail not supported for " ++ @typeName(T)),
//         };
//     };

//     return if (T == RuntimeTypeID)
//         RtTypeDetail{ .rt_integer = &Storage.type_detail }
//     else switch (type_info) {
//         .Struct => RtTypeDetail{ .rt_struct = &Storage.type_detail },
//         .Enum => RtTypeDetail{ .rt_enum = &Storage.type_detail },
//         .Union => RtTypeDetail{ .rt_union = &Storage.type_detail },
//         .Pointer => |pointer_info| switch (pointer_info.size) {
//             .One => RtTypeDetail{ .rt_pointer = &Storage.type_detail },
//             .Many => @compileError("Runtime type detail not supported for many-item pointers"),
//             .C => @compileError("Runtime type detail not supported for C pointers"),
//             .Slice => RtTypeDetail{ .rt_slice = &Storage.type_detail },
//         },
//         .Array => RtTypeDetail{ .rt_array = &Storage.type_detail },
//         .Optional => RtTypeDetail{ .rt_optional = &Storage.type_detail },
//         .Int => RtTypeDetail{ .rt_integer = &Storage.type_detail },
//         .Float => RtTypeDetail{ .rt_float = &Storage.type_detail },
//         .Bool => RtTypeDetail{ .rt_bool = &Storage.type_detail },
//         else => @compileError("Runtime type detail not supported for " ++ @typeName(T)),
//     };
// }

pub fn typeNeedsDeinit(comptime T: type) bool {
    return switch (comptime @typeInfo(T)) {
        .Pointer,
        // Explicitly not managing single-item pointers for now
        // This will probably change, or be informed by attributes or better heuristics or some kind of owning wrapper type
        // If we go with the owning wrapper type approach, then this will stand, and it might make sense
        //   to not explicitly support slices for deinit
        => |ptr_info| (ptr_info.size != .One and !ptr_info.is_const),

        .Array,
        .Struct,
        .Optional
            => true,

        .Union => |union_info| if (union_info.tag_type == null)
            @compileError("Reflection system doesn't support untagged union")
        else
            true,

        .Bool,
        .Int,
        .Float,
        .Void,
        .Enum,
        .Vector,
        .ComptimeFloat,
        .ComptimeInt
            => false,

        .Undefined,
        .NoReturn,
        .Null,
        .ErrorUnion,
        .ErrorSet,
        .Type,
        // .BoundFn,
        .Frame,
        .Opaque,
        .AnyFrame,
        .EnumLiteral,
        .Fn
            => @compileError("Reflection system does not support " ++ @tagName(@typeInfo(T))),
    };
}

const DeinitKind = enum {
    self_only,
    allocator,
    undeclared,
    unneeded,
};

fn typeDeinitKind(comptime T: type) DeinitKind {
    if (trait.isContainer(T) and @hasDecl(T, "deinit")) {
        switch (@TypeOf(T.deinit)) {
            DeinitFnNoAllocatorType(T), DeinitFnNoAllocatorType(*T), DeinitFnNoAllocatorType(*const T) => return .self_only,

            DeinitFnType(T), DeinitFnType(*T), DeinitFnType(*const T) => return .allocator,

            else => @compileError("Type " ++ @typeName(T) ++ " has deinit function, but it does not have a standard signature"),
        }
    }

    return if (typeNeedsDeinit(T))
        .undeclared
    else
        .unneeded;
}

pub fn DeinitFor(comptime T: type) type {
    return struct {
        pub fn asOpaquePtr() DeinitFnPtr {
            return @ptrCast(DeinitFnPtr, &@This().deinit);
        }

        pub fn deinit(self: *T, alloc: std.mem.Allocator) void {
            // if (comptime type_attributes.hasAttributeValue(T, Attributes.no_auto_deinit)) {
            // return;
            // }

            switch (comptime typeDeinitKind(T)) {
                .self_only => self.deinit(),
                .allocator => {
                    // @compileLog("Generating deinit(alloc) call for " ++ @typeName(T));
                    self.deinit(alloc);
                },
                .unneeded => {},
                .undeclared => {
                    if (comptime typeNeedsDeinit(T)) {
                        // @compileLog("Generating deinit for " ++ @typeName(T));
                        switch (comptime @typeInfo(T)) {
                            .Struct => {
                                inline for (meta.fields(T)) |field| {
                                    // if (comptime !type_attributes.fieldHasAttributeValue(T, field.name, Attributes.no_auto_deinit))
                                        {
                                        // @compileLog("generating deinit call for " ++ @typeName(T) ++ "." ++ field.name);
                                        DeinitFor(field.type).deinit(&@field(self, field.name), alloc);
                                    }
                                }
                            },
                            .Union => |union_info| {
                                const Tag = union_info.tag_type.?;
                                inline for (meta.fields(T)) |field| {
                                    // if (comptime !type_attributes.fieldHasAttributeValue(T, field.name, Attributes.no_auto_deinit))
                                        {
                                        if (comptime std.mem.eql(u8, field.name, @tagName(@as(Tag, self.*)))) {
                                            DeinitFor(field.type).deinit(&@field(self, field.name), alloc);
                                            comptime break;
                                        }
                                    }
                                }
                            },
                            .Pointer => |ptr_info| {
                                switch (comptime ptr_info.size) {
                                    .Slice => {
                                        if (comptime !ptr_info.is_const) {
                                            for (self.*) |*elem| {
                                                DeinitFor(ptr_info.child).deinit(elem, alloc);
                                            }
                                            alloc.free(self.*);
                                        }
                                    },
                                    .C, .Many => @compileError("C and Many pointers aren't supported by the reflection system"),
                                    .One => {
                                        if (comptime !ptr_info.is_const) {
                                            @compileError("Non-const single-item pointers not yet implemented, probably? " ++ @typeName(T));
                                        }
                                    },
                                }
                            },
                            .Optional => |opt_info| {
                                if (self.*) |*nonnull_self| {
                                    DeinitFor(opt_info.child).deinit(nonnull_self, alloc);
                                }
                            },
                            .Array => |array_info| {
                                inline for (self.*) |*elem| {
                                    DeinitFor(array_info.child).deinit(elem, alloc);
                                }
                            },
                            // .Opaque => @compileError("Opaque types may be supported by this reflection system in the future, but not for now"),
                            else => @compileError("Unexpected type to deinit: " ++ @typeName(T)),
                        }
                    }
                },
            }
        }
    };
}

fn deinitNoOp(_: *anyopaque, _: std.mem.Allocator) void {}

fn genDeinitFn(comptime T: type) DeinitFnPtr {
    comptime {
        return if (typeNeedsDeinit(T))
            DeinitFor(T).asOpaquePtr()
        else
            deinitNoOp;
    }
}

// fn genRtti(comptime T: type) *const RtTypeInfo {
//     const Storage = struct {
//         const type_info = RtTypeInfo{
//             .rttid = RuntimeType.id(T),
//             .tnid = TypeNameID.fromType(T), // TypeNameIDs are a privilege
//             .name = uniqueTypeName(T),
//             .size = @sizeOf(T),
//             .alignment = @alignOf(T),
//             .detail = genRtTypeDetail(T),
//             // .type_fn_id = TypeFnID.tryFromType(T),
//             // .type_fn_name = typeFnName(T),
//             .inner_types = genInnerTypesList(T),
//             // .interface_impls = genTypeInterfaceImplsArray(T),
//             .zeroInit = @ptrCast(ZeroInitFnPtr, &struct {
//                 pub fn zeroInit(ptr: *T) void {
//                     switch (comptime @typeInfo(T)) {
//                         .Struct => {
//                             ptr.* = std.mem.zeroInit(T, .{});
//                         },
//                         .Pointer => |ptr_info| {
//                             switch (ptr_info.size) {
//                                 .Slice, .C => ptr.* = std.mem.zeroes(T),
//                                 .One, .Many => {
//                                     ptr.* = undefined;
//                                     // @compileError("TRYINA ZERO INIT A POINTER: " ++ @typeName(T));
//                                 },
//                             }
//                         },
//                         else => {
//                             ptr.* = std.mem.zeroes(T);
//                         },
//                     }
//                 }
//             }.zeroInit),
//             .deinit = genDeinitFn(T), // completely deinits the type, no need to iterate through children at runtime
//         };
//     };

//     return &Storage.type_info;
// }
