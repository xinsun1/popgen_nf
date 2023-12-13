//
// Generate smartpca par file and run smartpca from metafile input
//

nextflow.enable.dsl = 2

include { MPILE_UP_CALL_REGION            } from '../../modules/local/gt_sam.nf'


workflow GT_META {
    take:
    list_region
    

    main:

    Channel.fromPath(list_region)
    | splitText()
    | map{it -> it.trim()}
    | set {ch_region}
    
    MPILE_UP_CALL_REGION (
        params.batch,                   // val batch
        file(params.ref),               // path ref
        file(params.list_bam),          // path list_bam
        params.mpileup,                 // val param_mpileup
        params.call,                    // val param_call
        ch_region,                      // val region
        )
    
    
    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}


workflow {
    GT_META ( params.list_region )
}

