//
// Generate smartpca par file and run smartpca from metafile input
//

nextflow.enable.dsl = 2

include { MPILE_UP_CALL_REGION; READ_CHR } from '../../modules/local/gt_sam.nf'


workflow GT_META {
    take:
    meta_batch
    list_region
    

    main:
    Channel.fromPath(meta_batch)
    | splitCsv ( header: true, sep: '\t')
    | map { row ->
        meta_gt = [
            batch:          row.batch,
            ref:            file(row.ref),
            list_bam:       file(row.list_bam),
            param_mpileup:  row.p_mpileup,
            param_call:     row.p_call
        ]
    }
    | set { meta_gt }

    Channel.fromPath( list_region )
    | view { it }
    
    
    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}


workflow {
    GT_META ( params.meta, params.list_region )
}

