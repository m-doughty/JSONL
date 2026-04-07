[![Actions Status](https://github.com/m-doughty/JSONL/actions/workflows/test.yml/badge.svg)](https://github.com/m-doughty/JSONL/actions)

NAME
====

JSONL - Read, write, edit, and filter JSONL (JSON Lines) files

SYNOPSIS
========

```raku
use JSONL;

# Convenience functions
my @lines = read-jsonl('data.jsonl'.IO).list;
write-jsonl('output.jsonl'.IO, [%(:name("Alice")), %(:name("Bob"))]);
append-jsonl('output.jsonl'.IO, %(:name("Charlie")));

# Direct hash-like access on lines
for read-jsonl('data.jsonl'.IO) -> $line {
    say $line<name>;           # Hash-like access
    say $line<meta><score>;    # Nested access
    say $line.line-number;     # 1-based source line number
}

# Grep with clean syntax
my @adults = read-jsonl('data.jsonl'.IO).grep({ $_<age> > 18 }).list;
```

DESCRIPTION
===========

JSONL provides a complete toolkit for working with JSONL (JSON Lines / NDJSON) files. Supports any JSON value type per line (objects, arrays, scalars).

JSONL::Line
-----------

A single parsed JSONL line. Pairs the parsed value with its source line number. Supports hash-like (`$line<key>`) and array-like (`$line[0]`) access.

```raku
my JSONL::Line $line = ...;
$line.value;                  # The parsed JSON value (Hash, Array, Str, Int, etc.)
$line.line-number;            # 1-based line number from source
$line.to-json;                # Serialize back to compact JSON string
$line.Str;                    # Same as to-json

# Hash-like access (when value is a Hash)
$line<name>;                  # AT-KEY
$line<name>:exists;           # EXISTS-KEY
$line.keys;                   # Key list
$line.values;                 # Value list
$line.kv;                     # Key-value pairs
$line.elems;                  # Number of elements

# Array-like access (when value is an Array)
$line[0];                     # AT-POS
$line[0]:exists;              # EXISTS-POS
```

JSONL::Reader
-------------

Lazy/streaming JSONL reader. Accepts file paths or IO handles.

```raku
# From file
my JSONL::Reader $r .= new(:path('data.jsonl'.IO));

# From handle (stdin, pipes)
my JSONL::Reader $r .= new(:handle($*IN));

# Lenient mode: skip blank lines, collect malformed as warnings
my JSONL::Reader $r .= new(:path($path), :lenient);
say $r.warnings;              # Lines that failed to parse

# Methods
$r.lines;                     # Lazy Seq of JSONL::Line
$r.list;                      # Eager List of all lines
$r.head(10);                  # First 10 lines
$r.tail(10);                  # Last 10 lines
$r.line-at(5);                # Line at 0-based index
$r.count;                     # Total line count
$r.grep({ $_<age> > 18 });   # Filter lines
$r.sample(100);               # Random sample (reservoir sampling)
$r.summary;                   # Stats: count, types, keys
$r.schema(:sample(100));      # Infer field=>type map
```

JSONL::Writer
-------------

Writes JSONL to files or handles. Always compact JSON, one value per line.

```raku
# To file
my JSONL::Writer $w .= new(:path('out.jsonl'.IO));
my JSONL::Writer $w .= new(:path($path), :!sorted-keys);  # Disable key sorting

# To handle
my JSONL::Writer $w .= new(:handle($fh));

# Methods
$w.write-line(%(:id(1)));     # Write single value + newline
$w.write-all(@values);        # Write all values (overwrites file)
$w.append(%(:id(2)));         # Open in append mode, write, close
$w.append-many(@values);      # Append multiple values
$w.close;                     # Close handle if we opened it
```

JSONL::Editor
-------------

In-place file editing. Reads the full file, applies the edit, writes it back.

```raku
my JSONL::Editor $e .= new;

$e.update-at($path, 0, %(:id(99)));       # Replace line at index
$e.delete-at($path, 2);                    # Remove line at index
$e.insert-at($path, 1, %(:id(50)));       # Insert at index
$e.transform($path, -> $line {            # Transform each line
    $line.value<id> > 5 ?? $line.value !! Nil  # Return Nil to delete
});

# All methods accept :lenient flag
$e.update-at($path, 0, $val, :lenient);
```

AUTHOR
======

Matt Doughty <matt@apogee.guru>

COPYRIGHT AND LICENSE
=====================

Copyright 2026 Matt Doughty

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

