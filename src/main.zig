const std = @import("std");

const DZ: i32 = 5;
const R1: i32 = 1;
const R2: i32 = 2;
const R1I = R1 * 256;
const R2I = R2 * 256;

pub fn main() !void {
    const std_out = std.io.getStdOut();
    var buf_writer = std.io.bufferedWriter(std_out.writer());
    const writer = buf_writer.writer();

    var sB: i16 = 0;
    var cB: i16 = 16_384;
    var sA: i16 = 11_583;
    var cA: i16 = 11_583;
    var sAsB: i16 = 0;
    var cAsB: i16 = 0;
    var sAcB: i16 = 11_583;
    var cAcB: i16 = 11_583;

    while (true) {
        const p0x: i32 = DZ * sB >> 6;
        const p0y: i32 = DZ * sAcB >> 6;
        const p0z: i32 = -DZ * cAcB >> 6;
        var niters: i32 = 0;
        var nnormals: i32 = 0;
        const yincC = (cA >> 6) + (cA >> 5);
        const yincS = (sA >> 6) + (sA >> 5);
        const xincX = (cB >> 7) + (cB >> 6);
        const xincY = (sAsB >> 7) + (sAsB >> 6);
        const xincZ = (cAsB >> 7) + (cAsB >> 6);
        var ycA = -((cA >> 1) + (cA >> 4));
        var ysA = -((sA >> 1) + (sA >> 4));

        var j: u8 = 0;
        while (j < 23) : (j += 1) {
            const xsAsB: i32 = (sAsB >> 4) - sAsB;
            const xcAsB: i32 = (cAsB >> 4) - cAsB;
            var vxi14 = (cB >> 4) - cB - sB;
            var vyi14 = ycA - @as(i16, @truncate(xsAsB)) - sAcB;
            var vzi14 = ysA + @as(i16, @truncate(xcAsB)) + cAcB;

            var i: u8 = 0;
            while (i < 79) : (i += 1) {
                var t: i32 = 512;
                var px = @as(i16, @truncate(p0x)) + (vxi14 >> 5);
                var py = @as(i16, @truncate(p0y)) + (vyi14 >> 5);
                var pz = @as(i16, @truncate(p0z)) + (vzi14 >> 5);
                const lx0 = sB >> 2;
                const ly0 = sAcB - cA >> 2;
                const lz0 = -cAcB - sA >> 2;

                while (true) : (niters += 1) {
                    var lx = lx0;
                    const ly = ly0;
                    var lz = lz0;

                    const t0 = computeCordicLength(px, py, &lx, ly);
                    const t1 = t0 - R2I;
                    const t2 = computeCordicLength(pz, @truncate(t1), &lz, lx);
                    var d = t2 - R1I;

                    t += d;
                    if (t > 8 * 256) {
                        try writer.writeByte(' ');
                        break;
                    } else if (d < 2) {
                        const N = lz >> 9;
                        try writer.writeByte(".,-~:;!*=#$@"[if (N > 0) if (N < 12) @intCast(N) else 11 else 0]);
                        nnormals += 1;
                        break;
                    }

                    var dx: i16 = 0;
                    var dy: i16 = 0;
                    var dz: i16 = 0;
                    var a = vxi14;
                    var b = vyi14;
                    var c = vzi14;

                    while (d > 0) {
                        if (d & 1024 > 0) {
                            dx += a;
                            dy += b;
                            dz += c;
                        }
                        d = (d & 1023) << 1;
                        a >>= 1;
                        b >>= 1;
                        c >>= 1;
                    }
                    px += dx >> 4;
                    py += dy >> 4;
                    pz += dz >> 4;
                }
                vxi14 += xincX;
                vyi14 -= xincY;
                vzi14 += xincZ;
            }

            try writer.writeByte('\n');

            ycA += yincC;
            ysA += yincS;
        }

        try writer.print("{d} iterations {d} lit pixels\x1b[K", .{ niters, nnormals });
        try buf_writer.flush();

        rotate(5, &cA, &sA);
        rotate(5, &cAsB, &sAsB);
        rotate(5, &cAcB, &sAcB);
        rotate(6, &cB, &sB);
        rotate(6, &cAcB, &cAsB);
        rotate(6, &sAcB, &sAsB);

        std.time.sleep(15 * std.time.ns_per_ms);
        try writer.writeAll("\r\x1b[23A");
    }
}

fn computeCordicLength(x_1: i16, y_1: i16, x_2: *i16, y_2: i16) i32 {
    var x1: i32 = x_1;
    var y1: i32 = y_1;
    var x2: i32 = x_2.*;
    var y2: i32 = y_2;

    if (x1 < 0) {
        x1 = -x1;
        x2 = -x2;
    }

    var i: u4 = 0;
    while (i < 8) : (i += 1) {
        const t = x1;
        const t2 = x2;

        if (y1 < 0) {
            x1 -= y1 >> i;
            y1 += t >> i;
            x2 -= y2 >> i;
            y2 += t2 >> i;
        } else {
            x1 += y1 >> i;
            y1 -= t >> i;
            x2 += y2 >> i;
            y2 -= t2 >> i;
        }
    }

    x_2.* = @truncate((x2 >> 1) + (x2 >> 3));
    return (x1 >> 1) + (x1 >> 3);
}

fn rotate(s: u4, x: *i16, y: *i16) void {
    x.* -= y.* >> s;
    y.* += x.* >> s;
}
