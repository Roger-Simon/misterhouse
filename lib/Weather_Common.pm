# Weather_Common package
# $Date$
# $Revision$
#
# This packages should be included by all weather modules and libraries.
# It provides a standard method to update common %Weather elements and
# to add hooks whenever weather changes are detected
#
# Internet clients should use &populate_internet_weather to tranfer their data into %Weather
# All clients should call &weather_updated whenever they have finished updating %Weather

package Weather_Common;

use strict;
use warnings;

BEGIN {
	use Exporter ();

	our @EXPORT = qw(
		weather_updated
		weather_add_hook
		convert_local_barom_to_sea_mb
		convert_local_barom_to_sea_in
		convert_local_barom_to_sea
		convert_sea_barom_to_local_mb
		convert_sea_barom_to_local_in
		convert_sea_barom_to_local
		convert_humidity_to_dewpoint
		convert_wind_dir_text_to_num
		convert_wind_dir_abbr_to_num
		convert_wind_dir_abbr_to_text
		populate_internet_weather
		);
}

our @weather_hooks;

# this should be called whenever a client has FINISHED updating %main::Weather

sub weather_updated {
	# get a pointer to the main $w hash to make things easier to read (and type!)
	my $w=\%main::Weather;

	my $windSpeed=$$w{WindAvgSpeed};

	# need wind speed in km/h for formulas to work
	if (defined $windSpeed) {
		if ($main::config_parms{weather_uom_wind} eq 'mph') {
			$windSpeed=&::convert_mile2km($windSpeed);
		}
		if ($main::config_parms{weather_uom_wind} eq 'mps') {
			$windSpeed=&::convert_mps2kph($windSpeed);
		}
	} else {
		$windSpeed='unknown';
	}

	# assume for now that windchill and humidex are negligible
	my $apparentTemp='unknown';
	my $temperatureText='unknown';
	if (defined $$w{TempOutdoor}) {
		$apparentTemp=$$w{TempOutdoor};
		$temperatureText=sprintf('%.1f&deg;%s',$$w{TempOutdoor}, $main::config_parms{weather_uom_temp});
	}
	$$w{WindChill}=$apparentTemp;
	$$w{Humidex}=$apparentTemp;
	$$w{ApparentTemp}=$apparentTemp;

	my $temp=$apparentTemp;
	my $dewpoint=$$w{DewOutdoor};
	if (!defined $dewpoint) {
		$dewpoint = $$w{DewIndoor};
		if (!defined $dewpoint) {
			$dewpoint='unknown';
		}
	}

	# need temp and dewpoint in Celsius for formulas to work
	if ($main::config_parms{weather_uom_temp} eq 'F') {
		grep {$_=&::convert_f2c($_) if defined $_} ($temp,$dewpoint);
	}

	my $pressureText='unknown';
	if (defined $$w{BaromSea}) {
		$pressureText=sprintf("%s %s",$$w{BaromSea},$main::config_parms{weather_uom_baro});
	}

	if ($windSpeed ne 'unknown' and $temp ne 'unknown') {
	# windchill formula is only valid for the following conditions
		if ($windSpeed >= 5 and $windSpeed <= 100 and $temp >= -50 and $temp <= 5) {
			my $windchill=13.12+0.6215*$temp-11.37*($windSpeed**0.16)+0.3965*$temp*($windSpeed**0.16);
			if ($main::config_parms{config_uom_temp} eq 'F') {
				$windchill=&::convert_c2f($windchill);
			}
			$windchill=sprintf('%.1f',$windchill);
			$$w{WindChill}=$windchill;
			$apparentTemp=$windchill;
		}
	}

	if ($temp ne 'unknown' and $dewpoint ne 'unknown') {
		my $vapourPressureSaturation=6.112*10.0**(7.5*$temp/(237.7+$temp));
		my $vapourPressure=6.112*10.0**(7.5*$dewpoint/(237.7+$dewpoint));
		# only calculate humidity if is isn't directly measured by something
		if (!$$w{HumidOutdoorMeasured}) {
			$$w{HumidOutdoor}=sprintf('%.0f',100*$vapourPressure/$vapourPressureSaturation);
		}
		my $humidex=$temp+(0.5555*($vapourPressure-10));

		# only report humidex if temperature is at least 20 degrees and
		# humidex is at least 25 degrees (standard rules)
		if (($temp >= 20) && ($humidex >= 25)) {
			if ($main::config_parms{weather_uom_temp} eq 'F') {
				$humidex=&::convert_c2f($humidex);
			}
			$humidex=sprintf('%.1f',$humidex);
			$$w{Humidex}=$humidex;
			$apparentTemp=$humidex;
		}
	}

	my $humidityText='unknown';
	if (defined $$w{HumidOutdoor}) {
		$humidityText=sprintf('%.0f%%',$$w{HumidOutdoor});
	}

	if ($apparentTemp ne 'unknown') {
		$$w{OutdoorApparent}=sprintf('%.1f',$apparentTemp);
	}

	my $apparentTempText='';

	if ($apparentTemp ne 'unknown') {
		$$w{TempOutdoorApparent}=$apparentTemp;
		if ($apparentTemp != $$w{TempOutdoor}) {
			$apparentTempText=" ($apparentTemp)";
		}
	}

	my $windDirName='unknown';
	my $windDirNameLong='unknown';
	my $windDirection=$$w{WindAvgDir};
	$windDirection=$$w{WindGustDir} if !defined $windDirection;

	if (defined $windDirection) {
		$windDirName=convert_wind_dir_to_abbr($windDirection);
		$windDirNameLong=convert_wind_dir_to_text($windDirection);
	}

	my $shortWindText='unknown';
	my $longWindText='unknown';

	if (defined $$w{WindAvgSpeed}) {
		if ($$w{WindAvgSpeed} < 1) {
			$shortWindText='no wind';
			$longWindText='no wind';
		} else {
			$shortWindText=sprintf('%s %.0f %s',$windDirName,$$w{WindAvgSpeed},$main::config_parms{weather_uom_wind});

			$longWindText=sprintf('%s at %.0f %s',$windDirNameLong,$$w{WindAvgSpeed},$main::config_parms{weather_uom_wind});
		}

		if (defined $$w{WindGustSpeed} and $$w{WindGustSpeed} > $$w{WindAvgSpeed}) {
			if ($$w{WindGustSpeed} < 1) {
				$shortWindText='no wind';
				$longWindText='no wind';
			} else {
				$shortWindText=sprintf('%s %.0f (%.0f) %s',$windDirName,$$w{WindAvgSpeed}, $$w{WindGustSpeed},$main::config_parms{weather_uom_wind});
				if ($$w{WindAvgSpeed} >= 1) {
					$longWindText.=sprintf(' gusting to %.0f %s',$$w{WindGustSpeed},$main::config_parms{weather_uom_wind});
				} else {
					$longWindText=sprintf('%s gusts of %.0f %s',$windDirNameLong,$$w{WindGustSpeed},$main::config_parms{weather_uom_wind});
				}
			}
		}
	}
	if ($shortWindText eq 'no wind') {
		$windDirNameLong='no wind';
	}
	$$w{WindDirection}=$windDirNameLong;

	my $clouds='unknown';
	$clouds=$$w{Clouds} if defined $$w{Clouds};
	my $conditions='unknown';
	$conditions=$$w{Conditions} if defined $$w{Conditions};

	$$w{Wind}=$shortWindText;

	$$w{Summary_Short}=sprintf('%s%s %s', $temperatureText, $apparentTempText, $humidityText);
	$$w{Summary}=$$w{Summary_Short}." $pressureText $clouds $conditions";
	$$w{Summary_Long}="Temperature: $temperatureText";
	if ($apparentTempText ne '') {
		$$w{Summary_Long}.='  Apparent Temperature: '.$$w{TempOutdoorApparent}.'&deg;'.$main::config_parms{weather_uom_temp};
	}
	$$w{Summary_Long}.="  Humidity: $humidityText";
	$$w{Summary_Long}.="  Wind: $longWindText";
	$$w{Summary_Long}.="  Sky: $clouds";
	if ($conditions eq '') {
		$$w{Summary_Long}.='  Conditions: nothing to report';
	} else {
		$$w{Summary_Long}.="  Conditions: $conditions";
	}

	foreach my $subref (@weather_hooks) {
		&$subref();
	}
}

sub weather_add_hook {
	my ($subref)=@_;
	push @weather_hooks, $subref;
}

# for the following conversion routines, this rule was used:
# pressure changes by 1 mb for each 8 meters of altitude gain
# and by 1 inHg for each 1000 ft
#
# for mb: altitude is in feet, so 1 mb for each 8 meters is
# 1 mb for each 8*3.28 feet = 24.24 feet

sub convert_local_barom_to_sea_mb {
	return sprintf('%.1f',$_[0] + $main::config_parms{altitude}/24.24);
}

sub convert_local_barom_to_sea_in {
	return sprintf('%.2f',$_[0] + $main::config_parms{altitude}/1000);
}

sub convert_local_barom_to_sea {
	return $main::config_parms{weather_uom_baro} eq 'mb' ? convert_local_barom_to_sea_mb($_[0]) : convert_local_barom_to_sea_in($_[0]);
}

sub convert_sea_barom_to_local_mb {
	return sprintf('%.1f',$_[0] - $main::config_parms{altitude}/24.24);
}

sub convert_sea_barom_to_local_in {
	return sprintf('%.2f',$_[0] - $main::config_parms{altitude}/1000);
}

sub convert_sea_barom_to_local {
	return $main::config_parms{weather_uom_baro} eq 'mb' ? convert_sea_barom_to_local_mb($_[0]) : convert_sea_barom_to_local_in($_[0]);
}

# converts humidity + temp (Celsius) to dewpoint (Celsius)
sub convert_humidity_to_dewpoint {
	my ($humidity,$temp_celsius)=@_;

	my $dew_point = 1 - $humidity / 100;
	$dew_point = (14.55 + .114 * $temp_celsius) * $dew_point + ((2.5 + .007 * $temp_celsius) * $dew_point ** 3)  + ((15.9 + .117 * $temp_celsius) * $dew_point ** 14);
	$dew_point = $temp_celsius - $dew_point;
	return sprintf('%.1f',$dew_point);
}

sub convert_wind_dir_text_to_num {
	my ($wind)=@_;

	$wind=lc($wind);

	if ($wind eq 'north') {
		$wind=0;
	} elsif ($wind eq 'northeast') {
		$wind=45;
	} elsif ($wind eq 'east') {
		$wind=90;
	} elsif ($wind eq 'southeast') {
		$wind=135;
	} elsif ($wind eq 'south') {
		$wind=180;
	} elsif ($wind eq 'southwest') {
		$wind=225;
	} elsif ($wind eq 'west') {
		$wind=270;
	} elsif ($wind eq 'northwest') {
		$wind=315;
	} else {
		$wind=undef;
	}
	return $wind;
}

sub convert_wind_dir_abbr_to_num {
	my ($dir)=@_;

	return 0 if $dir eq 'N';
	return 23 if $dir eq 'NNE';
	return 45 if $dir eq 'NE';
	return 68 if $dir eq 'ENE';
	return 90 if $dir eq 'E';
	return 113 if $dir eq 'ESE';
	return 135 if $dir eq 'SE';
	return 158 if $dir eq 'SSE';
	return 180 if $dir eq 'S';
	return 203 if $dir eq 'SSW';
	return 225 if $dir eq 'SW';
	return 248 if $dir eq 'WSW';
	return 270 if $dir eq 'W';
	return 293 if $dir eq 'WNW';
	return 315 if $dir eq 'NW';
	return 338 if $dir eq 'NNW';
	return undef;
}

sub convert_wind_dir_to_abbr {
	my ($dir)=@_;
	return 'unknown' if $dir !~ /^[\d \.]+$/;

	if ($dir >= 0 and $dir <= 359) {
		return qw{ N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW }[(($dir+11.25)/22.5)%16];
	}
	return 'unknown';
}

sub convert_wind_dir_to_text {
	my ($dir)=@_;
	return 'unknown' if $dir !~ /^[\d \.]+$/;

	if ($dir >= 0 and $dir <= 359) {
		return (
			'North',
			'North Northeast',
			'Northeast',
			'East Northeast',
			'East',
			'East Southeast',
			'Southeast',
			'South Southeast',
			'South',
			'South Southwest',
			'Southwest',
			'West Southwest',
			'West',
			'West Northwest',
			'Northwest',
			'North Northwest' )[(($dir+11.25)/22.5)%16];
	}
	return 'unknown';

}

# This should be called by external sources of weather like those
# found on the internet.
#
# Only a subset of the passed keys will be copied to the %Weather hash

sub populate_internet_weather {
	my ($weatherHashRef, $weatherKeys)=@_;

	my @keys;

	if ($weatherKeys ne '') {
		@keys=split(/\s+/,$weatherKeys);
	} else {
		if ($main::config_parms{weather_internet_elements} eq 'all' or $main::config_parms{weather_internet_elements} eq '') {
			@keys=qw (
				TempOutdoor
				DewOutdoor
				WindAvgDir
				WindAvgSpeed
				WindGustDir
				WindGustSpeed
				WindGustTime
				Clouds
				Conditions
				Barom
				BaromSea
				BaromDelta
				HumidOutdoorMeasured
				HumidOutdoor
				IsRaining
				IsSnowing
			);
		} else {
			@keys=split(/\s+/,$main::config_parms{weather_internet_elements});
		}
	}
	foreach my $key (@keys) {
		if (defined $$weatherHashRef{$key}) {
			$main::Weather{$key}=$$weatherHashRef{$key};
		}
	}
}

1;
