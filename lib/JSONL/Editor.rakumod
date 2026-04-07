use JSONL::Reader;
use JSONL::Writer;
use JSONL::Line;

unit class JSONL::Editor;

method !read-lines(IO::Path:D $path, Bool:D $lenient --> List) {
	JSONL::Reader.new(:$path, :$lenient).list;
}

method !write-lines(IO::Path:D $path, @lines) {
	my JSONL::Writer $writer .= new(:$path);
	$writer.write-all(@lines.map(*.value));
}

method update-at(IO::Path:D $path, Int:D $index, Any:D $new-value, Bool :$lenient = False) {
	my @lines = self!read-lines($path, $lenient);
	if $index < 0 || $index >= @lines.elems {
		die "JSONL::Editor: index $index out of bounds (file has {@lines.elems} lines)";
	}
	@lines[$index] = JSONL::Line.new(:value($new-value), :line-number(@lines[$index].line-number));
	self!write-lines($path, @lines);
}

method delete-at(IO::Path:D $path, Int:D $index, Bool :$lenient = False) {
	my @lines = self!read-lines($path, $lenient);
	if $index < 0 || $index >= @lines.elems {
		die "JSONL::Editor: index $index out of bounds (file has {@lines.elems} lines)";
	}
	@lines.splice($index, 1);
	self!write-lines($path, @lines);
}

method insert-at(IO::Path:D $path, Int:D $index, Any:D $value, Bool :$lenient = False) {
	my @lines = self!read-lines($path, $lenient);
	if $index < 0 || $index > @lines.elems {
		die "JSONL::Editor: index $index out of bounds (file has {@lines.elems} lines)";
	}
	my JSONL::Line $new-line .= new(:$value, :line-number($index + 1));
	@lines.splice($index, 0, $new-line);
	self!write-lines($path, @lines);
}

method transform(IO::Path:D $path, &transformer, Bool :$lenient = False) {
	my @lines = self!read-lines($path, $lenient);
	my @result;
	for @lines -> JSONL::Line $line {
		my $new-value = transformer($line);
		if $new-value.defined {
			@result.push: JSONL::Line.new(:value($new-value), :line-number($line.line-number));
		}
	}
	self!write-lines($path, @result);
}
