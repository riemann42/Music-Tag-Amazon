package MusicTagTest;
use base 'Exporter';
use vars '@EXPORT';
use strict;
use Test::More;
use Digest::SHA1;
use File::Copy;
use 5.006;

@EXPORT = qw(create_tag read_tag random_write random_read random_write_num random_read_num random_write_date random_read_date filetest);

my %values = ();

sub create_tag {
    my $filetest    = shift;
    my $tagoptions  = shift;
	my $testoptions = shift;
	return 0 unless (-f $filetest);
	my $tag = Music::Tag->new($filetest, $tagoptions, $testoptions->{plugin} || 'Auto');
	ok($tag, 'Object created: ' . $filetest);
	die unless $tag;
	ok($tag->get_tag,           'get_tag called: ' . $filetest);
	ok($tag->isa('Music::Tag'), 'Correct Class: ' . $filetest);
	return $tag;
}

sub read_tag {
	my $tag = shift;
	my $testoptions = shift;
	return 0 if (! exists $testoptions->{values_in});
	my $c=0;
	foreach my $meth (keys %{$testoptions->{values_in}}) {
		SKIP: {
			skip "$meth test skipped", 1 if (! $testoptions->{values_in}->{$meth});
			$c++;
			cmp_ok($tag->$meth, 'eq', $testoptions->{values_in}->{$meth});
		}
	}
	return $c;
}

sub random_write {
	my $tag = shift;
	my $testoptions = shift;
	return 0 if (! exists $testoptions->{random_write});
	my $c = 0;
	foreach my $meth (@{$testoptions->{random_write}}) {
		my $val = "test" . $meth . int(rand(1000));
		$values{$meth} = $val;
		ok($tag->$meth($val), 'auto write to ' . $meth);
		$c++;
	}
	return $c;
}

sub random_write_num {
	my $tag = shift;
	my $testoptions = shift;
	return 0 if (! exists $testoptions->{random_write_num});
	my $c = 0;
	foreach my $meth (@{$testoptions->{random_write_num}}) {
		my $val = int(rand(10))+1;
		$values{$meth} = $val;
		ok($tag->$meth($val), 'auto write to ' . $meth);
		$c++;
	}
	return $c;
}

sub random_write_date {
	my $tag = shift;
	my $testoptions = shift;
	return 0 if (! exists $testoptions->{random_write_date});
	my $c = 0;
	foreach my $meth (@{$testoptions->{random_write_date}}) {
		 my $val = int(rand(1_800_000_000));
		 $values{$meth} = $val;
		 ok($tag->$meth($val), 'auto write to '. $meth);
		 $c++;
	}
	return $c;
}

sub random_read {
	my $tag = shift;
	my $testoptions = shift;
	return 0 if (! exists $testoptions->{random_write});
	my $c = 0;
	foreach my $meth (@{$testoptions->{random_write}}) {
		cmp_ok($tag->$meth, 'eq', $values{$meth}, 'auto read of ' . $meth);
		$c++;
	}
	return $c;
}

sub random_read_num {
	my $tag = shift;
	my $testoptions = shift;
	return 0 if (! exists $testoptions->{random_write_num});
	my $c = 0;
	foreach my $meth (@{$testoptions->{random_write_num}}) {
		cmp_ok($tag->$meth, '==', $values{$meth}, 'auto read of ' . $meth);
		$c++;
	}
	return $c;
}

sub random_read_date {
	my $tag = shift;
	my $testoptions = shift;
	return 0 if (! exists $testoptions->{random_write_date});
	my $c = 0;
	foreach my $meth (@{$testoptions->{random_write_date}}) {
		 my $meth_t = $meth;
		 $meth_t =~ s/epoch/time/;
		 my $meth_d = $meth;
		 $meth_d =~ s/epoch/date/;
		 $meth_d =~ s/_date//;
		 my @tm = gmtime($values{$meth});
		 cmp_ok(substr($tag->$meth_t,0,16), 'eq', substr(sprintf('%04d-%02d-%02d %02d:%02d:%02d', $tm[5]+1900, $tm[4]+1, $tm[3], $tm[2], $tm[1], $tm[0]),0,16), 'auto read from '. $meth_t);
		 cmp_ok($tag->$meth_d, 'eq', sprintf('%04d-%02d-%02d', $tm[5]+1900, $tm[4]+1, $tm[3]), 'auto read from '. $meth_d);
		$c+=2;
	}
	return $c;
}

sub read_picture {
	my $tag = shift;
	my $testoptions = shift;
	my $c = 0;
	return 0 if (! $testoptions->{picture_read});
	ok($tag->picture_exists, 'Picture Exists');
	$c+=2;
	if ($testoptions->{picture_sha1}) {
		my $sha1 = Digest::SHA1->new();
		$sha1->add($tag->picture->{_Data});
		cmp_ok($sha1->hexdigest, 'eq', $testoptions->{picture_sha1}, 'digest of picture matches during read');
		$c++;
	}
}

sub write_picture {
	my $tag = shift;
	my $testoptions = shift;
	my $c = 0;
	return 0 if (! $testoptions->{picture_file});
	ok($tag->picture_filename($testoptions->{picture_file}), 'add picture');
	ok($tag->picture_exists, 'Picture Exists after write');
	$c+=2;
	if ($testoptions->{picture_sha1}) {
		my $sha1 = Digest::SHA1->new();
		$sha1->add($tag->picture->{_Data});
		cmp_ok($sha1->hexdigest, 'eq', $testoptions->{picture_sha1}, 'digest of picture matches after write');
		$c++;
	}
	return $c;
}

sub filetest {
    my $file        = shift;
    my $filetest    = shift;
    my $tagoptions  = shift;
    my $testoptions = shift;
	my $c = 0;

  SKIP: {
        skip ("File: $file does not exists", $testoptions->{count} || 1) if (! -f $file);
        return unless (-f $file);
        copy($file, $filetest);

        my $tag = create_tag($filetest,$tagoptions,$testoptions);
		$c+=3;
        die unless $tag;


		read_tag($tag,$testoptions);
		if ($testoptions->{picture_in}) {
			ok($tag->picture_exists, 'Picture should exists');
		}
		else {
			ok(! $tag->picture_exists, 'Picture should not exist');
		}
		$c++;

		if ($testoptions->{skip_write_tests}) {
			$tag->close();
			$tag = undef;
		}
		else {
			$c+= random_write($tag,$testoptions);
			$c+= random_write_num($tag,$testoptions);
			$c+= random_write_date($tag,$testoptions);
			$c+= write_picture($tag,$testoptions);
			ok($tag->set_tag, 'set_tag: ' . $filetest);
			$c++;
			$tag->close();
			$tag = undef;
			my $tag2 = create_tag($filetest,$tagoptions,$testoptions);
			$c+=3;
			$c+= random_read($tag2,$testoptions);
			$c+= random_read_num($tag2,$testoptions);
			$c+= random_read_date($tag2,$testoptions);
			$c+= read_picture($tag2,$testoptions);
			$tag2->close();
		}
		unlink($filetest);
		return $c;
    }
}


1;

