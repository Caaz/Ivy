commands => {
	'reload' => {
		access => 3,
		code => sub {
			print "Reloading.\n";
			reload();
		}
	}
},
utilities => {
 reload => sub { save(); my $hash = loadPlugins(); plugins('load'); return $hash; }
},