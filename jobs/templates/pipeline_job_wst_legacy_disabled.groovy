pipelineJob('wst') {
  description('DEPRECATED: Legacy WST job kept only for historical reference. Use WST-CI-Pipeline.')
  disabled(true)

  // Keep a minimal definition so this job remains seed-managed but non-runnable.
  definition {
    cps {
      script(
        '''
        pipeline {
          agent any
          stages {
            stage('Deprecated') {
              steps {
                error('Job "wst" is deprecated. Use "WST-CI-Pipeline".')
              }
            }
          }
        }
        '''.stripIndent()
      )
      sandbox(true)
    }
  }
}
