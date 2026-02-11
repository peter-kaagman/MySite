package MySite::Provider::OAuth;

use strict;
use warnings;
## use Dancer2::Plugin::Auth::Extensible::Provider; # niet aanwezig, legacy
use OAuth2::Client;
use base 'Dancer2::Plugin::Auth::Extensible::Provider';
use Dancer2 app => 'MySite';

sub authenticate {
    my ($self, $username, $password, $realm) = @_;
    # Not used for OAuth, but must be present
    return;
}

sub get_user {
    my ($self, $username) = @_;
    # Not used for OAuth, but must be present
    return;
}

sub get_user_realms {
    my ($self, $username) = @_;
    # Not used for OAuth, but must be present
    return;
}

sub oauth_redirect {
    my ($self, $provider) = @_;
    my $conf;
    if ($provider eq 'google') {
        $conf = {
            client_id     => config->{plugins}{'Auth::OAuth'}{providers}{Google}{tokens}{client_id},
            client_secret => config->{plugins}{'Auth::OAuth'}{providers}{Google}{tokens}{client_secret},
            authorize_url => 'https://accounts.google.com/o/oauth2/auth',
            token_url     => 'https://oauth2.googleapis.com/token',
            userinfo_url  => 'https://openidconnect.googleapis.com/v1/userinfo',
            scope         => 'openid email profile',
        };
    } elsif ($provider eq 'github') {
        $conf = {
            client_id     => config->{plugins}{'Auth::OAuth'}{providers}{Github}{tokens}{client_id},
            client_secret => config->{plugins}{'Auth::OAuth'}{providers}{Github}{tokens}{client_secret},
            authorize_url => 'https://github.com/login/oauth/authorize',
            token_url     => 'https://github.com/login/oauth/access_token',
            userinfo_url  => 'https://api.github.com/user',
            scope         => 'user:email',
        };
    }
    return unless $conf;
    my $client = OAuth2::Client->new(
        client_id     => $conf->{client_id},
        client_secret => $conf->{client_secret},
        authorize_url => $conf->{authorize_url},
        token_url     => $conf->{token_url},
    );
    return $client->authorize_url(
        scope => $conf->{scope},
        redirect_uri => 'YOUR_REDIRECT_URI',
    );
}

sub oauth_callback {
    my ($self, $provider, $code) = @_;
    my $conf;
    if ($provider eq 'google') {
        $conf = {
            client_id     => config->{plugins}{'Auth::OAuth'}{providers}{Google}{tokens}{client_id},
            client_secret => config->{plugins}{'Auth::OAuth'}{providers}{Google}{tokens}{client_secret},
            authorize_url => 'https://accounts.google.com/o/oauth2/auth',
            token_url     => 'https://oauth2.googleapis.com/token',
            userinfo_url  => 'https://openidconnect.googleapis.com/v1/userinfo',
            scope         => 'openid email profile',
        };
    } elsif ($provider eq 'github') {
        $conf = {
            client_id     => config->{plugins}{'Auth::OAuth'}{providers}{Github}{tokens}{client_id},
            client_secret => config->{plugins}{'Auth::OAuth'}{providers}{Github}{tokens}{client_secret},
            authorize_url => 'https://github.com/login/oauth/authorize',
            token_url     => 'https://github.com/login/oauth/access_token',
            userinfo_url  => 'https://api.github.com/user',
            scope         => 'user:email',
        };
    }
    return unless $conf;
    my $client = OAuth2::Client->new(
        client_id     => $conf->{client_id},
        client_secret => $conf->{client_secret},
        authorize_url => $conf->{authorize_url},
        token_url     => $conf->{token_url},
    );
    my $token = $client->get_access_token($code, redirect_uri => 'YOUR_REDIRECT_URI');
    return unless $token;
    my $userinfo = $client->get($conf->{userinfo_url}, access_token => $token->{access_token});
    return $userinfo;
}

1;

__END__

# Usage:
# - Configure your Dancer2 app to use this provider in the plugin config
# - Implement routes for /auth/google and /auth/github that call oauth_redirect and oauth_callback
# - Store client_id, client_secret, and redirect_uri securely
# - See OAuth2::Client documentation for details
