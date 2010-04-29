#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib '.';
use FizzBuzz;


fizzbuzz {
    from 1;
    to 100;
    rule { print 'Fizz' } where { $_ % 3 == 0 };
    rule { print 'Buzz' } where { $_ % 5 == 0 };
    fallback { print $_ };
    each_loop_end { print "\n" };
};

no FizzBuzz;
# fizzbuzz;    # error
