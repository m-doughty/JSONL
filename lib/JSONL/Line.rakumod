use JSON::Fast;

unit class JSONL::Line;

has Any $.value is required;
has Int:D $.line-number is required;

method to-json(--> Str:D) {
	to-json($!value, :!pretty, :sorted-keys);
}

method Str(--> Str:D) {
	self.to-json;
}

method AT-KEY(Str:D $key) {
	$!value{$key};
}

method EXISTS-KEY(Str:D $key --> Bool:D) {
	$!value{$key}:exists;
}

method AT-POS(Int:D $index) {
	$!value[$index];
}

method EXISTS-POS(Int:D $index --> Bool:D) {
	$!value[$index]:exists;
}

method keys() { $!value.keys }
method values() { $!value.values }
method kv() { $!value.kv }
method elems(--> Int:D) { $!value.elems }
