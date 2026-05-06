include {downloadGenome} from "./modules/downloads.nf"
include {download_reads} from "./modules/downloads.nf"
include {checkSums as checkSum1} from "./modules/downloads.nf"
include {checkSums as checkSum2} from "./modules/downloads.nf"
include {cut_genome} from "./modules/process_genome.nf"
include {build_index} from "./modules/process_genome.nf"
include {gene_location} from "./modules/locations.nf"
include {align_sort_reads} from "./modules/process_genome.nf"
include {reverse_engineer_reads} from "./modules/process_genome.nf"

params {
    batch: String
    refGenome_file_link: String
    checksum_annotations: String
    annotations_file_link: String
    checksum_genome: String
    csvSRA: String
    genes: String
    refGenome_regex: String
}

workflow {
    main:
    //download the reference genome
    downloadGenome(params.annotations_file_link, params.refGenome_file_link)
    checkSum1(params.checksum_annotations, params.annotations_file_link, downloadGenome.out.annot_file)
    checkSum2(params.checksum_genome, params.refGenome_file_link, downloadGenome.out.ref_file)
    //Extract only XY and 1-22 chromosomes from the refGenome
    cut_genome(downloadGenome.out.ref_file, params.refGenome_regex)
    //Build the index of genome_ref
    build_index(cut_genome.out.genome_ref)
    
    //Get the SRA IDs from input file and 
    SRA_files = Channel.fromPath(params.csvSRA)
                    .splitCsv(header: true, sep: ';')
                    .map(item -> item["SRA_id"])

    //Download the reads from SRA
    download_reads(SRA_files)
    download_reads.out.reads
        .set {paired_reads}

    //Align the reads using indexed items in folder
    align_sort_reads(build_index.out.indexed_folder,
     build_index.out.indexed_name,
     paired_reads)

    //Get the genes names from params file, and extract their location
    //using python script
    genes_names = Channel.fromPath(params.genes)
    gene_location(genes_names, downloadGenome.out.annot_file)

    //Get the localizations from csv output file and split by ";"
    //The the first column will be name of the gene
    //And the second column will be it's localization
    localizations = gene_location.out.genes_locs
        .splitCsv(sep: ";")

    //Combine the gene_names, genes_locations and fastq reads to
    //make sure each fastq file is used 
    combs = localizations.combine(align_sort_reads.out.align_tuple)

    //reverse the reads
    reverse_engineer_reads(combs)

    publish:
    gene_locations = gene_location.out.genes_locs
    revs = reverse_engineer_reads.out.fastqs_gene
}

output {
    //As output there will be genes locations
    gene_locations{
        path "genes_locations"
        mode "copy"
    }//And of course the reads
    revs{
        path "reversed_fastqs"
        mode "copy"
    }

}