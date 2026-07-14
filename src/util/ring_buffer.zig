pub fn RingBuffer(comptime T: type) type {
    return struct {
        last_read: usize = 0,
        last_write: usize = 0,
        buffer: []T,

        pub fn nextPtr(self: *@This()) ?*T {
            if (self.last_read == self.last_write) return null;
            self.last_read = (self.last_read + 1) % self.buffer.len;
            return &self.buffer[self.last_read];
        }

        /// non overwritable 
        pub fn newPtr(self: *@This()) ?*T {
            const next_write = (self.last_write + 1) % self.buffer.len;
            if (next_write == self.last_read) return null;
            self.last_write = next_write;
            return &self.buffer[self.last_write];
        }
    };
}
