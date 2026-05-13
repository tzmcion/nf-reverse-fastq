//Here each read will SRA accesion will be downloaded
//And alligned to the reference genome, given in a parameters
//By the index folder

include {align_sort_reads} from "../modules/process_genome.nf"
include {reverse_engineer_reads} from "../modules/process_genome.nf"
include {download_reads} from "../modules/downloads.nf"

workflow ALIGN_WORKFLOW {
    take:
    INDEX_folder
    INDEX_name
    GENE_locations
    SRA_accession
    main:
    //Download the reads
    download_reads(SRA_accession)
    //Combine the indexes and reads so the alignment runs as many times as there is SRA files
    comb = INDEX_folder.combine(INDEX_name)
    Combined_reads_SRA = download_reads.out.reads.combine(comb).view()
    //The alignment
    align_sort_reads(Combined_reads_SRA)
    //Combine gene names and gene locations
    split_genes = GENE_locations.splitCsv(sep:';')
    combinations = split_genes.combine(align_sort_reads.out.align_tuple)
    reverse_engineer_reads(combinations)

    emit:
    reads = reverse_engineer_reads.out.fastqs_gene
}