class Inline::Language::ObjectKeeper {
    has @!objects;
    has $!last_free = -1;

    method keep(Any:D $value) returns Int {
        if $!last_free != -1 {
            my $index = $!last_free;
            $!last_free = @!objects.AT-POS($!last_free);
            @!objects.ASSIGN-POS($index, $value);
            $index
        }
        else {
            @!objects.push($value);
            @!objects.end
        }
    }

    method get(Int $index) returns Any:D {
        @!objects[$index];
    }

    method free(Int $index --> Nil) {
        @!objects.ASSIGN-POS($index, $!last_free);
        $!last_free = $index;
    }
}

