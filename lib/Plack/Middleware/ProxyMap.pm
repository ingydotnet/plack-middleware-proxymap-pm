package Plack::Middleware::ProxyMap;
use 5.008003;
use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(proxymap);
use Plack::App::Proxy ();

our $VERSION = '0.12';

use Carp ();

# use XXX -with => 'YAML::XS';

sub call {
    my ($self, $env) = @_;
    my $proxymap = $self->proxymap;
    for my $entry (@$proxymap) {
        my (
            $prefix,
            $remote,
            $preserve_host_header,
            $env_override,
            $debug,
            $backend,
        ) = @{$entry}{qw(
            prefix
            remote
            preserve_host_header
            env
            debug
            backend
        )};
        Carp::croak("'prefix' or 'remote' entry missing in ProxyMap entry")
            unless $prefix and $remote;
        $preserve_host_header ||= 0;
        $env_override ||= {
            PATH_INFO => '',
            QUERY_STRING => '',
            HTTP_COOKIE => '',
        };
        $backend ||= 'AnyEvent::HTTP'; # Plack::App::Proxy's default
        my $request = $env->{REQUEST_URI};
        if ($request =~ s/^\Q$prefix\E//) {
            my $url = "$remote$request";
            warn "Plack::Middleware::Proxymap proxying " .
                "$env->{REQUEST_URI} to $url"
                    if $debug;
            return Plack::App::Proxy->new(
                remote => $url,
                preserve_host_header => $preserve_host_header,
                backend => $backend,
            )->(+{%$env, %$env_override});
        }
    }
    return $self->app->($env);
}

1;

=encoding utf8

=head1 NAME

Plack::Middleware::ProxyMap - Proxy Various URLs to Various Remotes

=head1 SYNOPSIS

    my $map = YAML::Load(<<'...');
    - prefix: /yahoo/
      remote: http://au.search.yahoo.com/search?p=
      preserve_host_header: 1
      env:
        HTTP_COOKIE: some cookie text
    - prefix: /google/
      remote: http://www.google.com/search?q=
    ...

    builder {
        enable "ProxyMap", proxymap => $map;
        $app;
    };

=head1 DESCRIPTION

This middleware allows you to easily map one or more URL prefixes to
remote URLs.

It makes use of L<Plack::App::Proxy> and supports its options. It also
makes it easy to specify custom overrides to any of the PSGI environment
entries. These are often necessary to proxy successfully.

=head1 PARAMETERS

The input to this module is an array ref of hash refs that contain the
following keys:

=over

=item prefix (required)

The string that matches the beginning of the URL. It it matches, it is
removed and the rest of the URL is tacked onto the end of the C<remote>
URL. (See below).

=item remote (required)

This is the remote URL to proxy to. The remainder of the incoming URL is
tacked onto this after the C<prefix> is removed. (See above).

=item preserve_host_header (optional)

Accepted values are 0 (default) or 1. Passed through to
L<Plack::App::Proxy>. See that module for more info.

If a proxy is not working as expected, try playing with this option.

=item env (optional)

This is a hash ref that will be merged into the current plack C<env>
hash when the proxy is used.

By default Proxymap will clear PATH_INFO, QUERY_STRING and HTTP_COOKIE,
which is usually what you want. To not clear anything, set this option
to a empty hash ref.

Can be useful for cookie injection, should you need that.

=item backend (optional)

Use this to specify an alternative backend for L<Plack::App::Proxy>. See
that module for more info.

=item debug (optional)

Set this to 1 to warn the remote url when performing a proxy.

=back

=head1 USAGE NOTE

This module can make it trivial to do ajax calls from JavaScript to load
external web pages. Since the browser thinks it is now your local web
page, there is no cross site prevention. When you get the content back,
you can load it into a DOM element and use things like jQuery to easily
find data, that you can subsequently display. You can also use REST APIs
that offer JSON but not JSONP, directly from JavaScript.

=head1 CREDIT

This is just a simple way to use L<Plack::App::Proxy>. Thanks to Lee
Aylward for that work.

Thanks to Strategic Data for supporting the writing and release of
this module.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
