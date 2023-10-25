//
// Generate smartpca par file and run smartpca from metafile input
//


include { SMARTPCA_PAR, SMARTPCA } from '../../modules/local/smartpca.nf'

// workflow {
//     Channel.fromFilePairs("data/reads/*/*_R{1,2}.fastq.gz")
//     | map { id, reads ->
//         (sample, replicate, type) = id.tokenize("_")
//         (treatmentFwd, treatmentRev) = reads*.parent*.name*.minus(~/treatment/)
//         meta = [
//             sample:sample,
//             replicate:replicate,
//             type:type,
//             treatmentFwd:treatmentFwd,
//             treatmentRev:treatmentRev,
//         ]
//         [meta, reads]
//     }
//     | view
// }

workflow SMARTPCA_META {
    take:
    meta_batch

    main:
    Channel.fromPath(meta_batch)
    | splitCsv ( header: true, sep: '\t' )
    | map { row ->
        eigen_meta = [
            snp:val(row.wdir"/"row.eigen_snp),
            geno:val(row.wdir"/"row.eigen_geno),
            pop:val(row.wdir"/"row.eigen_pop),
            pop_list:val(row.wdir"/"row.pop_list)
        ]
        para_meta = [
            nchr:val(row.n_chr),
            lsqprj:val(row.lsqprj),
            args:val(row.args)
        ]    
        [row.batch_id, eigen_meta, para_meta]
    }
    | view
    // | set(par_arg)
    // | SMARTPCA_PAR( ... )
    // | SMARTPCA() 


    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}
