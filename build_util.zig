const std = @import("std");
const builtin = @import("builtin");
const fs = std.fs;

pub const BuildDepTestSrc = union (enum) {
    pkg_root_src: void,
    file_src: []const u8,
    none: void,
};
        
pub const BuildDependency = struct {
    pkg: ?std.Build.CreateModuleOptions = null,
    // buildFn: ?fn (*std.build.Builder, *std.build.LibExeObjStep) void = null,
    buildFn: ?*const fn (*std.Build, *std.build.LibExeObjStep) void = null,
    test_src: BuildDepTestSrc = .pkg_root_src,

    pub const BuildOpts = struct {
        // add_pkg: bool = true,
    };
    pub fn build(comptime self: @This(), comptime self_name: []const u8, b: *std.Build, exe: *std.build.LibExeObjStep, opts: BuildOpts) void {
        _ = opts;
        _ = self_name;
        if (self.buildFn) |buildFn| {
            buildFn(b, exe);
        }
    }

    pub fn addPkg(comptime self: @This(), comptime self_name: []const u8, exe: *std.build.LibExeObjStep) void {
        if (self.pkg) |pkg| {
            var module = exe.builder.createModule(pkg);
            exe.addModule(self_name, module);
        }
    }

    pub fn buildAndAddPkg(comptime self: @This(), comptime self_name: []const u8, b: *std.Build, exe: *std.build.LibExeObjStep, opts: BuildOpts) void {
        self.build(self_name, b, exe, opts);
        self.addPkg(self_name, exe);
    }
};

pub const NamedBuildDependency = struct {
    name: []const u8,
    dep: *const BuildDependency,
};

fn callWrapper(comptime func: anytype, args: anytype) void {
    if (comptime builtin.zig_version.major == 0 and builtin.zig_version.minor == 10 and builtin.zig_version.patch <= 1) {
        @call(.{}, func, args);
    } else {
        @call(.auto, func, args);
    }
}

fn runForEachDep(comptime T: type, comptime method_name: []const u8, args: anytype) void {
    inline for (comptime std.meta.declarations(T)) |decl| {
        if (comptime decl.is_pub and @TypeOf(@field(T, decl.name)) == BuildDependency) {
            callWrapper(
                @field(BuildDependency, method_name),
                .{@field(T, decl.name), decl.name} ++ args);
        }
    }
}


fn countDeclaredDeps(comptime T: type) usize {
    comptime var n = 0;
    inline for (std.meta.declarations(T)) |decl| {
        if (comptime decl.is_pub and @TypeOf(@field(T, decl.name)) == BuildDependency) {
            n += 1;
        }
    }
    return n;
}


pub fn BuildDepsMixin(comptime Self: type) type {
    return struct {
        const num_deps = countDeclaredDeps(Self);

        pub fn buildAll(b: *std.Build, exe: *std.build.LibExeObjStep) void {
            runForEachDep(Self, "build", .{b, exe, .{}});
        }
        
        pub fn buildAndAddAllPkgs(b: *std.Build, exe: *std.build.LibExeObjStep) void {
            runForEachDep(Self, "buildAndAddPkg", .{b, exe, .{}});
        }

        pub fn addAllPkgs(exe: *std.build.LibExeObjStep) void {
            runForEachDep(Self, "addPkg", .{exe});
        }

        pub fn allDependencies() []const NamedBuildDependency {
            const cache = struct {
                const result = blk: {
                    comptime var array: [num_deps]NamedBuildDependency = undefined;
                    var i: usize = 0;
                    inline for (std.meta.declarations(Self)) |decl| {
                        if (decl.is_pub and @TypeOf(@field(Self, decl.name)) == BuildDependency) {
                            array[i] = NamedBuildDependency{.name = decl.name, .dep = &@field(Self, decl.name)};
                            i += 1;
                        }
                    }
                    break :blk array;    
                };
            };
            return &cache.result;
        }
    };
}


pub fn GenerateRootTestStep(comptime T: type) type {
    return struct {
        b: *std.Build,
        step: std.build.Step,
        root_test_path: []const u8,
        main_test_src: []const u8,

        pub fn create(b: *std.Build, root_test_path: []const u8, main_test_src: []const u8) *@This() {
            const self = b.allocator.create(@This()) catch unreachable;
            self.* = @This(){
                .b = b,
                .root_test_path = root_test_path,
                .main_test_src = main_test_src,
                .step = std.build.Step.init(
                    .custom,
                    "GenerateRootTestStep",
                    b.allocator,
                    make),
            };
            return self;
        }

        fn make(step: *std.build.Step) !void {
            const self = @fieldParentPtr(@This(), "step", step);
            generateRootTestFile(T, self.b, self.root_test_path, self.main_test_src);
        }
    };
}


fn generateRootTestFile(comptime T: type, b: *std.Build, out_file: []const u8, main_test_src: []const u8) void {
    var f = fs.cwd().createFile(out_file, .{}) catch unreachable;
    defer f.close();
    var w = f.writer();

    w.writeAll(
        \\const std = @import("std");
        \\ comptime {
    ) catch unreachable;

    const testblock_template =
        \\
        \\    std.testing.refAllDecls(@import("{s}"));
    ;

    w.print(testblock_template, .{main_test_src}) catch unreachable;

    inline for (comptime T.allDependencies()) |named_dep| {
        const test_src = switch (named_dep.dep.test_src) {
            .file_src => |src| src,
            .pkg_root_src => named_dep.dep.pkg.?.source.path,
            .none => continue,
        };
        var test_src_path = std.fs.path.relative(b.allocator, b.build_root, test_src) catch unreachable;
        std.mem.replaceScalar(u8, test_src_path, '\\', '/');
        w.print(testblock_template, .{test_src_path}) catch unreachable;
    }

    w.writeAll("}") catch unreachable;
}


pub fn updateDebugSln(exe_projname: []const u8, sln_filename: []const u8, b: *std.build.Builder) !void {
    const sln_template =
        \\Microsoft Visual Studio Solution File, Format Version 12.00
        \\# Visual Studio Version 17
        \\VisualStudioVersion = 17.0.32126.317
        \\MinimumVisualStudioVersion = 10.0.40219.1
        \\Project("{{911E67C6-3D85-4FCE-B560-20A9C3E3FF48}}") = "{s}", "{s}", "{{01C38ABF-E6F7-4236-910D-5BADD5518954}}"
        \\	ProjectSection(DebuggerProjectSystem) = preProject
        \\		PortSupplier = 00000000-0000-0000-0000-000000000000
        \\		Executable = {s}
        \\		RemoteMachine = DESKTOP-5OF8925
        \\		StartingDirectory = {s}
        \\		Arguments = {s}
        \\		Environment = Default
        \\		LaunchingEngine = 00000000-0000-0000-0000-000000000000
        \\		UseLegacyDebugEngines = No
        \\		LaunchSQLEngine = No
        \\		AttachLaunchAction = No
        \\		IORedirection = Auto
        \\	EndProjectSection
        \\EndProject
        \\Global
        \\	GlobalSection(SolutionConfigurationPlatforms) = preSolution
        \\		Release|x64 = Release|x64
        \\	EndGlobalSection
        \\	GlobalSection(ProjectConfigurationPlatforms) = postSolution
        \\		{{01C38ABF-E6F7-4236-910D-5BADD5518954}}.Release|x64.ActiveCfg = Release|x64
        \\	EndGlobalSection
        \\	GlobalSection(SolutionProperties) = preSolution
        \\		HideSolutionNode = FALSE
        \\	EndGlobalSection
        \\	GlobalSection(ExtensibilityGlobals) = postSolution
        \\		SolutionGuid = {{899778B7-6FB0-49DD-82C6-F9AE391DC892}}
        \\	EndGlobalSection
        \\EndGlobal
    ;


    const suppress_gen_debug_sln = b.option(
        bool,
        "nodebugsln",
        "When true, suppresses updating the debug solution for Visual Studio"
    ) orelse false;

    if (suppress_gen_debug_sln) {
        return;
    }


    const argv = try std.process.argsAlloc(b.allocator);
    defer b.allocator.free(argv);

    const full_exe_path = argv[0];
    const relative_exe_path = b.pathFromRoot(full_exe_path);
    const working_dir = b.pathFromRoot(".");

    var args_elems = try std.ArrayList([]const u8).initCapacity(b.allocator, argv.len);
    defer args_elems.deinit();

    args_elems.appendSliceAssumeCapacity(argv[1..]);
    args_elems.appendAssumeCapacity("-Dnodebugsln=true");

    const args_concat = try std.mem.join(b.allocator, " ", args_elems.items);
    defer b.allocator.free(args_concat);

    var sln_file = try std.fs.cwd().createFile(sln_filename, .{});
    defer sln_file.close();

    try sln_file.writer().print(sln_template, .{
        exe_projname,
        relative_exe_path,
        full_exe_path,
        working_dir,
        args_concat
    });
}


fn createFileEnsurePath(filepath: []const u8) !fs.File {
    var cwd: fs.Dir = fs.cwd();
    if (fs.path.dirname(filepath)) |dirname| {
        cwd.makePath(dirname) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
    }

    return cwd.createFile(filepath, .{});
}
