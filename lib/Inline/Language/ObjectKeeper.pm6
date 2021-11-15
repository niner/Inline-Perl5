class Inline::Language::ObjectKeeper {
    has IterationBuffer $!objects;
    has $!last_free;

    submethod BUILD() {
        $!objects := IterationBuffer.new;
        $!last_free := -1;
    }

    method push($value is raw) {
        my $objects := $!objects;
        $objects.push($value);
        $objects.elems - 1
    }

    method keep(Any:D $value is raw) returns Int {
        my $index := $!last_free;
        if $index == -1 {
            self.push($value)
        }
        else {
            my $objects := $!objects;
            $!last_free := $objects.AT-POS($index);
            $objects.BIND-POS($index, $value);
            $index
        }
    }

    method get(Int $index) returns Any:D {
        $!objects.AT-POS($index);
    }

    method free(Int $index --> Nil) {
        $!objects.BIND-POS($index, $!last_free);
        $!last_free := $index;
    }
}

