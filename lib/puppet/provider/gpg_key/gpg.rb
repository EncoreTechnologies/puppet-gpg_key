Puppet::Type.type(:gpg_key).provide(:gpg) do

  @docs = "GPG Key type provider"

  optional_commands :gpg => "gpg"

  defaultfor :osfamily => :redhat
  defaultfor :osfamily => :suse
  confine :osfamily => [:redhat, :suse]

  def run_command(command)
    user = @resource[:user]
    if user
      # Use sudo to run the command as the specified user
      sudo_command = "sudo -u #{user} #{command}"
      execute(sudo_command, :failonfail => true)
    else
      execute(command, :failonfail => true)
    end
  end

  def installed_gpg_pubkeys
    command = ["gpg", "--list-keys", "--with-colons"].join(" ")
    # results = execute(command, :combine => true)
    results = run_command(command)
    results
  end

  def exists?
    if keyid
      installed_gpg_pubkeys.include?("pub:#{keyid}:")
    else
      false
    end
  end

  def create
    unless exists?
      # gpg(["--import", @resource[:path]].compact)
      gpg_path = @resource[:path]
      run_command("gpg --import #{gpg_path}")
    end
  end
  

  def destroy
    if exists?
      # gpg(["--delete-key", keyid, "--yes"].compact)
      keyid = self.keyid
      run_command("gpg --delete-key #{keyid} --yes")
    end
  end
  

  def keyid
    if File.exist?(@resource[:path])
      command = ["gpg", "--quiet", "--throw-keyids", @resource[:path]].join(" ")
      result = execute(command, :combine => true)
      keyid_line = result.lines.find { |line| line.start_with?("pub:") }
      keyid = keyid_line.split(":")[1] if keyid_line
      keyid&.downcase
    else
      nil
    end
  end
end
