package MySite::ImageUpload;

use v5.20;
use utf8;
use Dancer2 appname => 'MySite', with => {};
# use Dancer2::Plugin::DBIC;
use Dancer2::Logger::Console;
use File::Path qw(make_path);
use POSIX qw(strftime);
use Imager;
use Image::ExifTool qw(:Public);
use MySite::ErrorHandler;

#
# Helper functies

# Helper: voeg suffix toe vóór extensie
sub _set_filename_suffix {
    my ($path, $suffix) = @_;
    $suffix //= '';
    $path =~ s{(\.[^.]+)$}{'_' . $suffix . $1}e;
    return $path;
}

# Bouw JSON-response
sub _build_upload_response {
    my ($url) = @_;
    return to_json({ success => 1, url => $url });
}

# Validatie functies
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

#
# Image bewerking: resize, WebP, metadata en dergelijke

# Voeg copyright toe aan JPEG/PNG metadata
sub _add_copyright_metadata {
    my ($path, $copyright, $orig_filename) = @_;
    # Alleen voor JPEG/PNG
    my $type = lc($path =~ /\.(jpe?g|png)$/i ? $1 : '');
    return unless $type eq 'jpg' || $type eq 'jpeg' || $type eq 'png';
    my $exifTool = new Image::ExifTool;
    my %tags;
    # Alleen copyright toevoegen als het nog niet bestaat
    my $existing_copyright = $exifTool->GetValue('Copyright')
        || $exifTool->GetValue('IPTC:CopyrightNotice')
        || $exifTool->GetValue('EXIF:Copyright')
        || $exifTool->GetValue('XMP:Rights');
    unless ($existing_copyright) {
        $tags{'Copyright'} = $copyright;
        $tags{'IPTC:CopyrightNotice'} = $copyright;
        $tags{'EXIF:Copyright'} = $copyright;
        $tags{'XMP:Rights'} = $copyright;
    }
    if ($orig_filename) {
        $tags{'EXIF:OriginalFileName'} = $orig_filename;
        $tags{'XMP:OriginalDocumentID'} = $orig_filename;
        $tags{'IPTC:ObjectName'} = $orig_filename;
    }
    $exifTool->SetNewValuesFromFile($path);
    $exifTool->SetNewValue($_, $tags{$_}) for keys %tags;
    my $ok = $exifTool->WriteInfo($path);
    warn '[ImageUpload] Copyright metadata schrijven mislukt: ' . $exifTool->GetValue('Error') unless $ok;
}
# Verwerk afbeelding: resize, WebP, metadata
sub _process_image {
    my ($target_path, $conf, $orig_filename) = @_;
    my $conf_resize = ($conf->{resize} || {});
    my $sizes = $conf->{sizes} || [];
    use Data::Dumper;
    debug("[ImageUpload] _process_image: sizes=" . Dumper($sizes));
    # Copyright uit config
    my $copyright = $conf->{copyright} // '';


    # Verzamel info voor JSON
    my $upload_time = scalar localtime;
    my @formats;

    # Origineel
    my ($ow, $oh) = (0,0);
    eval {
        require Imager;
        my $img = Imager->new;
        $img->read(file => $target_path);
        ($ow, $oh) = ($img->getwidth, $img->getheight);
    };
    my $public_dir = config->{public_dir} // 'public';
    my $rel_path = $target_path;
    $rel_path =~ s/^\Q$public_dir\E//;
    $rel_path = "/$rel_path" unless $rel_path =~ m{^/};
    push @formats, {
        path => $rel_path,
        type => 'original',
        width => int($ow),
        height => int($oh),
    };

    _add_copyright_metadata($target_path, $copyright, $orig_filename) if $copyright;

    # Resizes
    my $resize_info = [];
    my $resize_err = _generate_resized_versions($target_path, $sizes, $conf_resize, $copyright, $orig_filename, $resize_info);
    return $resize_err if $resize_err;
    push @formats, @$resize_info if $resize_info && ref($resize_info) eq 'ARRAY';

    # JSON-bestand schrijven
    my $json_path = $target_path;
    $json_path =~ s/\.[^.]+$/.json/;
    my $meta = {
        original_filename => $orig_filename,
        upload_time => $upload_time,
        copyright => $copyright,
        formats => [ map {
            { path => $_->{path}, type => $_->{type}, width => $_->{width}, height => $_->{height} }
        } @formats ],
    };
    debug("[ImageUpload] Probeer JSON-bestand te schrijven: $json_path");
    eval {
        require JSON;
        open my $fh, '>', $json_path or die "open $json_path: $!";
        my $json = JSON::encode_json($meta);
        debug("[ImageUpload] JSON-content: $json");
        print $fh $json;
        close $fh;
        debug("[ImageUpload] JSON-bestand succesvol geschreven: $json_path");
    };
    if ($@) {
        error("[ImageUpload] Fout bij schrijven JSON-bestand $json_path: $@");
    }

    my $err = _generate_webp_version($target_path, $orig_filename);
    return $err if $err;
    return undef;
}

# Oude versie van _generate_resized_versions verwijderd. Alleen de nieuwe versie blijft actief.

# Genereer WebP-versie indien nodig
sub _generate_webp_version {
    my ($target_path, $orig_filename) = @_;
    return undef if $orig_filename =~ /\.webp$/i;
    eval {
        my $img = Imager->new;
        if ($img->read(file => $target_path)) {
            my $webp_path = $target_path;
            $webp_path =~ s/\.[^.]+$/.webp/i;
            if ($img->write(file => $webp_path, type => 'webp', webp_quality => 85)) {
                debug "[ImageUpload] WebP-versie opgeslagen: $webp_path";
            } else {
                error "[ImageUpload] WebP write failed: " . $img->errstr;
                die $img->errstr;
            }
        } else {
            error "[ImageUpload] WebP read failed: " . $img->errstr;
            die $img->errstr;
        }
    };
    if ($@) {
        error "[ImageUpload] WebP-generatie exception: $@";
        return 'WebP-generatie mislukt.';
    }
    return undef;
}

# Genereer (en overschrijf) het origineel en extra formaten (proportioneel, aspect ratio behouden)
sub _generate_resized_versions {
    my ($orig_path, $sizes, $resize_orig, $copyright, $orig_filename, $resize_info) = @_;
    my $img = Imager->new;
    unless ($img->read(file => $orig_path)) {
        error "[ImageUpload] Resize: origineel niet leesbaar: " . $img->errstr;
        return 'Resize: origineel niet leesbaar';
    }
    my ($w, $h) = ($img->getwidth, $img->getheight);

    # Optioneel: resize het origineel zelf (overschrijven)
    if ($resize_orig && ref($resize_orig) eq 'HASH') {
        my $max_w = $resize_orig->{max_width} || $w;
        my $max_h = $resize_orig->{max_height} || $h;
        if ($w > $max_w || $h > $max_h) {
            my $scale = ($w/$max_w > $h/$max_h) ? $max_w/$w : $max_h/$h;
            my $new_w = int($w * $scale);
            my $new_h = int($h * $scale);
            my ($scaled, $err) = _resize_and_save($img, $orig_path, $new_w, $new_h);
            return $err if $err;
        } else {
            debug "[ImageUpload] Origineel: geen resize nodig.";
        }
    }

    # Extra formaten + WebP
    if ($sizes && ref($sizes) eq 'ARRAY' && @$sizes) {
        for my $size (@$sizes) {
            my $name = $size->{name} // 'resized';
            my $max_w = $size->{width} // $w;
            my $max_h = $size->{height} // $h;
            # Bepaal schaalfactor voor aspect ratio behoud
            my $scale = ($w/$max_w > $h/$max_h) ? $max_w/$w : $max_h/$h;
            $scale = 1 if $scale > 1; # niet vergroten
            my $new_w = int($w * $scale);
            my $new_h = int($h * $scale);
            my $out_path = _set_filename_suffix($orig_path, $name);
            debug("[ImageUpload] Resize: name=$name, max=(${max_w}x${max_h}), orig=(${w}x${h}), new=(${new_w}x${new_h}), out_path=$out_path");
            my ($scaled, $err);
            if ($new_w == $w && $new_h == $h) {
                debug("[ImageUpload] ${name}: formaat gelijk aan origineel, kopie maken naar $out_path");
                require File::Copy;
                File::Copy::copy($orig_path, $out_path);
                $scaled = Imager->new;
                $scaled->read(file => $out_path);
            } else {
                debug("[ImageUpload] ${name}: resize uitvoeren naar $out_path");
                ($scaled, $err) = _resize_and_save($img, $out_path, $new_w, $new_h);
                return $err if $err;
            }
            # Copyright en originele uploadnaam toevoegen aan elke resize (alleen JPEG/PNG)
            _add_copyright_metadata($out_path, $copyright, $orig_filename) if $copyright;
            _generate_webp_for($scaled, $out_path) if $scaled;
            # Verzamel info voor JSON
            if ($resize_info && ref($resize_info) eq 'ARRAY') {
                my $public_dir = config->{public_dir} // 'public';
                my $rel_path = $out_path;
                $rel_path =~ s/^\Q$public_dir\E//;
                $rel_path = "/$rel_path" unless $rel_path =~ m{^/};
                push @$resize_info, {
                    path => $rel_path,
                    type => $name,
                    width => int($new_w),
                    height => int($new_h),
                };
            }
        }
    }
    return undef;
}

# Valideer en sla bestand op, retourneer pad en url of foutmelding
sub _validate_and_save_upload {
    my ($upload, $conf) = @_;
    my ($ok, $err) = _validate_upload($upload, $conf);
    return (undef, undef, $err) unless $ok;

    my $safe_filename = _safe_filename($upload->filename);
    my $year  = strftime('%Y', localtime);
    my $month = strftime('%m', localtime);
    my $base_dir = config->{public_dir} // 'public';
    my $target_dir = "$base_dir/images/site/$year/$month";
    make_path($target_dir) unless -d $target_dir;
    my $target_path = "$target_dir/$safe_filename";
    $upload->copy_to($target_path);

    unless (_is_valid_image_file($target_path)) {
        unlink $target_path;
        return (undef, undef, 'Bestand is geen geldige afbeelding.');
    }
    my $url = "/images/site/$year/$month/$safe_filename";
    return ($target_path, $url, undef);
}


#
# Access file systeem, validatie, verwerking en response bouw

# Resize en save helper
sub _resize_and_save {
    my ($img, $out_path, $new_w, $new_h) = @_;
    my $scaled = $img->scale(xpixels=>$new_w, ypixels=>$new_h);
    unless ($scaled) {
        error "[ImageUpload] Resize scale failed: $out_path: " . $img->errstr;
        return (undef, 'Resize scale failed');
    }
    my $type = lc($img->type || '');
    my $ok;
    if ($type eq 'jpeg') {
        $ok = $scaled->write(file=>$out_path, jpegquality => 85);
    } else {
        $ok = $scaled->write(file=>$out_path);
    }
    unless ($ok) {
        error "[ImageUpload] Resize write failed: $out_path: " . $scaled->errstr;
        return (undef, 'Resize write failed');
    }
    debug("[ImageUpload] Formaat opgeslagen: $out_path ($new_w x $new_h)");
    return ($scaled, undef);
}

# WebP helper
sub _generate_webp_for {
    my ($img, $out_path) = @_;
    return if $out_path =~ /\.webp$/i;
    my $webp_path = $out_path;
    $webp_path =~ s/\.[^.]+$/.webp/i;
    if ($img->write(file => $webp_path, type => 'webp', webp_quality => 85)) {
        debug "[ImageUpload] WebP-versie opgeslagen: $webp_path";
    } else {
        error "[ImageUpload] WebP write failed: $webp_path: " . $img->errstr;
    }
}

# Handler functies
# Hoofd-uploadhandler: alleen flow, geen details
sub _upload_image {
    my $user = session->read('user');
    return MySite::ErrorHandler::json_error(message => 'Unauthorized', status => 401) unless $user;

    my $upload = request->upload('image');
    return MySite::ErrorHandler::json_error(message => 'Geen bestand ontvangen.') unless $upload;

    my $conf = config->{image_upload} || {};
    my ($target_path, $url, $err) = _validate_and_save_upload($upload, $conf);
    return MySite::ErrorHandler::json_error(message => $err) unless $target_path;

    my $process_err = _process_image($target_path, $conf, $upload->filename);
    return MySite::ErrorHandler::json_error(message => $process_err) if $process_err;

    return _build_upload_response($url);
}

# Configuratie endpoint: retourneer uploadconfig als JSON
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
