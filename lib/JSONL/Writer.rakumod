use JSON::Fast;

unit class JSONL::Writer;

has IO::Path $.path;
has IO::Handle $.handle;
has Bool:D $.sorted-keys = True;
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
	$!fh.say(self!serialize($value));
}

method write-all(@values) {
	if $!path.defined {
		self!open-for-write;
	}
	for @values -> Any:D $value {
		$!fh.say(self!serialize($value));
	}
	self.close if $!owns-handle;
}

method append(Any:D $value) {
	if $!path.defined {
		self!open-for-append;
		$!fh.say(self!serialize($value));
		self.close;
	} else {
		$!fh.say(self!serialize($value));
	}
}

method append-many(@values) {
	if $!path.defined {
		self!open-for-append;
		for @values -> Any:D $value {
			$!fh.say(self!serialize($value));
		}
		self.close;
	} else {
		for @values -> Any:D $value {
			$!fh.say(self!serialize($value));
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
