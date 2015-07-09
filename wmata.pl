#!/usr/bin/perl

##
# Script to get the information of the next Orange line train at Ballston-MU
# using the WMATA API.
#

# Setting this environment variable gets us around a SSL quirk.
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

# List of libraries that we'll need.
use LWP::UserAgent;
use HTTP::Request;
use JSON;

# Helps debug stuff.
use Data::Dumper;

##
# Helps get the content from WMATA API.
#
# @param content Reference to content obtained from WMATA API.
#
# @return 1 Success.
# @return 0 Failure.
#
sub getContent($) {
    my ($content) = @_;

    my $response;
    my $returnCode = 0; # Assume failure.

    my $url = "https://api.wmata.com/StationPrediction.svc/json/" .
              "GetPrediction/K04?api_key=kfgpmgvfgacx98de9q3xazww";

    my $ua = LWP::UserAgent->new;

    my $request = HTTP::Request->new(GET => $url);
    $response = $ua->request($request);

    if ($response->is_success) {
        $$content = $response->content;
        $returnCode = 1;
    }

    return $returnCode;
}

##
# Parses the JSON format data and prints meaningful information.
#
# @param content Content obtained from WMATA API.
#
sub printContent($)
{
    my ($content) = @_;

    my $count = 0;
    my $fromJSON = from_json($content);
    if (!$fromJSON) {
        die("Couldn't parse the JSON content.");
    }

    my %data;

    my $trains = $fromJSON->{"Trains"};
    my $statusCode = $fromJSON->{"statusCode"};
    my $message = $fromJSON->{"message"};

    foreach my $train (@$trains) {
        if ($train->{"Line"} eq "OR") {
            $count += 1;
            $data{$count}{"Destination"} = $train->{"DestinationName"};
            $data{$count}{"Arrival"} = $train->{"Min"};
        }
    }

    if (defined($statusCode) && defined($message)) {
        print($content . "\n");
    }
    else {
        # The first result is the train that is going to arrive next.
        print("Orange line | Ballston-MU | Next train info:\n");
        print("Destination:\t" . $data{1}{"Destination"} . "\n");
        my $unit = " min";
        if ($data{1}{"Arrival"} eq "ARR" || $data{1}{"Arrival"} eq "BRD") {
            $unit = "";
        }
        print("Arriving in:\t" . $data{1}{"Arrival"} . $unit . "\n");
    }
}

##
# Main function.
#
sub main()
{
    my $content;

    my $ret = getContent(\$content);
    if (!defined($ret) || $ret == 0) {
        die("Failed to get a response from the URL.");
    }

    printContent($content);
}

# Wait...doesn't that look like a C program.
main();
