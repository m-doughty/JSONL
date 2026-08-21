use JSON::Fast;

unit class JSONL::Writer;

has IO::Path $.path;
has IO::Handle $.handle;
has Bool:D $.sorted-keys = True;
has Bool:D $.flush = False;
has IO::Handle $!fh;
has Bool:D $!owns-handle = False;

submethod TWEAK() {
	if $!path.defined && $!handle.defined {
		die "JSONL::Writer: provide either :path or :handle, not both";
	}
	unless $!path.defined || $!handle.defined {
		die "JSONL::Writer: must provide :path or :handle";
	}
	if $!handle.defined {
		$!fh = $!handle;
		$!owns-handle = False;
	}
}

# JSONL is a byte format: each record is UTF-8 JSON followed by one 0x0A
# byte, on every platform. Records are therefore written as bytes,
# bypassing the handle's encoder entirely — Rakudo builds that encoder
# with newline translation on (rewriting "\n" to CRLF on Windows), it is
# not an `open` argument, and re-setting it through .encoding
# short-circuits when the encoding name is unchanged. Bytes have no such
# trapdoors, and .write is ordered with any .say the caller does on a
# shared handle.
method !emit(Any:D $value --> Nil) {
	# The closed-handle check .say performs and .write does not: without
	# it a write to a closed handle dies with a raw VM error instead of
	# the typed X::IO::Closed callers match on.
	die X::IO::Closed.new(:trying<write>)
		unless $!fh.defined && $!fh.opened;
	$!fh.write((self!serialize($value) ~ "\n").encode);
	$!fh.flush if $!flush;
	Nil;
}

method !serialize(Any:D $value --> Str:D) {
	to-json($value, :!pretty, :$!sorted-keys);
}

method !open-for-write() {
	$!fh = $!path.open(:w);
	$!owns-handle = True;
}

method !open-for-append() {
	$!fh = $!path.open(:a);
	$!owns-handle = True;
}

method write-line(Any:D $value) {
	if $!path.defined && !$!fh.defined {
		self!open-for-write;
	}
	self!emit($value);
}

method write-all(@values) {
	if $!path.defined {
		self!open-for-write;
	}
	for @values -> Any:D $value {
		self!emit($value);
	}
	self.close if $!owns-handle;
}

method append(Any:D $value) {
	if $!path.defined {
		self!open-for-append;
		self!emit($value);
		self.close;
	} else {
		self!emit($value);
	}
}

method append-many(@values) {
	if $!path.defined {
		self!open-for-append;
		for @values -> Any:D $value {
			self!emit($value);
		}
		self.close;
	} else {
		for @values -> Any:D $value {
			self!emit($value);
		}
	}
}

method close() {
	if $!owns-handle && $!fh.defined {
		$!fh.close;
		$!fh = Nil;
		$!owns-handle = False;
	}
}
