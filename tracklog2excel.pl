
use strict;
use warnings;
use Encode qw(decode encode from_to);
#use Switch;
#use utf8;

my $infilename = $ARGV[0];
my $filenamepostfix = '-excel';
my $separator = ';';

my $debug=0;


my @normalizable_fields =(
"Bat Battery Block 1 Voltage",
"Bat Battery Block 2 Voltage",
"Bat Highest Battery Block Voltage",
"Bat HV Battery Current(A)",
"Bat Lowest Battery Block Voltage",
"Bat State-of-Charge",
"EN Engine Coolant Temperature",
"EN Engine Speed",
"EN Fuel Injection time for cyl #1",
"EN Intake Air Temperature",
"EN Vehicle Speed",
"HV Battery Cell Temperature Max",
"HV Battery Cell Temperature Min",
"HV Engine Coolant Temperature",
"HV Engine Speed",
"HV HV Battery Current",
"HV HV Battery Voltage",
"HV Intake Air Temperature", 
"HV MG1 Inverter Temperature", 
"HV MG1 RPM", 
"HV MG2 RPM", 
"HV State-of-Charge", 
"HV Target Engine Revolution", 
"HV Vehicle Speed(km/h)" 
);

my @normalizer =(
.1,	#"Bat Battery Block 1 Voltage",
.1,	#"Bat Battery Block 2 Voltage",
.1,	#"Bat Highest Battery Block Voltage",
.1, #"Bat HV Battery Current",
.1,	#"Bat Lowest Battery Block Voltage",
.1,	#"Bat State-of-Charge",
.1,	#"EN Engine Coolant Temperature",
.001,#"EN Engine Speed",
.1,	#"EN Fuel Injection time for cyl #1",
.1,	#"EN Intake Air Temperature",
.1,	#"EN Vehicle Speed",
.1,	#"HV Battery Cell Temperature Max",
.1,	#"HV Battery Cell Temperature Min",
.1,	#"HV Engine Coolant Temperature",
.001,#"HV Engine Speed",
.1,	#"HV HV Battery Current",
.01,#"HV HV Battery Voltage",
.1,	#"HV Intake Air Temperature", 
.1,	#"HV MG1 Inverter Temperature", 
.001,#"HV MG1 RPM", 
.001,#"HV MG2 RPM", 
.1, #"HV State-of-Charge", 
.001,#"HV Target Engine Revolution", 
.1, #"HV Vehicle Speed" 
);



sub isnumber{
	if ( $_[0] eq "-" ) { return(0);}
	if ( $_[0] =~ /^[0-9,.E-]+$/) {
		return(1);
	} else {
		return(0);
	}
}

sub convertnumber{
	my $s=$_[0];
	$s=~ s/\./,/g;
	return $s;
}

sub unconvertnumber{
	my $s=$_[0];
	$s=~ s/,/\./g;
	return $s;
}


for my $wn (@ARGV) {
	if ($wn eq "-debug") { $debug=1;}
print "$wn\n";
}

if ( $ARGV[0] eq "") {
	print "usage: $0 trackLog.csv \n";
	exit;
}

my $extension = substr($infilename, rindex($infilename, '.')+1);
my $infilen = substr ($infilename,0 ,rindex($infilename, '.') );
#print "filename: $infilename extension: $extension\n";

if ( $extension ne "csv") {
	print "not csv input file extension ($extension)";
	exit;
}

my $outfilename = $infilen . $filenamepostfix . "." . $extension;

if ($debug) {
	print "infile: $infilename\n";
	print "outfile: $outfilename\n";
}

open (my $infile, '<', $infilename) or die $!; 
open (my $outfile, '>', $outfilename) or die $!;

my $row = '';

my @infieldname = ();
my @infieldvalue = ();
my @outfieldname = ();
my @outfieldvalue = ();
my @outfieldlastvalue = ();
my @outfieldmin = ();
my @outfieldmax = ();

my $innumfields = 0;
my $pos = 0;
my $i;
my $linenum=0;
my $infield=0;
my $outfield=0;
my $processed=0;
my $processingheader=1;
my $fuelinjectionfield=-1;
my $drivesituationidfield=-1;

$linenum=1;

while (! eof ($infile))	{
#read line
$row = <$infile>;
chomp($row);
@infieldvalue = split /,/, $row;
$innumfields = scalar @infieldvalue;
#print "innumfields $innumfields\n";

$outfield = 0;
for ($infield = 0; $infield<$innumfields; $infield++) {
	
	
#print "infieldname $infieldname[$infield]           infieldvalue  $infieldvalue[$infield]  infield: $infield \n";
	
	if ( $processingheader || !($infieldname[$infield] eq $infieldvalue[$infield]) ) { # header between lines, ignore line
	$processed = 0;
	
	$outfieldvalue[$outfield] = $infieldvalue[$infield];
	if ($processingheader) {
		$infieldname[$infield]=$infieldvalue[$infield];
	}
#============================================field processing=============================

	if ( $infieldname[$infield] eq "GPS Time" ){		
		if ($processingheader) {
			$outfieldlastvalue[$outfield] = 0;
		} else {	
			if ( isnumber($infieldvalue[$infield]) ){
				$outfieldvalue[$outfield] = convertnumber($outfieldvalue[$outfield]);
				$outfieldlastvalue[$outfield] = $outfieldvalue[$outfield];
			} else {
				if ( $infieldvalue[$infield] eq "-"  ) {
					$outfieldvalue[$outfield]=$outfieldlastvalue[$outfield];
				} else {
					#print "Warning: unprocessed field in line: $linenum filed: $infield: $infieldname[$infield]\n";
				}
			}
		}
		$processed=1;
	} #GPS Time

	if ( $infieldname[$infield] eq " Device Time" ){		
		if ($processingheader) {
			$infieldname[$outfield] = $infieldvalue[$infield];
			$outfieldlastvalue[$outfield] = "";
			$outfield++;
			$outfieldname[$outfield]="Device Time hh:mm";			#extra fields
			$outfieldvalue[$outfield]=$outfieldname[$outfield];
			$outfieldlastvalue[$outfield] = "00:00";
			$outfield++;
			$outfieldname[$outfield]="Device time exceltime";
			$outfieldvalue[$outfield]=$outfieldname[$outfield];
			$outfieldlastvalue[$outfield] = 0;
			$outfield++;
			$outfieldname[$outfield]="Log period (s)";
			$outfieldvalue[$outfield]=$outfieldname[$outfield];
			$outfieldlastvalue[$outfield] = 0;
		} else {	
			$pos=index ($infieldvalue[$infield],":");
			if ( $pos == -1 ){
				$outfieldvalue[$outfield]=$outfieldlastvalue[$outfield];
				$outfield++;
				$outfieldvalue[$outfield]=$outfieldlastvalue[$outfield];
				$outfield++;
				$outfieldvalue[$outfield]=$outfieldlastvalue[$outfield];
				$outfield++;
				$outfieldvalue[$outfield]=$outfieldlastvalue[$outfield];
			} else {
				$outfieldlastvalue[$outfield]=$outfieldvalue[$outfield];
				$outfield++;
				$outfieldvalue[$outfield]=substr($infieldvalue[$infield],$pos-2,5);					#hh:mm
				$outfieldlastvalue[$outfield]=$outfieldvalue[$outfield];
				$outfield++;
				$outfieldvalue[$outfield]=substr($infieldvalue[$infield],$pos-2,2)*60*60;
				$outfieldvalue[$outfield]+=substr($infieldvalue[$infield],$pos+1,2)*60;
				$outfieldvalue[$outfield]+=substr($infieldvalue[$infield],$pos+4,6);				#exceltime
				$outfieldvalue[$outfield+1]=$outfieldvalue[$outfield]-unconvertnumber($outfieldlastvalue[$outfield]);#log period
				$outfieldvalue[$outfield]=convertnumber($outfieldvalue[$outfield]);					#exceltime >,
				$outfieldlastvalue[$outfield]=$outfieldvalue[$outfield];
				$outfield++;				
				if ($outfieldvalue[$outfield] > 20) { $outfieldvalue[$outfield]=0; }
				$outfieldvalue[$outfield]=convertnumber($outfieldvalue[$outfield]);					#log period >,
				$outfieldlastvalue[$outfield]=$outfieldvalue[$outfield];
			}
			
		}
		$processed=1;
	} #Device Time

	
	
	if ( !$processed ){		#not individually processed
		if ($processingheader) {
			$infieldname[$outfield] = $infieldvalue[$infield];
			$outfieldlastvalue[$outfield] = 0;
		} else {	
			if ( isnumber($infieldvalue[$infield]) ){
				$outfieldvalue[$outfield] = convertnumber($outfieldvalue[$outfield]);
				$outfieldlastvalue[$outfield] = $outfieldvalue[$outfield];
			} else {
				if ( $infieldvalue[$infield] eq "-"  ) {
					$outfieldvalue[$outfield]=$outfieldlastvalue[$outfield];
				} else {
					#print "Warning: unprocessed field in line: $linenum filed: $infield: $infieldname[$infield]\n";
				}
			}
		}
	} #if not processed
	
	$i = $#normalizable_fields; 
	while ( ($i >= 0) && ($infieldname[$infield] ne $normalizable_fields[$i] ) ) {
		$i--;	
	}
	#print "norm i: $i\n";
	
	if ( $i >=0 ) {												# creating normalized field
		$outfield++;
		if ($processingheader) {
			$outfieldvalue[$outfield]="N10 ".$infieldvalue[$infield];
			$outfieldlastvalue[$outfield]=0;
		} else {
		if ( $infieldvalue[$infield] eq "-"  ) {
				$outfieldvalue[$outfield]=$outfieldlastvalue[$outfield];
			} else {
				$outfieldvalue[$outfield]=convertnumber(unconvertnumber($outfieldvalue[$outfield-1])*$normalizer[$i]);
				$outfieldlastvalue[$outfield]=$outfieldvalue[$outfield];
			}
		}
	}
	

	
	
#===========================================end of field processing=================================
	#print "infield:$infield  outfield: $outfield infieldvalue[infield] = $infieldvalue[$infield] outfieldvalue[outfield] = $outfieldvalue[$outfield]\n";		

	$outfield++;
	
	} else { # if header between lines
		$infield=$innumfields;
		$processingheader=2;
	} #if header
	
} #for


if ($processingheader) {									# combining injection time with drive situation id
	$fuelinjectionfield = $innumfields-1; 
	while ( ($fuelinjectionfield >= 0) && ($infieldname[$fuelinjectionfield] ne "EN Fuel Injection time for cyl #1(ms)" ) ) {
		$fuelinjectionfield--;	
	}
	if ($fuelinjectionfield>=0) {
		$drivesituationidfield = $innumfields-1; 
		while ( ($drivesituationidfield >= 0) && ($infieldname[$drivesituationidfield] ne "HV Drive Situation ID" ) ) {
			$drivesituationidfield--;	
		}
		if ($drivesituationidfield >= 0) {
			$outfieldvalue[$outfield]="Fuel injection time STOP compensated (ms)";
			$outfieldlastvalue[$outfield]=0;
			$outfield++;
		}
	}
} else {
	if ($drivesituationidfield >= 0) {
		if ( ($infieldvalue[$fuelinjectionfield] eq "-") || ($infieldvalue[$fuelinjectionfield] eq "-") ) {
				$outfieldvalue[$outfield]=$outfieldlastvalue[$outfield];
			} else {																#multiplication
				$outfieldvalue[$outfield]=convertnumber($infieldvalue[$fuelinjectionfield]*$infieldvalue[$drivesituationidfield]);
				$outfieldlastvalue[$outfield]=$outfieldvalue[$outfield];
			}
		$outfield++;	
	}
}
#print "drid $drivesituationidfield fuelid: $fuelinjectionfield\n;";

# write out line
if ($debug) {
	#print "outfield:$outfield\n";
	for ($i=0;$i<$outfield;$i++) {
		print $outfieldvalue[$i].";";
	}
	print "\n";
	<STDIN>;
}

# write out line to file
if ($processingheader<2) {
	for ($i=0;$i<$outfield;$i++) {
		if ($i>0) { print $outfile "$separator"; }
		print $outfile "$outfieldvalue[$i]";
	}
	print $outfile "\n";
}

$linenum++;

if ($processingheader) {$processingheader=0;}

} #while


close $infile;
close $outfile;



exit;

