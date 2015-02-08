commands => {
	'\!(?<code>.+)' => {
		access => 3,
		code => sub {
			my ($handle,$irc) = splice @_,0,2;
			my $result = eval($+{code});
			my $error = ($@)?$@:1;
			$error =~ s/\n|\r//g;
			$result =~ s/\n|\r//g;
			raw($handle,"PRIVMSG $$irc{where} :".(($result)?$result:$error));
		}
	},
	'reload' => {
		access => 3,
		code => sub {
			my ($handle,$irc) = splice @_,0,2;
			my $start = time;
			my @errors = @{ $u{core}{reload}() };
			$u{prism}{msg}($handle,$$irc{where},'core.reloaded',{seconds => time-$start,errors => (@errors+0)});
			for(@errors) { $u{prism}{msg}($handle,$$irc{where},'core.plugin_error',$_); }
		}
	},
	'refresh' => {
		access => 3,
		code => sub {
			my ($handle,$irc) = splice @_,0,2;
			my $start = time;
			my @errors = @{ $u{core}{refresh}() };
			$u{prism}{msg}($handle,$$irc{where},'core.refreshed',{seconds => time-$start,errors => (@errors+0)});
			for(@errors) { $u{prism}{msg}($handle,$$irc{where},'core.plugin_error',$_); }
		}
	},
	'meta' => {
		access => 2,
		code => sub {
			my ($handle,$irc) = splice @_,0,2;
			my %meta;
			my @files = ('main.pl',<plugins/*.pl>,<plugins.local/*.pl>);
			$meta{files} = @files;
			foreach(@files) {
				open NEW, "<".$_;
				my @lines = <NEW>;
				$meta{lines} += @lines;
				foreach(@lines) { $meta{comments}++ if($_ =~ /[^\\]\x23/); }
				close NEW;
			}
		 	$u{prism}{msg}($handle,$$irc{where},'core.meta',\%meta);
		}
	},
},
strings => {
	fun => {
		json => {
			reloaded => '{seconds:{seconds},errors:{errors}}',
			refreshed => '{seconds:{seconds},errors:{errors}}',
			plugin_error => '{plugin:{plugin},message:{message}}',
			meta => '{files:{files},lines:{lines},comments:{comments}}',
		}
	},
	en => { 
		us => {
			reloaded => 'Reloaded. [{seconds} seconds] [{errors} errors]',
			refreshed => 'Refreshed. [{seconds} seconds] [{errors} errors]',
			plugin_error => '[{plugin}] {message}',
			meta => 'Ivy: {files} files. {lines} lines. {comments} comments.',
		}
	}
},
utilities => {
 reload => sub { save(); my $array = loadPlugins(); plugins(['load']); return $array; },
 refresh => sub { delete $ivy{lastUpdated}; delete $ivy{plugin}; save(); my $array = loadPlugins(); plugins(['load']); return $array; }
},