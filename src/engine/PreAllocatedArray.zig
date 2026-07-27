const Allocator = @import("std").mem.Allocator;

pub const PreAllocatedArrayError = error{
    OutOfMemory,
};

pub fn PreAllocatedArray(comptime T: type) type {
    return struct {
        const ArraySelf = @This();
        pub const ElementWrapper = struct {
            /// Pointer to the array that owns the element data. has_changes should be set to true if the data is directly modified
            array: ?*ArraySelf,
            /// Fill this pointer with the data
            data: ?*T,
            /// Internal use for array operations
            index: usize,

            pub fn markUpdated(self: @This()) void {
                if (self.array) |array| {
                    array.has_changes = true;
                }
            }

            pub fn removeFromArray(self: *@This()) void {
                if (self.array) |array| {
                    array.swapRemove(self);
                }
            }
        };

        /// The allocator is used to generate the initial arrays only. It does not own the ElementWrappers
        allocator: Allocator,
        /// The data
        array_data: []T,
        /// Use pointers
        array_ptrs: []*ElementWrapper,
        /// The in-use size
        in_use_size: usize,
        /// Flag that gets set to true on any additions or removals.
        has_changes: bool,

        pub fn init(allocator: Allocator, max_elements: usize) !@This() {
            const data_ptr = try allocator.alloc(T, max_elements);
            const wrappers_ptr = try allocator.alloc(*ElementWrapper, max_elements);

            return .{
                .allocator = allocator,
                .array_data = data_ptr,
                .array_ptrs = wrappers_ptr,
                .in_use_size = 0,
                .has_changes = false,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.allocator.free(self.array_data);
            self.allocator.free(self.array_ptrs);
            self.* = undefined;
        }

        pub fn getInUseDataSlice(self: *@This()) []T {
            return self.array_data[0..self.in_use_size];
        }

        /// Push a new element, the data struct can be filled with values after this
        pub fn push(self: *@This(), value: *ElementWrapper) PreAllocatedArrayError!void {
            if (self.in_use_size == self.array_data.len) return PreAllocatedArrayError.OutOfMemory;

            value.array = self;
            value.data = &self.array_data[self.in_use_size];
            value.index = self.in_use_size;
            self.array_ptrs[self.in_use_size] = value;

            self.in_use_size += 1;
            self.has_changes = true;
        }

        /// Swap remove the element, the data in the element wrapper is not touched, but the array pointer and index are cleared
        pub fn swapRemove(self: *@This(), element: *ElementWrapper) void {
            const last_element_index = self.in_use_size - 1;
            defer {
                element.array = undefined;
                element.index = undefined;

                self.in_use_size -= 1;
                self.has_changes = true;
            }

            if (element.index == last_element_index) {
                self.array_data[element.index] = undefined;
                self.array_ptrs[element.index] = undefined;

                return;
            }

            self.array_data[element.index] = self.array_data[last_element_index];
            self.array_ptrs[element.index] = self.array_ptrs[last_element_index];
            self.array_ptrs[element.index].data = &self.array_data[element.index];
            self.array_ptrs[element.index].index = element.index;
        }
    };
}
