const std = @import("std");
const stats = @import("root.zig");

const SPDist = stats.UnionDist(f32);
const DPDist = stats.UnionDist(f64);

const Config = struct {
    inter_arrival_time: SPDist,
    wait_time: DPDist,
};

const content = 
    \\{
    \\  "inter_arrival_time": { "exponential": { "lambda": 2.0 } },  
    \\  "wait_time": { "constant": 1.0 }
    \\}
;

pub fn main(init: std.process.Init) !void {
    
    const gpa = init.gpa;
 
    const options = std.json.ParseOptions{ .ignore_unknown_fields = true };
    const parsed = try std.json.parseFromSlice(Config, gpa, content, options);
    
    defer parsed.deinit();
}
