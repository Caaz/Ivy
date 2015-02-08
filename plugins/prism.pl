required => 1,
commands => {
	'setColors (?<colors>.+)' => {
		code => sub {
			my ($handle,$irc) = splice @_,0,2;
			if($u{prism}{setColors}($$irc{where},$+{colors})) {
				$u{prism}{msg}($handle,$$irc{where},'prism.colors_set',{where=>$$irc{where}});
			}
			else {
				$u{prism}{msg}($handle,$$irc{where},'prism.colors_failed');
			}
		}
	},
	'setLanguage (?<lang>\w+\-\w+)' => {
		code => sub {
			my ($handle,$irc) = splice @_,0,2;
			if($u{prism}{setLanguage}($$irc{where},$+{lang})) {
				$u{prism}{msg}($handle,$$irc{where},'prism.language_set',{where=>$$irc{where}});
			}
			else {
				$u{prism}{msg}($handle,$$irc{where},'prism.language_failed');
			}
		}
	},
},
strings => {
	fun => {
		json => {
			colors_set => "{success:\x04true\x04,where:\"{where}\"}",
			colors_failed => "{success:\x04false\x04,error:\"\x04Invalid format. (00,00)\x04\"}",
			language_set => "{success:\x04true\x04,where:\"{where}\"}",
			language_failed => "{success:\x04false\x04,error:\"\x04Invalid format. (en-us)\x04\"}",
		}
	},
	en => {
		us => {
			colors_set => 'Colors set for {where}!',
			colors_failed => 'Colors set failed. The format is 00,00!',
			language_set => 'Language set for {where}!',
			language_failed => 'Language set failed. The format is en-us!',
		}
	}
},
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
		my $string =  $u{prism}{getString}($target,$key);
		for(values %{ $hash }) { $_ = (split /\n|\r/, $_)[0]; }
		$string =~ s/\{(\w+)\}/\x04$$hash{$1}\x04/g;
		raw($handle,"PRIVMSG $target :".$u{prism}{colorize}($target,$string));
	},
	colorize => sub {
		# I: Target, Message
		# <> toggles, >> selects a word
		# << sets default
		my ($target,$message) = splice @_,0,2;
		my @c = @{ $u{prism}{getColors}($target) };
		#for my $regex ('((?:\x23|\@)\w)','([a-z]+:\/\/\S+\.[a-z]{2,6}\/?(?:[\/\w=?]+)?)') { $message =~ s/$regex/\cC$c[1]$1\cC$c[0]/g; }
		my $color = 1;
		while ($message =~ s/\x04/\cC$c[$color]/) { $color = ($color)?0:1; }
		$message =~ s/\cC\d{1,2}\s+?(\cC\d{1,2})/$1/g;
		return "\cC".$c[0].$message;
	},
	getString => sub {
		# I: Target, Plugin, Key
		my ($target,$plugkey) = splice @_,0,2;
		my ($plugin,$key) = split /\./, $plugkey;
		my @lang = @{ $u{prism}{getLanguage}($target) };
		return ($ivy{plugin}{$plugin}{strings}{$lang[0]}{$lang[1]}{$key})?$ivy{plugin}{$plugin}{strings}{$lang[0]}{$lang[1]}{$key}:$ivy{plugin}{$plugin}{strings}{en}{us}{$key};
	},
	getLanguage => sub {
		# I: Target
		return ($ivy{data}{prism}{lang}{ $_[0] })?$ivy{data}{prism}{lang}{ $_[0] }:['en','us'];
	},
	getColors => sub {
		# I: Target
		return ($ivy{data}{prism}{colors}{ $_[0] })?$ivy{data}{prism}{colors}{ $_[0] }:$ivy{data}{prism}{colors}{'~global'};
	},
	setLanguage => sub {
		# I: Target, String to be parsed.
		# O: T/F
		my ($target,$string) = splice @_,0,2; 
		my @lang = split /\-/, $string;
		#while(@lang>2) { pop @lang; }
		@{ $ivy{data}{prism}{lang}{$target} } = @lang;
		return 1;
	},
	setColors => sub {
		# I: Target, String to be parsed.
		# O: T/F
		my ($target,$string) = splice @_,0,2; my @colors = split /\,/, $string;
		while(@colors>2) { pop @colors; }
		for(@colors) { 
			if($_ !~ /^\d+$/) { return 0; }
			else { $_ = "0$_" if(length($_) < 2); }
		}
		@{ $ivy{data}{prism}{colors}{$target} } = @colors;
		return 1;
	},
}