###########################################################################
#
# This file is auto-generated by the Perl DateTime Suite time locale
# generator (0.03).  This code generator comes with the
# DateTime::Locale distribution in the tools/ directory, and is called
# generate_from_cldr.
#
# This file as generated from the CLDR XML locale data.  See the
# LICENSE.cldr file included in this distribution for license details.
#
# This file was generated from the source file uk.xml.
# The source file version number was 1.75, generated on
# 2006/10/26 22:46:09.
#
# Do not edit this file directly.
#
###########################################################################

package DateTime::Locale::uk;

use strict;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; utf8->import;
    }
}

use DateTime::Locale::root;

@DateTime::Locale::uk::ISA = qw(DateTime::Locale::root);

my @day_names = (
"Понеділок",
"Вівторок",
"Середа",
"Четвер",
"Пʼятниця",
"Субота",
"Неділя",
);

my @day_abbreviations = (
"Пн",
"Вт",
"Ср",
"Чт",
"Пт",
"Сб",
"Нд",
);

my @day_narrows = (
"П",
"В",
"С",
"Ч",
"П",
"С",
"Н",
);

my @month_names = (
"січня",
"лютого",
"березня",
"квітня",
"травня",
"червня",
"липня",
"серпня",
"вересня",
"жовтня",
"листопада",
"грудня",
);

my @month_abbreviations = (
"січ\.",
"лют\.",
"бер\.",
"квіт\.",
"трав\.",
"черв\.",
"лип\.",
"серп\.",
"вер\.",
"жовт\.",
"лист\.",
"груд\.",
);

my @month_narrows = (
"С",
"Л",
"Б",
"К",
"Т",
"Ч",
"Л",
"С",
"В",
"Ж",
"Л",
"Г",
);

my @quarter_names = (
"I\ квартал",
"II\ квартал",
"III\ квартал",
"IV\ квартал",
);

my @am_pms = (
"дп",
"пп",
);

my @era_abbreviations = (
"до н\. е\.",
"н\. е\.",
);

my $date_parts_order = "dmy";


sub day_names                      { \@day_names }
sub day_abbreviations              { \@day_abbreviations }
sub day_narrows                    { \@day_narrows }
sub month_names                    { \@month_names }
sub month_abbreviations            { \@month_abbreviations }
sub month_narrows                  { \@month_narrows }
sub quarter_names                  { \@quarter_names }
sub am_pms                         { \@am_pms }
sub era_abbreviations              { \@era_abbreviations }
sub full_date_format               { "\%A\,\ \%\{day\}\ \%B\ \%\{ce_year\}\ р\." }
sub long_date_format               { "\%\{day\}\ \%B\ \%\{ce_year\}" }
sub medium_date_format             { "\%\{day\}\ \%b\ \%\{ce_year\}" }
sub short_date_format              { "\%d\.\%m\.\%y" }
sub date_parts_order               { $date_parts_order }



1;

