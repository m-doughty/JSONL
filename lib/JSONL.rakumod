use JSONL::Line;
use JSONL::Reader;
use JSONL::Writer;
use JSONL::Editor;

unit module JSONL;

sub read-jsonl(IO::Path:D $path, Bool :$lenient = False --> Seq) is export {
	JSONL::Reader.new(:$path, :$lenient).lines;
}

sub write-jsonl(IO::Path:D $path, @values, Bool :$sorted-keys = True) is export {
	JSONL::Writer.new(:$path, :$sorted-keys).write-all(@values);
}

sub append-jsonl(IO::Path:D $path, Any:D $value, Bool :$sorted-keys = True) is export {
	JSONL::Writer.new(:$path, :$sorted-keys).append($value);
}
