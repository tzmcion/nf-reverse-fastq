process downloadGenome{
    /*
        Downloads the reference genome and annotations
        From ensembl via wget
    */

    input:
    val link_annotations
    val link_refGenome

    output:
    path "annotations.gtf.gz", emit: annot_file
    path "refGenome.fa.gz", emit: ref_file

    script:
    """
        wget -O "annotations.gtf.gz" "${link_annotations}"
        wget -O "refGenome.fa.gz" "${link_refGenome}"
    """
}

process checkSums{
    /*
    Check if the downloads were correct
    */

    input:
    val checksum_file
    val annot_file_name
    path curr_file


    output:
    path "result.txt"

    script:
    """
    wget -O "checksum.txt" "${checksum_file}"
    fname=\$(basename "${annot_file_name}")
    awk -v name="\$fname" '\$3 ~ name {print \$1, \$2}' "checksum.txt" > cols.txt
    sum ${curr_file} | awk '{print \$1, \$2}' > cols2.txt
    if cmp --silent cols.txt cols2.txt; then
        echo "OK" > result.txt
    else
        echo "NOK - CONTROL SUM did not match, check for network
        corruption and run again" > result.txt
        echo "CONTROL SUM did not match, check for network
        corruption and run again  " 1>&2
        exit 64
    fi
    """
}

process download_reads{
    cpus 4
    conda "./environments/downloads.yaml"

    input:
    val SRA_id

    output:
    tuple val(SRA_id), path("*.fastq"), emit:reads

    script:
    """
    prefetch ${SRA_id}
    vdb-validate ./${SRA_id}
    fasterq-dump ./${SRA_id} -p -e 2
    rm -rfd ./${SRA_id}
    """
}