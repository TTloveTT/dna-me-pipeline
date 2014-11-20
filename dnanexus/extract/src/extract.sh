#!/bin/bash -x
# Bismark-ENCODE-WGBS 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

set -x
set +e

main() {

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    echo "getting files"
    dx download "$genome" -o - | gunzip > genome.fa
    mapped_fn=`dx describe "$mapped_files" --name | cut -d'.' -f1`
    dx download "$mapped_files" -o - | tar zxvf -

    dx download "$chrom_sizes" -o chrom.sizes

    mkdir input
    mv genome.fa input
    echo "Analyse methylation"
    outfile="$mapped_fn".fq_bismark
    bismark_methylation_extractor -s --comprehensive --cytosine_report --CX_context --ample_mem\
      --output /home/dnanexus/output/ --zero_based --genome_folder input output/"$outfile".sam

    samtools view -Sb output/"$outfile".sam > output/"$outfile".bam
    echo "Creat QC reports"
    cxrepo-bed.py -o /home/dnanexus/output /home/dnanexus/output/"$mapped_fn".fq_bismark.CX_report.txt

    # Fill in your application code here.
    #
    # To report any recognized errors in the correct format in
    # $HOME/job_error.json and exit this script, you can use the
    # dx-jobutil-report-error utility as follows:
    #
    #   dx-jobutil-report-error "My error message"
    #
    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.

    # The following line(s) use the dx command-line tool to upload your file
    # outputs after you have created them on the local file system.  It assumes
    # that you have used the output field name for the filename for each output,
    # but you can change that behavior to suit your needs.  Run "dx upload -h"
    # to see more options to set metadata.

    echo `ls /home/dnanexus/output`
    mv /home/dnanexus/output/CG_"$mapped_fn".fq_bismark.CX_report.txt "$mapped_fn"_CG_bismark.bed
    mv /home/dnanexus/output/CHG_"$mapped_fn".fq_bismark.CX_report.txt "$mapped_fn"_CHG_bismark.bed
    mv /home/dnanexus/output/CHH_"$mapped_fn".fq_bismark.CX_report.txt "$mapped_fn"_CHH_bismark.bed

    echo "Convert to BigBed"
    bedToBigBed "$mapped_fn"_CG_bismark.bed -type=bed9+2 chrom.sizes "$mapped_fn"_CG_bismark.bb
    bedToBigBed "$mapped_fn"_CHG_bismark.bed -type=bed9+2 chrom.sizes "$mapped_fn"_CHG_bismark.bb
    bedToBigBed "$mapped_fn"_CHH_bismark.bed -type=bed9+2 chrom.sizes "$mapped_fn"_CHH_bismark.bb

    gzip *.bed
    echo "Uploading files"
    find
    CG=$(dx upload "$mapped_fn"_CG_bismark.bed.gz --brief)
    CHG=$(dx upload "$mapped_fn"_CHG_bismark.bed.gz --brief)
    CHH=$(dx upload "$mapped_fn"_CHH_bismark.bed.gz --brief)

    CGbb=$(dx upload "$mapped_fn"_CG_bismark.bb --brief)
    CHGbb=$(dx upload "$mapped_fn"_CHG_bismark.bb --brief)
    CHHbb=$(dx upload "$mapped_fn"_CHH_bismark.bb --brief)

    mapped_reads=$(dx upload /home/dnanexus/output/"$outfile".bam --brief)
    cat output/*E_report.txt > output/$mapped_fn.fq_bismark_map_report.txt
    map_report=$(dx upload /home/dnanexus/output/"$mapped_fn".fq_bismark_map_report.txt --brief)
    M_bias_report=$(dx upload /home/dnanexus/output/"$mapped_fn".fq_bismark.M-bias.txt --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.
    echo "Adding output -- files should be renamed"

    dx-jobutil-add-output CG "$CG" --class=file
    dx-jobutil-add-output CHG "$CHG" --class=file
    dx-jobutil-add-output CHH "$CHH" --class=file
    dx-jobutil-add-output CGbb "$CGbb" --class=file
    dx-jobutil-add-output CHGbb "$CHGbb" --class=file
    dx-jobutil-add-output CHHbb "$CHHbb" --class=file
    dx-jobutil-add-output mapped_reads "$mapped_reads" --class=file
    dx-jobutil-add-output map_report "$map_report" --class=file
    dx-jobutil-add-output M_bias_report "$M_bias_report" --class=file
}
