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
		$!fh = self!disable-nl-translation($!handle);
		$!owns-handle = False;
	}
}

# JSONL is a byte format whose record separator is one 0x0A byte, on
# every platform. Rakudo builds a handle's encoder with newline
# translation ON (it is not an `open` argument — `open(:!translate-nl)`
# is silently swallowed by %_), which on Windows rewrites every "\n" to
# CRLF on the way out. Rebuilding the encoder through .encoding is the
# one supported way to turn that off; a no-op everywhere else.
method !disable-nl-translation(IO::Handle:D $fh --> IO::Handle:D) {
	$fh.encoding($_, :!translate-nl) with $fh.encoding;
	$fh;
}

method !serialize(Any:D $value --> Str:D) {
	to-json($value, :!pretty, :$!sorted-keys);
}

method !open-for-write() {
	$!fh = self!disable-nl-translation($!path.open(:w));
	$!owns-handle = True;
}

method !open-for-append() {
	$!fh = self!disable-nl-translation($!path.open(:a));
	$!owns-handle = True;
}

method write-line(Any:D $value) {
	if $!path.defined && !$!fh.defined {
		self!open-for-write;
	}
	$!fh.say(self!serialize($value));
	$!fh.flush if $!flush;
}

method write-all(@values) {
	if $!path.defined {
		self!open-for-write;
	}
	for @values -> Any:D $value {
		$!fh.say(self!serialize($value));
		$!fh.flush if $!flush;
	}
	self.close if $!owns-handle;
}

method append(Any:D $value) {
	if $!path.defined {
		self!open-for-append;
		$!fh.say(self!serialize($value));
		$!fh.flush if $!flush;
		self.close;
	} else {
		$!fh.say(self!serialize($value));
		$!fh.flush if $!flush;
	}
}

method append-many(@values) {
	if $!path.defined {
		self!open-for-append;
		for @values -> Any:D $value {
			$!fh.say(self!serialize($value));
			$!fh.flush if $!flush;
		}
		self.close;
	} else {
		for @values -> Any:D $value {
			$!fh.say(self!serialize($value));
			$!fh.flush if $!flush;
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
