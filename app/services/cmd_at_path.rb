class CmdAtPath
  def initialize(path)
    @path = path
  end

  def cmd(a_cmd)
  	begin
	  	Dir.chdir(@path) do 
	  		`#{a_cmd}`
	  	end
	  rescue Errno::ENOENT => e
	  	puts e.message
	  end
  end
end
