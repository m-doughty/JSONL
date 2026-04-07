use JSON::Fast;
use JSONL::Line;

unit class JSONL::Reader;

has IO::Path $.path;
has IO::Handle $.handle;
has Bool:D $.lenient = False;
has JSONL::Line @.warnings;

submethod TWEAK() {
	if $!path.defined && $!handle.defined {
		die "JSONL::Reader: provide either :path or :handle, not both";
	}
	unless $!path.defined || $!handle.defined {
		die "JSONL::Reader: must provide :path or :handle";
	}
}

method !source-lines(--> Seq) {
	if $!path.defined {
		$!path.lines;
	} else {
		$!handle.lines;
	}
}

method !parse-line(Str:D $raw, Int:D $line-number --> JSONL::Line) {
	if $raw.trim.chars == 0 {
		if $!lenient {
			return JSONL::Line;
		}
		die "JSONL::Reader: blank line at line $line-number";
	}
	my $value;
	try {
		$value = from-json($raw);
		CATCH {
			default {
				if $!lenient {
					@!warnings.push: JSONL::Line.new(:value($raw), :$line-number);
					return JSONL::Line;
				}
				die "JSONL::Reader: malformed JSON at line $line-number: {.message}";
			}
		}
	}
	JSONL::Line.new(:$value, :$line-number);
}

method lines(--> Seq) {
	my Int $line-number = 0;
	self!source-lines.map(-> Str $raw {
		$line-number++;
		self!parse-line($raw, $line-number);
	}).grep(*.defined);
}

method list(--> List) {
	self.lines.eager.list;
}

method head(Int:D $n --> List) {
	self.lines.head($n).list;
}

method tail(Int:D $n --> List) {
	self.lines.tail($n).list;
}

method line-at(Int:D $index --> JSONL::Line) {
	if $index < 0 {
		fail "JSONL::Reader: index must be non-negative, got $index";
	}
	my Int $current = 0;
	for self.lines -> JSONL::Line $line {
		return $line if $current == $index;
		$current++;
	}
	fail "JSONL::Reader: index $index out of bounds (file has $current lines)";
}

method count(--> Int:D) {
	my Int:D $n = 0;
	for self.lines { $n++ }
	$n;
}

method grep(&matcher --> Seq) {
	self.lines.grep(&matcher);
}

method sample(Int:D $n --> List) {
	# Reservoir sampling (Algorithm R)
	my JSONL::Line @reservoir;
	my Int $i = 0;
	for self.lines -> JSONL::Line $line {
		if $i < $n {
			@reservoir.push: $line;
		} else {
			my Int $j = (0..$i).pick;
			if $j < $n {
				@reservoir[$j] = $line;
			}
		}
		$i++;
	}
	@reservoir.list;
}

method summary(--> Hash) {
	my Int:D $count = 0;
	my %types;
	my %keys;
	for self.lines -> JSONL::Line $line {
		$count++;
		my Str:D $type = $line.value.^name;
		%types{$type}++;
		if $line.value ~~ Hash {
			for $line.value.keys -> Str $k {
				%keys{$k}++;
			}
		}
	}
	%(:$count, :types(%types), :keys(%keys));
}

method schema(Int :$sample = 100 --> Hash) {
	my %field-types;
	my Int:D $seen = 0;
	for self.lines -> JSONL::Line $line {
		last if $seen >= $sample;
		if $line.value ~~ Hash {
			for $line.value.kv -> Str $k, $v {
				my Str:D $type = $v.defined ?? $v.^name !! 'Nil';
				%field-types{$k} //= SetHash.new;
				%field-types{$k}.set($type);
			}
		}
		$seen++;
	}
	my %result;
	for %field-types.kv -> Str $k, SetHash $types {
		%result{$k} = $types.keys.sort.list;
	}
	%result;
}
