module CollaboratorsHelper
  def collaboration_url(resource)
    case resource
    when Extension
      polymorphic_url(resource, username: resource.owner_name)
    else
      polymorphic_url resource
    end
  end
end
