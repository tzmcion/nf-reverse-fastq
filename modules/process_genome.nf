process cut_genome{
    cpus 8
    conda "./environments/downloads.yaml"

    input:
    path genome_file
    val regex_pattern

    output:
    path "${genome_file.simpleName}.genome_ref.fa", emit: genome_ref

    script:
    """
    gzip -d ${genome_file} -c > _temp.fa
    seqkit grep -n -r -p \"${regex_pattern}\" _temp.fa -o ${genome_file.simpleName}.genome_ref.fa
    """
}

process build_index{
    cpus 8
    conda "./environments/process_genome.yaml"

    input:
    path refGenome

    output:
    path "./indexed", emit: indexed_folder
    val "${refGenome.simpleName}_index", emit: indexed_name

    script:
    """
    bowtie2-build --threads 8 ${refGenome} ${refGenome.simpleName}_index
    mkdir indexed
    mv *.bt2 ./indexed
    """
}

process align_sort_reads{
    cpus 4
    conda "./environments/process_genome.yaml"

    input: 
    path indexed_genome
    val indexed_name
    tuple val(SRA_id), path(reads)

    output:
    path "${SRA_id}.sorted.bam", emit: bamFile
    path "${SRA_id}.sorted.bai", emit: baiFile
    tuple path("${SRA_id}.sorted.bam"), path("${SRA_id}.sorted.bai"), emit:align_tuple

    script:
    """
    bowtie2 --no-unal -p 4 -x ${indexed_genome}/${indexed_name} -1 ${reads[0]} -2 ${reads[1]} -S ./out.sam
    samtools view -@ 4 -b ./out.sam -o ./out.bam
    samtools sort -@ 4 -O bam -o ./${SRA_id}.sorted.bam ./out.bam
    samtools index -@ 4 ./${SRA_id}.sorted.bam -o ./${SRA_id}.sorted.bai
    """
}

process reverse_engineer_reads{
    cpus 4
    conda "./environments/process_genome.yaml"

    input:
    tuple val(gene_name), val(gene_localization), path(bam_file), path(bai_file)

    output:
    path "${bam_file.simpleName}_${gene_name}.fastq", emit:fastqs_gene

    script:
    """
    samtools view -b ${bam_file} ${gene_localization} > ./gene.bam
    samtools fastq ./gene.bam > ${bam_file.simpleName}_${gene_name}.fastq
    """
}