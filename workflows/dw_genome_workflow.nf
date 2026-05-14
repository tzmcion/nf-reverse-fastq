include {downloadGenome} from "../modules/downloads.nf"
include {checkSums} from "../modules/downloads.nf"

workflow DOWNLOAD_CHECK_GENOME {
    take:
    annotations_file_link
    checksum_annotations
    refGenome_file_link
    checksum_genome

    main:
    downloadGenome(
        annotations_file_link,
        refGenome_file_link,
        checksum_annotations,
        checksum_genome
    )
    checkSums(
        downloadGenome.out.checksum_annot,
        annotations_file_link,
        downloadGenome.out.annot_file,
        downloadGenome.out.checksum_file_refGenome,
        refGenome_file_link,
        downloadGenome.out.ref_file
    )

    emit:
    annot_file = downloadGenome.out.annot_file
    ref_genome = downloadGenome.out.ref_file
}

