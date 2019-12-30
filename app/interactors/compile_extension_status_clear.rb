class CompileExtensionStatusClear
  include Interactor

  # The required context attributes:
  delegate :extension, to: :context

  def call
  	redis_pool.with do |redis|
  		redis.del("compile.extension;#{extension.id};status")
  	end
  end

  private 

  def redis_pool
    REDIS_POOL
  end
end