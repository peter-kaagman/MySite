package MySite::ImageUpload;

use v5.20;
use utf8;
use Dancer2 appname => 'MySite', with => {};
# use Dancer2::Plugin::DBIC;
use Dancer2::Logger::Console;
use File::Path qw(make_path);
use POSIX qw(strftime);
use Imager;


# Hulpfuncties onder package, conventioneel
# Controleer of bestand een geldige afbeelding is (magic-bytes via Imager)
# Gestandaardiseerde error-response helper
sub _json_error {
    my (%args) = @_;
    my $status = $args{status} || 400;
    status $status;
    return to_json({ success => 0, error => $args{message}, error_code => $args{error_code} });
}
# Voeg copyright toe aan JPEG/PNG metadata
sub _add_copyright_metadata {
    my ($path, $copyright) = @_;
    my $img = Imager->new;
    return unless $img->read(file => $path);
    # Alleen voor JPEG/PNG
    my $type = lc($img->type || '');
    if ($type eq 'jpeg' || $type eq 'png') {
        $img->tags(name => 'copyright', value => $copyright);
        $img->write(file => $path) or warn '[ImageUpload] Copyright metadata schrijven mislukt: ' . $img->errstr;
    }
}
sub _is_valid_image_file {
    my ($path) = @_;
    my $img = Imager->new;
    return $img->read(file => $path) ? 1 : 0;
}

sub _validate_upload {
    my ($upload, $conf) = @_;
    my $max_size = $conf->{max_size} || 2 * 1024 * 1024;
    my $allowed_ext = $conf->{allowed_ext} || ['.jpg','.jpeg','.png','.gif','.webp'];
    my $allowed_mime = $conf->{allowed_mime} || ['image/jpeg','image/png','image/gif','image/webp'];
    my $filename = $upload->filename;
    my $size = $upload->size;
    my $mime = $upload->type;
    my ($ext) = $filename =~ /(\.[^.]+)$/;
    unless ($ext && grep { lc($ext) eq lc($_) } @$allowed_ext) {
        return (0, 'Ongeldig bestandstype. Alleen ' . join(', ', @$allowed_ext) . ' toegestaan.');
    }
    unless (grep { lc($mime) eq lc($_) } @$allowed_mime) {
        return (0, 'Ongeldig mime-type. Alleen ' . join(', ', @$allowed_mime) . ' toegestaan.');
    }
    if ($size > $max_size) {
        return (0, 'Bestand te groot (max ' . int($max_size/1024/1024) . 'MB).');
    }
    return (1, undef);
}

sub _safe_filename {
    my ($orig_name) = @_;
    my ($ext) = $orig_name =~ /(\.[^.]+)$/;
    $ext //= '.img';
    my $unique = time . '_' . int(rand(10000));
    my $safe_filename = $unique . $ext;
    $safe_filename =~ s/[^a-zA-Z0-9_.-]/_/g;
    return $safe_filename;
}

sub _resize_image_if_needed {
    my ($path, $conf_resize) = @_;
    my $max_w = $conf_resize->{max_width} || 1920;
    my $max_h = $conf_resize->{max_height} || 1200;
    my $img = Imager->new;
    if ($img->read(file => $path)) {
        my ($w, $h) = ($img->getwidth, $img->getheight);
        debug "[ImageUpload] Originele afmetingen: ${w}x${h}, limiet: ${max_w}x${max_h}";
        if ($w > $max_w || $h > $max_h) {
            my $scale = ($w/$max_w > $h/$max_h) ? $max_w/$w : $max_h/$h;
            my $new_w = int($w * $scale);
            my $new_h = int($h * $scale);
            debug "[ImageUpload] Resizen naar: ${new_w}x${new_h}";
            my $scaled = $img->scale(xpixels=>$new_w, ypixels=>$new_h);
            if ($scaled) {
                # Optimalisatie: stel compressie-kwaliteit in voor JPEG
                my $type = lc($img->type || '');
                my $ok;
                if ($type eq 'jpeg') {
                    $ok = $scaled->write(file=>$path, jpegquality => 85);
                } else {
                    $ok = $scaled->write(file=>$path);
                }
                if ($ok) {
                    debug("[ImageUpload] Resize en opslaan gelukt: $path");
                } else {
                    error('[ImageUpload] Resize write failed: ' . $scaled->errstr);
                }
            } else {
                error '[ImageUpload] Image resize failed: ' . $img->errstr;
            }
        } else {
            debug "[ImageUpload] Geen resize nodig.";
        }
    } else {
        error '[ImageUpload] Image read failed: ' . $img->errstr;
    }
}

# Route: POST /upload-image

# Handler functie
sub _upload_image {
    # Auth check: only allow logged-in users
    my $user = session->read('user');
    unless ($user) {
        return MySite::ErrorHandler::json_error(
            message => 'Unauthorized',
            status => 401
        );
    }

    my $upload = request->upload('image');
    unless ($upload) {
        status 400;
        return to_json({ success => 0, error => 'Geen bestand ontvangen.' });
    }

    # Beveiliging: bestandstype, mime-type, grootte uit config
    my $conf = config->{image_upload} || {};
    my ($ok, $err) = _validate_upload($upload, $conf);
    unless ($ok) {
        status 400;
        return to_json({ success => 0, error => $err });
    }

    my $safe_filename = _safe_filename($upload->filename);

    my $year  = strftime('%Y', localtime);
    my $month = strftime('%m', localtime);
    my $base_dir = config->{public_dir} // 'public';
    my $target_dir = "$base_dir/images/site/$year/$month";
    make_path($target_dir) unless -d $target_dir;

    my $target_path = "$target_dir/$safe_filename";
    $upload->copy_to($target_path);


    # Magic-bytes check: is het echt een afbeelding?
    unless (_is_valid_image_file($target_path)) {
        unlink $target_path;
        status 400;
        return to_json({ success => 0, error => 'Bestand is geen geldige afbeelding.' });
    }

    # Automatische resize indien nodig
    my $conf_resize = ($conf->{resize} || {});
    _resize_image_if_needed($target_path, $conf_resize);


    # WebP-generatie: alleen als het geen .webp-bestand is
    unless ($safe_filename =~ /\.webp$/i) {
        eval {
            my $img = Imager->new;
            if ($img->read(file => $target_path)) {
                my $webp_path = $target_path;
                $webp_path =~ s/\.[^.]+$/.webp/i;
                # Optimalisatie: stel compressie-kwaliteit in voor WebP
                if ($img->write(file => $webp_path, type => 'webp', webp_quality => 85)) {
                    debug "[ImageUpload] WebP-versie opgeslagen: $webp_path";
                } else {
                    error "[ImageUpload] WebP write failed: " . $img->errstr;
                }
            } else {
                error "[ImageUpload] WebP read failed: " . $img->errstr;
            }
        };
        if ($@) {
            error "[ImageUpload] WebP-generatie exception: $@";
        }
    }

    my $url = "/images/site/$year/$month/$safe_filename";
    return to_json({ success => 1, url => $url });
}

sub image_upload_config_json {
    # Auth check: only allow logged-in users
    my $user = session->read('user');
    unless ($user) {
        return MySite::ErrorHandler::json_error(
            message => 'Unauthorized',
            status => 401
        );
    }
    my $conf = config->{image_upload} || {};
    # Normaliseer: ext en mime als array, max_size als integer
    my $max_size = $conf->{max_size} || 2 * 1024 * 1024;
    my $allowed_ext = $conf->{allowed_ext} || ['.jpg','.jpeg','.png','.gif','.webp'];
    my $allowed_mime = $conf->{allowed_mime} || ['image/jpeg','image/png','image/gif','image/webp'];
    return to_json({
        max_size => $max_size + 0,
        allowed_ext => $allowed_ext,
        allowed_mime => $allowed_mime,
    });
}


# Route definitie met prefix
prefix '/api' => sub {
    post '/upload-image' => \&_upload_image;
    get  '/upload-image-config' => \&image_upload_config_json;
};

1;
