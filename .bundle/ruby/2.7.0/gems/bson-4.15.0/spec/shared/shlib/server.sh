# This file contains functions pertaining to downloading, starting and
# configuring a MongoDB server.

set_fcv() {
  if test -n "$FCV"; then
    mongo --eval 'assert.commandWorked(db.adminCommand( { setFeatureCompatibilityVersion: "'"$FCV"'" } ));' "$MONGODB_URI"
    mongo --quiet --eval 'db.adminCommand( { getParameter: 1, featureCompatibilityVersion: 1 } )' |grep  "version.*$FCV"
  fi
}

add_uri_option() {
  opt=$1

  if ! echo $MONGODB_URI |sed -e s,//,, |grep -q /; then
    MONGODB_URI="$MONGODB_URI/"
  fi

  if ! echo $MONGODB_URI |grep -q '?'; then
    MONGODB_URI="$MONGODB_URI?"
  fi

  MONGODB_URI="$MONGODB_URI&$opt"
}

prepare_server() {
  arch=$1

  if test -n "$USE_OPT_MONGODB"; then
    export BINDIR=/opt/mongodb/bin
    export PATH=$BINDIR:$PATH
    return
  fi

  if test "$MONGODB_VERSION" = latest; then
    # Test on the most recent published 4.3 release.
    # https://jira.mongodb.org/browse/RUBY-1724
    echo 'Using "latest" server is not currently implemented' 1>&2
    exit 1
  else
    download_version="$MONGODB_VERSION"
  fi

  url=`$(dirname $0)/get-mongodb-download-url $download_version $arch`

  prepare_server_from_url $url
}

prepare_server_from_url() {
  url=$1

  mongodb_dir="$MONGO_ORCHESTRATION_HOME"/mdb
  mkdir -p "$mongodb_dir"
  curl --retry 3 $url |tar xz -C "$mongodb_dir" -f -
  BINDIR="$mongodb_dir"/`basename $url |sed -e s/.tgz//`/bin
  export PATH="$BINDIR":$PATH
}

install_mlaunch_virtualenv() {
  python2 -V || true
  if ! python2 -m virtualenv -h >/dev/null; then
    # Current virtualenv fails with
    # https://github.com/pypa/virtualenv/issues/1630
    python2 -m pip install 'virtualenv<20' --user
  fi
  if test "$USE_SYSTEM_PYTHON_PACKAGES" = 1 &&
    python2 -m pip list |grep mtools-legacy
  then
    # Use the existing mtools-legacy
    :
  else
    venvpath="$MONGO_ORCHESTRATION_HOME"/venv
    python2 -m virtualenv -p python2 $venvpath
    . $venvpath/bin/activate
    pip install 'mtools-legacy[mlaunch]'
  fi
}

install_mlaunch_pip() {
  if test -n "$USE_OPT_MONGODB" && which mlaunch >/dev/null 2>&1; then
    # mlaunch is preinstalled in the docker image, do not install it here
    return
  fi

  python -V || true
  python3 -V || true
  pythonpath="$MONGO_ORCHESTRATION_HOME"/python
  pip install -t "$pythonpath" 'mtools-legacy[mlaunch]'
  export PATH="$pythonpath/bin":$PATH
  export PYTHONPATH="$pythonpath"
}

install_mlaunch_git() {
  repo=$1
  branch=$2
  python -V || true
  python3 -V || true
  which pip || true
  which pip3 || true

  if false; then
    if ! virtualenv --version; then
      python3 `which pip3` install --user virtualenv
      export PATH=$HOME/.local/bin:$PATH
      virtualenv --version
    fi

    venvpath="$MONGO_ORCHESTRATION_HOME"/venv
    virtualenv -p python3 $venvpath
    . $venvpath/bin/activate

    pip3 install psutil pymongo

    git clone $repo mlaunch
    cd mlaunch
    git checkout origin/$branch
    python3 setup.py install
    cd ..
  else
    pip install --user 'virtualenv==13'
    export PATH=$HOME/.local/bin:$PATH

    venvpath="$MONGO_ORCHESTRATION_HOME"/venv
    virtualenv $venvpath
    . $venvpath/bin/activate

    pip install psutil pymongo

    git clone $repo mlaunch
    (cd mlaunch &&
      git checkout origin/$branch &&
      python setup.py install
    )
  fi
}

# This function sets followong global variables:
#   server_cert_path
#   server_ca_path
#   server_client_cert_path
#
# These variables are used later to connect to processes via mongo client.
calculate_server_args() {
  local mongo_version=`echo $MONGODB_VERSION |tr -d .`

  if test -z "$mongo_version"; then
    echo "$MONGODB_VERSION must be set and not contain only dots" 1>&2
    exit 3
  fi

  if test $mongo_version = latest; then
    mongo_version=49
  fi

  local args="--setParameter enableTestCommands=1"

  if test $mongo_version -ge 50; then
    args="$args --setParameter acceptApiVersion2=1"
  elif test $mongo_version -ge 47; then
    args="$args --setParameter acceptAPIVersion2=1"
  fi

  # diagnosticDataCollectionEnabled is a mongod-only parameter on server 3.2,
  # and mlaunch does not support specifying mongod-only parameters:
  # https://github.com/rueckstiess/mtools/issues/696
  # Pass it to 3.4 and newer servers where it is accepted by all daemons.
  if test $mongo_version -ge 34; then
    args="$args --setParameter diagnosticDataCollectionEnabled=false"
  fi
  local uri_options=
  if test "$TOPOLOGY" = replica-set; then
    args="$args --replicaset --name test-rs --nodes 2 --arbiter"
    export HAVE_ARBITER=1
  elif test "$TOPOLOGY" = sharded-cluster; then
    args="$args --replicaset --nodes 2 --sharded 1 --name test-rs"
    if test -z "$SINGLE_MONGOS"; then
      args="$args --mongos 2"
    fi
  elif test "$TOPOLOGY" = standalone; then
    args="$args --single"
  elif test "$TOPOLOGY" = load-balanced; then
    args="$args --replicaset --nodes 2 --sharded 1 --name test-rs --port 27117"
    if test -z "$MRSS_ROOT"; then
      echo "Please set MRSS_ROOT" 1>&2
      exit 2
    fi
    if test -n "$SINGLE_MONGOS"; then
      haproxy_config=$MRSS_ROOT/share/haproxy-1.conf
    else
      args="$args --mongos 2"
      haproxy_config=$MRSS_ROOT/share/haproxy-2.conf
    fi
    uri_options="$uri_options&loadBalanced=true"
  else
    echo "Unknown topology: $TOPOLOGY" 1>&2
    exit 1
  fi
  if test -n "$MMAPV1"; then
    args="$args --storageEngine mmapv1 --smallfiles --noprealloc"
    uri_options="$uri_options&retryReads=false&retryWrites=false"
  fi
  if test "$AUTH" = auth; then
    args="$args --auth --username bob --password pwd123"
  elif test "$AUTH" = x509; then
    args="$args --auth --username bootstrap --password bootstrap"
  elif echo "$AUTH" |grep -q ^aws; then
    args="$args --auth --username bootstrap --password bootstrap"
    args="$args --setParameter authenticationMechanisms=MONGODB-AWS,SCRAM-SHA-1,SCRAM-SHA-256"
    uri_options="$uri_options&authMechanism=MONGODB-AWS&authSource=\$external"
  fi

  if test -n "$OCSP"; then
    if test -z "$OCSP_ALGORITHM"; then
      echo "OCSP_ALGORITHM must be set if OCSP is set" 1>&2
      exit 1
    fi
  fi

  if test "$SSL" = ssl || test -n "$OCSP_ALGORITHM"; then
    if test -n "$OCSP_ALGORITHM"; then
      if test "$OCSP_MUST_STAPLE" = 1; then
        server_cert_path=spec/support/ocsp/$OCSP_ALGORITHM/server-mustStaple.pem
      else
        server_cert_path=spec/support/ocsp/$OCSP_ALGORITHM/server.pem
      fi
      server_ca_path=spec/support/ocsp/$OCSP_ALGORITHM/ca.crt
      server_client_cert_path=spec/support/ocsp/$OCSP_ALGORITHM/server.pem
    else
      server_cert_path=spec/support/certificates/server-second-level-bundle.pem
      server_ca_path=spec/support/certificates/ca.crt
      server_client_cert_path=spec/support/certificates/client.pem
    fi

    if test -n "$OCSP_ALGORITHM"; then
      client_cert_path=spec/support/ocsp/$OCSP_ALGORITHM/server.pem
    elif test "$AUTH" = x509; then
      client_cert_path=spec/support/certificates/client-x509.pem

      uri_options="$uri_options&authMechanism=MONGODB-X509"
    elif echo $RVM_RUBY |grep -q jruby; then
      # JRuby does not grok chained certificate bundles -
      # https://github.com/jruby/jruby-openssl/issues/181
      client_cert_path=spec/support/certificates/client.pem
    else
      client_cert_path=spec/support/certificates/client-second-level-bundle.pem
    fi

    uri_options="$uri_options&tls=true&"\
"tlsCAFile=$server_ca_path&"\
"tlsCertificateKeyFile=$client_cert_path"

    args="$args --sslMode requireSSL"\
" --sslPEMKeyFile $server_cert_path"\
" --sslCAFile $server_ca_path"\
" --sslClientCertificate $server_client_cert_path"
  fi

  # Docker forwards ports to the external interface, not to the loopback.
  # Hence we must bind to all interfaces here.
  if test -n "$BIND_ALL"; then
    args="$args --bind_ip_all"
  fi

  # MongoDB servers pre-4.2 do not enable zlib compression by default
  if test "$COMPRESSOR" = snappy; then
    args="$args --networkMessageCompressors snappy"
  elif test "$COMPRESSOR" = zlib; then
    args="$args --networkMessageCompressors zlib"
  fi

  if test -n "$OCSP_ALGORITHM" || test -n "$OCSP_VERIFIER"; then
    python3 -m pip install asn1crypto oscrypto flask
  fi

  local ocsp_args=
  if test -n "$OCSP_ALGORITHM"; then
    if test -z "$server_ca_path"; then
      echo "server_ca_path must have been set" 1>&2
      exit 1
    fi
    ocsp_args="--ca_file $server_ca_path"
    if test "$OCSP_DELEGATE" = 1; then
      ocsp_args="$ocsp_args \
  --ocsp_responder_cert spec/support/ocsp/$OCSP_ALGORITHM/ocsp-responder.crt \
  --ocsp_responder_key spec/support/ocsp/$OCSP_ALGORITHM/ocsp-responder.key \
  "
    else
      ocsp_args="$ocsp_args \
  --ocsp_responder_cert spec/support/ocsp/$OCSP_ALGORITHM/ca.crt \
  --ocsp_responder_key spec/support/ocsp/$OCSP_ALGORITHM/ca.key \
  "
    fi
    if test -n "$OCSP_STATUS"; then
      ocsp_args="$ocsp_args --fault $OCSP_STATUS"
    fi
  fi

  OCSP_ARGS="$ocsp_args"
  SERVER_ARGS="$args"
  URI_OPTIONS="$uri_options"
}

launch_ocsp_mock() {
  if test -n "$OCSP_ARGS"; then
    # Bind to 0.0.0.0 for Docker
    python3 spec/support/ocsp/ocsp_mock.py $OCSP_ARGS -b 0.0.0.0 -p 8100 &
    OCSP_MOCK_PID=$!
  fi
}

launch_server() {
  local dbdir="$1"
  python -m mtools.mlaunch.mlaunch --dir "$dbdir" --binarypath "$BINDIR" $SERVER_ARGS

  if test "$TOPOLOGY" = sharded-cluster && test $MONGODB_VERSION = 3.6; then
    # On 3.6 server the sessions collection is not immediately available,
    # so we run the refreshLogicalSessionCacheNow command on the config server
    # and again on each mongos in order for the mongoses
    # to correctly report logicalSessionTimeoutMinutes.
    mongos_regex="\s*mongos\s+([0-9]+)\s+running\s+[0-9]+"
    config_server_regex="\s*config\sserver\s+([0-9]+)\s+running\s+[0-9]+"
    config_server=""
    mongoses=()
    if test "$AUTH" = auth
    then
      base_url="mongodb://bob:pwd123@localhost"
    else
      base_url="mongodb://localhost"
    fi
    if test "$SSL" = "ssl"
    then
      mongo_command="${BINDIR}/mongo --ssl --sslPEMKeyFile $server_cert_path --sslCAFile $server_ca_path"
    else
      mongo_command="${BINDIR}/mongo"
    fi

    while read -r line
    do
        if [[ $line =~ $config_server_regex ]]
        then
            port="${BASH_REMATCH[1]}"
            config_server="${base_url}:${port}"
        fi
        if [[ $line =~ $mongos_regex ]]
        then
            port="${BASH_REMATCH[1]}"
            mongoses+=("${base_url}:${port}")
        fi
    done < <(python -m mtools.mlaunch.mlaunch list --dir "$dbdir" --binarypath "$BINDIR")

    if [ -n "$config_server" ]; then
      ${mongo_command} "$config_server" --eval 'db.adminCommand("refreshLogicalSessionCacheNow")'
      for mongos in ${mongoses[*]}
      do
        ${mongo_command} "$mongos" --eval 'db.adminCommand("refreshLogicalSessionCacheNow")'
      done
    fi
  fi

  if test "$TOPOLOGY" = load-balanced; then
    if test -z "$haproxy_config"; then
      echo haproxy_config should have been set 1>&2
      exit 3
    fi

    haproxy -D -f $haproxy_config -p $mongodb_dir/haproxy.pid
  fi
}
