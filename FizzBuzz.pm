package FizzBuzz;
use strict;
use warnings;
use utf8;
use 5.10.0;

use Carp;
use Sub::Prototype qw/set_prototype/;
use Data::Dump qw/dump/;




sub __sub_proto (&@) {
    my ($sub, $prototype) = @_;
    set_prototype $sub => $prototype if defined $prototype;
    $sub;
}

sub import {
    my $class = shift;
    my $pkg   = caller;

    # Avoid compile-error.
    no strict 'refs';
    *{"$pkg\::fizzbuzz"} = __sub_proto { goto &fizzbuzz } '&';
    *{"$pkg\::from"}     = __sub_proto { goto &from };
    *{"$pkg\::to"}       = __sub_proto { goto &to   };
    *{"$pkg\::rule"}     = __sub_proto { goto &rule } '&@';
    *{"$pkg\::fallback"} = __sub_proto { goto &fallback } '&';
    *{"$pkg\::where"}    = __sub_proto { goto &where } '&';
}

sub fizzbuzz (&) {
    my ($setup) = @_;
    my $pkg = caller;

    my $from;
    my $to;
    my @rule;
    my @fallback;

    do {
        # Define real subs.
        no warnings qw/redefine/;
        local *from = __sub_proto { $from = shift };
        local *to   = __sub_proto { $to   = shift };
        local *rule = __sub_proto { push @rule, [@_] } '&@';
        local *fallback = __sub_proto { push @fallback, @_ } '&';
        local *where = __sub_proto { $_[0] } '&';
        $setup->();
    };

    for my $i ($from..$to) {
        my $matched;
        for (@rule) {
            my ($proc, $pred) = @$_;
            if (do { local $_ = $i; $pred->() }) {
                $proc->();
                $matched = 1;
            }
        }
        unless ($matched) {
            for my $fallback (@fallback) {
                local $_ = $i;
                $fallback->();
            }
        }
        print "\n";
    }
}

sub __dummy {
    my ($subname, $prototype) = @_;
    return __sub_proto {
        croak "You can't call $subname() outside fizzbuzz().";
    } $prototype;
}

*from = __dummy from => '';
*to   = __dummy to   => '';
*rule = __dummy rule => '&';
*fallback = __dummy fallback => '&';
*where = __dummy where => '&';

"false";
