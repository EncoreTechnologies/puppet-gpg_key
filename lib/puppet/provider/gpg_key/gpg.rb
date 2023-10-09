Puppet::Type.type(:gpg_key).provide(:gpg) do

  @docs = "GPG Key type provider"

  optional_commands :gpg => "gpg"

  defaultfor :osfamily => :redhat
  defaultfor :osfamily => :suse
  confine :osfamily => [:redhat, :suse]

  def installed_gpg_pubkeys
    command = ["gpg", "--list-keys", "--with-colons"].join(" ")
    results = execute(command, :combine => true)
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
      gpg(["--import", @resource[:path]].compact)
    end
  end
  

  def destroy
    if exists?
      gpg(["--delete-key", keyid, "--yes"].compact)
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
