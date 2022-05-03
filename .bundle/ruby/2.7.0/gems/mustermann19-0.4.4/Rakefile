ENV['JRUBY_OPTS'] = '--2.0 -X-C'
ENV['RBXOPT'] = '-X20'

task(:rspec)     { ruby '-S rspec'      }
task(:doc_stats) { ruby '-S yard stats' }
task default: [:rspec, :doc_stats]
