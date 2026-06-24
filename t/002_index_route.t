use strict;
use warnings;

use MySite;
use Test::More tests => 6;
use Plack::Test;
use HTTP::Request::Common;
use Ref::Util qw<is_coderef>;

my $app = MySite->to_app;
ok( is_coderef($app), 'Got app' );

my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/' );

ok( $res->is_success, '[GET /] successful' );

my $list_res = $test->request( GET '/article/list' );
ok( $list_res->is_success, '[GET /article/list] successful' );
ok( !$list_res->is_redirect, '[GET /article/list] is not redirect' );

my $articles_res = $test->request( GET '/articles' );
ok( $articles_res->is_success, '[GET /articles] successful' );
ok( !$articles_res->is_redirect, '[GET /articles] is not redirect' );
