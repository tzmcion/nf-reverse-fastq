process downloadGenome{
    cpus 2
    /*
        Downloads the reference genome and annotations
        From ensembl via wget
    */

    input:
    val link_annotations
    val link_refGenome
    val link_annot_checksum
    val link_refGenome_checksum

    output:
    path "annotations.gtf.gz", emit: annot_file
    path "refGenome.fa.gz", emit: ref_file
    path "checksum_annot.txt", emit: checksum_annot
    path "checksum_refGenome.txt", emit: checksum_file_refGenome

    script:
    """
        wget -O "annotations.gtf.gz" "${link_annotations}"
        wget -O "refGenome.fa.gz" "${link_refGenome}"
        wget -O "checksum_annot.txt" "${link_annot_checksum}"
        wget -O "checksum_refGenome.txt" "${link_refGenome_checksum}"
    """
}

process checkSums{
    cpus 2
    /*
    Check if the downloads were correct
    */

    input:
    path checksum_file
    val annot_file_name
    path downloaded_annotFile
    path checksum_file_refGenome
    val refGenome_file_name
    path downloaded_refGenome


    output:
    path "result.txt"

    script:
    """
    fname=\$(basename "${annot_file_name}")
    awk -v name="\$fname" '\$3 ~ name {print \$1, \$2}' "${checksum_file}" > cols.txt
    sum ${downloaded_annotFile} | awk '{print \$1, \$2}' > cols2.txt
    if cmp --silent cols.txt cols2.txt; then
        echo "OK" > result.txt
    else
        echo "NOK - CONTROL SUM did not match, check for network
        corruption and run again" > result.txt
        echo "CONTROL SUM did not match, check for network
        corruption and run again  " 1>&2
        exit 64
    fi
    
    fname=\$(basename "${refGenome_file_name}")
    awk -v name="\$fname" '\$3 ~ name {print \$1, \$2}' "${checksum_file_refGenome}" > cols.txt
    sum ${downloaded_refGenome} | awk '{print \$1, \$2}' > cols2.txt
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
    cpus 2
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