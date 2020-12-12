package K1 {
    use mro 'c3';
    our @ISA = qw(U V W);
}
package K2 {
    use mro 'c3';
    our @ISA = qw(X V Y);
}
package K3 {
    use mro 'c3';
    our @ISA = qw(X U);
}
package WithC3MRO {
    use mro 'c3';
    our @ISA = qw(K1 K2 K3);
}
