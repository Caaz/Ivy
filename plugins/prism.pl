required => 1,
hook => {
	begin => sub {
		my $data = shift;
		$u{prism}{setColors}('~global','14,12') if(!$$data{colors}{'~global'});
	}
},
utilities => {
	msg => sub {
		# I: Handle, Target, plugin, String Key, data.
		my ($handle,$target,$key,$hash) = splice @_,0,5;
		print "Got $target, $key";
		my $string =  $u{prism}{getString}($target,$key);
		$string =~ s/\{(\w+)\}/\x04$$hash{$1}\x04/g;
		raw($handle,"PRIVMSG $target :".$u{prism}{colorize}($target,$string));
	},
	colorize => sub {
		# I: Target, Message
		# <> toggles, >> selects a word
		# << sets default
		my ($target,$message) = splice @_,0,2;
		my @c = @{ $u{prism}{getColors}($target) };
		for my $regex ('((?:\x23|\@)\w)','([a-z]+:\/\/\S+\.[a-z]{2,6}\/?(?:[\/\w=?]+)?)') { $message =~ s/$regex/\cC$c[1]$1\cC$c[0]/g; }
		my $color = 1;
		while ($message =~ s/\x04/\cC$c[$color]/) { $color = ($color)?0:1; }
		$message =~ s/\cC\d{1,2}\s+?(\cC\d{1,2})/$1/g;
		return "\cC".$c[0].$message;
	},
	getString => sub {
		# I: Target, Plugin, Key
		my ($target,$plugkey) = splice @_,0,2;
		my ($plugin,$key) = split /\./, $plugkey;
		my @lang = @{ $u{prism}{getColors}($target) };
		return ($ivy{plugin}{$plugin}{strings}{$lang[0]}{$lang[1]}{$key})?$ivy{plugin}{$plugin}{strings}{$lang[0]}{$lang[1]}{$key}:$ivy{plugin}{$plugin}{strings}{en}{us}{$key};
	},
	getLanguage => sub {
		return ($ivy{data}{prism}{lang}{ $_[0] })?$ivy{data}{prism}{lang}{ $_[0] }:['en','us'];
	},
	getColors => sub {
		# I: Target
		return ($ivy{data}{prism}{colors}{ $_[0] })?$ivy{data}{prism}{colors}{ $_[0] }:$ivy{data}{prism}{colors}{'~global'};
	},
	setLanguage => sub {
		# I: Target, String to be parsed.
		# O: T/F
		my ($target,$string) = splice @_,0,2; my @colors = split '-', $string;
		while(@colors>2) { pop @colors; }
		@{ $ivy{data}{prism}{lang}{$target} } = @colors;
		return 1;
	},
	setColors => sub {
		# I: Target, String to be parsed.
		# O: T/F
		my ($target,$string) = splice @_,0,2; my @colors = split ',', $string;
		while(@colors>2) { pop @colors; }
		for(@colors) { 
			if($_ !~ /^\d+$/) { return 0; }
			else { $_ = "0$_" if(length($_) < 2); }
		}
		@{ $ivy{data}{prism}{colors}{$target} } = @colors;
		return 1;
	},
}