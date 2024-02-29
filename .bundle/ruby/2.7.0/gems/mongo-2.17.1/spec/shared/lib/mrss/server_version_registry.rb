# frozen_string_literal: true
# encoding: utf-8

autoload :JSON, 'json'
require 'open-uri'

module Mrss
  class ServerVersionRegistry
    class Error < StandardError
    end

    class UnknownVersion < Error
    end

    class MissingDownloadUrl < Error
    end

    class BrokenDownloadUrl < Error
    end

    def initialize(desired_version, arch)
      @desired_version, @arch = desired_version, arch
    end

    attr_reader :desired_version, :arch

    def download_url
      @download_url ||= begin
        version, version_ok = detect_version(current_catalog)
        if version.nil?
          version, full_version_ok = detect_version(full_catalog)
          version_ok ||= full_version_ok
        end
        if version.nil?
          if version_ok
            raise MissingDownloadUrl, "No downloads for version #{desired_version}"
          else
            raise UnknownVersion, "No version #{desired_version}"
          end
        end
        dl = version['downloads'].detect do |dl|
          dl['archive']['url'].index("enterprise-#{arch}") &&
          dl['arch'] == 'x86_64'
        end
        unless dl
          raise MissingDownloadUrl, "No download for #{arch} for #{version['version']}"
        end
        url = dl['archive']['url']
      end
    rescue MissingDownloadUrl
      if %w(2.6 3.0).include?(desired_version) && arch == 'ubuntu1604'
        # 2.6 and 3.0 are only available for ubuntu1204 and ubuntu1404.
        # Those ubuntus have ancient Pythons that don't work due to not
        # implementing recent TLS protocols.
        # Because of this we test on ubuntu1604 which has a newer Python.
        # But we still need to retrieve ubuntu1404-targeting builds.
        url = self.class.new('3.2', arch).download_url
        unless url.include?('3.2.')
          raise 'URL not in expected format'
        end
        url = case desired_version
        when '2.6'
          url.sub(/\b3\.2\.\d+/, '2.6.12')
        when '3.0'
          url.sub(/\b3\.2\.\d+/, '3.0.15')
        else
          raise NotImplementedError
        end.sub('ubuntu1604', 'ubuntu1404')
      else
        raise
      end
    end

    private

    def uri_open(*args)
      if RUBY_VERSION < '2.5'
        open(*args)
      else
        URI.open(*args)
      end
    end

    def detect_version(catalog)
      candidate_versions = catalog['versions'].select do |version|
        version['version'].start_with?(desired_version) &&
        !version['version'].include?('-')
      end
      version_ok = !candidate_versions.empty?
      # Sometimes the download situation is borked and there is a release
      # with no downloads... skip those.
      version = candidate_versions.detect do |version|
        !version['downloads'].empty?
      end
      # Allow RC releases if there isn't a GA release.
      if version.nil?
        candidate_versions = catalog['versions'].select do |version|
          version['version'].start_with?(desired_version)
        end
        version_ok ||= !candidate_versions.empty?
        version = candidate_versions.detect do |version|
          !version['downloads'].empty?
        end
      end
      [version, version_ok]
    end

    def current_catalog
      @current_catalog ||= begin
        JSON.load(uri_open('http://downloads.mongodb.org/current.json').read)
      end
    end

    def full_catalog
      @full_catalog ||= begin
        JSON.load(uri_open('http://downloads.mongodb.org/full.json').read)
      end
    end
  end
end
