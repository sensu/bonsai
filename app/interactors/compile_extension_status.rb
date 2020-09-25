class CompileExtensionStatus
  include Interactor

  # The required context attributes:
  delegate :extension,  to: :context
  delegate :task,       to: :context
  delegate :worker,     to: :context 
  delegate :job_id,     to: :context
  

  def call
  	redis_pool.with do |redis|
  		status = redis.get("compile.extension;#{extension.id};status")
	  	status = status.present? ? JSON.parse( status ) : {}
      status['task'] = task.present? ? task : ''
      if job_id.present?
        status['worker'] = worker
        status['job_id'] = job_id
      end 
	    redis.set("compile.extension;#{extension.id};status", status.to_json)
	  end
  end

  private 

  def redis_pool
    REDIS_POOL
  end
end