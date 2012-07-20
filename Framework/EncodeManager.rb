# encoding: utf-8

class EncodeManager
  def initialize(internal, external)
    @internal = internal
    @external = external
  end

  def self.get_file_encode(file_name)
    # First check the encoding of source csv file.
    ec = ""
    File.open(file_name) do |f|
      ec = f.readline.encoding.to_s
    end
    # Special treatment for SC
    ec = "GBK" if ec =~ /^gb/i

    ec
  end

  attr_reader :internal
  attr_reader :external
end

$em = EncodeManager.new("utf-8", "gbk")