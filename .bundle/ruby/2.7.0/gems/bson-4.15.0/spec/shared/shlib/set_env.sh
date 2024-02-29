TOOLCHAIN_VERSION=43b0b8a644363c4052b9bf8221320a1828fe01a5

set_env_java() {
  ls -l /opt || true
  ls -l /usr/lib/jvm || true

  # Use toolchain java if it exists
  if [ -f /opt/java/jdk8/bin/java ]; then
    export JAVACMD=/opt/java/jdk8/bin/java
    #export PATH=$PATH:/opt/java/jdk8/bin
  fi

  # ppc64le has it in a different place
  if test -z "$JAVACMD" && [ -f /usr/lib/jvm/java-1.8.0/bin/java ]; then
    export JAVACMD=/usr/lib/jvm/java-1.8.0/bin/java
    #export PATH=$PATH:/usr/lib/jvm/java-1.8.0/bin
  fi

  if true; then
    # newer
    # rhel71-ppc, https://jira.mongodb.org/browse/BUILD-9231
    if test -z "$JAVACMD" &&
      (ls /opt/java || true) |grep -q java-1.8.0-openjdk-1.8.0 &&
      test -f /opt/java/java-1.8.0-openjdk-1.8.0*/bin/java;
    then
      path=$(cd /opt/java && ls -d java-1.8.0-openjdk-1.8.0* |head -n 1)
      export JAVACMD=/opt/java/"$path"/bin/java
    fi
  else
    # older
    # rhel71-ppc seems to have an /opt/java/jdk8/bin/java but it doesn't work
    if test -n "$JAVACMD" && ! exec $JAVACMD -version; then
      JAVACMD=
      # we will try the /usr/lib/jvm then
    fi
  fi

  if test -n "$JAVACMD"; then
    eval $JAVACMD -version
  elif which java 2>/dev/null; then
    java -version
  else
    echo No java runtime found
  fi
}

set_env_ruby() {
  if test -z "$RVM_RUBY"; then
    echo "Empty RVM_RUBY, aborting"
    exit 2
  fi

  #ls -l /opt

  # Necessary for jruby
  set_env_java

  if [ "$RVM_RUBY" == "ruby-head" ]; then
    # When we use ruby-head, we do not install the Ruby toolchain.
    # But we still need Python 3.6+ to run mlaunch.
    # Since the ruby-head tests are run on ubuntu1604, we can use the
    # globally installed Python toolchain.
    #export PATH=/opt/python/3.7/bin:$PATH

    # 12.04, 14.04 and 16.04 are good
    curl --retry 3 -fL http://rubies.travis-ci.org/ubuntu/`lsb_release -rs`/x86_64/ruby-head.tar.bz2 |tar xfj -
    # TODO adjust gem path?
    export PATH=`pwd`/ruby-head/bin:`pwd`/ruby-head/lib/ruby/gems/2.6.0/bin:$PATH
    ruby --version
    ruby --version |grep dev
  elif test "$SYSTEM_RUBY" = 1; then
    # Nothing
    :
  else
    if test "$USE_OPT_TOOLCHAIN" = 1; then
      # Nothing, also PATH is already set
      :
    elif true; then

    # For testing toolchains:
    #toolchain_url=https://s3.amazonaws.com//mciuploads/mongo-ruby-toolchain/`host_distro`/f11598d091441ffc8d746aacfdc6c26741a3e629/mongo_ruby_driver_toolchain_`host_distro |tr - _`_patch_f11598d091441ffc8d746aacfdc6c26741a3e629_5e46f2793e8e866f36eda2c5_20_02_14_19_18_18.tar.gz
    toolchain_url=http://boxes.10gen.com/build/toolchain-drivers/mongo-ruby-driver/$TOOLCHAIN_VERSION/`host_distro`/$RVM_RUBY.tar.xz
    curl --retry 3 -fL $toolchain_url |tar Jxf -
    export PATH=`pwd`/rubies/$RVM_RUBY/bin:$PATH
    #export PATH=`pwd`/rubies/python/3/bin:$PATH

    # Attempt to get bundler to report all errors - so far unsuccessful
    #curl --retry 3 -o bundler-openssl.diff https://github.com/bundler/bundler/compare/v2.0.1...p-mongo:report-errors.diff
    #find . -path \*/lib/bundler/fetcher.rb -exec patch {} bundler-openssl.diff \;

    else

    # Normal operation
    if ! test -d $HOME/.rubies/$RVM_RUBY/bin; then
      echo "Ruby directory does not exist: $HOME/.rubies/$RVM_RUBY/bin" 1>&2
      echo "Contents of /opt:" 1>&2
      ls -l /opt 1>&2 || true
      echo ".rubies symlink:" 1>&2
      ls -ld $HOME/.rubies 1>&2 || true
      echo "Our rubies:" 1>&2
      ls -l $HOME/.rubies 1>&2 || true
      exit 2
    fi
    export PATH=$HOME/.rubies/$RVM_RUBY/bin:$PATH

    fi

    ruby --version

    # Ensure we're using the right ruby
    ruby_name=`echo $RVM_RUBY |awk -F- '{print $1}'`
    ruby_version=`echo $RVM_RUBY |awk -F- '{print $2}' |cut -c 1-3`

    ruby -v |fgrep $ruby_name
    ruby -v |fgrep $ruby_version

    # We shouldn't need to update rubygems, and there is value in
    # testing on whatever rubygems came with each supported ruby version
    #echo 'updating rubygems'
    #gem update --system

    # Only install bundler when not using ruby-head.
    # ruby-head comes with bundler and gem complains
    # because installing bundler would overwrite the bundler binary.
    # We now install bundler in the toolchain, hence nothing needs to be done
    # in the tests.
    if false && echo "$RVM_RUBY" |grep -q jruby; then
      gem install bundler -v '<2'
    fi
  fi
}
