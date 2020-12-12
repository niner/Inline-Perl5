package C {
    our @ISA = qw(A B);
}
package D {
    our @ISA = qw(B A);
}
package NonC3MRO {
    our @ISA = qw(C D);
}
