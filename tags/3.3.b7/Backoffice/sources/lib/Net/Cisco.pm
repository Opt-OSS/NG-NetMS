package Net::Telnet::Cisco;

#-----------------------------------------------------------------
# Net::Telnet::Cisco - interact with a Cisco router
#
# $Id: Cisco.pm,v 1.52 2002/06/18 17:17:03 jkeroes Exp $
#
# Todo: Add error and access logging.
#
# POD documentation at end of file.
#
#-----------------------------------------------------------------

require 5.005;

use strict;
use Net::Telnet 3.02;
use AutoLoader;
use Carp;

use vars qw($AUTOLOAD @ISA $VERSION $DEBUG);

@ISA      = qw(Net::Telnet);
$VERSION  = '1.10';
$^W       = 1;
$DEBUG    = 0;
$|++;

#------------------------------
# Public Methods
#------------------------------

sub new {
    my $class = shift;

    my ($self, $host, %args);

    # Add default prompt to args if none present.
    push @_, (-Prompt =>
        '/(?m:^[\w.-]+\s?(?:\(config[^\)]*\))?\s?[\$#>]\s?(?:\(enable\))?\s*$)/')
	unless grep /^-?prompt$/i, @_;

    # There's a new cmd_prompt in town.
    $self = $class->SUPER::new(@_) or return;

    *$self->{net_telnet_cisco} = {
	last_prompt	       => '',
        last_cmd	       => '',

        always_waitfor_prompt  => 1,
	waitfor_pause	       => 0.1,

	autopage	       => 1,

	more_prompt	       => '/(?m:^\s*--More--)/',

	normalize_cmd	       => 1,

	send_wakeup 	       => 0,

	ignore_warnings	       => 0,
	warnings	       => '/(?mx:^% Unknown VPN
				     |^%IP routing table VRF.* does not exist. Create first$
				     |^%No CEF interface information
				     |^%No matching route to delete$
				     |^%Not all config may be removed and may reappear after reactivating/
				   )/',
    };

    ## Parse the args.
    if (@_ == 2) {  # one positional arg given
        $host = $_[1];
    } elsif (@_ > 2) {  # named args
        ## Get the named args.
        %args = @_;

        ## Parse the errmode named arg first.
        foreach (keys %args) {
            $self->errmode($args{$_})
                if /^-?errmode$/i;
        }

        ## Parse all other named args.
        foreach (keys %args) {
            if (/^-?always_waitfor_prompt$/i) {
                $self->always_waitfor_prompt($args{$_});
            }
            elsif (/^-?waitfor_pause$/i) {
                $self->waitfor_pause($args{$_});
	    }
            elsif (/^-?more_prompt$/i) {
                $self->more_prompt($args{$_});
	    }
            elsif (/^-?autopage$/i) {
                $self->autopage($args{$_});
	    }
            elsif (/^-?normalize_cmd$/i) {
                $self->normalize_cmd($args{$_});
	    }
	    elsif (/^-?send_wakeup$/i) {
		$self->send_wakeup($args{$_});
	    }
	}
    }

    $self;
} # end sub new


# The new prompt() stores the last matched prompt for later
# fun 'n amusement. You can access this string via $self->last_prompt.
#
# It also parses out any router errors and stores them in the
# correct place, where they can be acccessed/handled by the
# Net::Telnet error methods.
#
# No POD docs for prompt(); these changes should be transparent to
# the end-user.
sub prompt {
    my( $self, $prompt ) = @_;
    my( $prev, $stream );

    $stream  = $ {*$self}{net_telnet_cisco};
    $prev    = $self->SUPER::prompt;

    ## Parse args.
    if ( @_ == 2 ) {
        defined $prompt or $prompt = '';
	$self->_match_check($prompt);
	$self->SUPER::prompt($prompt);
    } elsif (@_ > 2) {
        return $self->error('usage: $obj->prompt($match_op)');
    }

    return $prev;
} # end sub prompt

# cmd() now parses errors and sticks 'em where they belong.
#
# This is a routerish error:
#   routereast#show asdf
#                     ^
#   % Invalid input detected at '^' marker.
#
# "show async" is valid, so the "d" of "asdf" raised an error.
#
# If an error message is found, the following error message
# is sent to Net::Telnet's error()-handler:
#
#   Last command and router error:
#   <last command prompt> <last command>
#   <error message fills remaining lines>
sub cmd {
    my $self             = shift;
    my $ok               = 1;

    my $normalize	 = $self->normalize_cmd;

    # Parse args
    if (@_ == 1) {
	$ {*$self}{net_telnet_cisco}{last_cmd} = $_[0];
    } elsif ( @_ >= 2 ) {
	my @args = @_;
	while (my ($k, $v) = splice @args, 0, 2) {
	    $ {*$self}{net_telnet_cisco}{last_cmd} = $v if $k =~ /^-?[Ss]tring$/;
	    $normalize = $v if $k =~ /^-?[Nn]ormalize_cmd$/;
	}
    }

    my $cmd		 = $ {*$self}{net_telnet_cisco}{last_cmd};
    my $old_ors		 = $self->output_record_separator;
    my $need_more	 = 0;
    my @out;

    while(1) {
	# Send a space (with no newline) whenever we see a "More" prompt.
	if ($need_more) {
	    $self->output_record_separator('');

	    # We saw a more prompt, so put it in the command output.
	    my @tmp = $self->last_prompt;

	    # Send the <space>, taking care not to
	    # discard the top line.
	    push @tmp, $self->SUPER::cmd(String => " ", Cmd_remove_mode => 0);

	    if ($self->normalize_cmd) {
		push @out, _normalize(@tmp);
	    } else {
		push @out, @tmp;
	    }
	} else {
	    $self->output_record_separator($old_ors);
	    push @out, $self->SUPER::cmd(@_);
	}

	# Look for errors in output
	for ( my ($i, $lastline) = (0, '');
	      $i <= $#out;
	      $lastline = $out[$i++] ) {

	    # This may have to be a pattern match instead.
	    if ( ( substr $out[$i], 0, 1 ) eq '%' ) {
		if ( $out[$i] =~ /'\^' marker/ ) { # Typo & bad arg errors
		    chomp $lastline;
		    $self->error( join "\n",
				  "Last command and router error: ",
				  ( $self->last_prompt . $cmd ),
				  $lastline,
				  $out[$i],
				);
		    splice @out, $i - 1, 3;
		} else { # All other errors.
		    chomp $out[$i];
		    $self->error( join "\n",
				  "Last command and router error: ",
				  ( $self->last_prompt . $cmd ),
				  $out[$i],
				);
		    splice @out, $i, 2;
		}
		$ok = 0;
		last;
	    }
	}

	# Restore old settings
	$self->output_record_separator($old_ors);

	# redo the while loop if we saw a More prompt.
	my $more_re = $self->re_sans_delims($self->more_prompt);
	if ($self->autopage && $self->last_prompt =~ /$more_re/) {
	    $need_more = 1;
	} else {
	    last;
	}
    }

    return wantarray ? @out : $ok;
}


# waitfor now stores prompts to $obj->last_prompt()
sub waitfor {
    my $self = shift;

    return unless @_;

    # $all_prompts will be built into a regex that matches all currently
    # valid prompts.
    #
    # -Match args will be added to this regex. The current prompt will
    # be appended when all -Matches have been exhausted.
    my $all_prompts = '';

    # Literal string matches, passed in with -String.
    my @literals = ();

    # Parse the -Match => '/prompt \$' type options
    # waitfor can accept more than one -Match argument, so we can't just
    # hashify the args.
    if (@_ >= 2) {
	my @args = @_;
	while ( my ($k, $v) = splice @args, 0, 2 ) {
	    if ($k =~ /^-?[Ss]tring$/) {
		push @literals, $v;
	    } elsif ($k =~ /^-?[Mm]atch$/) {
		$all_prompts = $self->prompt_append($all_prompts, $v);
	    }
	}
    } elsif (@_ == 1) {
	# A single argument is always a -match.
	$all_prompts = $self->prompt_append($all_prompts, $_[0]);
    }

    my $all_re	   = $self->re_sans_delims($all_prompts);
    my $prompt_re  = $self->re_sans_delims($self->prompt);
    my $more_re    = $self->re_sans_delims($self->more_prompt);


    # Add the current prompt if it's not already there. You can turn this behavior
    # off by setting always_waitfor_prompt to a false value.
    if ($self->always_waitfor_prompt && index($all_re, $prompt_re) == -1) {
	unshift @_, "-Match" if @_ == 1;
	push @_, (-Match => $self->prompt);

	$all_prompts  = $self->prompt_append($all_prompts, $self->prompt);
	$all_re	      = $self->re_sans_delims($all_prompts);
    }

    # Add the more prompt if it's not present. See the autopage() docs
    # to turn this behaviour off.
    if ($self->autopage && index($all_re, $more_re) == -1) {
	unshift @_, "-Match" if @_ == 1;
	push @_, (-Match => $self->more_prompt);

	$all_prompts  = $self->prompt_append($all_prompts, $self->more_prompt);
	$all_re	      = $self->re_sans_delims($all_prompts);
    }

    return $self->error("Godot ain't home - waitfor() isn't waiting for anything.")
	unless $all_prompts || @literals;

    # There's a timing issue that I can't quite figure out.
    # Adding a small pause here seems to make it go away.
    select undef, undef, undef, $self->waitfor_pause;

    my ($prematch, $match) = $self->SUPER::waitfor(@_);

    # If waitfor saw a prompt then store it.
    if ($match) {
	for (@literals) {
	    if (index $match, $_) {
		return wantarray ? ($prematch, $match) : 1;
	    }
	}

	if ($match =~ /($all_re)/m ) {
	    $ {*$self}{net_telnet_cisco}{last_prompt} = $1;
	    return wantarray ? ($prematch, $match) : 1;
	}
    }
    return wantarray ? ( $prematch, $match ) : 1;
}


sub login {
    my($self) = @_;
    my(
       $cmd_prompt,
       $endtime,
       $error,
       $lastline,
       $match,
       $orig_errmode,
       $orig_timeout,
       $prematch,
       $reset,
       $timeout,
       $usage,
       $sent_wakeup,
       );
    my ($username, $password, $tacpass, $passcode ) = ('','','','');
    my (%args, %seen);

    local $_;

    ## Init vars.
    $timeout = $self->timeout;
    $self->timed_out('');
    return if $self->eof;
    $cmd_prompt = $self->prompt;
    $sent_wakeup = 0;

    print "login:\t[orig: $cmd_prompt]\n" if $DEBUG;

    $usage = 'usage: $obj->login([Name => $name,] [Password => $password,] '
	   . '[Passcode => $passcode,] [Prompt => $matchop,] [Timeout => $secs,])';

    if (@_ == 3) {  # just username and passwd given
	($username, $password) = (@_[1,2]);
    }
    else {  # named args given
	## Get the named args.
	(undef, %args) = @_;

	## Parse the named args.
	foreach (keys %args) {
	    if (/^-?name$/i) {
		$username    = $args{$_};
	    } elsif (/^-?passw/i) {
		$password    = $args{$_};
	    } elsif (/^-?passcode/i) {
		$passcode    = $args{$_};
	    } elsif (/^-?prompt$/i) {
		# login() always looks for a cmd_prompt. This is not
		# controllable via always_waitfor_prompt().
		$cmd_prompt = $self->prompt_append($cmd_prompt, $args{$_});
	    } elsif (/^-?timeout$/i) {
		$timeout = _parse_timeout($args{$_});
	    } else {
		return $self->error($usage);
	    }
	}
    }

    print "login:\t[after args: $cmd_prompt]\n" if $DEBUG;

    ## Override these user set-able values.
    $endtime	  = _endtime($timeout);
    $orig_timeout = $self->timeout($endtime);
    $orig_errmode = $self->errmode;

    ## Create a subroutine to reset to original values.
    $reset
	= sub {
	    $self->errmode($orig_errmode);
	    $self->timeout($orig_timeout);
	    1;
	};

    ## Create a subroutine to generate an error for user.
    $error
	= sub {
	    my($errmsg) = @_;

	    &$reset;
	    if ($self->timed_out) {
		return $self->error($errmsg);
	    } elsif ($self->eof) {
		($lastline = $self->lastline) =~ s/\n+//;
		return $self->error($errmsg, ": ", $lastline);
	    } else {
		return $self->error($self->errmsg);
	    }
	};


    # Send a newline as the wakeup-call
    if ($self->send_wakeup eq 'connect') {

	$sent_wakeup = 1;

	my $old_sep = $self->output_record_separator;

	$self->output_record_separator("\n");
	$self->print('');
	$self->output_record_separator($old_sep);
    }


    while (1) {
	(undef, $_) = $self->waitfor(
		-match => '/(?:[Ll]ogin|[Uu]sername|[Pp]assw(?:or)?d)[:\s]*$/',
		-match => '/(?i:Passcode)[:\s]*$/',
		-match => $cmd_prompt,
	);

	unless ($_) {
	    return &$error("read eof waiting for login or password prompt")
		if $self->eof;

	    # We timed-out. Send a newline as the wakeup-call.
	    if ($sent_wakeup == 0 && $self->send_wakeup eq 'timeout') {

		$sent_wakeup = 1;

		my $old_sep = $self->output_record_separator;

		$self->output_record_separator("\n");
		$self->print('');
		$self->output_record_separator($old_sep);

		next;
	    }

	    return &$error("timed-out during login process");
	}

	my $cmd_prompt_re = $self->re_sans_delims($cmd_prompt);

	if (not defined) {
	    return $self->error("login failed: access denied or bad name, passwd, etc");
	} elsif (/sername|ogin/) {
	    $self->print($username) or return &$error("login disconnected");
	    $seen{login}++ && $self->error("login failed: access denied or bad username");
	} elsif (/[Pp]assw/) {
	    $self->print($password) or return &$error("login disconnected");
	    $seen{passwd}++ && $self->error("login failed: access denied or bad password");
	} elsif (/(?i:Passcode)/) {
	    $self->print($passcode) or return &$error("login disconnected");
	    $seen{passcode}++ && $self->error("login failed: access denied or bad passcode");
	} elsif (/($cmd_prompt_re)/) {
	    &$reset; # Success. Reset obj to default vals before continuing.
	    last;
	} else {
	    $self->error("login received unexpected prompt. Aborting.");
	}
    }

    1;
} # end sub login


# Overridden to support ignore_warnings()
sub error {
    my $self = shift;

    # Ignore warnings
    if ($self->ignore_warnings) {
	my $errmsg = join '', @_;
	my $warnings_re = $self->re_sans_delims($self->warnings);
	return if $errmsg =~ /$warnings_re/;
    }

    return $self->SUPER::error(@_);
}


# Tries to enter enabled mode with the password arg.
sub enable {
    my $self = shift;
    my $usage = 'usage: $obj->enable([Name => $name,] [Password => $password,] '
	      . '[Passcode => $passcode,] [Level => $level] )';
    my ($en_username, $en_password, $en_passcode, $en_level) = ('','','','');
    my ($error, $lastline, $orig_errmode, $reset, %args, %seen);

    if (@_ == 1) {  # just passwd given
	($en_password) = shift;
    } else {  # named args given
	%args = @_;

	foreach (keys %args) {
	    if (/^-?name$|^-?login$|^-?user/i) {
		$en_username = $args{$_};
	    } elsif (/^-?passw/i) {
		$en_password = $args{$_};
	    } elsif (/^-?passc/i) {
		$en_passcode = $args{$_};
	    } elsif (/^-?level$/i) {
		$en_level    = $args{$_};
	    } else {
		return $self->error($usage);
	    }
	}
    }

    ## Create a subroutine to generate an error for user.
    $error = sub {
	    my($errmsg) = @_;

	    if ($self->timed_out) {
		return $self->error($errmsg);
	    } elsif ($self->eof) {
		($lastline = $self->lastline) =~ s/\n+//;
		return $self->error($errmsg, ": ", $lastline);
	    } else {
		return $self->error($errmsg);
	    }
	};

    # Store the old prompt without the //s around it.
    my ($old_prompt) = $self->re_sans_delims($self->prompt);

    # We need to expect either a Password prompt or a
    # typical prompt. If the user doesn't have enough
    # access to run the 'enable' command, the device
    # won't even query for a password, it will just
    # ignore the command and display another [boring] prompt.
    $self->print("enable $en_level");

    {
	my ($prematch, $match) = $self->waitfor(
		-match => '/[Ll]ogin[:\s]*$/',
		-match => '/[Uu]sername[:\s]*$/',
		-match => '/[Pp]assw(?:or)?d[:\s]*$/',
		-match => '/(?i:Passcode)[:\s]*$/',
		-match => "/$old_prompt/",
        ) or do {
		return &$error("read eof waiting for enable login or password prompt")
		    if $self->eof;
		return &$error("timed-out waiting for enable login or password prompt");
	};

	if (not defined $match) {
	    return &$error("enable failed: access denied or bad name, passwd, etc");
	} elsif ($match =~ /sername|ogin/) {
	    $self->print($en_username) or return &$error("enable failed");
	    $seen{login}++
 		&& return &$error("enable failed: access denied or bad username");
	    redo;
        } elsif ($match =~ /[Pp]assw/ ) {
	    $self->print($en_password) or return &$error("enable failed");
	    $seen{passwd}++
		 && return &$error("enable failed: access denied or bad password");
	    redo;
	} elsif ($match =~ /(?i:Passcode)/ ) {
	    $self->print($en_passcode) or return &$error("enable failed");
	    $seen{passcode}++
		 && return &$error("enable failed: access denied or bad passcode");
	    redo;
	} elsif ($match =~ /$old_prompt/) {
	    ## Success! Exit the block.
	    last;
	} else {
	    return &$error("enable received unexpected prompt. Aborting.");
	}
    }

    if (not defined $en_level or $en_level =~ /^[1-9]/) {
	# Prompts and levels over 1 give a #/(enable) prompt.
	return $self->is_enabled ? 1 : &$error('Failed to enter enable mode');
    } else {
	# Assume success
        return 1;
    }
}

# Leave enabled mode.
sub disable {
    my $self = shift;
    $self->cmd('disable');
    return $self->is_enabled ? $self->error('Failed to exit enabled mode') : 1;
}

# Send control-^ (without newline)
sub ios_break {
    my $self = shift;

    my $old_ors = $self->output_record_separator;
    $self->output_record_separator('');
    my $ret = $self->print("\c^");
    $self->output_record_separator($old_ors);

    return $ret;
}

# Displays the last prompt.
sub last_prompt {
    my $self = shift;
    my $stream = $ {*$self}{net_telnet_cisco};
    exists $stream->{last_prompt} ? $stream->{last_prompt} : undef;
}

# Displays the last command.
sub last_cmd {
    my $self = shift;
    my $stream = $ {*$self}{net_telnet_cisco};
    exists $stream->{last_cmd} ? $stream->{last_cmd} : undef;
}

# Examines the last prompt to determine the current mode.
# Some prompts may be hard set to #, so this won't always return a valid answer.
# Call 'show priv' instead.
# 1     => enabled.
# undef => not enabled.
sub is_enabled { $_[0]->last_prompt =~ /\#|enable|config/ ? 1 : undef }

# Typical get/set method.
sub always_waitfor_prompt {
    my ($self, $arg) = @_;
    my $stream = $ {*$self}{net_telnet_cisco};
    $stream->{always_waitfor_prompt} = $arg if defined $arg;
    return $stream->{always_waitfor_prompt};
}

# Typical get/set method.
sub waitfor_pause {
    my ($self, $arg) = @_;
    my $stream = $ {*$self}{net_telnet_cisco};
    $stream->{waitfor_pause} = $arg if defined $arg;
    return $stream->{waitfor_pause};
}

# Typical get/set method.
sub autopage {
    my ($self, $arg) = @_;
    my $stream = $ {*$self}{net_telnet_cisco};
    $stream->{autopage} = $arg if defined $arg;
    return $stream->{autopage};
}

# Typical get/set method.
sub normalize_cmd {
    my ($self, $arg) = @_;
    my $stream = $ {*$self}{net_telnet_cisco};
    $stream->{normalize_cmd} = $arg if defined $arg;
    return $stream->{normalize_cmd};
}

# Typical get/set method.
sub send_wakeup {
    my ($self, $arg) = @_;
    my $stream = $ {*$self}{net_telnet_cisco};
    $stream->{send_wakeup} = $arg if defined $arg;
    return $stream->{send_wakeup};
}

# Typical get/set method.
sub ignore_warnings {
    my ($self, $arg) = @_;
    my $stream = $ {*$self}{net_telnet_cisco};
    $stream->{ignore_warnings} = $arg if defined $arg;
    return $stream->{ignore_warnings};
}

# Get/set the More prompt
sub more_prompt {
    my ($self, $arg) = @_;
    my $stream = $ {*$self}{net_telnet_cisco};
    if (defined $arg) {
	$self->_match_check($arg);
        $stream->{more_prompt} = $arg;
    }
    return $stream->{more_prompt};
}

# Join two or more regexen into one on "|".
sub prompt_append {
    my $self = shift;
    my $orig = shift || '';
    return $self->error("usage: \$obj->prompt_append(orig, new, [new...])")
	unless @_;

    print "prompt_append:\t[original: $orig]\n" if $DEBUG;

    if ($orig) {
	if ($self->_match_check($orig)) {
	    $orig = $self->re_sans_delims($orig);
	    return $self->error("Can't parse prompt: '$orig'") unless $orig;
	}
    }

    for (@_) {
	print "prompt_append:\t[append: $_]\n" if $DEBUG;
	if ($self->_match_check($_)) {
	    my $re = $self->re_sans_delims($_);

	    unless ($re) {
		$self->error("Can't parse prompt: '$_'");
		next;
	    }

	    $orig .= $orig ? "|$re" : $re;
	}
    }

    print "prompt_append:\t[return: /$orig/]\n\n" if $DEBUG;
    return "/$orig/";
}

# Return a Net::Telnet regular expression without the delimiters.
sub re_sans_delims {
    my ($self, $str) = @_;

    return $self->error("usage: \$obj->re_sans_delims(\$matchop)")
	unless $str;

    $self->_match_check($str);
    my ($delim, $re) = $str =~  /^\s*m?\s*(\W)(.*)\1\s*$/;
    return $re;
}

#------------------------------
# Private methods
#------------------------------

# strip backspaces, deletes, kills, and the character they
# pertain to, from an array.
sub _normalize {
    $_ = join "", @_;

    1 while s/[^\cH\c?][\cH\c?]//mg; # ^H ^?
    s/^.*\cU//mg;		     # ^U

    return wantarray ? split /$/m, $_ : $_; # ORS instead?
}

# Lifted from Net::Telnet en toto
sub _match_check {
    my ($self, $code) = @_;
    return unless $code;

    my $error;
    my @warns = ();

    print "_match_check:\t[Checking: $code]\n" if $DEBUG;

    ## Use eval to check for syntax errors or warnings.
    {
	local $SIG{'__DIE__'} = 'DEFAULT';
	local $SIG{'__WARN__'} = sub { push @warns, @_ };
	local $^W = 1;
	local $_ = '';
	eval "\$_ =~ $code;";
    }
    if ($@) {
	## Remove useless lines numbers from message.
	($error = $@) =~ s/ at \(eval \d+\) line \d+.?//;
	chomp $error;
	return $self->error("bad match operator: $error");
    }
    elsif (@warns) {
	## Remove useless lines numbers from message.
	($error = shift @warns) =~ s/ at \(eval \d+\) line \d+.?//;
	$error =~ s/ while "strict subs" in use//;
	chomp $error;
	return $self->error("bad match operator: $error");
    }

    1;
} # end sub _match_check

#------------------------------
# Class methods
#------------------------------

# Look for subroutines in Net::Telnet if we can't find them here.
sub AUTOLOAD {
    my ($self) = @_;
    croak "$self is an [unexpected] object, aborting" if ref $self;
    $AUTOLOAD =~ s/.*::/Net::Telnet::/;
    goto &$AUTOLOAD;
}

1;

__END__

#------------------------------------------------------------
# Docs
#------------------------------------------------------------

=head1 NAME

Net::Telnet::Cisco - interact with a Cisco router

=head1 SYNOPSIS

  use Net::Telnet::Cisco;

  my $session = Net::Telnet::Cisco->new(Host => '123.123.123.123');
  $session->login('login', 'password');

  # Execute a command
  my @output = $session->cmd('show version');
  print @output;

  # Enable mode
  if ($session->enable("enable_password") ) {
      @output = $session->cmd('show privilege');
      print "My privileges: @output\n";
  } else {
      warn "Can't enable: " . $session->errmsg;
  }

  $session->close;

=head1 DESCRIPTION

Net::Telnet::Cisco provides additional functionality to Net::Telnet
for dealing with Cisco routers.

cmd() parses router-generated error messages - the kind that
begin with a '%' - and stows them in $obj-E<gt>errmsg(), so that
errmode can be used to perform automatic error-handling actions.

=head1 CAVEATS

Before you use Net::Telnet::Cisco, you should have a good
understanding of Net::Telnet, so read it's documentation first, and
then come back here to see the improvements.

Some things are easier to accomplish with UCD's C-based SNMP module,
or the all-perl Net::SNMP. SNMP has three advantages: it's faster,
handles errors better, and doesn't use any VTYs on the router. SNMP
does have some limitations, so for anything you can't accomplish with
SNMP, there's Net::Telnet::Cisco.

=head1 METHODS

=over 4

=item B<new> - create new Net::Telnet::Cisco object

    $session = Net::Telnet::Cisco->new(
	[Autopage		  => $boolean,] # 1
	[More_prompt		  => $matchop,] # '/(?m:^\s*--More--)/',
	[Always_waitfor_prompt	  => $boolean,] # 1
	[Waitfor_pause		  => $milliseconds,] # 0.1
	[Normalize_cmd		  => $boolean,] # 1
	[Send_wakeup		  => $when,] # 0
	[Ignore_warnings	  => $boolean,] # 0
	[Warnings		  => $matchop,] # see docs
	
	# Net::Telnet arguments
	[Binmode		  => $mode,]
	[Cmd_remove_mode	  => $mode,]
	[Dump_Log		  => $filename,]
	[Errmode		  => $errmode,]
	[Fhopen			  => $filehandle,]
	[Host			  => $host,]
	[Input_log		  => $file,]
	[Input_record_separator	  => $char,]
	[Option_log		  => $file,]
	[Output_log		  => $file,]
	[Output_record_separator  => $char,]
	[Port			  => $port,]
	[Prompt			  => $matchop,] # see docs
	[Telnetmode		  => $mode,]
	[Timeout		  => $secs,]
    );

Creates a new object. Read `perldoc perlboot` if you don't understand that.

=item B<login> - login to a router

    $ok = $obj->login($username, $password);

    $ok = $obj->login([Name     => $username,]
                      [Password => $password,]
                      [Passcode => $passcode,] # for Secur-ID/XTACACS
                      [Prompt   => $match,]
                      [Timeout  => $secs,]);

All arguments are optional as of v1.05. Some routers don't ask for a
username, they start the login conversation with a password request.

=item B<cmd> - send a command

    $ok = $obj->cmd($string);
    $ok = $obj->cmd(String   => $string,
                    [Output  => $ref,]
                    [Prompt  => $match,]
                    [Timeout => $secs,]
                    [Cmd_remove_mode => $mode,]);

    @output = $obj->cmd($string);
    @output = $obj->cmd(String   => $string,
                        [Output  => $ref,]
                        [Prompt  => $match,]
                        [Timeout => $secs,]
                        [Cmd_remove_mode => $mode,]
                        [Normalize_cmd => $boolean,]);

Normalize_cmd has been added to the default Net::Telnet args. It
lets you temporarily change whether backspace, delete, and kill
characters are parsed in the command output. (This is performed by default)

=item B<prompt> - return control to the program whenever this string occurs in router output

    $matchop = $obj->prompt;

    $prev = $obj->prompt($matchop);

The default cmd_prompt changed in v1.05. It's suitable for
matching prompts like C<router$ >, C<router# >, C<routerE<gt>
(enable) >, and C<router(config-if)# >

Let's take a closer look, shall we?

  (?m:			# Net::Telnet doesn't accept quoted regexen (i.e. qr//)
			# so we need to use an embedded pattern-match modifier
			# to treat the input as a multiline buffer.

    ^			# beginning of line

      [\w.-]+		# router hostname

      \s?		# optional space

      (?:		# Strings like "(config)" and "(config-if)", "(config-line)",
			# and "(config-router)" indicate that we're in privileged
        \(config[^\)]*\) # EXEC mode (i.e. we're enabled).
      )?		# The middle backslash is only there to appear my syntax
			# highlighter.

      \s?		# more optional space

      [\$#>]		# Prompts typically end with "$", "#", or ">". Backslash
			# for syntax-highlighter.

      \s?		# more space padding

      (?:		# Catalyst switches print "(enable)" when in privileged
        \(enable\)	# EXEC mode.
      )?

      \s*		# spaces before the end-of-line aren't important to us.

    $			# end of line

  )			# end of (?m:

The default prompt published in 1.03 was
C</^\s*[\w().-]*[\$#E<gt>]\s?(?:\(enable\))?\s*$/>. As you can see,
the prompt was drastically overhauled in 1.05. If your code suddenly starts
timing out after upgrading Net::Telnet::Cisco, this is the first thing
to investigate.

=item B<enable> - enter enabled mode

    $ok = $obj->enable;

    $ok = $obj->enable($password);

    $ok = $obj->enable([Name => $name,] [Password => $password,]
	               [Passcode => $passcode,] [Level => $level,]);

This method changes privilege level to enabled mode, (i.e. root)

If a single argument is provided by the caller, it will be used as
a password. For more control, including the ability to set the
privilege-level, you must use the named-argument scheme.

enable() returns 1 on success and undef on failure.

=item B<is_enabled> - Am I root?

    $bool = $obj->is_enabled;

A trivial check to see whether we have a root-style prompt, with
either the word "(enable)" in it, or a trailing "#".

B<Warning>: this method will return false positives if your prompt has
"#"s in it. You may be better off calling C<$obj-E<gt>cmd("show
privilege")> instead.

=item B<disable> - leave enabled mode

    $ok = $obj->disable;

This method exits the router's privileged mode.

=item B<ios_break> - send a break (control-^)

    $ok = $obj->ios_break;

You may have to use errmode(), fork, or threads to break at the
an appropriate time.

=item B<last_prompt> - displays the last prompt matched by prompt()

    $match = $obj->last_prompt;

last_prompt() will return '' if the program has not yet matched a
prompt.

=item B<always_waitfor_prompt> - waitfor and cmd prompt behaviour

    $boolean = $obj->always_waitfor_prompt;

    $boolean = $obj->always_waitfor_prompt($boolean);

Default value: 1

If you pass a Prompt argument to cmd() or waitfor() a String or Match,
they will return control on a successful match of your argument(s) or
the default prompt. Set always_waitfor_prompt to 0 to return control
only for your arguments.

This method has no effect on login(). login() will always wait for a
prompt.

=item B<waitfor_pause> - insert a small delay before waitfor()

    $boolean = $obj->waitfor_pause;

    $boolean = $obj->waitfor_pause($milliseconds);

Default value: 0.1

In rare circumstances, the last_prompt is set incorrectly. By adding
a very small delay before calling the parent class's waitfor(), this
bug is eliminated. If you ever find reason to modify this from it's
default setting, please let me know.

=item B<autopage> - Turn autopaging on and off

    $boolean = $obj->autopage;

    $boolean = $obj->autopage($boolean);

Default value: 1

IOS pages output by default. It expects human eyes to be reading the
output, not programs. Humans hit the spacebar to scroll page by
page so autopage() mimicks that behaviour. This is the slow way to
handle paging. See the Paging EXAMPLE for a faster way.

=item B<normalize_cmd> - Turn normalization on and off

    $boolean = $obj->normalize_cmd;

    $boolean = $obj->normalize_cmd($boolean);

Default value: 1

IOS clears '--More--' prompts with backspaces (e.g. ^H). If
you're excited by the thought of having raw control characters
like ^H (backspace), ^? (delete), and ^U (kill) in your command
output, turn this feature off.

Logging is unaffected by this setting.

=item B<more_prompt> - Matchop used by autopage()

    $matchop = $obj->prompt;

    $prev = $obj->prompt($matchop);

Default value: '/(?m:\s*--More--)/'.

Please email me if you find others.

=item B<send_wakeup> - send a newline to the router at login time

    $when = $obj->send_wakeup;

    $when = $obj->send_wakeup( 'connect' );
    $when = $obj->send_wakeup( 'timeout' );
    $when = $obj->send_wakeup( 0 );

Default value: 0

Some routers quietly allow you to connect but don't display the
expected login prompts. Sends a newline in the hopes that this
spurs the routers to print something.

'connect' sends a newline immediately upon connection.
'timeout' sends a newline if the connection timeouts.
0 turns this feature off.

I understand this works with Livingston Portmasters.

=item B<ignore_warnings> - Don't call error() for warnings

    $boolean = $obj->ignore_warnings;

    $boolean = $obj->ignore_warnings($boolean);

Default value: 0

Not all strings that begin with a '%' are really errors. Some are just
warnings. By setting this, you are ignoring them. This will show up in
the logs, but that's it.

=item B<warnings> - Matchop used by ignore_warnings().

    $boolean = $obj->warnings;

    $boolean = $obj->warnings($matchop);

Default value:

	/(?mx:^% Unknown VPN
	     |^%IP routing table VRF.* does not exist. Create first$
	     |^%No CEF interface information
	     |^%No matching route to delete$
	     |^%Not all config may be removed and may reappear after reactivating
	 )/

Not all strings that begin with a '%' are really errors. Some are just
warnings. Cisco calls these the CIPMIOSWarningExpressions.

=back

=head1 EXAMPLES

=head2 Paging

v1.08 added internal autopaging support to cmd(). Whenever a '--Page--'
prompt appears on the screen, we send a space right back. It works, but
it's slow. You'd be better off sending one of the following commands
just after login():

  # To a router
  $session->cmd('terminal length 0');

  # To a switch
  $session->cmd('set length 0');

=head2 Logging

Want to see the session transcript? Just call input_log().

  e.g.
  my $session = Net::Telnet::Cisco->new(Host => $router,
					Input_log => "input.log",
					);

See input_log() in L<Net::Telnet> for info.

Input logs are easy-to-read translated transcripts with all of the
control characters and telnet escapes cleaned up. If you want to view
the raw session, see dump_log() in L<Net::Telnet>. If you're getting
tricky and using print() in addition to cmd(), you may also want to use 
output_log().

=head2 Big output

Trying to dump the entire BGP table? (e.g. "show ip bgp") The default buffer size
is 1MB, so you'll have to increase it.

  my $MB = 1024 * 1024;
  $session->max_buffer_length(5 * $MB);

=head2 Sending multiple lines at once

Some commands like "extended ping" and "copy" prompt for several lines
of data. It's not necessary to change the prompt for each
line. Instead, send everything at once, separated by newlines.

For:

  router# ping
  Protocol [ip]:
  Target IP address: 10.0.0.1
  Repeat count [5]: 10
  Datagram size [100]: 1500
  Timeout in seconds [2]:
  Extended commands [n]:
  Sweep range of sizes [n]:

Try this:

  my $protocol  = ''; # default value
  my $ip       = '10.0.0.1';
  my $repeat    = 10;
  my $datagram  = 1500;
  my $timeout   = ''; # default value
  my $extended  = ''; # default value
  my $sweep     = ''; # default value

  $session->cmd(
  "ping
  $protocol
  $ip
  $repeat
  $datagram
  $timeout
  $extended
  $sweep
  ");

If you prefer, you can put the cmd on a single line and replace
every static newline with the "\n" character.

e.g.

  $session->cmd("ping\n$protocol\n$ip\n$repeat\n$datagram\n"
	      . "$timeout\n$extended\n$sweep\n");

=head2 Backup via TFTP

Backs up the running-confg to a TFTP server. Backup file is in
the form "router-confg". Make sure that file exists on the TFTP
server or the transfer will fail!

  my $backup_host  = "tftpserver.somewhere.net";
  my $device	   = "cisco.somewhere.net";
  my $type         = "router"; # or "switch";
  my $ios_version  = 12;

  my @out;
  if ($type eq "router") {
      if ($ios_version >= 12) {
          @out = $session->cmd("copy system:/running-config "
     			. "tftp://$backup_host/$device-confg\n\n\n");
      } elsif ($ios_version >= 11) {
          @out = $session->cmd("copy running-config tftp\n$backup_host\n"
     			. "$device-confg\n");
      } elsif ($ios_version >= 10) {
          @out = $session->cmd("write net\n$backup_host\n$device-confg\n\n");
      }
  } elsif ($type eq "switch") {
      @out = $session->cmd("copy system:/running-config "
     		    . "tftp://$backup_host/$device-confg\n\n\n");
  }

=head1 SUPPORT

http://NetTelnetCisco.sourceforge.net/

=head2 Mailing lists

I<nettelnetcisco-announce> is for important security bulletins and upgrades. Very low traffic, no spam, B<HIGHLY RECOMMENDED!>
http://lists.sourceforge.net/lists/listinfo/nettelnetcisco-announce

I<nettelnetcisco-users> is for usage discussion, help, tips, tricks, etc.
http://lists.sourceforge.net/lists/listinfo/nettelnetcisco-users

I<nettelnetcisco-devel> is for uber-hackers; you know who you are.
http://lists.sourceforge.net/lists/listinfo/nettelnetcisco-devel

=head2 Help/discussion forums

http://sourceforge.net/forum/?group_id=48856

=head2 Bug tracker

http://sourceforge.net/tracker/?group_id=48856

=head1 SEE ALSO

L<Net::Telnet>

L<Net::SNMP>

UCD NetSNMP - http://www.netsnmp.org/

RAT/NCAT - http://ncat.sourceforge.net/

=head1 AUTHOR

Joshua_Keroes@eli.net $Date: 2002/06/18 17:17:03 $

It would greatly amuse the author if you would send email to him
and tell him how you are using Net::Telnet::Cisco.

As of Mar 2002, 170 people have emailed me. N::T::C is used to
help manage over 14,000 machines! Keep the email rolling in!

=head1 THANKS

The following people understand what Open Source Software is all
about. Thanks Brian Landers, Aaron Racine, Niels van Dijke, Tony
Mueller, Frank Eickholt, Al Sorrell, Jebi Punnoose, Christian Alfsen,
Niels van Dijke, Kevin der Kinderen, Ian Batterbee, Leonardo Cont,
Steve Meier, and Andre Bonhote.

Institutions: infobot.org #perl, perlmonks.org, sourceforge.net,
the geeks at geekhouse.org, and eli.net.

Send in a patch and we can make the world a better place.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2000-2002 Joshua Keroes, Electric Lightwave Inc.
All rights reserved. This program is free software; you
can redistribute it and/or modify it under the same terms
as Perl itself.

