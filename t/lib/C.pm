package C;

sub blessed_hash   { bless { foo => 42 },     __PACKAGE__ }
sub blessed_array  { bless [ foo, 42 ],       __PACKAGE__ }
sub blessed_scalar { bless \(my $x = 42),     __PACKAGE__ }
sub blessed_regex  { bless qr/foo$/,          __PACKAGE__ }
sub blessed_sub    { bless sub { return 42 }, __PACKAGE__ }

# Not sure how to do this.
#sub blessed_typeglob { bless …, __PACKAGE__ }

1;
