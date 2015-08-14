#!/usr/bin/env perl
use strict;
use warnings;
use Bio::EnsEMBL::Registry;
use Bio::AlignIO;
use Getopt::Long qw(GetOptionsFromArray);
use Data::Dumper;

# OPTIONS
my ( $reg_conf, $species1, $species2, $output_file, $help );
GetOptionsFromArray(
	    \@ARGV,
        'reg_conf=s'   => \$reg_conf,
        's1=s'         => \$species1,
        's2=s'         => \$species2,
        'o|output=s'   => \$output_file,
        'h|help'       => \$help,
);

print _help_text() if ($help);
$reg_conf ||= '/lustre/scratch109/ensembl/cc21/mouse_data/mouse_reg_livemirror.conf';
$output_file ||= 'breakpoints.tsv';
die("Please provide species of interest (-s1 & -s2)") unless( defined($species1) && defined($species2) );

my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_all($reg_conf);
#$registry->load_registry_from_url( 'mysql://ensadmin:ensembl@compara1:3306/cc21_ensembl_compara_master' );
#$registry->load_registry_from_url( 'mysql://ensadmin:ensembl@compara4/wa2_Pahari_EiJ_core_80' );

my $mlss_adap       = $registry->get_adaptor( 'mice_merged', 'compara', 'MethodLinkSpeciesSet' );
my $gblock_adap     = $registry->get_adaptor( 'mice_merged', 'compara', 'GenomicAlignBlock' );

my $mlss = $mlss_adap->fetch_by_method_link_type_registry_aliases( "LASTZ_NET", [ $species1, $species2 ] );
my @gblocks = @{ $gblock_adap->fetch_all_by_MethodLinkSpeciesSet( $mlss ) };

open(OUT, '>', $output_file);
while ( my $gblock = shift @gblocks ) {
	my @gas = @{ $gblock->get_all_GenomicAligns() };
	while ( my $genomic_align = shift @gas ){
		print OUT $genomic_align->genomic_align_block_id, "\t", $genomic_align->dnafrag_id, "\t", $genomic_align->dnafrag_start, "\t", $genomic_align->dnafrag_end, "\n";
	}
}
close(OUT);

sub _help_text {
	return <<HELP;
Description:
    Output a tab delimited file listing all breakpoints (start + end of genomic alignment blocks) occurring between two species.
    Output will consist of 4 columns:
        1. genomic_align_block_id
        2. dnafrag_id
        3. dnafrag_start
        4. dnafrag_end

Usage: perl breakpoints.pl <options>
	-reg_conf   path to registry config file (default: /lustre/scratch109/ensembl/cc21/mouse_data/mouse_reg_livemirror.conf)
	-s1         species of interest 1
	-s2         species of interest 2
	-o|output   path to output file (default: breakpoints.tsv)
	-h|help     display this help

HELP
}