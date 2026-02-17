
#!/usr/bin/sh

# Zorg dat lokale Perl-modules gevonden worden
export PERL5LIB="$PWD/local/lib/perl5"

/usr/bin/perl \
	-MDBIx::Class::Schema::Loader=make_schema_at,dump_to_dir:./lib \
	-e 'make_schema_at( 
		"MySite::Schema", 
		{ debug => 1 }, 
		[ 
			"dbi:SQLite:dbname=./db/mysite.sqlite", 
			"", 
			"" 
		] 
	)'
