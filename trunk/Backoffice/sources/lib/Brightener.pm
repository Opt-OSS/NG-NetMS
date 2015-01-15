package Brightener;

use Filter::Util::Call ;

my $ret='';

sub import
{
  filter_add(
    sub {
      my ($status) ;
      $status = filter_read();
      if ($status > 0) {
	if (/^\s*$/) {
	  s/\n//;
	  tr/ \t/01/;
	  $ret = $ret.$_;
	  $_ = '';
	}
      }
      if ($status == 0) {
	$_ =  pack "b*", $ret;
	return 1;
      }
      $status ;
    })
}

1 ;

__END__
