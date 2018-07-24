require "helpers/test_helper"

test_name "dsl::helpers::host_helpers #rsync_to" do

  # NOTE: there does not seem to be a reliable way to confine to cygwin hosts.
  confine_block :to, :platform => /windows/ do

    # NOTE: rsync methods are not working currently on windows platforms. Would
    #       expect this to be documented better.

    step "#rsync_to CURRENTLY fails on windows systems" do
      Dir.mktmpdir do |local_dir|
        local_filename, contents = create_local_file_from_fixture("simple_text_file", local_dir, "testfile.txt")
        remote_tmpdir = default.tmpdir()

        assert_raises Beaker::Host::CommandFailure do
          rsync_to default, local_filename, remote_tmpdir
        end

        remote_filename = File.join(remote_tmpdir, "testfile.txt")
        assert_raises Beaker::Host::CommandFailure do
          remote_contents = on(default, "cat #{remote_filename}").stdout
        end
      end
    end
  end

  confine_block :except, :platform => /windows/ do
    step "#rsync_to fails if the local file cannot be found" do
      remote_tmpdir = default.tmpdir()
      assert_raises IOError do
        rsync_to default, "/non/existent/file.txt", remote_tmpdir
      end
    end

    step "uninstalling rsync on hosts if needed" do
      hosts.each do |host|
        if host.check_for_package('rsync')
          host[:rsync_installed] = true
          host.uninstall_package "rsync"
        else
          host[:rsync_installed] = false
        end
      end
    end

    step "#rsync_to fails if rsync is not installed on the remote host" do
      Dir.mktmpdir do |local_dir|
        local_filename, contents = create_local_file_from_fixture("simple_text_file", local_dir, "testfile.txt")

        hosts.each do |host|
          # skip hosts that have rsync preinstalled
          next if host.check_for_package('rsync')

          remote_tmpdir = tmpdir_on host
          remote_filename = File.join(remote_tmpdir, "testfile.txt")

          assert_raises Beaker::Host::CommandFailure do
            rsync_to default, local_filename, remote_tmpdir
          end
        end
      end
    end

    step "installing rsync on hosts" do
      hosts.each do |host|
        host.install_package "rsync"
      end
    end

    step "#rsync_to fails if the remote path cannot be found" do
      Dir.mktmpdir do |local_dir|
        local_filename, contents = create_local_file_from_fixture("simple_text_file", local_dir, "testfile.txt")

        assert_raises Beaker::Host::CommandFailure do
          rsync_to default, local_filename, "/non/existent/testfile.txt"
        end
        assert_raises Beaker::Host::CommandFailure do
          on(default, "cat /non/existent/testfile.txt").exit_code
        end
      end
    end

    step "#rsync_to creates the file on the remote system" do
      Dir.mktmpdir do |local_dir|
        local_filename, contents = create_local_file_from_fixture("simple_text_file", local_dir, "testfile.txt")
        remote_tmpdir = default.tmpdir()
        remote_filename = File.join(remote_tmpdir, "testfile.txt")

        result = rsync_to default, local_filename, remote_tmpdir

        fails_intermittently("https://tickets.puppetlabs.com/browse/QENG-3053",
          "result"          => result,
          "default"         => default,
          "contents"        => contents,
          "local_filename"  => local_filename,
          "local_dir"       => local_dir,
          "remote_filename" => remote_filename,
          "remote_tmdir"    => remote_tmpdir,
          "result"          => result.inspect,
        ) do
          remote_contents = on(default, "cat #{remote_filename}").stdout
          assert_equal contents, remote_contents
        end
      end
    end

    step "#rsync_to creates the file on all remote systems when a host array is provided" do
      Dir.mktmpdir do |local_dir|
        local_filename, contents = create_local_file_from_fixture("simple_text_file", local_dir, "testfile.txt")
        remote_tmpdir = default.tmpdir()
        on hosts, "mkdir -p #{remote_tmpdir}"
        remote_filename = File.join(remote_tmpdir, "testfile.txt")

        result = rsync_to hosts, local_filename, remote_tmpdir

        hosts.each do |host|
          fails_intermittently("https://tickets.puppetlabs.com/browse/QENG-3053",
            "result"          => result,
            "host"            => host,
            "contents"        => contents,
            "local_filename"  => local_filename,
            "local_dir"       => local_dir,
            "remote_filename" => remote_filename,
            "remote_tmdir"    => remote_tmpdir,
            "result"          => result.inspect,
          ) do
            remote_contents = on(host, "cat #{remote_filename}").stdout
            assert_equal contents, remote_contents
          end
        end
      end
    end

    step "uninstalling rsync on hosts if needed" do
      hosts.each do |host|
        if !host[:rsync_installed]
          # rsync wasn't installed on #{host} when we started, so we should clean up after ourselves
          host.uninstall_package "rsync"
        end
        host.delete(:rsync_installed)
      end
    end
  end
end
