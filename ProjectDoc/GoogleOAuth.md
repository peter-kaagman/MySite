# Google OAuth2 authenticatie in Dancer2

Deze applicatie implementeert Google OAuth2 login met alleen standaard Perl-modules (LWP::UserAgent, JSON) en Dancer2. Er wordt géén externe OAuth2-module gebruikt.

## Werking

1. **Configuratie**
   - Zet je Google client_id, client_secret, authorize_url, token_url, userinfo_url en scope in `config.yml` onder `oauth_providers.google`.
   - Je kunt per omgeving (development, production, config_local.yml) een andere `redirect_uri` instellen. Als deze niet is opgegeven, wordt automatisch de lokale callback-URL gebruikt.

2. **Login flow**
   - Route `/login/google` bouwt de Google authorize URL en redirect de gebruiker naar Google.
   - De `redirect_uri` wordt uit de config gehaald als die bestaat, anders wordt `uri_for('/callback/google')` gebruikt.

3. **Callback**
   - Route `/callback/google` ontvangt de `code` van Google.
   - Met LWP::UserAgent wordt een POST gedaan naar de token endpoint om een access_token op te halen.
   - Met het access_token wordt gebruikersinfo opgehaald van de userinfo endpoint.
   - De gebruikersinfo wordt opgeslagen in de Dancer2 session (`session user => $userinfo`).

4. **Logout**
   - Route `/logout` verwijdert de sessie en logt de gebruiker uit.

## Configuratievoorbeeld (config.yml)

```yaml
oauth_providers:
  google:
    client_id: 'YOUR_GOOGLE_CLIENT_ID'
    client_secret: 'YOUR_GOOGLE_CLIENT_SECRET'
    authorize_url: 'https://accounts.google.com/o/oauth2/auth'
    token_url: 'https://oauth2.googleapis.com/token'
    userinfo_url: 'https://openidconnect.googleapis.com/v1/userinfo'
    scope: 'openid email profile'
    # redirect_uri: 'https://jouwsite.nl/callback/google'  # optioneel, voor productie
```

## Belangrijk
- De `redirect_uri` die je gebruikt moet ook geregistreerd zijn in de Google Cloud Console.
- Door gebruik te maken van Dancer2's `config`, kun je eenvoudig per omgeving andere settings laden (bijv. met `config_local.yml` of `production.yml`).
- De login flow werkt zowel lokaal als in productie (bijv. Docker of cloud) zonder codewijzigingen, alleen door de juiste config te gebruiken.

## Uitbreiden
- Je kunt eenvoudig andere providers toevoegen door extra entries onder `oauth_providers` te maken en routes toe te voegen.
- De gebruikersinfo is na login beschikbaar via `session('user')` in je routes en templates.

## Appendix: Voorbeeld van de 3 route handlers

```perl
get '/login/google' => sub {
    my $google_conf = config->{oauth_providers}->{google};
    my $redirect_uri = $google_conf->{redirect_uri} || uri_for('/callback/google');
    my $base = $google_conf->{authorize_url};
    my $params = {
        client_id     => $google_conf->{client_id},
        redirect_uri  => $redirect_uri,
        response_type => 'code',
        scope         => $google_conf->{scope},
        access_type   => 'offline',
        prompt        => 'consent',
    };
    my $query = join('&', map { $_ . '=' . uri_escape($params->{$_}) } keys %$params);
    my $url = "$base?$query";
    return redirect $url;
};

get '/callback/google' => sub {
    my $google_conf = config->{oauth_providers}->{google};
    my $code = query_parameters->get('code');
    return "No code provided" unless $code;
    my $redirect_uri = $google_conf->{redirect_uri} || uri_for('/callback/google');
    my $ua = LWP::UserAgent->new;
    my $token_url = $google_conf->{token_url};
    my $res = $ua->post($token_url, {
        code          => $code,
        client_id     => $google_conf->{client_id},
        client_secret => $google_conf->{client_secret},
        redirect_uri  => $redirect_uri,
        grant_type    => 'authorization_code',
    });
    return "Token request failed: " . $res->status_line unless $res->is_success;
    my $token = decode_json($res->decoded_content);
    my $access_token = $token->{access_token} or return "No access_token in response";
    # Haal userinfo op
    my $userinfo_url = $google_conf->{userinfo_url};
    my $userinfo_res = $ua->get($userinfo_url . '?access_token=' . uri_escape($access_token));
    return "Userinfo request failed: " . $userinfo_res->status_line unless $userinfo_res->is_success;
    my $userinfo = decode_json($userinfo_res->decoded_content);
    session user => $userinfo;
    return redirect '/';
};

get '/logout' => sub {
    session->destroy;
    return redirect '/';
};
```

---

*Laatste update: februari 2026*
