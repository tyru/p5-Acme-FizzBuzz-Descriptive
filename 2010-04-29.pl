#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib '.';
use Acme::FizzBuzz::Descriptive;


fizzbuzz {
    from 1;
    to 100;
    rule { print "$_:Fizz" } where { $_ % 3 == 0 };
    rule { print "$_:Buzz" } where { $_ % 5 == 0 };
    fallback { print $_ };
    each_loop_end { print "\n" };
};

no Acme::FizzBuzz::Descriptive;
# fizzbuzz;    # error
