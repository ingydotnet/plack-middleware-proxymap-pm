use inc::Module::Install;

all_from    'lib/Plack/Middleware/ProxyMap.pm';
readme_from;
manifest_skip;
ack_xxx;
version_check;

requires 'Plack::Middleware';
requires 'Plack::App::Proxy';

WriteAll;
