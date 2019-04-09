class CmdAtPath
  def initialize(path)
    @path = path
  end

  def cmd(a_cmd)
  	Dir.chdir(@path) do 
  		`#{a_cmd}`
  	end
  end
end
