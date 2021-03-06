package Acme::FizzBuzz::Descriptive;
use strict;
use warnings;
use utf8;
use 5.8.0;

our $VERSION = eval '0.001';

use Carp;
use Scalar::Util qw/set_prototype openhandle/;
use Data::Util qw/install_subroutine is_integer is_string/;
use Scope::Guard;
use FileHandle;



sub __sub_proto (&@) {
    my ($sub, $prototype) = @_;
    set_prototype \&$sub => $prototype if defined $prototype;
    $sub;
}


my %SUBNAME_VS_PROTOTYPE = (
    from => undef,
    to => undef,
    rule => '&@',
    fallback => '&',
    where => '&',
    each_loop_begin => '&',
    each_loop_end => '&',
    select => undef,
);



# Install dummy subs.
sub __dummy {
    my ($subname, $prototype) = @_;
    return __sub_proto {
        croak "You can't call $subname() outside fizzbuzz().";
    } $prototype;
}

for my $subname (keys %SUBNAME_VS_PROTOTYPE) {
    install_subroutine __PACKAGE__, $subname => __dummy $subname => $SUBNAME_VS_PROTOTYPE{$subname};
}



sub import {
    my $class = shift;
    my $pkg   = caller;

    # Install dummy subs to avoid compile-error.
    for my $subname (keys %SUBNAME_VS_PROTOTYPE) {
        install_subroutine $pkg, $subname => __sub_proto { goto &$subname } $SUBNAME_VS_PROTOTYPE{$subname};
    }

    install_subroutine $pkg, fizzbuzz => __sub_proto { goto &fizzbuzz } prototype 'fizzbuzz';
}

sub unimport {
    my $pkg   = caller;

    no strict 'refs';
    for my $subname ('fizzbuzz', keys %SUBNAME_VS_PROTOTYPE) {
        delete ${"$pkg\::"}{$subname};
    }
}



sub __validate_condition {
    my ($from, $to, $rule, $fallback) = @_;

    unless (defined $from) {
        croak "from() is not called.";
    }
    unless (is_integer($from)) {
        croak "from()'s value is not integer.";
    }
    unless (defined $to) {
        croak "to() is not called.";
    }
    unless (is_integer($to)) {
        croak "to()'s value is not integer.";
    }
    unless ($from <= $to) {
        croak "$from..$to is invalid range.";
    }
}

sub fizzbuzz (&) {
    my ($setup) = @_;
    my $pkg = caller;

    my $from;
    my $to;
    my @rule;
    my @fallback;
    my @begin_proc;
    my @end_proc;
    my $out_fh;
    my @guard;
    my $open_mode = 'w';

    do {
        # Define real subs.
        #
        # TODO Check arguments more strictly.

        no warnings qw/redefine/;
        local *from = __sub_proto { $from = shift } $SUBNAME_VS_PROTOTYPE{from};
        local *to   = __sub_proto { $to   = shift } $SUBNAME_VS_PROTOTYPE{to};
        local *rule = __sub_proto { push @rule, [@_] } $SUBNAME_VS_PROTOTYPE{rule};
        local *fallback = __sub_proto { push @fallback, @_ } $SUBNAME_VS_PROTOTYPE{fallback};
        local *where = __sub_proto { $_[0] } $SUBNAME_VS_PROTOTYPE{where};
        local *each_loop_begin = __sub_proto { push @begin_proc, @_ } $SUBNAME_VS_PROTOTYPE{each_loop_begin};
        local *each_loop_end = __sub_proto { push @end_proc, @_ } $SUBNAME_VS_PROTOTYPE{each_loop_end};
        local *select = __sub_proto {
            $out_fh = shift;
            $open_mode = shift || $open_mode;
            unless (is_string($out_fh) || openhandle($out_fh)) {
                croak "select()'s argument is filename or filehandle.";
            }
        } $SUBNAME_VS_PROTOTYPE{each_loop_end};

        $setup->();
    };

    __validate_condition($from, $to, [@rule], [@fallback]);

    # Do select($out_fh).
    if (defined $out_fh) {
        if (is_string($out_fh)) {
            $out_fh = FileHandle->new($out_fh => $open_mode) or die "$!: $out_fh";
        }
        unless (openhandle($out_fh)) {
            croak "filehandle is not open.";
        }

        my $prev_fh = select $out_fh;
        push @guard, sub { select $prev_fh };
    }

    for my $i ($from..$to) {
        $_->() for @begin_proc;

        my $matched;
        for (@rule) {
            my ($proc, $pred) = @$_;
            local $_ = $i;
            if ($pred->()) {
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

        $_->() for @end_proc;
    }
}



"false";
