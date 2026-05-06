process process_genome{
    cpus 8
    conda "./environments/process_genome.yaml"

    input:
    path genome_ref

    output:
    path "./${genome_ref.simpleName}_indexed"

    script:
    """
    bowtie2-build --threads 8 ${genome_ref} ${genome_ref.simpleName}_index
    mkdir ${genome_ref.simpleName}_indexed
    mv *.bt2 ./${genome_ref.simpleName}_indexed
    """
}

process align_reads{
    cpus 4
    conda "./environments/process_genome.yaml"

    input:
    path index_folder
    path forward_reads
    path reverse_reads

    output:
    path "${forward_reads.simpleName}.bam"

    script:
    """
    
    bowtie2 --no-unal -p 4 -x ${index_folder} -1 ${forward_reads} -2 ${reverse_reads} -S _tmp.sam
    samtools view -b _tmp.sam -o ${forward_reads.simpleName}.bam
    """
}