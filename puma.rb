workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

before_fork do
  if $db
    $db.close
  end
end

on_refork do
  if $db    
    $db.close
  end
end

on_worker_boot do
  if $db
    $db.reconnect
  end
end
